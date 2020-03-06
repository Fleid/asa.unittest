<#
.SYNOPSIS
Companion script used to install the dependencies required for the main package

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7 
PS: VSCode has a weird behavior on that topic, use Terminal : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

This script will first download nuget.exe, the Nuget CLI tool for Windows. See https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools#nugetexe-cli
After that nuget.exe will be invoked to install the required packages from nuget.

Finally the script will invoke npm to install the npm packages.
These packages will be installed globally (npm install -g).
If npm is not available, please download node.js. See https://nodejs.org/en/download/

.PARAMETER installPath
Path to the folder in the fixture that will contain the dependencies, usually (solutionPath\asaProjectName.Tests\2_act)

.PARAMETER npmPackages
List of npm packages to install

.PARAMETER nugetPackages
List of nuget packages to install

.EXAMPLE
Install-AutToolset -installPath C:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\2_act -npmpackages jsondiffpatch -nugetpackages Microsoft.Azure.StreamAnalytics.CICD
#>

Function Install-AutToolset{

    [CmdletBinding()]
    param (
        [string]$installPath = $(Throw "-asaProjectName is required"),
        [string[]]$npmPackages, # = @("jsondiffpatch"),
        [string[]]$nugetPackages # = @("Microsoft.Azure.StreamAnalytics.CICD")
    )

    BEGIN {
        if (-not (Test-Path $installPath)) {New-Item -ItemType Directory -Path $installPath | Out-Null}
    }

    PROCESS {

        if ($nugetPackages.Count -gt 0){

            if (-not (Test-Path -Path "$installPath\nuget.exe" -PathType Leaf)){
                # Windows - get nuget.exe from https://www.nuget.org/downloads
                Write-Verbose "001 - Download nuget.exe"
                Invoke-WebRequest `
                    -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe `
                    -OutFile (Join-Path $installPath "nuget.exe") |
                    Out-Null
            }

            foreach ($nugetPackage in $nugetPackages){
                Write-Verbose "002 - Installing nuget package : $nugetPackage"
                Invoke-Expression -Command "$installPath\nuget.exe install $nugetPackage -OutputDirectory $installPath" |
                    Out-Null
            }
        } #IF nuget

        if ($npmPackages.Count -gt 0){
            foreach ($npmPackage in $npmPackages){
                Write-Verbose "003 - Installing npm package : $npmPackage"
                Invoke-Expression -Command "npm install -g $npmPackage" |
                    Out-Null
            }
        } #IF npm

    } # PROCESS
    END {}
}