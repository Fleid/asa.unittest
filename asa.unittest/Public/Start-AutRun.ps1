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

        if ($assertPath -eq "" -or $assertPath -eq $null) {$assertPath = "$solutionPath\$unittestFolder\3_assert"}
        $testPath = "$assertPath\$timeStamp"

        $actPath = "$solutionPath\$unittestFolder\2_act"
        $saPath = "$actPath\Microsoft.Azure.StreamAnalytics.CICD.$ASAnugetVersion\tools\sa.exe"

        $errorCounter = 0


        ################################################################################################################################
        # 2xx - Arranging files
 
        $testCases = New-AutRunFixture -solutionPath $solutionPath -asaProjectName $asaProjectName -testPath $testPath -unittestFolder $unittestFolder

        ################################################################################################################################
        # 4xx - Running the test
        write-verbose "401 - Run SA in parallel jobs"

        ForEach ($testCase in $testCases) { New-AutRunJob -saPath $saPath -testPath $testPath -testCase $testCase -asaProjectName $asaProjectName }

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
        $errorCounter = Get-AutRunResult -testDetails $testDetails
        #$testDetails | ... | Out-Null

        ################################################################################################################################
        # Final result
        if ($errorCounter -gt 0) {Write-Verbose "Ending Test Run with $errorCounter errors"}
        if ($errorCounter -gt 0) {throw("Ending Test Run with $errorCounter errors")}
        
    } #PROCESS
    END {}
}