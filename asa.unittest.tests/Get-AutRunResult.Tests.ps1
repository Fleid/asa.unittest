### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "Get-AutRunResultNominal" {
    InModuleScope $moduleName {

        $testDetail1 = New-Object PSObject -Property @{foo = "bar1"}
        $testDetail2 = New-Object PSObject -Property @{foo = "bar2"}
        $testDetails = @($testDetail1, $testDetail2)

        Mock Get-Content {}
        Mock Out-File {}

        It "runs" {
            Get-AutRunResult -testDetails $testDetails  | 
            Assert-MockCalled Out-File -Times 0 -Scope It
        }
    }
}
