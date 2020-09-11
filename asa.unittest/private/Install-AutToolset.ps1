<#
.SYNOPSIS
Companion script used to install a nuget package required for the main module

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7
PS: VSCode has a weird behavior on that topic, use Terminal : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

This script will first download nuget.exe, the Nuget CLI tool for Windows. See https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools#nugetexe-cli
After that nuget.exe will be invoked to install the required package from nuget.

.PARAMETER installPath
Path to the folder in the fixture that will contain the dependencies, usually (solutionPath\asaProjectName.Tests\2_act)

.PARAMETER packageHash
Hashtable of the package to install with the format @{type="nuget";package="Microsoft.Azure.StreamAnalytics.CICD";version="3.0.0"}

.EXAMPLE
Install-AutToolset -installPath C:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\2_act -packageHash @{type="nuget";package="Microsoft.Azure.StreamAnalytics.CICD";version="3.0.0"}
#>

Function Install-AutToolset{

    [CmdletBinding()]
    param (
        [string]$installPath = $(Throw "-installPath is required"),
        [hashtable]$packageHash # = @{type="nuget";package="Microsoft.Azure.StreamAnalytics.CICD";version="3.0.0"}
    )

    BEGIN {
        if (-not (Test-Path $installPath)) {New-Item -ItemType Directory -Path $installPath | Out-Null}
    }

    PROCESS {

        if ($packageHash.type -eq "nuget"){

            if (-not (Test-Path -Path "$installPath\nuget.exe" -PathType Leaf)){
                # Windows - get nuget.exe from https://www.nuget.org/downloads
                Write-Verbose "001 - Download nuget.exe"
                Invoke-WebRequest `
                    -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe `
                    -OutFile (Join-Path $installPath "nuget.exe") |
                    Out-Null
            }


            Write-Verbose "002 - Installing nuget package : $($packageHash.package)"
            if ($packageHash.version) {
                Invoke-External -l "$installPath\nuget.exe" install $packageHash.package -version $packageHash.version -OutputDirectory $installPath |
                Out-Null
            }
            else {
                Invoke-External -l "$installPath\nuget.exe" install $packageHash.package -OutputDirectory $installPath |
                Out-Null
            }
        }

    } # PROCESS
    END {}
}
