<#
.SYNOPSIS
Companion script used to initialize an Azure Stream Analytics - Unit Testing test project

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7
PS: VSCode has a weird behavior on that topic, use Terminal : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

This script will create the required folder fixture, download the dependencies and add a gitignore file to protect against repo sprawl

.PARAMETER installPath
Path to the folder in the fixture that will contain the dependencies, usually (solutionPath\asaProjectName.Tests\2_act)

.EXAMPLE
Create-AutToolset -installPath C:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\
#>

Function New-AutProject{

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Low"
        )]
    param (
        [string]$installPath = $(Throw "-installPath is required")
    )

    BEGIN {
        if (-not (Test-Path $installPath)) {New-Item -ItemType Directory -Path $installPath | Out-Null}
    }

    PROCESS {
        if ($pscmdlet.ShouldProcess("Creating a new AUT project at $installPath"))
        {
            # Create folder structure
            if (-not (Test-Path "$installPath\1_arrange")) {New-Item -ItemType Directory -Path "$installPath\1_arrange" | Out-Null}
            if (-not (Test-Path "$installPath\2_act")) {New-Item -ItemType Directory -Path "$installPath\2_act" | Out-Null}
            if (-not (Test-Path "$installPath\3_assert")) {New-Item -ItemType Directory -Path "$installPath\3_assert" | Out-Null}

            # Install dependencies
            Install-AutToolset -installPath "$installPath\2_act" -npmpackages jsondiffpatch -nugetpackages Microsoft.Azure.StreamAnalytics.CICD

            $gitIgnoreContent = `
"
# testing dependencies
2_act/nuget.exe
2_act/Microsoft.Azure.StreamAnalytics.CICD.*/

# local test results
3_assert/*
"
            if (-not (Test-Path "$installPath\.gitignore" -PathType Leaf)) {$gitIgnoreContent | Out-File "$installPath\.gitignore"}

        } # SHOULD
    } # PROCESS
    END {}
}
