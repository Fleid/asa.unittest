<#
.SYNOPSIS
Controller script used to create a new XML asaproj file from a JSON one. If one already exists it will be overwritten.

.DESCRIPTION
The tool used to run tests in unittest_prun (sa.exe) requires a manifest file (.asaproj) that describes the content of the asa project.
At the moment, Visual Studio generates XML asaproj files, Visual Studio Code generates JSON asaproj files.
The XML ones are the one expected by sa.exe.

New-AUTAsaparoj will take a JSON asaproj file (generated previously by Visual Studio Code), and create the equivalent XML file.
If one already exists it will be overwritten.
Not every item will be ported, only those required during a test run will (asaql, jobconfig, local mock inputs).

See documentation for more information : https://github.com/Fleid/asa.unittest

.PARAMETER sourceAsaproj
PowerShell object converted from an asaproj.json. The easiest way to generate this is to use `(Get-Content asaproj.json | ConvertFrom-JSON)`

.EXAMPLE
(Get-Content asaproj.json | ConvertFrom-JSON) | New-AutAsaprojXML |Out-File ASAHelloWorld.asaproj
#>

function New-AutAsaprojXML{

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Low"
        )]
    param (
        [Parameter(ValueFromPipeline=$true)]
        [PSCustomObject]$sourceAsaproj
    )

    BEGIN {}

    PROCESS {
        if ($pscmdlet.ShouldProcess("Generating a XML file for $sourceAsaproj"))
            {

            ################################################################################################################################
            write-verbose "001 - Testing the input"

            if (($null -eq $sourceAsaproj.startFile) -or ($sourceAsaproj.startFile -eq "")) {
                Throw "Error : startFile (aka .asaql path) is missing or empty from input asaProj file"
            }

            if (-not ($sourceAsaproj.configurations | Where-Object {$_.subType -in "JobConfig"})) {
                Throw "Error : JobConfig path is missing or empty from input asaProj file"
            }

            ################################################################################################################################

            # Constants
            $newline = "`r`n"
            $header = "<Project ToolsVersion=`"4.0`" DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`">"
            $footer = "</Project>"
            $itemGroupStart = "<ItemGroup>"
            $itemGroupEnd = "</ItemGroup>"
            $itemFilter = @("InputMock","JobConfig","JSFunction")

            ################################################################################################################################
            write-verbose "101 - Generating the XML asaproj"

            # Header
            $targetAsaproj = $header + $newline

            # First ItemGroup for script file (asaql)
            $targetAsaproj += $itemGroupStart + $newline
            $targetAsaproj += "<Script Include=`"$($sourceAsaproj.startFile)`"/>" + $newline
            $targetAsaproj += "<ScriptCode Include=`"$($sourceAsaproj.startFile).cs`">" + $newline
            $targetAsaproj += "<DependentUpon>$($sourceAsaproj.startFile)</DependentUpon>" + $newline
            $targetAsaproj += "</ScriptCode>" + $newline
            $targetAsaproj += $itemGroupEnd + $newline

            # Second ItemGroup for InputMock (local input config files) and JobConfig
            $targetAsaproj += $itemGroupStart + $newline

            $sourceAsaproj.configurations | `
                Where-Object {$_.subType -in $itemFilter} |
                Foreach-Object -process {
                    $targetAsaproj += "<Configure Include=`"$($_.filePath)`">" + $newline
                    $targetAsaproj += "<SubType>$($_.subType)</SubType>" + $newline
                    $targetAsaproj += "</Configure>" + $newline
                }

            $targetAsaproj += $itemGroupEnd + $newline

            # Footer
            $targetAsaproj += $footer + $newline

            ################################################################################################################################
            write-verbose "401 - Writing the content to ouptut pipeline"

            # Create new object
            $outputObject = $targetAsaproj

            $outputObject

        } #ShouldProcess
    } #PROCESS
    END {}
}
