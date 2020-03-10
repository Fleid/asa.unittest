### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Get-AutRunResult.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\Get-AutRunResult.ps1


Describe "Get-AutRunResult Nominal" {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"
        $t_testCase = "123"

        Mock Get-ChildItem {}
        Mock Get-Content {}
        Mock Out-File {}

        It "tries to get a list of files" {
            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase  | Out-Null |
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It
        }

        It "tries nothing if it gets nothing" {
            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase  | Out-Null |
            Assert-MockCalled Out-File -Times 0  -Exactly -Scope It
        }
    }
}
