### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Install-AutToolset.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\Install-AutToolset.ps1

Describe "Install-AutToolset beginning" { 
    InModuleScope $moduleName {

        $installPath = "foo"

        Mock Test-Path {return $true} -ParameterFilter {$Path -eq $installPath}
        Mock Test-Path {return $true} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {}
        Mock Invoke-Expression {}

        It "doesn't create a folder" {
            Install-AutToolset -installPath $installPath | 
            Assert-MockCalled New-Item -Times 0 -Scope It  -ParameterFilter {$Path -eq $installPath}
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq $installPath}
        It "does create a folder" {
            Install-AutToolset -installPath $installPath | 
            Assert-MockCalled New-Item -Times 1 -Scope It  -ParameterFilter {$Path -eq $installPath}
        }
    }
}

Describe "Install-AutToolset nuget" {
    InModuleScope $moduleName {

        $installPath = "foo"

        # The test folder exists
        Mock Test-Path {return $true} -ParameterFilter { $Path -and $Path -eq $installPath }
        # Nuget.exe is not there
        Mock Test-Path {return $false} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {} #Nuget download
        Mock Invoke-Expression {} #Nuget or npm executions

        It "does not download nuget on default parameter" {
            Install-AutToolset -installPath $installPath | 
            Assert-MockCalled Invoke-WebRequest -Times 0 -Scope It
        }

        It "does download nuget once for 1 package" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar" | 
            Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It
        }

        It "does download nuget once for N packages" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-WebRequest -Times 1 -Scope It
        }

        It "does not invoke nuget on default parameter" {
            Install-AutToolset -installPath $installPath | 
            Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ParameterFilter { $Command -like "$installPath\nuget*" }
        }

        It "does invoke nuget once for 1 package" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar" | 
            Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ParameterFilter { $Command -like "$installPath\nuget*" }
        }

        It "does invoke nuget N times for N packages (N=2)" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-Expression -Times 2 -Scope It -ParameterFilter { $Command -like "$installPath\nuget*" }
        }

        # Nuget.exe is already there
        Mock Test-Path {return $true} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        It "does not download nuget when needed but already there" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar" | 
            Assert-MockCalled Invoke-WebRequest -Times 0 -Scope It
        }
    }
}

Describe "Install-AutToolset npm" {
        InModuleScope $moduleName {
    
            $installPath = "foo"

            # The test folder exists
            Mock Test-Path {return $true} -ParameterFilter { $Path -and $Path -eq $installPath }
            Mock New-Item {}
            Mock Invoke-WebRequest {} #Nuget download
            Mock Invoke-Expression {} #Nuget or npm executions

            It "does not invoke npm on default parameter" {
                Install-AutToolset -installPath $installPath | 
                Assert-MockCalled Invoke-Expression -Times 0 -Scope It -ParameterFilter { $Command -like "npm*" }
            }
    
            It "does invoke npm once for 1 package" {
                Install-AutToolset -installPath $installPath -npmPackages "bar" | 
                Assert-MockCalled Invoke-Expression -Times 1 -Scope It -ParameterFilter { $Command -like "npm*" }
            }
    
            It "does invoke npm N times for N packages (N=2)" {
                Install-AutToolset -installPath $installPath -npmPackages "bar1","bar2" | 
                Assert-MockCalled Invoke-Expression -Times 2 -Scope It -ParameterFilter { $Command -like "npm*" }
            }
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
        Mock Invoke-Expression {} #Nuget or npm executions

        It "does invoke nuget for nuget + npm" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar1","bar2" -npmPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-Expression -Times 2 -Scope It -ParameterFilter { $Command -like "$installPath\nuget*" }
        }

        It "does invoke npm for nuget + npm" {
            Install-AutToolset -installPath $installPath -nugetPackages "bar1","bar2" -npmPackages "bar1","bar2" | 
            Assert-MockCalled Invoke-Expression -Times 2 -Scope It -ParameterFilter { $Command -like "npm*" }
        }

    }
}

