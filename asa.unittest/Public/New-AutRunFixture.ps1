<#
.SYNOPSIS
Controller script used to generate the fixture required for a test run

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project = name of the project folder = name of the query in that folder (.asaql) = name of the project description file (.asaproj)

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_arrange, 2_act, 3_assert), usually "asaProjectName.Tests"

.PARAMETER testId
Timestamp of the test run (yyyyMMddHHmmss), will be used in the folder structure

.EXAMPLE
New-AutRunFixture -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder -testID $testID
#>

Function New-AutRunFixture{

    [CmdletBinding()]
    param (
        [string]$solutionPath = $(Throw "-solutionPath is required"),
        [string]$asaProjectName = $(Throw "-asaProjectName is required"),
        [string]$unittestFolder = $(Throw "-unittestFolder is required"),
        [string]$testID = $(Throw "-testID is required")
    )

    BEGIN {
        if (-not (Test-Path($solutionPath))) {throw "$solutionPath is not a valid path"}

        $asaProjectPath = "$solutionPath\$asaProjectName"
        if (-not (Test-Path($asaProjectPath))) {throw "$solutionPath\$asaProjectName is not a valid path"}

        $arrangePath = "$solutionPath\$unittestFolder\1_arrange"
        if (-not (Test-Path($asaProjectPath))) {throw "$solutionPath\$unittestFolder\1_arrange is not a valid path"}

        $testPath = "$solutionPath\$unittestFolder\3_assert\$testID"
        if (-not (Test-Path($asaProjectPath))) {throw "$solutionPath\$unittestFolder\3_assert\$testID is not a valid path"}

    }

    PROCESS {

        $testDetails = (Get-ChildItem -Path $arrangePath -File) | 
            Get-AutFieldFromFileInfo -s "~" -n 4 |
            Select-Object `
                FullName, `
                FilePath, `
                Basename, `
                @{Name = "TestCase"; Expression = {$_.Basename0}}, `
                @{Name = "FileType"; Expression = {$_.Basename1}}, `
                @{Name = "SourceName"; Expression = {$_.Basename2}}, `
                @{Name = "TestLabel"; Expression = {$_.Basename3}}

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
                    New-AUTAsaprojXML -asaProjectName $asaProjectName -solutionPath $_.Path
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

        ## Output Pipeline
        $testDetails.TestCase | Sort-Object -Unique

    } #PROCESS
    END {}
}