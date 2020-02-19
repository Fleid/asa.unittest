## Sourcing the module

- Created a auto loader module root (psm1)
- Created a default manifest (psd1) : `New-ModuleManifest –Path asa.unittest.psd1 –Root ./asa.unittest.psm1`
- All scripts are relocated in private/public, written as `function x {}` and saved as `.ps1`

- Loading the module:

```PowerShell
Import-Module -Name .\asa.unittest.psm1 -verbose -force
Remove-Module asa.unittest
```
