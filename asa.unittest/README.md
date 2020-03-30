# Developer Experience

## Solution

Folder hierarchy:

```Text
ModuleRoot
|- Examples
|- Module.test
|- Module
    |- Private (.ps1 functions, if necessary)
    |- Public (.ps1 functions)
    |- Module.psm1 (module in auto loader mode, see the file directly)
    |- Module.psd1 (manifest auto generated via `New-ModuleManifest`
```

Loading the module manually:

```PowerShell
$moduleFolder = "C:\Users\fleide\Repos\asa.unittest\asa.unittest"
$moduleFile = ".\asa.unittest.psm1"
Set-Location $moduleFolder
Import-Module -Name $moduleFile -verbose -force
#Remove-Module asa.unittest

```

Testing a run

```PowerShell
$installFolder = "C:\temp\fleide2\Repos\asa.unittest\examples\ASAHelloWorld.Tests\"
New-AutProject `
    -installPath $installFolder

$asaProjectName = "ASAHelloWorld"
$solutionPath = "C:\Users\fleide\Repos\asa.unittest\examples"
$unittestFolder = "ASAHelloworld.Tests"
Start-AutRun `
    -asaProjectName $asaProjectName `
    -solutionPath $solutionPath `
    -unittestFolder $unittestFolder `
    -verbose

```

From the Gallery

```PowerShell
Get-InstalledModule -name asa.unittest
Uninstall-Module -Name asa.unittest

Install-Module -Name asa.unittest -verbose
```

## Development

Scripts should be isolated in atomic .ps1 file, written as advanced functions. They can then be loaded and ran directly.

Common parameters:

```PowerShell
$ASAnugetVersion = "2.4.0"
$solutionPath = "C:\Users\fleide\Repos\asa.unittest\examples"
$asaProjectName = "ASAHelloWorld"
$unittestFolder = "ASAHelloWorld.Tests"
$testID = (Get-Date -Format "yyyyMMddHHmmss")

$exePath = "C:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\2_act\Microsoft.Azure.StreamAnalytics.CICD.2.4.0\tools\sa.exe"
```

## Testing

### Creating a new test

- Add a new fixture via `New-Fixture .\MyScript.ps1`
- Move the .test into `\asa.unittest.test`
- Update its header to:

```PowerShell
### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.."
#Look for the manifest to get to ModuleRoot\Module
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1")
#Extract the module name from above
$moduleName = Split-Path $moduleRoot -Leaf
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

###
```

### Running a test

```PowerShell
$testFolder = "C:\Users\fleide\Repos\asa.unittest\asa.unittest.tests"
Set-Location $testFolder
Invoke-Pester .\MyScript.Tests.ps1
Invoke-Pester

```

### Linting

```PowerShell
# Install-PackageProvider Nuget -MinimumVersion 2.8.5.201 –Force
Install-Module -Name PSScriptAnalyzer

$moduleFolder = "C:\Users\fleide\Repos\asa.unittest\asa.unittest"
Set-Location $moduleFolder
Invoke-ScriptAnalyzer -Path . -Recurse
Invoke-ScriptAnalyzer -Path .\public
Invoke-ScriptAnalyzer -Path .\private

```

### Code Coverage

Command in comment at the top each test file

## Publishing to the Gallery

```PowerShell
$moduleFolder = "C:\Users\fleide\Repos\asa.unittest\asa.unittest"
$moduleManifest = ".\asa.unittest.psd1"
Set-Location $moduleFolder
Test-ModuleManifest $moduleManifest -verbose

$rootFolder = "C:\Users\fleide\Repos\asa.unittest"
$modulePath = ".\asa.unittest"
$nugetApiKey = "XXX"
Set-Location $rootFolder

Publish-Module -Path $modulePath -WhatIf -Verbose -NuGetApiKey $nugetApiKey
Publish-Module -Path $modulePath -NuGetApiKey $nugetApiKey
```
