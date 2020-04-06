<#
.SYNOPSIS
Orchestrator script used to run unit tests on an Azure Stream Analytics project

In case of issues with PowerShell Execution Policies, see https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_scripts?view=powershell-7
PS: VSCode has a weird behavior on that topic, use Windows Terminal instead : https://github.com/PowerShell/vscode-powershell/issues/1217

.DESCRIPTION
See documentation for more information : https://github.com/Fleid/asa.unittest

This script leverages a text fixture (folder structure + filename convention) to run unit tests for a given ASA project.
It requires dependencies installed by the companion script Install_AutToolset

.PARAMETER asaNugetVersion
Version of the Azure Stream Analytics CI/CD nuget package (Microsoft.Azure.StreamAnalytics.CICD) to be downloaded and used

.PARAMETER solutionPath
Path to the solution (folder) containing both the Azure Stream Analytics folder and the Tests folder

.PARAMETER asaProjectName
Name of the Azure Stream Analytics project = name of the project folder = name of the query in that folder (.asaql) = name of the project description file (.asaproj)

.PARAMETER unittestFolder
Name of the folder containing the test fixture (folders 1_arrange, 2_act, 3_assert), usually "asaProjectName.Tests"

.EXAMPLE
Start-AutRun.ps1 -solutionPath "C:\Users\fleide\Repos\asa.unittest" -asaProjectName "ASAHelloWorld" -verbose
#>

Function Start-AutRun{

    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Low"
        )]
    param (
        #[ValidateSet("2.3.0","2.4.0","2.4.1")]
        [string]$asaNugetVersion,

        [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY, # Azure DevOps Pipelines default variable

        [string]$asaProjectName = $(Throw "-asaProjectName is required"),

        [string]$unittestFolder = "$asaProjectName.Tests"
    )

    BEGIN {
        ################################################################################################################################
        write-verbose "101 - Set and check variables"

        if (-not (Test-Path $solutionPath)) {Throw "Invalid -solutionPath"}

        if (-not (`
                     ($asaProjectName -match '^[a-zA-Z0-9_-]+$') `
                -and ($asaProjectName.Length -ge 3) `
                -and ($asaProjectName.Length -le 63) `
        )) {Throw "Invalid -asaProjectName (3-63 alp_ha-num)"}

        if (-not (Test-Path "$solutionPath\$unittestFolder\1_arrange")) {Throw "Can't find 1_arrange folder at $solutionPath\$unittestFolder\1_arrange"}

        if (-not $asaNugetVersion) {
            $asaNugetVersion = (`
                Get-ChildItem -path "$solutionPath\$unittestFolder\2_act\" | `
                Where-Object { ($_.Name -like "Microsoft.Azure.StreamAnalytics.CICD.*") `
                    -and ($_.Name -match '([0-9]+\.[0-9]+\.[0-9]+)$') } | `
                Sort-Object -Descending -Property LastWriteTime | `
                Select-Object -First 1 -ExpandProperty Name `
            ).Substring(37) #Microsoft.Azure.StreamAnalytics.CICD.
        }

        $exePath = "$solutionPath\$unittestFolder\2_act\Microsoft.Azure.StreamAnalytics.CICD.$asaNugetVersion\tools\sa.exe"
        if (-not (Test-Path $exePath -PathType Leaf)) {Throw "Can't find sa.exe at $solutionPath\$unittestFolder\2_act\Microsoft.Azure.StreamAnalytics.CICD.$asaNugetVersion\tools\sa.exe"}

        $testID = (Get-Date -Format "yyyyMMddHHmmss")
    }

    PROCESS {
        if ($pscmdlet.ShouldProcess("Starting an asa.unittest run for $asaProjectName at $unittestFolder"))
        {
            ################################################################################################################################
            # 2xx - Creating run fixture

            $testCases = New-AutRunFixture `
                -solutionPath $solutionPath `
                -asaProjectName $asaProjectName `
                -unittestFolder $unittestFolder `
                -testID $testID

            ################################################################################################################################
            # 4xx - Running the jobs
            write-verbose "401 - Run SA in parallel jobs"

            ForEach ($testCase in $testCases) {
                New-AutRunJob `
                    -solutionPath $solutionPath `
                    -asaProjectName $asaProjectName `
                    -unittestFolder $unittestFolder `
                    -testID $testID `
                    -testCase $testCase `
                    -exePath $exePath
            }

            ## Wait for all jobs to complete and results ready to be received
            write-verbose "402 - Waiting for all jobs to end..."

            Wait-Job * | Out-Null

            write-verbose "403 - Jobs done"

            <#
            ## Debug ~ Process the results
            foreach($job in Get-Job)
            {
                $result = Receive-Job $job
                Write-Host $result
            }
            #>

            ################################################################################################################################

            write-verbose "501 - Calculating diffs"

            $errorCounter = 0

            ## For each Output test file, generate a testable file (adding brackets to it) then run the diff with the corresponding arranged output file

            ForEach ($testCase in $testCases) {
                $errorCounter += Get-AutRunResult `
                    -solutionPath $solutionPath `
                    -asaProjectName $asaProjectName `
                    -unittestFolder $unittestFolder `
                    -testID $testID `
                    -testCase $testCase
            }

            ################################################################################################################################

            # Final result
            if ($errorCounter -gt 0) {Write-Verbose "Ending Test Run with $errorCounter errors"}
            if ($errorCounter -gt 0) {throw("Ending Test Run with $errorCounter errors")}

        } #ShouldProcess
    } #PROCESS
    END {}
}