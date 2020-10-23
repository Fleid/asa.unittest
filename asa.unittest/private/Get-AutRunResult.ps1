<#
.SYNOPSIS
Controller script used to generate results of a test run

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the unittest folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project = name of the project folder = name of the query in that folder (.asaql) = name of the project description file (.asaproj)

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_arrange, 2_act, 3_assert), usually "asaProjectName.Tests"

.PARAMETER testId
Timestamp of the test run (yyyyMMddHHmmss), will be used in the folder structure

.PARAMETER testCase
Current test to be run (001, 002, 003...)

.PARAMETER asaNugetVersion
Version of the Azure Stream Analytics CI/CD nuget package (Microsoft.Azure.StreamAnalytics.CICD) to be downloaded and used

.EXAMPLE
Get-AutRunResult -solutionPath $solutionPath -asaProjectName $asaProjectName -unittestFolder $unittestFolder -testID $testID -testCase $testCase -asaNugetVersion "3.0.0"
#>

Function Get-AutRunResult{

    [CmdletBinding()]
    [OutputType([int])]
    param (
        [string]$solutionPath,# = $(Throw "-solutionPath is required"),
        [string]$asaProjectName = $(Throw "-asaProjectName is required"),
        [string]$unittestFolder = $(Throw "-unittestFolder is required"),
        [string]$testID = $(Throw "-testID is required"),
        [string]$testCase = $(Throw "-testCase is required"),
        [string]$asaNugetVersion = $(Throw "-asaNugetVersion is required")
    )

    BEGIN {
        if (-not (Test-Path($solutionPath))) {throw "$solutionPath is not a valid path"}

        $testPath = "$solutionPath\$unittestFolder\3_assert\$testID\$testCase"
        if (-not (Test-Path($testPath))) {throw "$testPath is not a valid path"}

        $outputSourcePath = "$testPath\$asaProjectName\Inputs"
        if (-not (Test-Path($outputSourcePath))) {throw "$outputSourcePath is not a valid path"}
    }

    PROCESS {
        $errorCounter = 0

        $testDetails = (Get-ChildItem -Path $outputSourcePath -File) |
            Get-AutFieldFromFileInfo -s "~" -n 4 |
            Select-Object `
                FullName, `
                FilePath, `
                Basename, `
                @{Name = "TestCase"; Expression = {$_.Basename0}}, `
                @{Name = "FileType"; Expression = {$_.Basename1}}, `
                @{Name = "SourceName"; Expression = {$_.Basename2}}, `
                @{Name = "TestLabel"; Expression = {$_.Basename3}}

        $testDetails | Where-Object { $_.FileType -eq "Output" } |
        Select-Object `
            FullName,
            SourceName,
            TestCase,
            @{Name = "rawContent"; Expression = {"$testPath\$($_.SourceName).json"}}, #sa.exe output
            @{Name = "testableFilePath"; Expression = {"$testPath\$($_.SourceName).testable.json"}}, #to be generated
            @{Name = "sortedTestCaseOutputFilePath"; Expression = {"$testPath\$($_.Basename).sorted.json"}}, #to be generated
            @{Name = "testCaseOutputFile"; Expression = {"$testPath\$asaProjectName\Inputs\$($_.FullName)"}} |
        Foreach-Object -process {

            # Prepare input content (sorting)
            $referenceContent = Get-Content -Path $_.testCaseOutputFile | ConvertFrom-Json

            $referenceContentProperties = `
                    $referenceContent  | `
                    Get-Member -MemberType NoteProperty | `
                    Sort-Object -Property Name | `
                    Select-Object -ExpandProperty Name

            $referenceSortedContent = $referenceContent | Sort-Object -Property $referenceContentProperties | ConvertTo-JSON

            Add-Content -Path $_.sortedTestCaseOutputFilePath -Value $referenceSortedContent

            # Prepare output content (format, sorting)

            if ($asaNugetVersion.split(".")[0].Equals("2")) {
                $testableContent = ("[$(Get-Content -Path $_.rawContent)]") | ConvertFrom-Json
            } else {
                # New format after CICD 3.0.0
                $testableContent = (Invoke-ReadAllText -p $_.rawContent).split("`n") | ConvertFrom-Json
            }

            $testableContentProperties = `
                    $testableContent | `
                    Get-Member -MemberType NoteProperty | `
                    Sort-Object -Property Name | `
                    Select-Object -ExpandProperty Name

            $testableSortedContent = $testableContent | Sort-Object -Property $testableContentProperties | ConvertTo-JSON

            Add-Content -Path $_.testableFilePath -Value $testableSortedContent

            # Actual testing
            $left = Get-Content $_.sortedTestCaseOutputFilePath
            $right = Get-Content $_.testableFilePath
            $testResult = Compare-Object $left $right

            if ($testResult) {
                $testResult | Out-File "$testPath\$($_.SourceName).Result.txt"
                Write-Verbose ">> Errors on test $($_.TestCase)\$($_.SourceName):"
                $testResult | Foreach-Object {Write-Verbose "$($_.SideIndicator) $($_.InputObject)"}
                $errorCounter++
            }
        }

        $errorCounter

    } #PROCESS
    END {}
}