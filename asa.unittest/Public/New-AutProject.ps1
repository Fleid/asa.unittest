<#
.SYNOPSIS
Companion script used to initialize an Azure Stream Analytics - Unit Testing test project

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7
PS: VSCode has a weird behavior on that topic, use Terminal : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

This script will create the required folder fixture and download the dependencies

.PARAMETER installPath
Path to the folder in the fixture that will contain the dependencies, usually (solutionPath\asaProjectName.Tests\2_act)

.EXAMPLE
Create-AutToolset -installPath C:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\
#>

Function New-AutProject{

    [CmdletBinding()]
    param (
        [string]$installPath = $(Throw "-installPath is required")
    )

    BEGIN {
        if (-not (Test-Path $installPath)) {New-Item -ItemType Directory -Path $installPath | Out-Null}
    }

    PROCESS {
        # Create folder structure
        if (-not (Test-Path "$installPath\1_assert")) {New-Item -ItemType Directory -Path "$installPath\1_assert" | Out-Null}
        if (-not (Test-Path "$installPath\2_act")) {New-Item -ItemType Directory -Path "$installPath\2_act" | Out-Null}
        if (-not (Test-Path "$installPath\3_assert")) {New-Item -ItemType Directory -Path "$installPath\3_assert" | Out-Null}

        # Install dependencies
        Install-AutToolset -installPath "$installPath\2_act" -npmpackages jsondiffpatch -nugetpackages Microsoft.Azure.StreamAnalytics.CICD

    } # PROCESS
    END {}
}
