<#
.SYNOPSIS
Helper function for invoking an external utility (executable).
The raison d'être for this function is to allow calls to external executables via their *full paths* to be mocked in Pester.

.DESCRIPTION
See source for more information : https://stackoverflow.com/questions/37926844/how-to-mock-a-call-to-an-exe-file-with-pester

.PARAMETER LiteralPath
Literal path to the executable ("...\nuget.exe", "npm")

.PARAMETER PassThruArgs
Arguments to be passed to the executable

.EXAMPLE
Invoke-External -l "npm" install -g $npmPackage | Out-Null
#>

Function Invoke-External {

  [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [string] $LiteralPath,
      [Parameter(ValueFromRemainingArguments=$true)]
      $PassThruArgs
    )

    BEGIN {}

    PROCESS {
        & $LiteralPath $PassThruArgs
    } #PROCESS

    END {}
}
