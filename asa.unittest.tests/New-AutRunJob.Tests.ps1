### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\New-AutRunJob.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\New-AutRunJob.ps1

Describe "New-AutRunJob Nominal" {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"
        $t_testCase = "123"
        $t_exePath = "foo.exe"

        #Mock Test-Path {return $true}
        Mock Start-Job {}

        It "runs" {
            New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath |
            Assert-MockCalled Start-Job -Times 1 -Exactly -Scope It
        }
    }
}
