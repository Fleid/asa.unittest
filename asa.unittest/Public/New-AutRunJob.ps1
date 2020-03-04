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
        [string]$saPath,
        [string]$testPath,
        [string]$testCase,
        [string]$asaProjectName
    )

    BEGIN {}

    PROCESS {
        Start-Job -ArgumentList $saPath,$testPath,$testCase,$asaProjectName -ScriptBlock{
            param($saPath,$testPath,$testCase,$asaProjectName)
            & $saPath localrun -Project $testPath\$testCase\$asaProjectName\$asaProjectName.asaproj -OutputPath $testPath\$testCase} |   
        Out-Null

    } #PROCESS
    END {}
}