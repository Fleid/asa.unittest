### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################


Describe "New-AutRunFixture parameters"  {
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


        #Mock Test-Path {return $true}
        Mock New-Item {} #-ParameterFilter { $ItemType -and $ItemType -eq "Directory" }
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
