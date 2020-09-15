### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\New-AutRunFixture.Tests.ps1 -CodeCoverage .\..\asa.unittest\private\New-AutRunFixture.ps1


Describe "New-AutRunFixture nominal"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        $t_tests = @(
            [PSCustomObject] @{Basename0="003";FilePath="foobar";Basename1="Input";FullName="fb"},
            [PSCustomObject] @{Basename0="001";FilePath="foobar1";Basename1="Input";FullName="fb"},
            [PSCustomObject] @{Basename0="001";FilePath="foobar2"},
            [PSCustomObject] @{Basename0="002";FilePath="foobar"}
        )

        Mock Get-ChildItem {1}
        Mock Get-AutFieldFromFileInfo {return $t_tests}
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        It "runs with a valid set of parameters" {
           { New-AutRunFixture `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID }|
            Should -not -throw
        }

        It "provides an output" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID |
             Should -be @("001","002","003")
         }

         It "tests a job with -WhatIf" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID `
                 -WhatIf |
             Should -be $null

            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It
         }

        It "creates test case folders" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\001")}
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\002")}
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\003")}
            Assert-MockCalled New-Item -Times 3 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\00?")}
        }

        It "creates input subfolder in each test case folder" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\001\$t_asaProjectName\Inputs\")}
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\002\$t_asaProjectName\Inputs\")}
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\003\$t_asaProjectName\Inputs\")}
            Assert-MockCalled New-Item -Times 3 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\00?\$t_asaProjectName\Inputs\")}
        }

        It "copies ASA config files in each test case folders" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 3 -Exactly -Scope It -ParameterFilter {$Path -like "*.as*"}
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -like "*.asaproj"}
        It "calls New-AUTAsaprojXML if needed" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled New-AUTAsaprojXML -Times 3 -Exactly -Scope It
        }

        Mock Test-Path {return $true} -ParameterFilter {$Path -like "*.asaproj"}
        It "doesn't call New-AUTAsaprojXML unnecessarily" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled New-AUTAsaprojXML -Times 0 -Exactly -Scope It
        }
        Mock Test-Path {return $true}

        It "copies ASA mock input files in each test case folders" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 3 -Exactly -Scope It -ParameterFilter {$Path -like "*Local*.json"}
        }  

        It "copies test files from 1_arrange in each test case folders" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 4 -Exactly -Scope It -ParameterFilter {$Path -like "foobar*"}
        }

        It "edit the ASA conf file for each input files" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Out-File -Times 2 -Exactly -Scope It
        }

    }
}
Describe "New-AutRunFixture ASA cs code behind files handling"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        $t_tests = @(
            [PSCustomObject] @{Basename0="003";FilePath="foobar";Basename1="Input";FullName="fb"},
            [PSCustomObject] @{Basename0="001";FilePath="foobar1";Basename1="Input";FullName="fb"},
            [PSCustomObject] @{Basename0="001";FilePath="foobar2"},
            [PSCustomObject] @{Basename0="002";FilePath="foobar"}
        )

        Mock Get-ChildItem {1}
        Mock Get-AutFieldFromFileInfo {return $t_tests}
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        It "copies ASA cs code behind files in each test case folders" {
            New-AutRunFixture `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID

            Assert-MockCalled Copy-Item -Times 3 -Exactly -Scope It -ParameterFilter {$Path -like "*.cs"}
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -and ($Path -like "*$t_asaProjectName.asaql.cs")}
        It "creates an empty file if there's none"{
            New-AutRunFixture `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID

            Assert-MockCalled New-Item -Times 3 -Exactly -Scope It -ParameterFilter {($Name -like "$t_asaProjectName.asaql.cs") -and ($Path -like "*\$t_asaProjectName\")}
        }
    }
}

