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
        $t_exePath = "sa"

        Mock Test-Path {return $true}
        Mock Start-Job {}

        It "starts a job" {
            New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath

            Assert-MockCalled Start-Job -Times 1 -Exactly -Scope It
        }

        It "tests a job -WhatIf" {
            New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath `
            -WhatIf
            
            Assert-MockCalled Start-Job -Times 0 -Exactly -Scope It
        }
    }
}

Describe "New-AutRunJob Parameter" {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"
        $t_testCase = "123"
        $t_exePath = "foo.exe"

        Mock Test-Path {return $true}
        Mock Start-Job {}

        It "doesn't run if solutionPath is missing" {
            {New-AutRunJob `
            #-solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath} |
            Should -throw "-solutionPath is required"
        }

        It "doesn't run if asaProjectName is missing" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            #-asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath} |
            Should -throw "-asaProjectName is required"
        }

        It "doesn't run if unittestFolder is missing" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            #-unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath} |
            Should -throw "-unittestFolder is required"
        }

        It "doesn't run if testID is missing" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            #-testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath} |
            Should -throw "-testID is required"
        }

        It "doesn't run if testCase is missing" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            #-testCase $t_testCase `
            -exePath $t_exePath} |
            Should -throw "-testCase is required"
        }

        It "doesn't run if exePath is missing" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            #-exePath $t_exePath 
            }|
            Should -throw "-exePath is required"
        }
    }
}

Describe "New-AutRunJob Paths" {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"
        $t_testCase = "123"
        $t_exePath = "foo.exe"

        Mock Test-Path {return $true}
        Mock Start-Job {}

        Mock Test-Path {return $false} -ParameterFilter {$pathtype -eq "Leaf"}
        It "fails if there's no file at exePath" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath} |
            Should -throw "No file found at $exePath"
        }

        Mock Test-Path {return $true} -ParameterFilter {$pathtype -eq "Leaf"}
        $t_testPath = "$t_solutionPath\$t_unittestFolder\3_assert\$t_testID"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_testPath}
        It "doesn't run if testPath not valid" {
            {New-AutRunJob `
            -solutionPath $t_solutionPath `
            -asaProjectName $t_asaProjectName `
            -unittestFolder $t_unittestFolder `
            -testID $t_testID `
            -testCase $t_testCase `
            -exePath $t_exePath 
            }|
            Should -throw "$t_testPath is not a valid path"
        }
    }
}


