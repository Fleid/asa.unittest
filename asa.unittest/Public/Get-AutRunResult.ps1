<#
.SYNOPSIS
Powershell script used to...

.DESCRIPTION
This script will ...
See documentation for more information.

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.EXAMPLE
Get-AutRunResult -testDetails $testDetails 
#>

Function Get-AutRunResult{

    [CmdletBinding()]
    param (
        [string]$solutionPath,
        [string]$asaProjectName,
        [string]$unittestFolder,
        [string]$testID,
        [string]$testCase
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