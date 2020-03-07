<#
.SYNOPSIS
Controller script used to generate results of a test run

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

.PARAMETER testCase
Current test to be run (001, 002, 003...)

.EXAMPLE
Get-AutRunResult -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder -testID $testID -testCase $testCase
#>

Function Get-AutRunResult{

    [CmdletBinding()]
    param (
        [string]$solutionPath = $(Throw "-solutionPath is required"),
        [string]$asaProjectName = $(Throw "-asaProjectName is required"),
        [string]$unittestFolder = $(Throw "-unittestFolder is required"),
        [string]$testID = $(Throw "-testID is required"),
        [string]$testCase = $(Throw "-testCase is required")
    )

    BEGIN {}

    PROCESS {
        $errorCounter = 0
        
        $testPath = "$solutionPath\$unittestFolder\3_assert\$testID\$testCase"
        $outputSourcePath = "$testPath\$asaProjectName\Inputs"

        $testFiles = (Get-ChildItem -Path $outputSourcePath -File) 

        $testDetails = $testFiles | Select-Object `
        @{Name = "FullName"; Expression = {$_.Name}}, `
        @{Name = "FilePath"; Expression = {$_.Fullname}}, `
        @{Name = "Basename"; Expression = {$_.Basename}}, `
        @{Name = "TestCase"; Expression = {$parts = $_.Basename.Split("~"); $parts[0]}}, `
        @{Name = "FileType"; Expression = {$parts = $_.Basename.Split("~"); $parts[1]}}, `
        @{Name = "SourceName"; Expression = {$parts = $_.Basename.Split("~"); $parts[2]}}, `
        @{Name = "TestLabel"; Expression = {$parts = $_.Basename.Split("~"); $parts[3]}}

        $testDetails | Where-Object { $_.FileType -eq"Output" } |
        Select-Object `
            FullName,
            SourceName,
            TestCase,
            @{Name = "rawContent"; Expression = {"$testPath\$($_.SourceName).json"}}, #sa.exe output
            @{Name = "testableFilePath"; Expression = {"$testPath\$($_.SourceName).testable.json"}}, #to be generated
            @{Name = "testCaseOutputFile"; Expression = {"$testPath\$asaProjectName\Inputs\$($_.FullName)"}} |
        Foreach-Object -process {
            $testableContent = "[$(Get-Content -Path $_.rawContent)]"; #adding brackets
            Add-Content -Path $_.testableFilePath -Value $testableContent;
            $testResult = jsondiffpatch $_.testCaseOutputFile $_.testableFilePath;
            $testResult | Out-File "$testPath\$($_.SourceName).Result.txt"
            if ($testResult) {$errorCounter++}
        }

        $errorCounter

    } #PROCESS
    END {}
}