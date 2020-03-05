<#
.SYNOPSIS
Powershell script used to...

.DESCRIPTION
This script will ...
See documentation for more information.

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.EXAMPLE
New-AutRunFixture -testDetails $testDetails -asaProjectName $asaProjectName -asaProjectPath $asaProjectPath -testPath $testPath
#>

Function New-AutRunJob{

    [CmdletBinding()]
    param (
        [string]$solutionPath,
        [string]$asaProjectName,
        [string]$unittestFolder,
        [string]$testID,
        [string]$testCase,
        [string]$exePath
    )

    BEGIN {}

    PROCESS {

        $testPath = "$solutionPath\$unittestFolder\3_assert\$testID"

        Start-Job -ArgumentList $exePath,$testPath,$testCase,$asaProjectName -ScriptBlock{
            param($exePath,$testPath,$testCase,$asaProjectName)
            & $exePath localrun -Project $testPath\$testCase\$asaProjectName\$asaProjectName.asaproj -OutputPath $testPath\$testCase} |   
        Out-Null

    } #PROCESS
    END {}
}