### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\New-AutManifestFromFiles.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\New-AutManifestFromFiles.ps1

Describe "New-AutManifestFromFiles parameter solutionPath" {
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        #$t_outputFilePath

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock Get-Content {}
        Mock Out-File {}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "runs with a valid solutionPath" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder

            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        It "fails without a solutionPath" {
            {New-AutManifestFromFiles `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "-solutionPath is required"
        }

        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_solutionPath}
        It "fails with an empty/invalid solutionPath" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -solutionPath"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}

        $t_Script = "$t_solutionPath\$t_asaProjectName\$t_asaProjectName.asaql"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_Script}
        It "fails if solutionPath doesn't lead to a .asaql query" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "Can't find $t_asaProjectName.asaql at $t_solutionPath\$t_asaProjectName"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_Script}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_arrangePath}
        It "fails if solutionPath doesn't lead to a valid 1_arrange folder" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "$t_arrangePath is not a valid path"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_arrangePath}
    }
}


Describe "New-AutManifestFromFiles parameter asaProjectName" {`
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        #$t_outputFilePath

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock Get-Content {}
        Mock Out-File {}

        $t_localInputSourcePath = "$t_solutionPath\$t_asaProjectName\Inputs"
        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "runs with a valid asaProjectName" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder
            
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        It "fails without a asaProjectName" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -unittestFolder $t_unittestFolder} |
            Should -throw "-asaProjectName is required"
        }

        $t_localInputSourcePath = "$t_solutionPath\$t_asaProjectName\Inputs"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_localInputSourcePath}
        It "fails if asaProjectName doesn't lead to a valid Inputs subfolder" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "Can't find the Inputs subfolder at $t_solutionPath\$t_asaProjectName"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_localInputSourcePath}

        $t_Script = "$t_solutionPath\$t_asaProjectName\$t_asaProjectName.asaql"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_Script}
        It "fails if asaProjectName doesn't lead to a .asaql query" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "Can't find $t_asaProjectName.asaql at $t_solutionPath\$t_asaProjectName"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_Script}
    }
}


Describe "New-AutManifestFromFiles parameter unittestFolder" {`
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        #$t_outputFilePath

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock Get-Content {}
        Mock Out-File {}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "runs with a valid unittestFolder" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder
            
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        $t_arrangePath = "$t_solutionPath\$t_asaProjectName.Tests\1_arrange"
        It "defaults to asaProjectName.Tests without a unittestFolder" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName
            
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
         }

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_arrangePath}
        It "fails if unittestFolder doesn't lead to a valid 1_arrange folder" {
            {New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "$t_arrangePath is not a valid path"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_arrangePath}

    }
}


Describe "New-AutManifestFromFiles parameter outputFilePath" {`
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_outputFilePath = "testConfig.json"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo  {}
        Mock Get-Content {}
        Mock Out-File {}

        It "runs with a valid outputFilePath" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -outputFilePath $t_outputFilePath
            
            Assert-MockCalled Out-File -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq $t_outputFilePath}
        }

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        $t_defaultedOutputFilePath = $t_arrangePath+"\testConfig_$internalTimeStamp.json"
        It "defaults to timestamp without a outputFilePath" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder
            
            Assert-MockCalled Out-File -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq $t_defaultedOutputFilePath}
        }

        $t_outputFilePath = ""
        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        $t_defaultedOutputFilePath = $t_arrangePath+"\testConfig_$internalTimeStamp.json"
        It "defaults to timestamp with an empty outputFilePath" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -outputFilePath $t_outputFilePath
            
            Assert-MockCalled Out-File -Times 1 -Exactly -Scope It -ParameterFilter { $FilePath -eq $t_defaultedOutputFilePath}
        }
    }
}


