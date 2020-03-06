### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "New-AutRunJob Nominal" {
    InModuleScope $moduleName {

        $solutionPath = "foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testID = "xxx"
        $testCase = "123"
        $exePath = "foo.exe"

        #Mock Test-Path {return $true}
        Mock Start-Job {}

        It "runs" {
            New-AutRunJob `
            -solutionPath $solutionPath `
            -asaProjectName $asaProjectName `
            -unittestFolder $unittestFolder `
            -testID $testID `
            -testCase $testCase `
            -exePath $exePath |
            Assert-MockCalled Start-Job -Times 1 -Scope It
        }
    }
}
