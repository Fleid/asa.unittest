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

.PARAMETER testPath
Path to the test folder that will contain the fixture (1_arrange, 2_act, 3_assert sub-folders)

.EXAMPLE
Install-AutToolset -installPath C:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\2_Act $npmpackages jsondiffpatch #nugetpackages Microsoft.Azure.StreamAnalytics.CICD
#>

Function Install-AutToolset{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [string]$installPath,
        [string[]]$npmPackages, # = @("jsondiffpatch"),
        [string[]]$nugetPackages # = @("Microsoft.Azure.StreamAnalytics.CICD")
    )

    BEGIN {
        if (-not (Test-Path $installPath)) {New-Item -ItemType Directory -Path $installPath | Out-Null}
    }

    PROCESS {

        if ($nugetPackages.Count -gt 0){

            # Windows - get nuget.exe from https://www.nuget.org/downloads
            Write-Verbose "001 - Download nuget.exe"
            Invoke-WebRequest `
                -Uri https://dist.nuget.org/win-x86-commandline/latest/nuget.exe `
                -OutFile (Join-Path $installPath "nuget.exe") |
                Out-Null
            
            foreach ($nugetPackage in $nugetPackages){
                Write-Verbose "002 - Installing nuget package : $nugetPackage"
                Invoke-Expression -Command "./$installPath/nuget install $nugetPackage -OutputDirectory $installPath" |
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