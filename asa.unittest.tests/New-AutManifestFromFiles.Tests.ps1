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
            New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
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
            New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
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
            New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter { $Path -eq $t_arrangePath}
        }

        $t_arrangePath = "$t_solutionPath\$t_asaProjectName.Tests\1_arrange"
        It "defaults to asaProjectName.Tests without a unittestFolder" {
            New-AutManifestFromFiles `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName |
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
