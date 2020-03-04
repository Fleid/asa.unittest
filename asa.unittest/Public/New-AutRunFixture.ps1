<#
.SYNOPSIS
Powershell script used to...

.DESCRIPTION
This script will ...
See documentation for more information.

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.EXAMPLE
New-AutRunFixture -testDetails $testDetails -asaProjectName $asaProjectName -asaProjectPath $asaProjectPath -testPath $testPath
#>

Function New-AutRunFixture{

    [CmdletBinding()]
    param (
        [string]$solutionPath,
        [string]$asaProjectName,
        [string]$unittestFolder,
        [string]$testPath
    )

    BEGIN {}

    PROCESS {

        $asaProjectPath = "$solutionPath\$asaProjectName"
        $arrangePath = "$solutionPath\$unittestFolder\1_arrange"

        $testFiles = (Get-ChildItem -Path $arrangePath -File) 

        $testDetails = $testFiles | Select-Object `
            @{Name = "FullName"; Expression = {$_.Name}}, `
            @{Name = "FilePath"; Expression = {$_.Fullname}}, `
            @{Name = "Basename"; Expression = {$_.Basename}}, `
            @{Name = "TestCase"; Expression = {$parts = $_.Basename.Split("~"); $parts[0]}}, `
            @{Name = "FileType"; Expression = {$parts = $_.Basename.Split("~"); $parts[1]}}, `
            @{Name = "SourceName"; Expression = {$parts = $_.Basename.Split("~"); $parts[2]}}, `
            @{Name = "TestLabel"; Expression = {$parts = $_.Basename.Split("~"); $parts[3]}}

       write-verbose "201 - Create and populate test folders"

       $testFolders = `
           $testDetails | 
           Select-Object @{Name = "Path"; Expression = {"$testPath\$($_.TestCase)"}} |
           Sort-Object -Property Path -Unique

       ## Create 1 folder for each test case
       $testFolders | New-Item -ItemType Directory | Out-Null

       ## Create an ASA project folder in test case folder
       $testFolders |
           Select-Object @{Name = "Path"; Expression = {"$($_.Path)\$asaProjectName\Inputs\"}} |
           New-Item -ItemType Directory |
           Out-Null

       ## Copy .asaql, .asaproj (XML) and JobConfig, asaproj (JSON) required for run in each test case folder
       $testFolders | 
           Select-Object @{Name="Destination"; Expression = {"$($_.Path)\$asaProjectName\"}} |
           Copy-Item -Path "$asaProjectPath\*.as*","$asaProjectPath\*.json" -recurse |
           Out-Null

       ## If there isn't a XML asaproj, generate it from the JSON one
       $testFolders | 
           ForEach-Object -Process {
               if (-not(Test-Path "$($_.Path)\$asaProjectName\$asaProjectName.asaproj" -PathType leaf)) {
                   $exe = "$actPath\New-AUTAsaproj.ps1"
                   & $exe -asaProjectName $asaProjectName -solutionPath $_.Path
               }
           }

       ## Copy the local input mock file required for run in each test case folder
       $testFolders | 
           Select-Object @{Name="Destination"; Expression = {"$($_.Path)\$asaProjectName\Inputs\"}} |
           Copy-Item -Path "$asaProjectPath\Inputs\Local*.json" -recurse |
           Out-Null

       ## Copy test files from 1_arrange to each test case folder 
       $testDetails | 
           Select-Object `
               @{Name = "Destination"; Expression = {"$testPath\$($_.TestCase)\$asaProjectName\Inputs\"}},
               @{Name = "Path"; Expression = {$_.FilePath}} |
           Copy-Item |
           Out-Null

       ################################################################################################################################
       # 3xx - Updating config files
       write-verbose "301 - Update each conf file"

       ## For each Input test file, edit the corresponding Local config file in the test case Input folder to point to it
       $testDetails | 
           Where-Object { $_.FileType -eq"Input" } |
           Select-Object `
               FullName,
               @{Name = "confFilePath"; Expression = {"$testPath\$($_.TestCase)\$asaProjectName\Inputs\Local_$($_.SourceName).json"}} |
           Foreach-Object -process {
               $localInputData = Get-Content $_.confFilePath | ConvertFrom-Json;
               $localInputData.FilePath = $_.FullName;
               $localInputData | ConvertTo-Json | Out-File $_.confFilePath
           } |
           Out-Null

        ## Output Pipeline
        $testDetails.TestCase | Sort-Object -Unique

    } #PROCESS
    END {}
}