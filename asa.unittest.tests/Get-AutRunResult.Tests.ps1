### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Get-AutRunResult.Tests.ps1 -CodeCoverage .\..\asa.unittest\private\Get-AutRunResult.ps1

InModuleScope $moduleName {

    BeforeAll {

        $t_solutionPath = "TestDrive:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"
        $t_testID = "yyyymmddhhmmss"
        $t_testCase = "123"
        $t_asaNugetVersion = "3.0.0"

        $t_testPath = "$t_solutionPath\$t_unittestFolder\3_assert\$t_testID\$t_testCase"
        $t_outputSourcePath = "$t_testPath\$t_asaProjectName\Inputs"

        Mock Test-Path {return $true}
        Mock Get-ChildItem {}
        Mock Get-AutFieldFromFileInfo {}
        Mock Get-Content {}
        Mock Add-Content {}
        Mock Compare-Object {}
        Mock Out-File {}
        Mock Invoke-ReadAllText {}

    }

    Describe "Get-AutRunResult Nominal" {

        BeforeEach {
            Mock Get-ChildItem {return 1}
            Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}
            Mock Invoke-ReadAllText {return (@{FilePath="foobar"} | ConvertTo-Json)}
        }

        It "tries to get a list of files" {
            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Get-ChildItem -Times 1 -Exactly -Scope It -ParameterFilter ($Path -eq $t_outputSourcePath)
        }

        It "tries nothing if it gets nothing" {
            Mock Get-AutFieldFromFileInfo {}

            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Out-File -Times 0  -Exactly -Scope It
        }

        It "calls Get-AutFieldFromFileInfo if it find files" {
            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Get-AutFieldFromFileInfo -Times 1 -Exactly -Scope It
        }

        It "Generates N testable files for N output files for asANugetVersion 2.x" {
            Mock Get-AutFieldFromFileInfo {return @(`
                @{Basename0="003";FilePath="foobar";Basename1="Output";Basename2="fb3"},`
                @{Basename0="001";FilePath="foobar1";Basename1="Output";Basename2="fb11"},`
                @{Basename0="001";FilePath="foobar2";Basename1="Output";Basename2="fb12"},`
                @{Basename0="002";FilePath="foobar";Basename1="Output";Basename2="fb2"}`
            )}
            $t_asaNugetVersion = "2.x.y"

            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Get-Content -Times 16 -Exactly -Scope It #4 for ref, 4 for output times 2
            Assert-MockCalled Add-Content -Times 8 -Exactly -Scope It #4 for ref, 4 for output times 2
        }

        It "Generates N testable files for N output files for asANugetVersion 3 or above" {
            Mock Get-AutFieldFromFileInfo {return @(`
                @{Basename0="003";FilePath="foobar";Basename1="Output";Basename2="fb3"},`
                @{Basename0="001";FilePath="foobar1";Basename1="Output";Basename2="fb11"},`
                @{Basename0="001";FilePath="foobar2";Basename1="Output";Basename2="fb12"},`
                @{Basename0="002";FilePath="foobar";Basename1="Output";Basename2="fb2"}`
            )}

            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Get-Content -Times 12 -Exactly -Scope It #4 for output times 3
            Assert-MockCalled Invoke-ReadAllText -Times 4 -Exactly -Scope It #4 for ref
            Assert-MockCalled Add-Content -Times 8 -Exactly -Scope It #4 for ref, 4 for output times 2
        }

        It "Tests and generates 0 result files for N passing tests" {
            Mock Get-AutFieldFromFileInfo {return @(`
                @{Basename0="003";FilePath="foobar";Basename1="Output";Basename2="fb3"},`
                @{Basename0="001";FilePath="foobar1";Basename1="Output";Basename2="fb11"},`
                @{Basename0="001";FilePath="foobar2";Basename1="Output";Basename2="fb12"},`
                @{Basename0="002";FilePath="foobar";Basename1="Output";Basename2="fb2"}`
            )}
            Mock Compare-Object {return $null}

            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Compare-Object -Times 4 -Exactly -Scope It
            Assert-MockCalled Out-File -Times 0 -Exactly -Scope It
        }

        It "Tests and generates 4 result files for N failing tests" {
            Mock Get-AutFieldFromFileInfo {return @(`
                @{Basename0="003";FilePath="foobar";Basename1="Output";Basename2="fb3"},`
                @{Basename0="001";FilePath="foobar1";Basename1="Output";Basename2="fb11"},`
                @{Basename0="001";FilePath="foobar2";Basename1="Output";Basename2="fb12"},`
                @{Basename0="002";FilePath="foobar";Basename1="Output";Basename2="fb2"}`
            )}
            Mock Compare-Object {return "ERROR"}

            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Compare-Object -Times 4 -Exactly -Scope It
            Assert-MockCalled Out-File -Times 4 -Exactly -Scope It
        }

        It "returns N for N errors" {
            Mock Get-AutFieldFromFileInfo {return @(`
                @{Basename0="003";FilePath="foobar";Basename1="Output";Basename2="fb3"},`
                @{Basename0="001";FilePath="foobar1";Basename1="Output";Basename2="fb11"},`
                @{Basename0="001";FilePath="foobar2";Basename1="Output";Basename2="fb12"},`
                @{Basename0="001";FilePath="foobar3";Basename1="Output";Basename2="fb13"},`
                @{Basename0="002";FilePath="foobar";Basename1="Output";Basename2="fb2"}`
            )}
            Mock Compare-Object {return "a"}

            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion |
            Should -be 5
        }
    }

    Describe "Get-AutRunResult empty folders"  {

        It "provides 0 error in output pipeline on an empty folder" {
            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion |
            Should -be 0
        }

        It "generates no file on an empty folder" {
            Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion | Out-Null

            Assert-MockCalled Out-File -Times 0  -Exactly -Scope It
        }
    }

    Describe "Get-AutRunResult parameters"  {

        It "runs with a valid set of parameters" {

            Mock Get-ChildItem {return 1}
            Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}

            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion } |
            Should -not -throw "-* is required"
        }

        It "fails without -solutionPath" {
            { Get-AutRunResult `
                #-solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion } |
            Should -throw "-solutionPath is required"
        }

        It "fails without -asaProjectName" {
            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                #-asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion } |
            Should -throw "-asaProjectName is required"
        }

        It "fails without -unittestFolder" {
            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                #-unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion } |
            Should -throw "-unittestFolder is required"
        }

        It "fails without -testID" {
            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                #-testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion } |
            Should -throw "-testID is required"
        }

        It "fails without -testCase" {
            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                #-testCase $t_testCase
                -asaNugetVersion $t_asaNugetVersion } |
            Should -throw "-testCase is required"
        }

        It "fails without -asaNugetVersion" {
            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                #-asaNugetVersion $t_asaNugetVersion `
                } |
            Should -throw "-asaNugetVersion is required"
        }
    }

    Describe "Get-AutRunResult paths"  {

        It "runs with a valid set of paths" {
            Mock Get-ChildItem {return 1}
            Mock Get-Content {return (@{FilePath="foobar"} | ConvertTo-Json)}

            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion } |
            Should -not -throw
        }


        It "fails when solutionPath is not a valid path" {
            Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_solutionPath}

            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion  } |
            Should -throw "$t_solutionPath is not a valid path"
        }

        It "fails when testPath is not a valid path" {
            Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_testPath}

            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion  } |
            Should -throw "$t_testPath is not a valid path"
        }

        It "fails when outputSourcePath is not a valid path" {
            Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_outputSourcePath}

            { Get-AutRunResult `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -testID $t_testID `
                -testCase $t_testCase `
                -asaNugetVersion $t_asaNugetVersion  } |
            Should -throw "$t_outputSourcePath is not a valid path"
        }
    }
} #InModuleScope