Describe "New-AutManifestFromFiles behavior" {`
    InModuleScope $moduleName {

        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_outputFilePath = "testConfig.json"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true}
        Mock Get-Date {return $internalTimeStamp}

        Mock Get-ChildItem {return 1}
        Mock Get-Content {}
        Mock Out-File {}

        Mock Get-AutFieldFromFileInfo {return @(`
            @{FilePath="001~Input~Stream~.json";Basename0="001";Basename1="Input";Basename2="Stream";},`
            @{FilePath="001~Input~Ref~.json";Basename0="001";Basename1="Input";Basename2="Ref"},`
            @{FilePath="001~Output~OutA~.json";Basename0="001";Basename1="Output";Basename2="OutA"},`

            @{FilePath="002~Input~Stream~.json";Basename0="002";Basename1="Input";Basename2="Stream";},`
            @{FilePath="002~Input~Ref~.json";Basename0="002";Basename1="Input";Basename2="Ref"},`
            @{FilePath="002~Output~OutB~.json";Basename0="002";Basename1="Output";Basename2="OutB"},`

            @{FilePath="003~Input~Stream~.json";Basename0="003";Basename1="Input";Basename2="Stream";},`
            @{FilePath="003~Input~Ref~.json";Basename0="003";Basename1="Input";Basename2="Ref"},`
            @{FilePath="003~Output~OutA~.json";Basename0="003";Basename1="Output";Basename2="OutA"},`
            @{FilePath="003~Output~OutB~.json";Basename0="003";Basename1="Output";Basename2="OutB"}`
        )}

        $t_arrangePath = "$t_solutionPath\$t_unittestFolder\1_arrange"
        It "gets the test file list" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -outputFilePath $t_outputFilePath
            
            Assert-MockCalled Get-ChildItem  -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
            Assert-MockCalled Get-AutFieldFromFileInfo -Times 1 -Exactly -Scope It
        }

        $t_localInputSourcePath = "$t_solutionPath\$t_asaProjectName\Inputs"
        It "gets the details of the 2 sources" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -outputFilePath $t_outputFilePath
            
            Assert-MockCalled Get-Content -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq "$t_localInputSourcePath\Local_Stream.json"}
            Assert-MockCalled Get-Content -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq "$t_localInputSourcePath\Local_Ref.json"}
        }

        It "creates a file" {
            $output = New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -outputFilePath $t_outputFilePath
            
            Assert-MockCalled Out-File -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_outputFilePath}
        }

        Mock Get-Content `
            {return (@{Type="Reference Data";Format="csv";ScriptType="InputMock";}| ConvertTo-JSON)} `
            -ParameterFilter { $Path -eq "$t_localInputSourcePath\Local_Ref.json"} 

        Mock Get-Content `
            {return (@{Type="Data Stream";Format="json";ScriptType="InputMock";} | ConvertTo-JSON)} `
            -ParameterFilter { $Path -eq "$t_localInputSourcePath\Local_Stream.json"} 

        $expectedOutput = '{
            "Script": "foo\\bar\\bar.asaql",
            "TestCases": [
              {
                "Name": "001",
                "Inputs": [
                  {
                    "InputAlias": "Stream",
                    "Type": "Data Stream",
                    "Format": "json",
                    "FilePath": "001~Input~Stream~.json",
                    "ScriptType": "InputMock"
                  },
                  {
                    "InputAlias": "Ref",
                    "Type": "Reference Data",
                    "Format": "csv",
                    "FilePath": "001~Input~Ref~.json",
                    "ScriptType": "InputMock"
                  }
                ],
                "ExpectedOutputs": [
                  {
                    "OutputAlias": "OutA",
                    "FilePath": "001~Output~OutA~.json",
                    "Required": "true"
                  },
                  {
                    "OutputAlias": "OutB",
                    "FilePath": "foo.bar",
                    "Required": "false"
                  }
                ]
              },
              {
                "Name": "002",
                "Inputs": [
                  {
                    "InputAlias": "Stream",
                    "Type": "Data Stream",
                    "Format": "json",
                    "FilePath": "002~Input~Stream~.json",
                    "ScriptType": "InputMock"
                  },
                  {
                    "InputAlias": "Ref",
                    "Type": "Reference Data",
                    "Format": "csv",
                    "FilePath": "002~Input~Ref~.json",
                    "ScriptType": "InputMock"
                  }
                ],
                "ExpectedOutputs": [
                  {
                    "OutputAlias": "OutA",
                    "FilePath": "foo.bar",
                    "Required": "false"
                  },
                  {
                    "OutputAlias": "OutB",
                    "FilePath": "002~Output~OutB~.json",
                    "Required": "true"
                  }
                ]
              },
              {
                "Name": "003",
                "Inputs": [
                  {
                    "InputAlias": "Stream",
                    "Type": "Data Stream",
                    "Format": "json",
                    "FilePath": "003~Input~Stream~.json",
                    "ScriptType": "InputMock"
                  },
                  {
                    "InputAlias": "Ref",
                    "Type": "Reference Data",
                    "Format": "csv",
                    "FilePath": "003~Input~Ref~.json",
                    "ScriptType": "InputMock"
                  }
                ],
                "ExpectedOutputs": [
                  {
                    "OutputAlias": "OutA",
                    "FilePath": "003~Output~OutA~.json",
                    "Required": "true"
                  },
                  {
                    "OutputAlias": "OutB",
                    "FilePath": "003~Output~OutB~.json",
                    "Required": "true"
                  }
                ]
              }
            ]
          }' | ConvertFrom-Json | ConvertTo-Json -Depth 4
        It "outputs a valid config file" {
            New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -outputFilePath $t_outputFilePath |
            Should be $expectedOutput
        }
    }
}
