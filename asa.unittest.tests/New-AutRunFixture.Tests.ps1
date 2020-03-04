### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "New-AutRunFixture Nominal" {
    InModuleScope $moduleName {

        $solutionPath = "foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testPath = "bar.Tests\3_assert\timestamp"

        #Mock Test-Path {return $true}
        Mock Get-ChildItem {}
        Mock New-Item {} -ParameterFilter { $ItemType -and $ItemType -eq "Directory" }
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock Out-File {}

        It "runs" {
            New-AutRunFixture -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder -testPath $testPath | 
            Assert-MockCalled New-Item -Times 0 -Scope It
        }
    }
}
