<#
.SYNOPSIS
Backward compatibility, now use Install-AUTtoolset

.PARAMETER ASAnugetVersion
Version of the Azure Stream Analytics CI/CD nuget package (Microsoft.Azure.StreamAnalytics.CICD) to be downloaded and used

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_Arrange, 2_act...), usually "unittest"

#>

[CmdletBinding()]
param (
    [ValidateSet("2.3.0")]
    [string]$ASAnugetVersion = "2.3.0",
    [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY,
    [string]$unittestFolder ="unittest"
)

$command = `
    "$solutionPath\$unittestFolder\2_act\Install-AutToolset.ps1 "+`
    "$(if ($ASAnugetVersion) {"-ASAnugetVersion $ASAnugetVersion"}) "+`
    "$(if ($solutionPath) {"-solutionPath $solutionPath"}) "+`
    "$(if ($unittestFolder) {"-unittestFolder $unittestFolder"})"

Write-Host "Deprecated command - Invoking : $command"
Invoke-Expression $command