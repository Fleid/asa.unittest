<#
.SYNOPSIS
Controller script that start a job on a given executable
Potential to be upgraded to tool

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

.PARAMETER exePath
Path to sa.exe, usually $exePath = "$solutionPath\$unittestFolder\2_act\Microsoft.Azure.StreamAnalytics.CICD.$asaNugetVersion\tools\sa.exe"

.EXAMPLE
New-AutRunJob -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder -testID $testID -testCase $testCase -exePath $exePath
#>

Function New-AutRunJob{

    [CmdletBinding()]
    param (
        [string]$solutionPath = $(Throw "-solutionPath is required"),
        [string]$asaProjectName = $(Throw "-asaProjectName is required"),
        [string]$unittestFolder = $(Throw "-unittestFolder is required"),
        [string]$testID = $(Throw "-testID is required"),
        [string]$testCase = $(Throw "-testCase is required"),
        [string]$exePath = $(Throw "-exePath is required")
    )

    BEGIN {

        if (-not (Test-Path -Path $exePath -PathType Leaf)) {throw "No file found at $exePath"}

        $testPath = "$solutionPath\$unittestFolder\3_assert\$testID"
        if (-not (Test-Path -Path $testPath)) {throw "$testPath is not a valid path"}

    }

    PROCESS {

        Start-Job -ArgumentList $exePath,$testPath,$testCase,$asaProjectName -ScriptBlock{
            param($exePath,$testPath,$testCase,$asaProjectName)
            & $exePath localrun -Project $testPath\$testCase\$asaProjectName\$asaProjectName.asaproj -OutputPath $testPath\$testCase} |
        Out-Null

    } #PROCESS
    END {}
}