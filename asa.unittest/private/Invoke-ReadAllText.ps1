<#
.SYNOPSIS
Helper function for invoking a .NET class.
Allows for moking in Pester

.DESCRIPTION
See source for more information : https://github.com/pester/Pester/issues/592

.PARAMETER param1
Literal path to the executable ("...\nuget.exe", "npm")

.EXAMPLE
Invoke-ReadAllText -param1 $rawContent

#>

Function Invoke-ReadAllText
{
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory=$true)]
        [string] $path
    )

BEGIN {}

PROCESS {
    return [IO.File]::ReadAllText($path)
} #PROCESS

END {}
}
