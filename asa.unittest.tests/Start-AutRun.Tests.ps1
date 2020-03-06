﻿### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "Start-AutRun Nominal" {
    InModuleScope $moduleName {

        $ASAnugetVersion = "2.3.0"
        $solutionPath = "foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"

        #Mock Test-Path {return $true}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}

        It "runs" {
            Start-AutRun `
                -ASAnugetVersion $ASAnugetVersion `
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It
        }
    }
}
