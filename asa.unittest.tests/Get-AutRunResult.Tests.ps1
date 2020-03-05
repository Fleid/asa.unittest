### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "Get-AutRunResult Nominal" {
    InModuleScope $moduleName {

        $solutionPath = "foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testID = "xxx"
        $testCase = "123"

        Mock Get-ChildItem {}
        Mock Get-Content {}
        Mock Out-File {}

        It "tries to get a list of files" {
            Get-AutRunResult `
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID `
                -testCase $testCase  | Out-Null |
            Assert-MockCalled Get-ChildItem -Times 1 -Scope It
        }

        It "tries nothing if it gets nothing" {
            Get-AutRunResult `
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID `
                -testCase $testCase  | Out-Null |
            Assert-MockCalled Out-File -Times 0  -Scope It
        }
    }
}
