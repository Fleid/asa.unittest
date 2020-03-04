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
        [PSObject]$testDetails
    )

    BEGIN {}

    PROCESS {
        $errorCounter = 0

        $testDetails | Where-Object { $_.FileType -eq"Output" } |
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
        }

        $errorCounter 

    } #PROCESS
    END {}
}