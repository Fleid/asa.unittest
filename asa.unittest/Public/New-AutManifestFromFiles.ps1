<#
.SYNOPSIS
Tool that generates a manifest (testConfig.json) required by the npm Azure Stream Analyics CICD package from a folder of tests following the asa.unittest naming convention

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project, usually the name of the project folder

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_arrange, 2_act, 3_assert), usually "asaProjectName.Tests"

.PARAMETER outputFilePath
Path to the file to be generated

.EXAMPLE
New-AutManifestFromFiles -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder -outputFilePath $outputFilePath
#>
Function New-AutManifestFromFiles{

        [CmdletBinding(
            SupportsShouldProcess=$true,
            ConfirmImpact="Low"
            )]
        param (
            [string]$solutionPath = $(Throw "-solutionPath is required"),
            [string]$asaProjectName = $(Throw "-asaProjectName is required"),
            [string]$unittestFolder = "$asaProjectName.Tests",
            [string]$outputFilePath
        )

        BEGIN {
                ################################################################################################################################
                write-verbose "New-AutManifestFromFiles::101 - Set and check variables"

                if (-not (Test-Path $solutionPath)) {Throw "Invalid -solutionPath"}

                $arrangePath = "$solutionPath\$unittestFolder\1_arrange"
                if (-not (Test-Path $arrangePath )) {throw "$arrangePath is not a valid path"}

                $Script = "$solutionPath\$asaProjectName\$asaProjectName.asaql"
                if (-not (Test-Path $Script )) {throw "Can't find $asaProjectName.asaql at $solutionPath\$asaProjectName"}

                $localInputSourcePath = "$solutionPath\$asaProjectName\Inputs"
                if (-not (Test-Path $localInputSourcePath )) {throw "Can't find the Inputs subfolder at $solutionPath\$asaProjectName"}

                if (-not ($outputFilePath.Length -ge 1)){
                        $outputFilePath = $arrangePath+"\testConfig_$(Get-Date -Format "yyyyMMddHHmmss").json"
                        write-verbose "New-AutManifestFromFiles::No outputFilePath provided, will default to $outputFilePath"
                }

        }

        PROCESS {
                if ($pscmdlet.ShouldProcess("Starting a manifest generation for $asaProjectName at $arrangePath"))
                {

                        ################################################################################################################################
                        # Test inventory
                        write-verbose "New-AutManifestFromFiles::201 - Getting the list of every files/tests in the 1_arrange folder"

                        $testDetails = (Get-ChildItem -Path $arrangePath -File) |
                                Get-AutFieldFromFileInfo -s "~" -n 4 |
                                Select-Object `
                                FullName, `
                                FilePath, `
                                Basename, `
                                @{Name = "TestCase"; Expression = {$_.Basename0}}, `
                                @{Name = "FileType"; Expression = {$_.Basename1}}, `
                                @{Name = "SourceName"; Expression = {$_.Basename2}}, `
                                @{Name = "TestLabel"; Expression = {$_.Basename3}}

                        ################################################################################################################################
                        # Generating the inputs
                        write-verbose "New-AutManifestFromFiles::301 - Processing the input files"

                        ## First we find the distinct list of input sources, regardless of the test, and lookup their attributes in their config files
                        $inputProps = $testDetails `
                                | Where-Object {$_.FileType -eq "Input"} `
                                | Select-Object SourceName -Unique `
                                | Select-Object `
                                        SourceName,
                                        @{Name = "SourceConfigFile"; Expression = {"$localInputSourcePath\Local_"+$_.SourceName+".json"}},
                                        @{Name = "SourceConfigProps"; Expression = {Get-Content -Path "$localInputSourcePath\Local_$($_.SourceName).json" | ConvertFrom-Json}}

                        ## Then we generate the expected list at the right cardinality (test x input source)
                        $Inputs = $testDetails `
                                | Where-Object {$_.FileType -eq "Input"} `
                                | Select-Object `
                                        @{Name = "Name"; Expression = {$_.TestCase}}, `
                                        @{Name = "InputAlias"; Expression = {$_.SourceName}}, `
                                        @{Name = "FilePath"; Expression = {$_.FilePath}}, `
                                        @{Name = "Type"; Expression = {($inputProps | Where-Object -Property SourceName -eq $_.SourceName).SourceConfigProps.Type}}, `
                                        @{Name = "Format"; Expression = {($inputProps | Where-Object -Property SourceName -eq $_.SourceName).SourceConfigProps.Format}}, `
                                        @{Name = "ScriptType"; Expression = {($inputProps | Where-Object -Property SourceName -eq $_.SourceName).SourceConfigProps.ScriptType}}


                        ################################################################################################################################
                        # Generating the outputs
                        write-verbose "New-AutManifestFromFiles::302 - Processing the output files"

                        ## To understand if an output is required or not for a test, we check if it's present or missing in the test declaration

                        ## For that we first build the carthesian product of {test x output}
                        $testList = $testDetails `
                                | Select-Object TestCase -Unique

                        $outputSources = $testDetails `
                                | Where-Object {$_.FileType -eq "Output"} `
                                | Select-Object SourceName -Unique

                        $outputStub = `
                                foreach ($testCase in $testList) {
                                foreach ($outputSource in $outputSources){
                                        [PSCustomObject]@{
                                                Name = $testCase.TestCase;
                                                OutputAlias = $outputSource.SourceName
                                        }
                                }}

                        ## Details of each test
                        $outputDetails = $testDetails `
                                | Where-Object {$_.FileType -eq "Output"}

                        ## We "left join" the carthesian product to the test list, if an output is missing from the declaration it's not required
                        $ExpectedOutputs = $outputStub `
                                | Select-Object `
                                        Name,
                                        OutputAlias,
                                        @{Name = "Required"; Expression = {if (($outputDetails `
                                                                                        | Where-Object -Property SourceName -eq $_.OutputAlias `
                                                                                        | Where-Object -Property TestCase -eq $_.Name).FilePath) `
                                                                                {"true"} else {"false"}
                                                                        }},
                                        @{Name = "FilePath"; Expression = {if (($outputDetails `
                                                                                        | Where-Object -Property SourceName -eq $_.OutputAlias `
                                                                                        | Where-Object -Property TestCase -eq $_.Name).FilePath) `
                                                                                {($outputDetails `
                                                                                        | Where-Object -Property SourceName -eq $_.OutputAlias `
                                                                                        | Where-Object -Property TestCase -eq $_.Name).FilePath} `
                                                                                else {"foo.bar"}
                                }
                        }

                        ################################################################################################################################
                        # Generating the final file
                        write-verbose "New-AutManifestFromFiles::401 - Generating the config file"

                        ## Build an array of object with the required attribute
                        $TestCases = `
                                foreach ($testCase in $testList) {
                                [PSCustomObject]@{
                                        Name = $testCase.TestCase;
                                        Inputs = ($Inputs | Where-Object -Property Name -eq $testCase.TestCase | Select-Object InputAlias, Type, Format, FilePath, ScriptType);
                                        ExpectedOutputs = ($ExpectedOutputs | Where-Object -Property Name -eq $testCase.TestCase| Select-Object OutputAlias, FilePath, Required)
                                }
                        }

                        ## Build the final expected object and convert to JSON
                        $testConfig = [PSCustomObject]@{
                                Script = $Script;
                                TestCases = $TestCases
                        }

                        $finalJSON = $testConfig | ConvertTo-Json -Depth 4
                        $finalJSON | Out-File -FilePath $outputFilePath
                        $finalJSON
                }
        } #PROCESS
        END {}
}