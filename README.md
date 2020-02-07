# Unit testing Azure Stream Analytics

Unit testing for [Azure Stream Analytics](https://docs.microsoft.com/en-us/azure/stream-analytics/) (ASA), the serverless [complex-event-processing](https://en.wikipedia.org/wiki/Complex_event_processing) service running in Azure.

In this article:

- Description
  - Context
  - Unit testing
- Getting started
  - Requirements
  - Hello World
  - Installation
- Operations
  - ~~Configuring the asaproj file~~
  - Configuring a test case
  - Running a test
  - Build automation in Azure DevOps
  - Troubleshooting
- Internal Details
  - Change Log

***

## Description

### Context

At the time of writing, the major IDEs that support ASA ([VSCode](https://code.visualstudio.com/) and [Visual Studio](https://visualstudio.microsoft.com/vs/)) don't offer unit testing for it natively. 

This solution intends to fill that gap by enabling:

- fully local, repeatable executions over multiple test cases
- automated evaluation of the resulting outputs against the expected ones

For that it leverages the **local testing with sample data** capabilities of either [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) or [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run), as unit testing should not rely on external services (no live input).

Local runs are scripted thanks to the `sa.exe` tool from the [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) package.

The results are then evaluated against reference data sets thanks to the [jsondiffpatch](https://github.com/benjamine/JsonDiffPatch) library.

The whole thing is wired together in a **PowerShell** script based on a predefined test fixture (folder structure + naming convention):

![figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)

*[figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)*

This repository provides an **installation script**, in addition to the test script, to automate most of the setup. This installation script also allows automated executions in a continuous build pipeline such as **Azure DevOps Pipelines**.

Please note that this solution is currently available **only on Windows** as it depends on *Microsoft.Azure.StreamAnalytics.CICD*.

### Unit testing

From [Wikipedia](https://en.wikipedia.org/wiki/Unit_testing):

> Unit tests are typically automated tests written and run by software developers to ensure that a section of an application (known as the "unit") meets its design and behaves as intended.

Here **the unit is an individual output of an ASA job / query**. The test runner will need all the test inputs required for the job, but it will calculate test results only for outputs having a reference data file provided.

For practical reason (limiting the number of tests mean limiting the number of parallel runs to do), a single test can involve multiple outputs, as is demonstrated in the sample files.

Unit tests should not rely on external services, so all runs are done via local runs on sample data. Using live sources, or the Cloud service, to run tests would not qualify as unit testing.

***

## Getting started

### Requirements

This solution leverages [PowerShell](https://en.wikipedia.org/wiki/PowerShell), a [nuget](https://en.wikipedia.org/wiki/NuGet) package and a [npm](https://en.wikipedia.org/wiki/Npm_(software)) package to enable unit testing:

- For **PowerShell**, any [recent version](https://github.com/PowerShell/PowerShell/releases) should do (*assets* tab under a specific release)
- The **npm CLI** must also be installed manually (available with [Node.JS](https://nodejs.org/en/download/))
- The nuget CLI will be downloaded via the provided installation script, but it requires the [.NET Framework 4.7.2 or above](https://dotnet.microsoft.com/download/dotnet-framework) to run.

From there, the installation script will take care of the other dependencies (including the nuget CLI).

To be noted that those requirements are installed by default on every Azure DevOps Pipelines agents.

### Hello World

The following steps show how to download and run the solution with the included Hello World ASA project:

1. Check all requirements are installed
1. Clone/download this repository (it includes a basic ASA project `ASAHelloWorld` and a couple of pre-configured tests in *unittest\1_arrange* )
1. **Only once** - execute the installer in the *unittest\2_act* folder: `Install-AutToolset.ps1`
   - Open a **Powershell** host (terminal, ISE...)
   - Navigate to `asa.unittest\unittest\2_act`
   - Run `.\Install-AutToolset.ps1 -solutionPath "C:\Users\florian\Repos\asa.unittest" -verbose` with the right `-solutionPath` (absolute paths)
   - ![Screenshot of a terminal run of the installation script](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_install_terminal.png?raw=true)
   - In case of issues see **troubleshooting**
1. Execute the test runner in the *unittest\2_act* folder: `Start-AutRun.ps1`
   - Open a **Powershell** host (terminal, ISE...)
   - Navigate to `asa.unittest\unittest\2_act`
   - Run `.\Start-AutRun.ps1 -asaProjectName "ASAHelloWorld" -solutionPath "C:\Users\florian\Repos\asa.unittest" -assertPath "C:\Users\florian\Repos\asa.unittest\unittest\3_assert"-verbose` with the right `-solutionPath` and `-assertPath` (absolute paths)
   - ![Screenshot of a terminal run of the installation script](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_prun_terminal.png?raw=true)
   - Here it is expected that the test ends with 2 errors, in test case *003*
   - In case of issues see **troubleshooting**

### Installation

The following steps show how to download and run the solution on an existing ASA project:

1. Check all requirements are installed
1. If it doesn't exist, **create a solution folder** (simple top folder)
1. Prepare the ASA Project
   - Copy or move the existing ASA project to the solution folder
   - ~~If the project was developed with VSCode (not necessary for Visual Studio), add an `.asaproj` file to the ASA project as explained below~~
   - In ASA, add local inputs for every source used in the query (see [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) / [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run))
1. Clone/download this repository, copy or move the *unittest* folder to the solution folder
1. **Only once** - execute the installer in the *unittest\2_act* folder: `Install-AutToolset.ps1`
   - Open a **Powershell** host (terminal, ISE...)
   - Navigate to `unittest\2_act` in the solution folder
   - Run `.\Install-AutToolset.ps1 -solutionPath "C:\<SOLUTIONFOLDERPATH>" -verbose` with the right `-solutionPath` (absolute paths)
   - In case of issues see **troubleshooting**

***

## Operations

### Configuring the asaproj file

There is no need to manually create an asaproj file anymore, as it's being generated on the fly by the tool.
The original documentation is available in the README history.

### Configuring a test case

A test case is made of at least 2 files : a **test input data** file and a **reference output data** file. The test runner will start a local job ingesting the test input data, and compare the output of that job to the reference output data. Mapping inputs and outputs will be done following a file name convention.

**Reminder** : every input source used in the job query to be tested must have a local source configured in the ASA project ([VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run), [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run)).

Once this is done:

1. In `unittest\1_arrange`, prepare input files:
   - Copy the **test input data** file to be used in the test case for the test case
   - Rename it according to the file name convention : `xxx~input~sourceAlias~testLabel.yyy`
      - `xxx` : for the test case number (grouping multiple inputs and outputs together), for example : 001, 002...
      - `~` : as the separator
      - `input` : flags the file as an input file
      - `sourceAlias` : alias of the source in the query
      - `testLabel` : a label to identify the test (`nominal`, `missingField`, `nullValue`...)
      - `yyy` : any of the supported data format extension (csv, json, avro)
1. In `unittest\1_arrange`, prepare output files:
   - Copy the **reference output data** file to be used in the test case
   - Rename it according to the file name convention : `xxx~output~sinkAlias~testLabel.json`
      - `xxx` : for the test case number (grouping multiple inputs and outputs together), for example : 001, 002...
      - `~` : as the separator
      - `output` : flags the file as an input file
      - `sinkAlias` : alias of the destination in the query
      - `testLabel` : a label to identify the test (`nominal`, `missingField`, `nullValue`...)
      - `json` : **the data must be in JSON format as it's the only format currently supported for local output** (the ASA engine doesn't honor the output format for local runs)

Note that [live extracts](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run#prepare-sample-data) are a good way to generate test input data. Similarly for the output of local runs for reference output data. Note that these files may be generated in a **line separated** format, meaning without a proper array syntax (missing `[...]` around all records), which is not supported by the test runner. They will need to be corrected as follow:

Wrong format:

```JSON
{"EventId":"3","EventMessage":"Hello"}{"EventId":"4","EventMessage":"Friends"}
```

Proper format (brackets and commas):

```JSON
[
{"EventId":"3","EventMessage":"Hello"},
{"EventId":"4","EventMessage":"Friends"}
]
```

The solution comes with a couple of pre-configured test cases to illustrate the format and naming convention.

### Running a test

Once installation is done:

1. Configure a test case as explained above
1. Execute the test runner in the *unittest\2_act* folder: `Start-AutRun.ps1`
   - Open a **Powershell** host (terminal, ISE...)
   - Navigate to `unittest\2_act` in the solution folder
   - Run `.\Start-AutRun.ps1 -asaProjectName "<ASAPROJECTNAME>" -solutionPath "C:\<SOLUTIONFOLDERPATH>" -assertPath "C:\<SOLUTIONFOLDERPATH>\unittest\3_assert"-verbose` with the right `-solutionPath` and `-assertPath` (absolute paths)
   - In case of issues see **troubleshooting**

Once the test fixture is set, the recommended way of running jobs is via a terminal window.

### Build automation in Azure DevOps

Use a [PowerShell task](https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/powershell?view=azure-devops) to run the installation script first and the test runner script second.

Note that both scripts use default values for most parameters. These default values are wired to the [build variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml#build-variables) provided by Azure DevOps. As such, they can be left unassigned in the task.

The **installation script** only needs the `$unittestFolder` name if it's not the default (`unittest`), as illustrated with the script extract below:

```PowerShell
[CmdletBinding()]
param (
    [ValidateSet("2.3.0")]
    [string]$ASAnugetVersion = "2.3.0",
    [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY,
    [string]$unittestFolder ="unittest"
)
```

The **test runner** (Start-AutRun) needs to be provided with the `$asaProjectName`, and the `$unittestFolder` if it's not the default (`unittest`), as illustrated with the script extract below:

```PowerShell
param (
    [ValidateSet("2.3.0")]
    [string]$ASAnugetVersion = "2.3.0",

    [string]$solutionPath = $ENV:BUILD_SOURCESDIRECTORY, # Azure DevOps Pipelines default variable

    [Parameter(Mandatory=$True)]
    [string]$asaProjectName,

    [string]$unittestFolder = "unittest",
    [string]$assertPath = $ENV:COMMUB_TESTRESULTSDIRECTORY # Azure DevOps Pipelines default variable
)
```

### Troubleshooting

The main causes of error are:

#### PowerShell

PowerShell [execution policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7). PowerShell comes with that mechanism which is supposed to make a user deeply aware of the fact they're running a script they haven't written. For users with administrative rights, it's an easy to solve issue via **an admin session** and the command `Set-ExecutionPolicy -ExecutionPolicy Unrestricted` ([doc](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7)). For non admins, the easiest is to create new powershell scripts (text files with the `.ps1` extension) and copy/paste the content of each script (install, Start-AutRun). Note that the VSCode Integrated PowerShell environment has [an issue with execution policies](https://github.com/PowerShell/vscode-powershell/issues/1217) and should be avoided (use terminal instead)

PowerShell [remoting for jobs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_jobs?view=powershell-7). Depending on the version of PowerShell (older), it may require remoting to be enabled to start background jobs. Background jobs are used by the test runner to start runs in parallel. This should not be necessary, but [the command to enable remoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting?view=powershell-7) is `Enable-PSRemoting`

#### Test Fixture

- ~~Missing or malformed `asaproj` XML file. See the paragraph on how to configure it, check values against the JSON asaproj file as they should be the same. Limit the content to what is strictly necessary (script, JobConfig, local inputs)~~
- Bad format for JSON data files: test input JSON files and **all** reference output file need to be array of records (`[{...},{...}]`).
- Both the ASA project folder and the unittest folder need to be in the same solution folder
- The ASA project folder, ASA script file (`.asaql`) and the XML asaproj file (`.asaproj`) needs to have the same name

***

## Internal details

**(This needs to be updated to reflect the new parallel run workflow)**

![figure 2 - Detailed overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overviewFull.png?raw=true)

*[figure 2 - Detailed overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overviewFull.png?raw=true)*

### Change Log

- February 2020 : 
  - Automated the generation of the XML asaproj file (required by sa.exe) from the JSON one (for VSCode project)
  - Renamed scripts to follow PowerShell standards, with backward compatibility

### Scenario and components

This solution uses the following components:

- the [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) nuget package, which provides `sa.exe`, a Windows-only executable that allows to run an ASA job [via command line](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-tools-for-visual-studio-cicd)
  - the [nuget CLI](https://docs.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference), to download and install the package above
- the **jsondiffpatch** npm package ([GitHub]((https://github.com/benjamine/JsonDiffPatch) ), [npm](https://www.npmjs.com/package/jsondiffpatch)) which allows to compare json files
  - the [npm CLI](https://docs.npmjs.com/cli-documentation/) to install the package above, available with [Node.JS](https://nodejs.org/en/download/)
- [PowerShell](https://github.com/PowerShell/PowerShell/releases) as the shell to run intermediary tasks and execute the required commands

These components are used in a script as follow:

![figure 1 - Schema of the unit testing setup - it is detailed below](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_solution.png?raw=true)

The script will expect the following folder structure to run properly:

- **mySolutionFolder** <- *Potentially new top solution folder*
  - **ASATest1** <- *Existing ASA project folder, containing the `.asaql` file and inputs folder*
  - **unittest** <- *New folder for the test project*
    - 1_arrange <- *New folder that will contain test cases*
    - 2_act <- *New folder that will contain dependencies and scripts*
    - 3_assert <- *New folder that will contain test run results*

### Shortcomings

- Slow execution
- No integration to the usual IDEs
- No cross-platform options
