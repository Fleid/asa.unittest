### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Install-AutToolset.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\Install-AutToolset.ps1

Describe "Install-AutToolset paramater installPath" {
    InModuleScope $moduleName {

        $t_installPath = "foo"

        Mock Test-Path {return $true} -ParameterFilter {$Path -eq $t_installPath}
        Mock Test-Path {return $true} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {}
        Mock Invoke-External {} -ParameterFilter {$LiteralPath -like "*nuget*"}
        Mock Invoke-External {} -ParameterFilter {$LiteralPath -eq "npm"}

        It "fails if installPath is missing" {
            { Install-AutToolset } |
            Should -throw "-installPath is required"
        }

        It "doesn't create a folder if it exists" {
            Install-AutToolset -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It  -ParameterFilter {$Path -eq $t_installPath}
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq $t_installPath}
        It "does create a folder it doesn't" {
            Install-AutToolset -installPath $t_installPath |
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It  -ParameterFilter {$Path -eq $t_installPath}
        }

    }
}

Describe "Install-AutToolset behavior nuget" {
    InModuleScope $moduleName {

        $t_installPath = "foo"
        $t_nugetPackages = "bar"

        # The test folder exists
        Mock Test-Path {return $true} -ParameterFilter { $Path -and $Path -eq $t_installPath }
        # Nuget.exe is not there
        Mock Test-Path {return $false} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {} #Nuget download
        Mock Invoke-External {}

        It "does not download nuget on default parameter" {
            Install-AutToolset -installPath $t_installPath |
            Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
        }

        $t_nugetPackages = "bar"
        It "does download nuget once for 1 package" {
            Install-AutToolset -installPath $t_installPath -nugetPackages $t_nugetPackages |
            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly -Scope It
        }

        $t_nugetPackages = "bar1","bar2"
        It "does download nuget once for N packages" {
            Install-AutToolset -installPath $t_installPath -nugetPackages $t_nugetPackages |
            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly -Scope It
        }

        $t_nugetPackages = "bar"
        # Nuget.exe is already there
        Mock Test-Path {return $true} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        It "does not download nuget when needed but already there" {
            Install-AutToolset -installPath $t_installPath -nugetPackages $t_nugetPackages |
            Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
        }

        $t_nugetPackages =
        It "does not invoke nuget on default parameter" {
            Install-AutToolset -installPath $t_installPath |
            Assert-MockCalled Invoke-External -Times 0 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "$t_installPath\nuget*" }
        }

        $t_nugetPackages = "bar"
        It "does invoke nuget once for 1 package" {
            Install-AutToolset -installPath $t_installPath -nugetPackages $t_nugetPackages |
            Assert-MockCalled Invoke-External -Times 1 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "$t_installPath\nuget*" }
        }

        $t_nugetPackages = "bar1","bar2"
        It "does invoke nuget N times for N packages (N=2)" {
            Install-AutToolset -installPath $t_installPath -nugetPackages $t_nugetPackages  |
            Assert-MockCalled Invoke-External -Times 2 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "$t_installPath\nuget*" }
        }


    }
}

Describe "Install-AutToolset npm" {
        InModuleScope $moduleName {

            $t_installPath = "foo"

            # The test folder exists
            Mock Test-Path {return $true} -ParameterFilter { $Path -and $Path -eq $t_installPath }
            Mock New-Item {}
            Mock Invoke-WebRequest {} #Nuget download
            Mock Invoke-External {} 

            It "does not invoke npm on default parameter" {
                Install-AutToolset -installPath $t_installPath |
                Assert-MockCalled Invoke-External -Times 0 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "npm*" }
            }

            $t_npmPackages = "bar"
            It "does invoke npm once for 1 package" {
                Install-AutToolset -installPath $t_installPath -npmPackages $t_npmPackages |
                Assert-MockCalled Invoke-External -Times 1 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "npm*" }
            }

            $t_npmPackages = "bar1","bar2"
            It "does invoke npm N times for N packages (N=2)" {
                Install-AutToolset -installPath $t_installPath -npmPackages $t_npmPackages |
                Assert-MockCalled Invoke-External -Times 2 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "npm*" }
            }

            Mock Invoke-External {Throw "npm: The term 'npm' is not"} -ParameterFilter { $LiteralPath -like "npm*" }
            $t_npmPackages = "bar"
            It "fails if npm is not installed" {
                {Install-AutToolset -installPath $t_installPath -npmPackages $t_npmPackages} |
                Should -throw "npm: The term 'npm' is not"
            }
            Mock Invoke-External {} #Nuget or npm executions
        }
}

Describe "Install-AutToolset nuget + npm" {
    InModuleScope $moduleName {

        $installPath = "foo"

        # The test folder exists
        Mock Test-Path {return $true} -ParameterFilter { $Path -and $Path -eq $installPath }
        # Nuget.exe is not there
        Mock Test-Path {return $false} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {} #Nuget download
        Mock Invoke-External {}

        It "does invoke nuget for nuget + npm" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar1","bar2" -npmPackages "bar1","bar2" |
            Assert-MockCalled Invoke-External -Times 2 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "*nuget*" }
        }

        It "does invoke npm for nuget + npm" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar1","bar2" -npmPackages "bar1","bar2" |
            Assert-MockCalled Invoke-External -Times 2 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "npm*" }
        }

    }
}