<#
.SYNOPSIS
PowerShell script used to install the dependencies required for the main unit test script to run

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7 
PS: VSCode has a weird behavior on that topic, use Terminal : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
This script will first download nuget.exe, the Nuget CLI tool for Windows. See https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools#nugetexe-cli

After that nuget.exe will be invoked to install the Microsoft.Azure.StreamAnalytics.CICD package from nuget. See https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/
This package contains sa.exe, the tool used to run unit tests.

Finally the script will invoke npm to install the jsondiffpatch package. See https://www.npmjs.com/package/jsondiffpatch
This package will be installe globally (npm install -g).
If npm is not available, please download node.js. See https://nodejs.org/en/download/

.PARAMETER ASAnugetVersion
Version of the Azure Stream Analytics CI/CD nuget package (Microsoft.Azure.StreamAnalytics.CICD) to be downloaded and used

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_Arrange, 2_act...), usually "unittest"

.EXAMPLE
.\unittest_install.ps1 -solutionPath "C:\Users\Florian\Source\Repos\utASAHello" -verbose
.\unittest_install.ps1 -solutionPath "C:\Users\Florian\Source\Repos\utASAHello" -ASAnugetVersion 2.4.0 -unittestFolder ut
#>

[CmdletBinding()]
param (
    [ValidateSet("2.3.0")]
    [string]$ASAnugetVersion = "2.3.0",
    [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY,
    [string]$unittestFolder ="unittest"
)

Set-Location "$solutionPath\$unittestFolder\2_act" |
    Out-Null

# Windows - get nuget.exe from https://www.nuget.org/downloads
Write-Verbose "001 - Download nuget.exe"
Invoke-WebRequest `
    -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe `
    -OutFile nuget.exe |
    Out-Null

# Install ASA CI/CD package from nuget
Write-Verbose "002 - Install ASA.CICD nuget package"
Invoke-Expression "./nuget install Microsoft.Azure.StreamAnalytics.CICD -version $ASAnugetVersion" |
    Out-Null

# Install jsondiffpatch from npm
Write-Verbose "003 - Install jsondiffpatch npm package"
Invoke-Expression "npm install -g jsondiffpatch" |
    Out-Null
