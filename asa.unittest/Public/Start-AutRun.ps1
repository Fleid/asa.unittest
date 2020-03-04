<#
.SYNOPSIS
Powershell script used to run unit tests on an Azure Stream Analytics project

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7 
PS: VSCode has a weird behavior on that topic, use Terminal : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
This script will leverage a text fixture (folder structure + filename convention) to run unit tests for a given ASA project.

It requires dependencies installed by a companion script Install_AutToolset.ps1

See documentation for more information.

.PARAMETER ASAnugetVersion
Version of the Azure Stream Analytics CI/CD nuget package (Microsoft.Azure.StreamAnalytics.CICD) to be downloaded and used

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project = name of the project folder = name of the query in that folder (.asaql) = name of the project description file (.asaproj)

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_Arrange, 2_act...), usually "unittest"

.PARAMETER assertPath
Name of the target folder where test assets will be generated and test results will be output

.EXAMPLE
Start-AutRun.ps1 -asaProjectName "ASAHelloWorld" -solutionPath "C:\Users\fleide\Repos\asa.unittest" -assertPath "C:\Users\fleide\Repos\asa.unittest\unittest\3_assert"-verbose
#>

Function Start-AutRun{

    [CmdletBinding()]
    param (
        [ValidateSet("2.3.0")]
        [string]$ASAnugetVersion = "2.3.0",

        [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY, # Azure DevOps Pipelines default variable

        [Parameter(Mandatory=$True)]
        [string]$asaProjectName,

        [string]$unittestFolder = "unittest",
        [string]$assertPath = $ENV:COMMUB_TESTRESULTSDIRECTORY # Azure DevOps Pipelines default variable
    )

    BEGIN {}

    PROCESS {

        ################################################################################################################################
        write-verbose "101 - Set Variables"

        ## Set variables
        $timeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        $asaProjectPath = "$solutionPath\$asaProjectName"
        $arrangePath = "$solutionPath\$unittestFolder\1_arrange"
        $actPath = "$solutionPath\$unittestFolder\2_act"
        $testPath = "$assertPath\$timeStamp"


        $saPath = "$actPath\Microsoft.Azure.StreamAnalytics.CICD.$ASAnugetVersion\tools\sa.exe"

        $errorCounter = 0

        write-verbose "102 - Load tests (001, 002...)"

        $testFiles = (Get-ChildItem -Path $arrangePath -File) 

        $testDetails = $testFiles | Select-Object `
            @{Name = "FullName"; Expression = {$_.Name}}, `
            @{Name = "FilePath"; Expression = {$_.Fullname}}, `
            @{Name = "Basename"; Expression = {$_.Basename}}, `
            @{Name = "TestCase"; Expression = {$parts = $_.Basename.Split("~"); $parts[0]}}, `
            @{Name = "FileType"; Expression = {$parts = $_.Basename.Split("~"); $parts[1]}}, `
            @{Name = "SourceName"; Expression = {$parts = $_.Basename.Split("~"); $parts[2]}}, `
            @{Name = "TestLabel"; Expression = {$parts = $_.Basename.Split("~"); $parts[3]}}

        $testCases = $testDetails.TestCase | Sort-Object -Unique

        ################################################################################################################################
        # 2xx - Arranging files
        write-verbose "201 - Create and populate test folders"

        $testFolders = `
            $testDetails | 
            Select-Object @{Name = "Path"; Expression = {"$testPath\$($_.TestCase)"}} |
            Sort-Object -Property Path -Unique

        ## Create 1 folder for each test case
        $testFolders | New-Item -ItemType Directory | Out-Null

        ## Create an ASA project folder in test case folder
        $testFolders |
            Select-Object @{Name = "Path"; Expression = {"$($_.Path)\$asaProjectName\Inputs\"}} |
            New-Item -ItemType Directory |
            Out-Null

        ## Copy .asaql, .asaproj (XML) and JobConfig, asaproj (JSON) required for run in each test case folder
        $testFolders | 
            Select-Object @{Name="Destination"; Expression = {"$($_.Path)\$asaProjectName\"}} |
            Copy-Item -Path "$asaProjectPath\*.as*","$asaProjectPath\*.json" -recurse |
            Out-Null

        ## If there isn't a XML asaproj, generate it from the JSON one
        $testFolders | 
            ForEach-Object -Process {
                if (-not(Test-Path "$($_.Path)\$asaProjectName\$asaProjectName.asaproj" -PathType leaf)) {
                    $exe = "$actPath\New-AUTAsaproj.ps1"
                    & $exe -asaProjectName $asaProjectName -solutionPath $_.Path
                }
            }

        ## Copy the local input mock file required for run in each test case folder
        $testFolders | 
            Select-Object @{Name="Destination"; Expression = {"$($_.Path)\$asaProjectName\Inputs\"}} |
            Copy-Item -Path "$asaProjectPath\Inputs\Local*.json" -recurse |
            Out-Null

        ## Copy test files from 1_arrange to each test case folder 
        $testDetails | 
            Select-Object `
                @{Name = "Destination"; Expression = {"$testPath\$($_.TestCase)\$asaProjectName\Inputs\"}},
                @{Name = "Path"; Expression = {$_.FilePath}} |
            Copy-Item |
            Out-Null

        ################################################################################################################################
        # 3xx - Updating config files
        write-verbose "301 - Update each conf file"

        ## For each Input test file, edit the corresponding Local config file in the test case Input folder to point to it
        $testDetails | 
            Where-Object { $_.FileType -eq"Input" } |
            Select-Object `
                FullName,
                @{Name = "confFilePath"; Expression = {"$testPath\$($_.TestCase)\$asaProjectName\Inputs\Local_$($_.SourceName).json"}} |
            Foreach-Object -process {
                $localInputData = Get-Content $_.confFilePath | ConvertFrom-Json;
                $localInputData.FilePath = $_.FullName;
                $localInputData | ConvertTo-Json | Out-File $_.confFilePath
            } |
            Out-Null

        ################################################################################################################################
        # 4xx - Running the test
        write-verbose "401 - Run SA in parallel jobs"

        ForEach ($testCase in $testCases ){
            Start-Job -ArgumentList $saPath,$testPath,$testCase,$asaProjectName -ScriptBlock{
                param($saPath,$testPath,$testCase,$asaProjectName)
                & $saPath localrun -Project $testPath\$testCase\$asaProjectName\$asaProjectName.asaproj -OutputPath $testPath\$testCase} |   
            Out-Null
        }

        write-verbose "402 - Waiting for all jobs to end..."

        ## Wait for all jobs to complete and results ready to be received
        Wait-Job * | Out-Null

        write-verbose "403 - Jobs done"

        <#
        ## Process the results
        foreach($job in Get-Job)
        {
            $result = Receive-Job $job
            Write-Host $result
        }
        #>

        write-verbose "404 - Calculating diffs"
        ## For each Output test file, generate a testable file (adding brackets to it) then run the diff with the corresponding arranged output file
        $testDetails | 
            Where-Object { $_.FileType -eq"Output" } |
            Select-Object `
                FullName,
                SourceName,
                TestCase,
                @{Name = "rawContent"; Expression = {"$testPath\$($_.TestCase)\$($_.SourceName).json"}}, #sa.exe output
                @{Name = "testableFilePath"; Expression = {"$testPath\$($_.TestCase)\$($_.SourceName).testable.json"}}, #to be generated
                @{Name = "testCaseOutputFile"; Expression = {"$testPath\$($_.TestCase)\$asaProjectName\Inputs\$($_.FullName)"}} |
            Foreach-Object -process {
                $testableContent = "[$(Get-Content -Path $_.rawContent)]"; #adding brackets
                Add-Content -Path $_.testableFilePath -Value $testableContent;
                $testResult = jsondiffpatch $_.testCaseOutputFile $_.testableFilePath;
                $testResult | Out-File "$testPath\$($_.TestCase)\$($_.SourceName).Result.txt"
                if ($testResult) {$errorCounter++}
            } |
            Out-Null

        ################################################################################################################################
        # Final result
        if ($errorCounter -gt 0) {Write-Verbose "Ending Test Run with $errorCounter errors"}
        if ($errorCounter -gt 0) {throw("Ending Test Run with $errorCounter errors")}
        
    } #PROCESS
    END {}
}