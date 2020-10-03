
<#
.SYNOPSIS
Tool that archive then update output test files to the format required by the npm Azure Stream Analyics CICD package from a folder of tests following the asa.unittest syntax
It can be run on files already in the new format without issues.
Start-AutRun can handle both formats equally.

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project = name of the project folder = name of the query in that folder (.asaql) = name of the project description file (.asaproj)

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_arrange, 2_act, 3_assert), usually "asaProjectName.Tests"

.PARAMETER archivePath
Path where the existing files will be archived. If missing will generate a new one timestamped for each execution

.EXAMPLE
Set-AutNewFormatOutputFiles -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder
#>

Function Set-AutNewFormatOutputFiles{

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Low"
        )]
    param (
        [string]$solutionPath = $(Throw "-solutionPath is required"),
        [string]$asaProjectName,
        [string]$unittestFolder = "$asaProjectName.Tests",
        [string]$archivePath
    )

    BEGIN {
        ################################################################################################################################
        write-verbose "Set-AutNewFormatOutputFiles::101 - Set and check variables"

        if (-not (Test-Path -Path $solutionPath)) {Throw "Invalid -solutionPath"}

        $arrangePath = "$solutionPath\$unittestFolder\1_arrange"
        if (-not (Test-Path($arrangePath))) {throw "$arrangePath is not a valid path"}

        if (-not (($archivePath.Length -ge 1))){
                $archivePath = $arrangePath + "\archive_$(Get-Date -Format "yyyyMMddHHmmss")"
                write-verbose "Set-AutNewFormatOutputFiles::No archivePath provided, will default to $archivePath"
                New-Item -ItemType Directory -Path $archivePath
        }
        if (-not (Test-Path -Path $archivePath)) {throw "$archivePath is not a valid path"}
    }

    PROCESS {
        if ($pscmdlet.ShouldProcess("Starting a format conversion for output files of $asaProjectName at $arrangePath. Existing files archived at $archivePath"))
        {
            ################################################################################################################################
            # Output files inventory
            write-verbose "Set-AutNewFormatOutputFiles::201 - Getting the list of output files to be processed in the 1_arrange folder"

            $filesToBeProcessed = Get-ChildItem -Path $arrangePath `
                | Where-Object {$_.Name -like "*~Output~*~*.json"}

            ################################################################################################################################
            # Convert files to the new format
            write-verbose "Set-AutNewFormatOutputFiles::301 - Converting content"

            foreach ($file in $filesToBeProcessed){
                write-verbose "Set-AutNewFormatOutputFiles::302 - Converting $($file.Name) content"
                
                $fileName = $file.FullName

                ## This extract only the content of {...} and all other syntax
                ## Thanks to https://techtalk.gfi.com/windows-powershell-extracting-strings-using-regular-expressions/
                $fileContent = (Invoke-ReadAllText -path $fileName).split("`n") `
                | Select-String -pattern "\{([^}]+)\}" `
                | ForEach-Object Matches `
                | ForEach-Object Value

                ## Generating a single string out of the array, adding back CRLF as the separator
                $newContent = $fileContent -join "`r`n"

                write-verbose "Set-AutNewFormatOutputFiles::302 - Archiving $($file.Name)"
                $destination = $archivePath + "\" + $file.Name
                Copy-Item -Path $fileName  -Destination $destination -Force
                if (-not (Test-Path -Path $destination)) {throw "Set-AutNewFormatOutputFiles::302 - $($file.Name) was not archived, not found in archive, it will not be processed, no data was lost"}

                ## Using WriteAllText to avoid the final empty line that pops up with Out-File
                write-verbose "Set-AutNewFormatOutputFiles::303 - Generating new $($file.Name)"
                Invoke-WriteAllText -f $fileName -c $newContent
            }

            write-verbose "Set-AutNewFormatOutputFiles::301 - Conversion finished"
        }
    } #PROCESS
    END {}
}