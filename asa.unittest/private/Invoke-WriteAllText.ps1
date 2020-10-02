<#
.SYNOPSIS
Helper function for invoking a .NET class.
Allows for moking in Pester

.DESCRIPTION
See source for more information : https://github.com/pester/Pester/issues/592

.PARAMETER param1
Literal path to the executable ("...\nuget.exe", "npm")

.EXAMPLE
Invoke-WriteAllText -file $file -content $content

#>

Function Invoke-WriteAllText
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $file,
        [Parameter(Mandatory=$true)]
        [string] $content
    )

BEGIN {}

PROCESS {
    [IO.File]::WriteAllText($file, $content)
} #PROCESS

END {}
}
