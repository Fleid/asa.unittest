### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\Start-AutRun.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\Start-AutRun.ps1


Describe "Start-AutRun parameter asaNugetVersion" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}
        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}
        Mock Get-ChildItem {}
        Mock Get-Content {}

        $t_asaNugetVersion = "2.3.0"
        It "runs with a valid asaNugetVersion" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It
        }

        Mock New-AutRunFixture {return @{test="001"}}
        Mock Get-ChildItem {return @(`
            [PSCustomObject] @{Name="Microsoft.Azure.StreamAnalytics.CICD.6.6.7"; LastWriteTime="2020-01-01 12:00:00"},`
            [PSCustomObject] @{Name="nuget.exe"; LastWriteTime="2020-05-01 12:00:00"},`
            [PSCustomObject] @{Name="Microsoft.Azure.StreamAnalytics.CICD.18.45.123"; LastWriteTime="2020-03-01 12:00:00"} `
        )}
        It "runs without an asaNugetVersion" {
            Start-AutRun `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunJob -Times 1 -Exactly -Scope It -ParameterFilter { ($exePath -like "*Microsoft.Azure.StreamAnalytics.CICD.18.45.123\tools\sa.exe")}
        }
        Mock New-AutRunFixture {}
        Mock Get-ChildItem {}

<# Removed to provide forward compatibility

        $t_asaNugetVersion = "1.0.0"
        It "fails with a invalid asaNugetVersion" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Cannot validate argument on parameter 'asaNugetVersion'"
        }
#>

<# Added feature to grab the latest installed version of the component
        $t_asaNugetVersion = ""
        It "fails with an empty asaNugetVersion" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Cannot validate argument on parameter 'asaNugetVersion'"
        }
#>

        $t_asaNugetVersion = "2.3.0"
        Mock Test-Path {return $false} -ParameterFilter {$path -like "*sa.exe"}
        It "fails if asaNugetVersion doesn't lead to sa.exe" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Can't find sa.exe at"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}

    }
}

Describe "Start-AutRun parameter solutionPath" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}
        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}
        Mock Get-ChildItem {}
        Mock Get-Content {}

        It "runs with a valid solutionPath" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It
        }

        $ENV:BUILD_SOURCESDIRECTORY = $t_solutionPath
        It "loads the default solutionPath from ENV" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It -ParameterFilter { $solutionPath -eq $t_solutionPath}
        }

        Mock Test-Path {return $false} -ParameterFilter {$path -eq $t_solutionPath}
        It "fails with an empty/invalid solutionPath" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -solutionPath"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}

        Mock Test-Path {return $false} -ParameterFilter {$path -like "*sa.exe"}
        It "fails if solutionPath doesn't lead to sa.exe" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw  "Can't find sa.exe"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}

    }
}

Describe "Start-AutRun parameter asaProjectName" {
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}
        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}
        Mock Get-ChildItem {}
        Mock Get-Content {}

        It "runs with a asaProjectName" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It
        }

        $t_asaProjectName = "X.X.X.ASA.ProjectName"
        It "runs with dots in the asaProjectName" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It
        }
        $t_asaProjectName = "bar"

        It "fails without a asaProjectName" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                #-asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "-asaProjectName is required"
        }

        $t_asaProjectName = ""
        It "fails with an empty solutionPath" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -asaProjectName ("
        }

        <#
        # 1.0.9 - This is actually not necessary, the validation requirement are only applied on the Azure job, not the local project
        $t_asaProjectName = " "
        It "fails with an invalid asaProjectName (space)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -asaProjectName (3"
        }

        $t_asaProjectName = "aa"
        It "fails with an invalid solutionPath (2char)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -asaProjectName (3"
        }

        $t_asaProjectName = "aaa+9"
        It "fails with an invalid solutionPath (invalid char)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -asaProjectName (3"
        }

        $t_asaProjectName = "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
        It "fails with an invalid solutionPath (over 63char)" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Invalid -asaProjectName (3"
        }
        #>
    }
}

Describe "Start-AutRun parameter unittestFolder" {`
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}

        Mock Get-Date {return $internalTimeStamp}
        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}
        Mock Get-ChildItem {}
        Mock Get-Content {}

        It "runs with a valid unittestFolder" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It
        }

        It "runs without a unittestFolder" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName} |
            Should -not -throw
        }

        It "loads the default unittestFolder (bar.Tests)" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It -ParameterFilter { $unittestFolder -eq "$t_asaProjectName.Tests"}
        }

        $t_unittestFolder = "TestingForReal"
        It "doesn't overwrite a unittestFolder with default (bar.Tests)" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It -ParameterFilter { $unittestFolder -eq "$t_unittestFolder"}
        }
        $t_unittestFolder = "bar.Tests"


        Mock Test-Path {return $false} -ParameterFilter {$path -like "*sa.exe"}
        It "fails if unittest doesn't lead to sa.exe" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Can't find sa.exe at"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}

        Mock Test-Path {return $false} -ParameterFilter {$path -like "*1_arrange"}
        It "fails if unittest doesn't lead to 1_arrange" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Can't find 1_arrange folder at"
        }
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}

    }
}

