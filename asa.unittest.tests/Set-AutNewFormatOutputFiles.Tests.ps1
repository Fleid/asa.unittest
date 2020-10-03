### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Set-AutNewFormatOutputFiles.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\Set-AutNewFormatOutputFiles.ps1

Describe "Set-AutNewFormatOutputFiles paramater solutionPath" {
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        #$t_archivePath

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock New-Item {}
        Mock Get-ChildItem  {}
        Mock Invoke-ReadAllText {}
        Mock Copy-Item {}
        Mock Invoke-WriteAllText {}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "runs with a valid solutionPath" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder

            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        It "fails without a solutionPath" {
            {Set-AutNewFormatOutputFiles `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "-solutionPath is required"
        }

        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_solutionPath}
        It "fails with an empty/invalid solutionPath" {
            {Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -solutionPath"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_arrangePath}
        It "fails if solutionPath doesn't lead to a valid 1_arrange folder" {
            {Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "$t_arrangePath is not a valid path"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_arrangePath}

    }
}

Describe "Set-AutNewFormatOutputFiles paramater unittestFolder" {
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        #$t_archivePath

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock New-Item {}
        Mock Get-ChildItem  {}
        Mock Invoke-ReadAllText {}
        Mock Copy-Item {}
        Mock Invoke-WriteAllText {}
        
        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "runs with a valid unittestFolder" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder
            
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        $t_arrangePath = "$t_solutionPath\$t_asaProjectName.Tests\1_arrange"
        It "defaults to asaProjectName.Tests without a unittestFolder" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName
            
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
         }

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_arrangePath}
        It "fails if unittestFolder doesn't lead to a valid 1_arrange folder" {
            {Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "$t_arrangePath is not a valid path"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_arrangePath}

    }
}


Describe "Set-AutNewFormatOutputFiles parameter outputFilePath" {`
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_archivePath = "backup"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock New-Item {}
        Mock Copy-Item {}
        Mock Get-ChildItem  {return [PSCustomObject]@{Name="foo~Output~bar~bar.json";FullName="foo:\bar\foo~Output~bar~bar.json"}}
        Mock Invoke-ReadAllText {return "[`n{1.2=3,4}`r`n,{abc=def}`n`r`n`n]`r`n"}
        Mock Invoke-WriteAllText {}

        It "runs with a valid outputFilePath" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            
            Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Destination -eq "$t_archivePath\foo~Output~bar~bar.json"}
        }

        Mock Test-Path {return $false} -ParameterFilter {$Path -eq $t_archivePath}
        It "fails with a invalid outputFilePath" {
            {Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            } |
            Should -Throw "$t_archivePath is not a valid path"
        }
        Mock Test-Path {return $true}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        $t_defaultedArchivePath = $t_arrangePath + "\archive_$internalTimeStamp"
        It "defaults to timestamp without a outputFilePath" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder
            
            Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_defaultedArchivePath}
            Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Destination -eq "$t_defaultedArchivePath\foo~Output~bar~bar.json"}
        }

        $t_archivePath = ""
        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        $t_defaultedArchivePath = $t_arrangePath + "\archive_$internalTimeStamp"
        It "defaults to timestamp with an empty outputFilePath" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            
                Assert-MockCalled New-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_defaultedArchivePath}
                Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Destination -eq "$t_defaultedArchivePath\foo~Output~bar~bar.json"}
        }
    }
}


Describe "Set-AutNewFormatOutputFiles behavior" {`
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_archivePath = "backup"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock New-Item {}
        Mock Copy-Item {}
        Mock Get-ChildItem  {return @(`
            [PSCustomObject]@{Name="foo1~Output~bar~bar.json";FullName="foo:\bar\foo1~Output~bar~bar.json"},`
            [PSCustomObject]@{Name="foo2~Output~bar~bar.json";FullName="foo:\bar\foo2~Output~bar~bar.json"},`
            [PSCustomObject]@{Name="foo2~Input~bar~Output.json";FullName="foo:\bar\foo2~Input~bar~Output.json"},`
            [PSCustomObject]@{Name="Output~Input~bar~bar.json";FullName="foo:\bar\Output~Input~bar~bar.json"},`
            [PSCustomObject]@{Name="foo3~Input~Output~bar.json";FullName="foo:\bar\foo3~Input~Output~bar.json"}`
        )}
        Mock Invoke-ReadAllText {return "`r`n[`r`n   {1.2=3,4},`r`n  ,{abc=def}`r`n]`r`n"}
        Mock Invoke-WriteAllText {}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "gets the test file list" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            
            Assert-MockCalled Get-ChildItem  -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        It "gets the content of the 2 sources" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            
            Assert-MockCalled Invoke-ReadAllText -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq "foo:\bar\foo1~Output~bar~bar.json"}
            Assert-MockCalled Invoke-ReadAllText -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq "foo:\bar\foo2~Output~bar~bar.json"}
        }

        It "archive both files" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            
            Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq "foo:\bar\foo1~Output~bar~bar.json"}
            Assert-MockCalled Copy-Item -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq "foo:\bar\foo2~Output~bar~bar.json"}
        }

        $t_file = "foo1~Output~bar~bar.json"
        $t_destination = $t_archivePath + "\" + $t_file
        Mock Test-Path {return $false} -ParameterFilter {$Path -eq $t_destination} 
        It "fails if archiving fails" {
            {Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            } |
            Should -throw "Set-AutNewFormatOutputFiles::302 - $t_file was not archived, not found in archive, it will not be processed, no data was lost"
        }
        Mock Test-Path {return $true} -ParameterFilter {$Path -eq $t_destination} 

        It "generates 2 valid files" {
            Set-AutNewFormatOutputFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -archivePath $t_archivePath
            
            Assert-MockCalled Invoke-WriteAllText -Times 1 -Exactly -Scope It -ParameterFilter {($file -eq "foo:\bar\foo1~Output~bar~bar.json") -and ($content -eq "{1.2=3,4}`r`n{abc=def}") }
            Assert-MockCalled Invoke-WriteAllText -Times 1 -Exactly -Scope It -ParameterFilter {($file -eq "foo:\bar\foo2~Output~bar~bar.json") -and ($content -eq "{1.2=3,4}`r`n{abc=def}")  }
        }
    }
}