Describe "New-AutRunFixture ASA functions handling"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        $t_tests = @(
            [PSCustomObject] @{Basename0="003";FilePath="foobar";Basename1="Input";FullName="fb"},
            [PSCustomObject] @{Basename0="001";FilePath="foobar1";Basename1="Input";FullName="fb"},
            [PSCustomObject] @{Basename0="001";FilePath="foobar2"},
            [PSCustomObject] @{Basename0="002";FilePath="foobar"}
        )

        Mock Get-ChildItem {1}
        Mock Get-AutFieldFromFileInfo {return $t_tests}
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        Mock Test-Path {return $true} -ParameterFilter {$Path -and ($Path -like "*\Functions\")}
        It "creates function subfolder in each test case folder" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\001\$t_asaProjectName\Functions\")}
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\002\$t_asaProjectName\Functions\")}
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\003\$t_asaProjectName\Functions\")}
            Assert-MockCalled New-Item -Times 3 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\00?\$t_asaProjectName\Functions\")}
        }
        Mock Test-Path {return $true}

        Mock Test-Path {return $true} -ParameterFilter {$Path -and ($Path -like "*\Functions\")}
        It "copies ASA JS Function files in each test case folders" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 3 -Exactly -Scope It -ParameterFilter {$Path -like "*.js"}
        }
        Mock Test-Path {return $true}

        Mock Test-Path {return $true} -ParameterFilter {$Path -and ($Path -like "*\Functions\")}
        It "copies ASA JS Function definition (JSON) files in each test case folders" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 3 -Exactly -Scope It -ParameterFilter {$Path -like "*.js.json"}
        }
        Mock Test-Path {return $true}

        Mock Test-Path {return $false} -ParameterFilter {$Path -and ($Path -like "*\Functions\")}
        It "doesn't create a function subfolder in each test case folder if there's no source function folder" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\001\$t_asaProjectName\Functions\")}
            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\002\$t_asaProjectName\Functions\")}
            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\003\$t_asaProjectName\Functions\")}
            Assert-MockCalled New-Item -Times 0 -Exactly -Scope It -ParameterFilter {($ItemType -eq "Directory") -and ($Path -like "*\$t_testID\00?\$t_asaProjectName\Functions\")}
        }
        Mock Test-Path {return $true}

        Mock Test-Path {return $false} -ParameterFilter {$Path -and ($Path -like "*\Functions\")}
        It "doesn't copy ASA JS Function files in each test case folders if there's no source function folder" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 0 -Exactly -Scope It -ParameterFilter {$Path -like "*.js"}
        }
        Mock Test-Path {return $true}

        Mock Test-Path {return $false} -ParameterFilter {$Path -and ($Path -like "*\Functions\")}
        It "doesn't copy ASA JS Function definition (JSON) files in each test case folders if there's no source function folder" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID

            Assert-MockCalled Copy-Item -Times 0 -Exactly -Scope It -ParameterFilter {$Path -like "*.js.json"}
        }
        Mock Test-Path {return $true}

    }
}

Describe "New-AutRunFixture empty folders"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        Mock Test-Path {return $true}

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo {}

        Mock New-Item {}
        Mock Copy-Item {}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        It "provides an empty output on an empty folder" {
            New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID |
             Should -be @()
         }
    }
}

Describe "New-AutRunFixture parameters"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        It "runs with a valid set of parameters" {
           { New-AutRunFixture `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID }|
            Should -not -throw "-* is required"
        }

        It "fails without -solutionPath" {
            { New-AutRunFixture `
                 #-solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID }|
             Should -throw "-solutionPath is required"
        }

        It "fails without -asaProjectName" {
            { New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 #-asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID }|
             Should -throw "-asaProjectName is required"
        }

        It "fails without -unittestFolder" {
            { New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 #-unittestFolder $t_unittestFolder `
                 -testID $t_testID }|
             Should -throw "-unittestFolder is required"
        }

        It "fails without -testID" {
            { New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 #-testID $t_testID
                }|
             Should -throw "-testID is required"
        }
    }
}

Describe "New-AutRunFixture paths"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock New-Item {}
        Mock Copy-Item {}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        Mock Test-Path {return $true}
        It "runs with a valid set of paths" {
           { New-AutRunFixture `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID }|
            Should -not -throw
        }

        Mock Test-Path {return $false}
        It "fails when solutionPath is not a valid path" {
           { New-AutRunFixture `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID }|
            Should -throw "$t_solutionPath is not a valid path"
        }

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        It "fails when asaProjectPath is not a valid path" {
            { New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID }|
             Should -throw "$t_solutionPath\$t_asaProjectName is not a valid path"
         }

         Mock Test-Path {return $true} -ParameterFilter {$path -eq "$t_solutionPath\$t_asaProjectName"}
         It "fails when arrangePath is not a valid path" {
            { New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID }|
             Should -throw "$t_solutionPath\$t_unittestFolder\1_arrange is not a valid path"
         }

         Mock Test-Path {return $true} -ParameterFilter {$path -eq "$t_solutionPath\$t_unittestFolder\1_arrange"}
         It "fails when testPath is not a valid path" {
            { New-AutRunFixture `
                 -solutionPath $t_solutionPath `
                 -asaProjectName $t_asaProjectName `
                 -unittestFolder $t_unittestFolder `
                 -testID $t_testID }|
             Should -throw "$t_solutionPath\$t_unittestFolder\3_assert\$t_testID is not a valid path"
         }
    }
}
