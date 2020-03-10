### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "New-AutRunFixture nominal"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        Mock Get-ChildItem {return 1}
        Mock Get-AutFieldFromFileInfo {return @(@{Basename0="003";FilePath="foobar"},@{Basename0="001";FilePath="foobar"},@{Basename0="001";FilePath="foobar"},@{Basename0="002";FilePath="foobar"})}
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

        It "copies ASA files in each test case folders" {
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
    }
}

Describe "New-AutRunFixture empty folders"  {
    InModuleScope $moduleName {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"

        Mock Get-ChildItem {return 1}
        Mock Get-AutFieldFromFileInfo {return @(@{Basename0="003";FilePath="foobar"},@{Basename0="001";FilePath="foobar"},@{Basename0="001";FilePath="foobar"},@{Basename0="002";FilePath="foobar"})}
        Mock New-Item {} 
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

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
