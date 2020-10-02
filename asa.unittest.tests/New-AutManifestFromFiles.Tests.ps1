### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\New-AutManifestFromFiles.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\New-AutManifestFromFiles.ps1

Describe "New-AutManifestFromFiles paramater installPath" {
    InModuleScope $moduleName {

        $t_installPath = "foo"

        Mock Test-Path {return $true} 
        Mock New-Item {}
        Mock Install-AutToolset {}
        Mock Out-File {}

        It "fails if installPath is missing" {
            { New-AutManifestFromFiles } |
            Should -throw "-installPath is required"
        }

        It "doesn't create a folder if it exists" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It  -ParameterFilter {$Path -eq $t_installPath}
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq $t_installPath}
        It "does create a folder it doesn't" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It  -ParameterFilter {$Path -eq $t_installPath}
        }

    }
}

Describe "New-AutManifestFromFiles behavior folder structure" {
    InModuleScope $moduleName {

        $t_installPath = "foo"

        Mock Test-Path {return $true} 
        Mock New-Item {}
        Mock Install-AutToolset {}
        Mock Out-File {}

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq "$t_installPath\1_arrange"}
        It "does create a folder 1_arrange" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It  -ParameterFilter {$Path -eq "$t_installPath\1_arrange"}
        }
        Mock Test-Path {return $true}

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq "$t_installPath\2_act"}
        It "does create a folder 2_act" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It  -ParameterFilter {$Path -eq "$t_installPath\2_act"}
        }
        Mock Test-Path {return $true} 

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq "$t_installPath\3_assert"}
        It "does create a folder 3_assert" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It  -ParameterFilter {$Path -eq "$t_installPath\3_assert"}
        }
        Mock Test-Path {return $true}

    }
}

Describe "New-AutManifestFromFiles behavior dependencies" {
        InModuleScope $moduleName {

            $t_installPath = "foo"

            Mock Test-Path {return $true} 
            Mock New-Item {}
            Mock Install-AutToolset {}
            Mock Out-File {}

            It "calls Install-AutToolset with the right parameters" {
                New-AutManifestFromFiles -installPath $t_installPath |
                Assert-MockCalled Install-AutToolset -Times 1 -Exactly -Scope It  -ParameterFilter {  
                        ($installPath -eq "$t_installPath\2_act") `
                        -and  `
                        ($packageHash.package -eq "Microsoft.Azure.StreamAnalytics.CICD") `
                        -and  `
                        ($packageHash.type -eq "nuget")
                    }
            }

        }
}

Describe "New-AutManifestFromFiles behavior gitignore" {
    InModuleScope $moduleName {

        $t_installPath = "foo"

        Mock Test-Path {return $true} 
        Mock New-Item {}
        Mock Install-AutToolset {}
        Mock Out-File {}

        It "doesn't create a gitignore if there's one already" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled Out-File -Times 0 -Exactly -Scope It
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq "$t_installPath\.gitignore"}
        It "does create a gitignore if there's none" {
            New-AutManifestFromFiles -installPath $t_installPath |
            Assert-MockCalled Out-File -Times 1 -Exactly -Scope It
        }

    }
}