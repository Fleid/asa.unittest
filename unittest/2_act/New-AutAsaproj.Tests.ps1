$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-AutAsaproj" {

    Mock Out-File { return 1 }

    It "requires a solution" {
        New-AutAsaproj -asaProjectName NAME1 |
        Assert-MockCalled Out-File -Exactly 0 -Scope It 
    }

    It "requires a solution" {
        New-AutAsaproj -asaProjectName NAME1 |
        Assert-MockCalled Out-File -Exactly 0 -Scope It 
    }
}
