### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "New-AutRunFixture nominal"  {
    InModuleScope $moduleName {

        $solutionPath = "TestDrive:\foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testID = "yyyymmddhhmmss"

        $asaProjectPath = "$solutionPath\$asaProjectName"
        $arrangePath = "$solutionPath\$unittestFolder\1_arrange"
        New-Item -Path $asaProjectPath -ItemType Directory
        New-Item -Path $arrangePath -ItemType Directory
        New-item -Path $arrangePath -ItemType File -Name "001~Input~hwsource~nominal.csv"
        New-item -Path $arrangePath -ItemType File -Name "001~Output~outputall.json"

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
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID }|
            Should -not -throw
        }

        It "doesn't run without a solutionPath" {}

    }
}

Describe "New-AutRunFixture parameters"  {
    InModuleScope $moduleName {

        $solutionPath = "TestDrive:\foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testID = "yyyymmddhhmmss"

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
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID }|
            Should -not -throw "-* is required"
        }
        
        It "fails without -solutionPath" {
            { New-AutRunFixture `
                 #-solutionPath $solutionPath `
                 -asaProjectName $asaProjectName `
                 -unittestFolder $unittestFolder `
                 -testID $testID }|
             Should -throw "-solutionPath is required"
        }

        It "fails without -asaProjectName" {
            { New-AutRunFixture `
                 -solutionPath $solutionPath `
                 #-asaProjectName $asaProjectName `
                 -unittestFolder $unittestFolder `
                 -testID $testID }|
             Should -throw "-asaProjectName is required"
        }

        It "fails without -unittestFolder" {
            { New-AutRunFixture `
                 -solutionPath $solutionPath `
                 -asaProjectName $asaProjectName `
                 #-unittestFolder $unittestFolder `
                 -testID $testID }|
             Should -throw "-unittestFolder is required"
        }

        It "fails without -testID" {
            { New-AutRunFixture `
                 -solutionPath $solutionPath `
                 -asaProjectName $asaProjectName `
                 -unittestFolder $unittestFolder `
                 #-testID $testID 
                }|
             Should -throw "-testID is required"
        }
    }
}

Describe "New-AutRunFixture paths"  {
    InModuleScope $moduleName {

        $solutionPath = "TestDrive:\foo"
        $asaProjectName = "bar"
        $unittestFolder = "bar.Tests"
        $testID = "yyyymmddhhmmss"

        $asaProjectPath = "$solutionPath\$asaProjectName"
        $arrangePath = "$solutionPath\$unittestFolder\1_arrange"
        New-Item -Path $asaProjectPath -ItemType Directory
        New-Item -Path $arrangePath -ItemType Directory
        New-item -Path $arrangePath -ItemType File -Name "001~Input~hwsource~nominal.csv"
        New-item -Path $arrangePath -ItemType File -Name "001~Output~outputall.json"

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock New-Item {} 
        Mock Copy-Item {}
        Mock Test-Path {return $true}
        Mock New-AUTAsaprojXML {}
        Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
        Mock Out-File {}

        It "fails when solutionPath is not a valid path" {
           { New-AutRunFixture `
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID }|
            Should -throw "$solutionPath is not a valid path"
        }

        It "fails when asaProjectPath is not a valid path" {
            { New-AutRunFixture `
                 -solutionPath $solutionPath `
                 -asaProjectName $asaProjectName `
                 -unittestFolder $unittestFolder `
                 -testID $testID }|
             Should -throw "$solutionPath\$asaProjectName is not a valid path"
         }

         It "fails when arrangePath is not a valid path" {
            { New-AutRunFixture `
                 -solutionPath $solutionPath `
                 -asaProjectName $asaProjectName `
                 -unittestFolder $unittestFolder `
                 -testID $testID }|
             Should -throw "$solutionPath\$unittestFolder\1_arrange is not a valid path"
         }

         It "fails when testPath is not a valid path" {
            { New-AutRunFixture `
                 -solutionPath $solutionPath `
                 -asaProjectName $asaProjectName `
                 -unittestFolder $unittestFolder `
                 -testID $testID }|
             Should -throw "$solutionPath\$unittestFolder\3_assert\$testID is not a valid path"
         }

    }
}