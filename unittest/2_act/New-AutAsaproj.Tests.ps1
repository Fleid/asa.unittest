$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-AutAsaproj Parameters" {
    
    Mock Get-Content { return 1 }

    It "requires a valid solution path and project name" {
        New-AutAsaproj -solutionPath SOLUTION1 -asaProjectName PROJECT1 |
        Assert-MockCalled Get-Content -Exactly 0 -Scope It 
    }

}

Describe "New-AutAsaproj Logic" {
    
    Mock Test-Path { return $true }
    Mock Get-Content { return "[{`"startFile`":`"Foo`"}]" }

    It "requires a valid solution path and project name" {
        New-AutAsaproj -solutionPath SOLUTION1 -asaProjectName PROJECT1 | Should -Be "my test text.-Footer"
    }
}