Describe "Start-AutRun behavior orchestration" {`
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "C:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}

        Mock Get-Date {return $internalTimeStamp}

        Mock New-AutRunFixture {}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {}
        Mock Get-ChildItem {}
        Mock Get-Content {}

        It "doesn't run on -Whatif" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder `
                -WhatIf |
            Assert-MockCalled New-AutRunJob -Times 0 -Exactly -Scope It
        }

        It "runs a single New-AutRunFixture" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunFixture -Times 1 -Exactly -Scope It
        }

        It "doesn't run New-AutRunJob for 0 test case" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunJob -Times 0 -Exactly -Scope It
        }

        It "doesn't run Get-AutRunResult for 0 test case" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled Get-AutRunResult -Times 0 -Exactly -Scope It
        }

        Mock New-AutRunFixture {return @{test="001"}}
        It "runs New-AutRunJob 1 time for 1 test case" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunJob -Times 1 -Exactly -Scope It
        }

        Mock New-AutRunFixture {return @(@{test="001"},@{test="002"})}
        It "runs New-AutRunJob 2 times for 2 test cases" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled New-AutRunJob -Times 2 -Exactly -Scope It
        }

        Mock New-AutRunFixture {return @{test="001"}}
        It "runs Get-AutRunResult 1 time for 1 test case" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled Get-AutRunResult -Times 1 -Exactly -Scope It
        }

        Mock New-AutRunFixture {return @(@{test="001"},@{test="002"})}
        It "runs New-AutRunJob 2 times for 2 test cases" {
            Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder |
            Assert-MockCalled Get-AutRunResult -Times 2 -Exactly -Scope It
        }

    }
}

Describe "Start-AutRun behavior result processing" {`
    InModuleScope $moduleName {

        $t_asaNugetVersion = "2.3.0"
        $t_solutionPath = "C:\foo"
        $t_asaProjectName = "bar"
        $t_unittestFolder = "bar.Tests"

        $internalTimeStamp = (Get-Date -Format "yyyyMMddHHmmss")

        Mock Test-Path {return $true} -ParameterFilter {$path -eq $t_solutionPath}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*sa.exe"}
        Mock Test-Path {return $true} -ParameterFilter {$path -like "*1_arrange"}

        Mock Get-Date {return $internalTimeStamp}

        Mock New-AutRunFixture {return @(@{test="001"},@{test="002"})}
        Mock New-AutRunJob {}
        Mock Get-AutRunResult {return 0}
        Mock Get-ChildItem {}
        Mock Get-Content {return "MyErrorResults"}

        It "doesn't throw for 0 errors" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -not -throw
        }

        Mock New-AutRunFixture {return @{test="002"}}
        Mock Get-AutRunResult {return 1}
        It "does throw for 1 errors" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Ending Test Run with 1 errors"
        }

        Mock New-AutRunFixture {return @(@{test="001"},@{test="002"})}
        Mock Get-AutRunResult {return 1}
        It "does throw for 2 errors" {
            {Start-AutRun `
                -asaNugetVersion $t_asaNugetVersion `
                -solutionPath $t_solutionPath `
                -asaProjectName $t_asaProjectName `
                -unittestFolder $t_unittestFolder} |
            Should -throw "Ending Test Run with 2 errors"
        }
    }
}