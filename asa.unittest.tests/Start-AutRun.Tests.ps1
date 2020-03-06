﻿### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

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

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
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

        Mock New-AutRunFixture {return @{test="001"}}
        It "runs without an asaNugetVersion" {
            Start-AutRun `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunJob -Times 1 -Scope It -ParameterFilter { $exePath -like "*$t_asaNugetVersion*"}
        }
        Mock New-AutRunFixture {}

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

        Mock Test-Path {return $false} -ParameterFilter {$path -like "*sa.exe"}
        It "fails if asaNugetVersion doesn't lead to sa.exe" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}

    }
}

Describe "Start-AutRun parameter solutionPath" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}

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
        
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_solutionPath}
        It "fails with an empty/invalid solutionPath" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}

        Mock Test-Path {return $false} -ParameterFilter {$path -like "*sa.exe"}
        It "fails if solutionPath doesn't lead to sa.exe" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}

    }
}

Describe "Start-AutRun parameter asaProjectName" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}

        $t_solutionPath = "foo"
        It "runs with a asaProjectName" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It
        }

        It "fails without a asaProjectName" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }

        $t_asaProjectName = ""
        It "fails with an empty solutionPath" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }

        $t_asaProjectName = " "
        It "fails with an invalid asaProjectName (space)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }

        $t_asaProjectName = "aa"
        It "fails with an invalid solutionPath (2char)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }

        $t_asaProjectName = "aaa+9"
        It "fails with an invalid solutionPath (invalid char)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }

        $t_asaProjectName = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        It "fails with an invalid solutionPath (over 63char)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
    }
}

Describe "Start-AutRun parameter unittestFolder" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
 
        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}

        It "runs with a valid unittestFolder" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It
        }

        It "runs without a unittestFolder" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName} |
            Should -not -throw
        }

        It "loads the default unittestFolder" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Scope It -ParameterFilter { $unittestFolder -eq $t_unittestFolder}
        }
        
        Mock Test-Path {return $false} -ParameterFilter {$path -like "*sa.exe"}
        It "fails if unittest doesn't lead to sa.exe" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}

    }
}

