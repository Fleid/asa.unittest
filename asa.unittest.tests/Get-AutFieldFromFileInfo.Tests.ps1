### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Get-AutFieldFromFileInfo.Tests.ps1 -CodeCoverage .\..\asa.unittest\private\Get-AutFieldFromFileInfo.ps1


Describe "Get-AutFieldFromFileInfo parameters"  {
    InModuleScope $moduleName {
        function GetFullPath {
            Param(
                [string] $Path
            )
            return $Path.Replace('TestDrive:', (Get-PSDrive TestDrive).Root)
        }


        $t_testPath = "TestDrive:\users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\1_arrange"
        New-Item -Path $t_testPath -ItemType Directory
        New-item -Path $t_testPath -ItemType File -Name "001~Input~hwsource~nominal.csv"
        New-item -Path $t_testPath -ItemType File -Name "001~Output~outputall.json"

        $t_thisFileInfo = (Get-ChildItem -Path $t_testPath -File)
        $t_separatorOfFields = "~"
        $t_numberOfFields = 4

        $Output_1 = New-Object PSObject -Property @{
            FullName="001~Input~hwsource~nominal.csv"
            FilePath= GetFullPath("TestDrive:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\1_arrange\001~Input~hwsource~nominal.csv")
            Basename= "001~Input~hwsource~nominal"
            basename0="001"
            basename1="Input"
            basename2="hwsource"
            basename3="nominal"
        }

        $Output_2 = New-Object PSObject -Property @{
            FullName="001~Output~outputall.json"
            FilePath= GetFullPath("TestDrive:\Users\fleide\Repos\asa.unittest\examples\ASAHelloWorld.Tests\1_arrange\001~Output~outputall.json")
            Basename= "001~Output~outputall"
            basename0="001"
            basename1="Output"
            basename2="outputall"
        }

        #Mock Test-Path {return $true}

        It "runs with a valid set of parameters (output1)" {
            $actual = Get-AutFieldFromFileInfo `
                -t $t_thisFileInfo[0] `
                -s $t_separatorOfFields `
                -n $t_numberOfFields

            $t = $true

            foreach($actual_properties in $actual.PSObject.Properties)
            {
                $t = $t -and ($Output_1.($actual_properties.Name) -eq $actual_properties.value)
            }

            $t | Should -be $true
        }

        $t_numberOfFields = 3
        It "runs with a valid set of parameters (output2)" {
            $actual = Get-AutFieldFromFileInfo `
                -t $t_thisFileInfo[1] `
                -s $t_separatorOfFields `
                -n $t_numberOfFields

            $t = $true

            foreach($actual_properties in $actual.PSObject.Properties)
            {
                $t = $t -and ($Output_2.($actual_properties.Name) -eq $actual_properties.value)
            }

            $t | Should -be $true
        }

        It "runs from the pipeline" {
            $actual = $t_thisFileInfo[0] | Get-AutFieldFromFileInfo -s "~" -n 4

            $t = $true

            foreach($actual_properties in $actual.PSObject.Properties)
            {
                $t = $t -and ($Output_1.($actual_properties.Name) -eq $actual_properties.value)
            }

            $t | Should -be $true
        }
    }
}
