### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "Start-AutRun parameter asaNugetVersion" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}

        $t_asaNugetVersion = "2.3.0"
        It "runs with a valid asaNugetVersion" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It
        }

        It "runs without a asaNugetVersion" {
            Start-AutRun `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It
        }

        $t_asaNugetVersion = "1.0.0"
        It "fails with a invalid asaNugetVersion" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }

        $t_asaNugetVersion = ""
        It "fails with an empty asaNugetVersion" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
    }
}

Describe "Start-AutRun parameter solutionPath" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}

        $t_solutionPath = "foo"
        It "runs with a valid solutionPath" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It
        }

        It "runs without a solutionPath" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -not -throw
        }

        $ENV:BUILD_SOURCESDIRECTORY = $t_solutionPath
        It "loads the default solutionPath from ENV" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It -ParameterFilter { $solutionPath -eq $t_solutionPath}
        }
        
        $solutionPath = ""
        It "fails with an empty/invalid solutionPath" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
    }
}
