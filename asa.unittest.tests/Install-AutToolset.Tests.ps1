### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Install-AutToolset.Tests.ps1 -CodeCoverage .\..\asa.unittest\private\Install-AutToolset.ps1

Describe "Install-AutToolset paramater installPath" {
    InModuleScope $moduleName {

        $t_installPath = "foo"

        Mock Test-Path {return $true} -ParameterFilter {$Path -eq $t_installPath}
        Mock Test-Path {return $true} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {}
        Mock Invoke-External {} -ParameterFilter {$LiteralPath -like "*nuget*"}

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

Describe "Install-AutToolset hashtable" {
    InModuleScope $moduleName {

        $t_installPath = "foo"

        $t_nuget_version   = @{type="nuget";Package="bar";version="1.x.version.y"}
        $t_nuget_noversion = @{type="nuget";Package="foo"}

        # The test folder exists
        Mock Test-Path {return $true} -ParameterFilter { $Path -and $Path -eq $t_installPath }
        # Nuget.exe is not there
        Mock Test-Path {return $false} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        Mock New-Item {}
        Mock Invoke-WebRequest {} #Nuget download
        Mock Invoke-External {}

        ### Nuget Download

        It "does not download nuget on default parameter" {
            Install-AutToolset -installPath $t_installPath |
            Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
        }

        It "does download nuget once for 1 package" {
            Install-AutToolset -installPath $t_installPath -packageHash $t_nuget_version |
            Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly -Scope It
        }

        # Nuget.exe is already there
        Mock Test-Path {return $true} -ParameterFilter { $PathType -and $PathType -eq "Leaf" }
        It "does not download nuget when needed but already there" {
            Install-AutToolset -installPath $t_installPath -packageHash $t_nuget_version |
            Assert-MockCalled Invoke-WebRequest -Times 0 -Exactly -Scope It
        }

        ### Nuget Invokation

        It "does not invoke nuget on default parameter" {
            Install-AutToolset -installPath $t_installPath |
            Assert-MockCalled Invoke-External -Times 0 -Exactly -Scope It -ParameterFilter { $LiteralPath -like "$t_installPath\nuget*" }
        }

        It "does invoke nuget once for 1 package with version" {
            Install-AutToolset -installPath $t_installPath -packageHash  $t_nuget_version |
            Assert-MockCalled Invoke-External -Times 1 -Exactly -Scope It -ParameterFilter { ($LiteralPath -like "$t_installPath\nuget*") }
        }

        It "does invoke nuget once for 1 package with no version" {
            Install-AutToolset -installPath $t_installPath -packageHash  $t_nuget_noversion |
            Assert-MockCalled Invoke-External -Times 1 -Exactly -Scope It -ParameterFilter { ($LiteralPath -like "$t_installPath\nuget*") }
        }
    }
}