# Developer experience

## Preparing the solution

Proper folder hierarchy:

ModuleRoot
|- Examples
|- Module.test
|- Module
    |- Private (.ps1 functions, if necessary)
    |- Public (.ps1 functions)
    |- Module.psm1 (module in auto loader mode, see the file directly)
    |- Module.psd1 (manifest auto generated via `New-ModuleManifest`

From there, the module can be loaded via:

```PowerShell
Import-Module -Name .\asa.unittest.psm1 -verbose -force
Remove-Module asa.unittest
```

## Development

Scripts should be isolated in atomic .ps1 file, written as advanced functions.
They can be loaded and ran directly.


## Testing

### Creating a new test

- Add a new fixture via `New-Fixture .\MyScript.ps1`
- Move the .test into asa.unittest.test
- Update its header to:

```PowerShell
### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
```

### Running a test

```PowerShell
cd asa.unittest.test
Invoke-Pester .\MyScript.Tests.ps1
Invoke-Pester
```
