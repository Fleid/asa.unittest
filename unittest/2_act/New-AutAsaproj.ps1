<#
.SYNOPSIS
PowerShell tool used to create a new XML asaproj file from a JSON one.
If one already exists it will be overwritten.

.DESCRIPTION
The tool used to run tests in unittest_prun (sa.exe) requires a manifest file (.asaproj) that describes the content of the asa project.
At the moment, Visual Studio generates XML asaproj files, Visual Studio Code generates JSON asaproj files. 
The XML ones are the one expected by sa.exe.

New-AUTAsaparoj will take a JSON asaproj file (generated previously by Visual Studio Code), and create the equivalent XML file.
If one already exists it will be overwritten.
Not every item will be ported, only those required during a test run will (asaql, jobconfig, local mock inputs).

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project = name of the project folder = name of the query in that folder (.asaql) = name of the project description file (.asaproj)

.EXAMPLE
.\New-AUTAsaproj.ps1 -asaProjectName "ASAHelloWorld" -solutionPath "C:\Users\fleide\Repos\asa.unittest" -verbose
#>

[CmdletBinding()]
param (
    [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY, # Azure DevOps Pipelines default variable

    [Parameter(Mandatory=$True)]
    [string]$asaProjectName
)

################################################################################################################################
write-verbose "101 - Set Variables"

# Variables
$asaProjectPath = "$solutionPath\$asaProjectName"
$sourceAsaprojFile = "$asaProjectPath\asaproj.json"
$targetAsaprojFile = "$asaProjectPath\$asaProjectName.asaproj"

# Constants
$newline = "`n"
$header = "<Project ToolsVersion=`"4.0`" DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`">" 
$footer = "</Project>"
$itemGroupStart = "<ItemGroup>"
$itemGroupEnd = "</ItemGroup>"

################################################################################################################################
write-verbose "201 - Loading existing content from the JSON asaproj file"

$sourceAsaproj = Get-Content $sourceAsaprojFile | ConvertFrom-Json

################################################################################################################################
write-verbose "301 - Generating the XML asaproj"

# Header
$targetAsaproj = $header + $newline

# First ItemGroup for script file (asaql)
$targetAsaproj += $itemGroupStart + $newline 
$targetAsaproj += "<Script Include=`"$($sourceAsaproj.startFile)`"/>" + $newline 
$targetAsaproj += $itemGroupEnd + $newline 

# Second ItemGroup for InputMock (local input config files) and JobConfig
$targetAsaproj += $itemGroupStart + $newline 

$sourceAsaproj.configurations | `
    Where-Object {$_.subType -in "InputMock","JobConfig" } |
    Foreach-Object -process {
        $targetAsaproj += "<Configure Include=`"$($_.filePath)`">" + $newline 
        $targetAsaproj += "<SubType>$($_.subType)</SubType>" + $newline 
        $targetAsaproj += "</Configure>" + $newline 
    }

$targetAsaproj += $itemGroupEnd + $newline 

# Footer
$targetAsaproj += $footer + $newline 

################################################################################################################################
write-verbose "401 - Writing the content to disk"

# Create new file
$targetAsaproj | Out-File $targetAsaprojFile 