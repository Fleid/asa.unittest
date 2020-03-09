### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "New-AutRunFixture parameters"  {
    InModuleScope $moduleName {

        $solutionPath = "TestDrive:\"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testID = "yyyymmddhhmmss"

        #Mock Test-Path {return $true}
        Mock Get-ChildItem {return (Get-ChildItem -Path $solutionPath -File)}
        Mock Get-AutFieldFromFileInfo {}
        Mock New-Item {} #-ParameterFilter { $ItemType -and $ItemType -eq "Directory" }
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock Out-File {}

        It "runs with a valid set of parameters" {
            New-AutRunFixture `
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID | Out-Null | 
            Assert-MockCalled Get-AutFieldFromFileInfo -Times 1 -Scope It
        }

        It "doesn't run without a solutionPath" {}

    }
}
