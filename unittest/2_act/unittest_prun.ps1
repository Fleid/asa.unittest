<#
.SYNOPSIS
Backward compatibility, now use Start-AutRun

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
.\unittest_prun.ps1 -asaProjectName "ASAHelloWorld" -solutionPath "C:\Users\fleide\Repos\asa.unittest" -assertPath "C:\Users\fleide\Repos\asa.unittest\unittest\3_assert"-verbose
#>

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

$command = `
    "$solutionPath\$unittestFolder\2_act\Start-AutRun.ps1 "+`
    "$(if ($ASAnugetVersion) {"-ASAnugetVersion $ASAnugetVersion"}) "+`
    "$(if ($solutionPath) {"-solutionPath $solutionPath"}) "+`
    "-asaProjectName $asaProjectName "+`
    "$(if ($unittestFolder) {"-unittestFolder $unittestFolder"}) "+`
    "$(if ($assertPath) {"-assertPath $assertPath"})"

Write-Host "Deprecated command - Invoking : $command"
Invoke-Expression $command
