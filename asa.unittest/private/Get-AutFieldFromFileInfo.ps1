<#
.SYNOPSIS
Tool script used to parse a FileInfo to extract fields from naming convention

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

.PARAMETER thisFileInfo
FileInfo to be processed

.PARAMETER fieldSeparator
Separator used in the naming convention

.PARAMETER numberOfFields
Number of fields to be extracted

.EXAMPLE
(Get-ChildItem -Path $arrangePath -File) | Get-AutFieldFromFileInfo
#>

Function Get-AutFieldFromFileInfo{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [System.IO.FileInfo]$thisFileInfo,
        [string]$separatorOfFields,
        [int]$numberOfFields
    )

    BEGIN {}

    PROCESS {
        $Fields = New-Object PSObject -Property @{
            FullName = $thisFileInfo.Name
            FilePath = $thisFileInfo.Fullname
            Basename = $thisFileInfo.Basename
        }

        $basenameParts = $thisFileInfo.Basename.Split($separatorOfFields)

        for (($i=0);($i -lt $numberOfFields);$i++){
            $Fields | Add-Member Noteproperty "basename$fieldSeparator$i" $basenameParts[$i]
        }

        $Fields
    }
}