### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "Install-AutToolset beginning" { 
    InModuleScope $moduleName {

        Mock Test-Path {return $true}
        Mock New-Item {}
        Mock Set-Location {}
        Mock Invoke-WebRequest {}
        Mock Invoke-Expression {}

        It "doesn't create a folder" {
            Install-AutToolset -installPath "foo" | 
            Assert-MockCalled New-Item -Times 0 -Scope It
        }

        Mock Test-Path {return $false}

        It "does create a folder" {
            Install-AutToolset -installPath "foo" | 
            Assert-MockCalled New-Item -Times 1 -Scope It
        }
    }
}

Describe "Install-AutToolset running" {
    InModuleScope $moduleName {

        Mock Test-Path {return $true}
        Mock New-Item {}
        Mock Set-Location {}
        Mock Invoke-WebRequest {}
        Mock Invoke-Expression {}

        It "does not download nuget on default parameter" {
            Install-AutToolset -installPath "foo" | 
            Assert-MockCalled Invoke-WebRequest -Times 0 -Scope It
        }

        It "does download nuget once for 1 package" {
            Install-AutToolset -installPath "foo" -nugetPackages "bar" | 
            Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It
        }

        It "does download nuget once for N packages" {
            Install-AutToolset -installPath "foo" -nugetPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It
        }

        It "does not invoke nuget on default parameter" {
            Install-AutToolset -installPath "foo" | 
            Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ParameterFilter { $Command -like ".*" }
        }

        It "does invoke nuget once for 1 package" {
            Install-AutToolset -installPath "foo" -nugetPackages "bar" | 
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ParameterFilter { $Command -like ".*" }
        }

        It "does invoke nuget N times for N packages" {
            Install-AutToolset -installPath "foo" -nugetPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-Expression -Times 2 -Scope It -ParameterFilter { $Command -like ".*" }
        }

        It "does not invoke npm on default parameter" {
            Install-AutToolset -installPath "foo" | 
            Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ParameterFilter { $Command -like "npm*" }
        }

        It "does invoke npm once for 1 package" {
            Install-AutToolset -installPath "foo" -npmPackages "bar" | 
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ParameterFilter { $Command -like "npm*" }
        }

        It "does invoke npm N times for N packages" {
            Install-AutToolset -installPath "foo" -npmPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-Expression -Times 2 -Scope It -ParameterFilter { $Command -like "npm*" }
        }
    }
}
