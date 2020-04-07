# Unit testing Azure Stream Analytics

A [PowerShell Gallery module](https://www.powershellgallery.com/packages/asa.unittest/) for unit testing [Azure Stream Analytics](https://docs.microsoft.com/en-us/azure/stream-analytics/) (ASA) jobs, the serverless [complex-event-processing](https://en.wikipedia.org/wiki/Complex_event_processing) service running in Azure.

![Logo of asa.unittest](https://raw.githubusercontent.com/Fleid/asa.unittest/master/bandage.png)

In this article:

- [Description](https://github.com/Fleid/asa.unittest#description)
  - [Context](https://github.com/Fleid/asa.unittest#context)
  - [Unit testing](https://github.com/Fleid/asa.unittest#Unit-testing)
- [Getting started](https://github.com/Fleid/asa.unittest#Getting-started)
  - [Requirements](https://github.com/Fleid/asa.unittest#Requirements)
  - [Hello World](https://github.com/Fleid/asa.unittest#Hello-World)
  - [Installation](https://github.com/Fleid/asa.unittest#Installation)
- [Operations](https://github.com/Fleid/asa.unittest#Operations)
  - [Running a test](https://github.com/Fleid/asa.unittest#Running-a-test)
  - [Configuring a test case](https://github.com/Fleid/asa.unittest#Configuring-a-test-case)
  - [Build automation in Azure DevOps](https://github.com/Fleid/asa.unittest#Build-automation-in-Azure-DevOps)
  - [Troubleshooting](https://github.com/Fleid/asa.unittest#Troubleshooting)
- [Internal Details](https://github.com/Fleid/asa.unittest#Internal-Details)
  - [Change Log](https://github.com/Fleid/asa.unittest#Change-Log)
  - [Thanks](https://github.com/Fleid/asa.unittest#Thanks)

***

## Description

### Context

At the time of writing, the major IDEs that support ASA ([VSCode](https://code.visualstudio.com/) and [Visual Studio](https://visualstudio.microsoft.com/vs/)) do not offer native unit testing capabilities.

This solution intends to fill that gap by enabling:

- fully local, repeatable executions over multiple test cases
- automated evaluation of the resulting outputs against expected ones

For that it leverages the **local testing with sample data** capabilities of either [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) or [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run), as unit testing should not rely on external services (no live input).

Local runs are scripted thanks to the `sa.exe` tool from the [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) package.

The results are then evaluated against reference data sets thanks to the [jsondiffpatch](https://github.com/benjamine/JsonDiffPatch) library.

The whole thing is wired together in a **PowerShell** script based on a predefined test fixture (folder structure + naming convention):

![figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)

*[figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)*

This repository provides an **installation script** (`New-AutProject`), in addition to the test script (`Start-AutRun`), to automate most of the setup. This installation script also allows automated executions in a continuous build pipeline such as **Azure DevOps Pipelines**.

Please note that this solution is currently available **only on Windows** as it depends on *Microsoft.Azure.StreamAnalytics.CICD*.

### Unit testing

From [Wikipedia](https://en.wikipedia.org/wiki/Unit_testing):

> Unit tests are typically automated tests written and run by software developers to ensure that a section of an application (known as the "unit") meets its design and behaves as intended.

Here **the unit is an individual output of an ASA job / query**. The test runner will need all the test inputs required for the job, but it will calculate test results only for outputs having a reference data file provided.

For practical reason (limiting the number of tests mean limiting the number of parallel runs to do), a single test can involve multiple outputs, as is demonstrated in [the sample files](https://github.com/Fleid/asa.unittest/tree/master/examples/ASAHelloWorld.Tests/1_arrange).

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

### Fixture structure

The scripts will expect the following folder structure to run properly:

- **mySolutionFolder** <- *Potentially new top solution folder*
  - **ASATest1** <- *Existing ASA project folder, containing the `.asaql` file and inputs folder*
  - **ASATest1.Tests** <- *New folder for the test project*
    - 1_arrange <- *New folder that will contain test cases*
    - 2_act <- *New folder that will contain dependencies and scripts*
    - 3_assert <- *New folder that will contain test run results*

The step-by-step processes below explain how to set up this environment from scratch.

### Hello World

The following steps show how to download and run the solution with the included Hello World ASA project:

1. Check all the [requirements](https://github.com/Fleid/asa.unittest#Requirements) are installed
1. Import the module from the PowerShell Gallery
   - Open a **Powershell** host (terminal, ISE, VSCode...)
   - Run `Install-Module -Name asa.unittest` to import the module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/asa.unittest)
1. Clone/download the [Examples folder](https://github.com/Fleid/asa.unittest/tree/master/examples) from this repository, save it to a convenient location (`C:\temp\examples` from now on)
1. **Only once** - execute the installer: `New-AutProject`
   - In the **Powershell** host
   - Run `New-AutProject -installPath "C:\temp\examples\ASAHelloWorld.Tests" -verbose` with `installPath` the absolute path to the **test folder**, **not** the ASA project folder
   - ![Screenshot of a terminal run of the installation script](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_install_terminal.png?raw=true)
   - In case of issues see [troubleshooting](https://github.com/Fleid/asa.unittest#Troubleshooting)
1. Execute the test runner: `Start-AutRun`
   - In the **Powershell** host
   - Run `Start-AutRun -solutionPath "C:\temp\examples" -asaProjectName "ASAHelloWorld" -verbose` with `solutionPath` the absolute path to the folder containing both the ASA and the Test projects. `Start-AutRun` offers additional parameters that can be discovered via its help
   - ![Screenshot of a terminal run of the installation script](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_prun_terminal.png?raw=true)
   - Here it is expected that the test ends with 2 errors, in test case *003*. The folder `C:\temp\examples\ASAHelloWorld.Tests\3_assert` will contain the full trace of the run
   - In case of issues see [troubleshooting](https://github.com/Fleid/asa.unittest#Troubleshooting)

### Installation

The following steps show how to download and run the solution on an existing ASA project:

1. Check all requirements are installed
1. Prepare the ASA Project
   - If it doesn't exist, **create a solution folder** (simple top folder, `C:\temp\examples` in the HelloWorld above)
   - Copy or move the existing ASA project to the solution folder
   - In ASA, add local inputs for every source used in the query (see [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) / [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run))
1. **Only once** - Import the module from the PowerShell Gallery
   - Open a **Powershell** host (terminal, ISE, VSCode...)
   - Run `Install-Module -Name asa.unittest` to import the module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/asa.unittest)
   - In case of issues see [troubleshooting](https://github.com/Fleid/asa.unittest#Troubleshooting)
1. **Only once** - execute the installer: `New-AutProject`
   - In the **Powershell** host
   - Run `New-AutProject -installPath "MySolutionPath\MyTestFolder" -verbose` with `installPath` the absolute path to the **test folder**, **not** the ASA project folder. Usually the `MyTestFolder` sub-folder is of the form `MyAsaProject.Tests`

***

## Operations

### Running a test

Once the [installation](https://github.com/Fleid/asa.unittest#Installation) is done:

1. [Configure a test case](https://github.com/Fleid/asa.unittest#Configuring-a-test-case)
1. Execute the test runner: `Start-AutRun`
   - Open a **Powershell** host (terminal, ISE...)
   - Run `Start-AutRun -solutionPath "MySolutionPath" -asaProjectName "MyAsaProject" -verbose` with `solutionPath` the absolute path to the folder containing both the ASA and the Test projects. `Start-AutRun` offers additional parameters that can be discovered via its help
   - In case of issues see **troubleshooting**

For local development, the recommended way of running jobs is via a terminal window.

### Configuring a test case

A test case is made of at least 2 files : a **test input data** file and a **reference output data** file. The test runner will start a local job ingesting the test input data, and compare the output of that job to the reference output data. Mapping inputs and outputs will be done following a file name convention.

**Reminder** : every input source used in the job query to be tested must have a local source configured in the ASA project ([VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run), [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run)).

Once this is done:

1. In `MyTestFolder\1_arrange`, prepare input files:
   - Copy the **test input data** file to be used in the test case for the test case
   - Rename it according to the file name convention : `xxx~input~sourceAlias~testLabel.yyy`
      - `xxx` : for the test case number (grouping multiple inputs and outputs together), for example : 001, 002...
      - `~` : as the separator
      - `input` : flags the file as an input file
      - `sourceAlias` : alias of the source in the query
      - `testLabel` : a label to identify the test (`nominal`, `missingField`, `nullValue`...)
      - `yyy` : any of the supported data format extension (csv, json, avro)
1. In `MyTestFolder\1_arrange`, prepare output files:
   - Copy the **reference output data** file to be used in the test case
   - Rename it according to the file name convention : `xxx~output~sinkAlias~testLabel.json`
      - `xxx` : for the test case number (grouping multiple inputs and outputs together), for example : 001, 002...
      - `~` : as the separator
      - `output` : flags the file as an input file
      - `sinkAlias` : alias of the destination in the query
      - `testLabel` : a label to identify the test (`nominal`, `missingField`, `nullValue`...)
      - `json` : **the data must be in JSON format as it's the only format currently supported for local output** (the ASA engine doesn't honor the output format for local runs)

Note that [live extracts](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run#prepare-sample-data) are a good way to generate test input data. For reference output data, the best is to leverage the output files in the **LocalRunOutputs** folder, located in the ASA project after a successful local run. Note that these files may be generated in a **line separated** format which is not supported by the test runner. They will need to be corrected as follow:

Unsupported format:

```JSON
{"EventId":"3","EventMessage":"Hello"}
{"EventId":"4","EventMessage":"Friends"}
```

Supported format (brackets **and** commas):

```JSON
[
{"EventId":"3","EventMessage":"Hello"},
{"EventId":"4","EventMessage":"Friends"}
]
```

The solution comes with a couple of [pre-configured test cases](https://github.com/Fleid/asa.unittest/tree/master/unittest/1_arrange) to illustrate the format and naming convention.

### Build automation in Azure DevOps

Use a [PowerShell task](https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/powershell?view=azure-devops) to run the installation script first, and the test runner script second.

Note that both scripts use default values for most parameters. These default values are wired to the [build variables](https://docs.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml#build-variables) provided by Azure DevOps. As such, they can be left unassigned in the task.

The parameters are:

- For the **installation script** (`New-AutProject`)
  - `$installPath`, the folder containing the test fixture
- For the **test runner** (`Start-AutRun`)
  - `$asaProjectName`
  - `$unittestFolder` is defaulted to `$asaProjectName.Tests`
  - `$solutionPath` is defaulted to `$ENV:BUILD_SOURCESDIRECTORY`

### Troubleshooting

The main causes of error are:

#### PowerShell

PowerShell [execution policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7). PowerShell comes with that mechanism which is supposed to make a user deeply aware of the fact they're running a script they haven't written. For users with administrative rights, it's an easy to solve issue via **an admin session** and the command `Set-ExecutionPolicy -ExecutionPolicy Unrestricted` ([doc](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7)). For non admins, the easiest is to create new powershell scripts (text files with the `.ps1` extension) and copy/paste the content of each script (install, Start-AutRun). Note that the VSCode Integrated PowerShell environment has [an issue with execution policies](https://github.com/PowerShell/vscode-powershell/issues/1217) and should be avoided (use terminal instead)

PowerShell [remoting for jobs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_jobs?view=powershell-7). Depending on the version of PowerShell (older), it may require remoting to be enabled to start background jobs. Background jobs are used by the test runner to start runs in parallel. This should not be necessary, but [the command to enable remoting](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting?view=powershell-7) is `Enable-PSRemoting`

#### Test Fixture

- Both the ASA project folder and the unittest folder need to be in the same solution folder
- The ASA project folder, ASA script file (`.asaql`) and the XML asaproj file (`.asaproj`) needs to have the same name
- Bad format for JSON data files: test input JSON files and **all** reference output file need to be array of records (`[{...},{...}]`) - see [Configuring a test case](https://github.com/Fleid/asa.unittest#Configuring-a-test-case)

***

## Internal details

### Change Log

- March 2020 :
  - Full refactoring to allow publication in the PowerShell Gallery
  - Complete unit test coverage (Pester) and linting
- February 2020 :
  - Automated the generation of the XML asaproj file (required by sa.exe) from the JSON one (for VSCode project)
  - Renamed scripts to follow PowerShell standards, with backward compatibility

### Components

This solution uses the following components:

- the [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) nuget package, which provides `sa.exe`, a Windows-only executable that allows to run an ASA job [via command line](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-tools-for-visual-studio-cicd)
  - the [nuget CLI](https://docs.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference), to download and install the package above
- the **jsondiffpatch** npm package ([GitHub]((https://github.com/benjamine/JsonDiffPatch) ), [npm](https://www.npmjs.com/package/jsondiffpatch)) which allows to compare json files
  - the [npm CLI](https://docs.npmjs.com/cli-documentation/) to install the package above, available with [Node.JS](https://nodejs.org/en/download/)
- [PowerShell](https://github.com/PowerShell/PowerShell/releases) as the shell to run intermediary tasks and execute the required commands

### Shortcomings

- Slow execution
- No integration to the usual IDEs
- No cross-platform options

### Thanks

- [Kevin Marquette](https://twitter.com/KevinMarquette) for his [invaluable](https://powershellexplained.com/2017-01-21-powershell-module-continious-delivery-pipeline/) blog on PowerShell
- [jsondiffpatch](https://github.com/benjamine/JsonDiffPatch) : Diff & patch JavaScript objects
- [Tabler icons](https://github.com/tabler/tabler-icons) : A set of over 400 free MIT-licensed high-quality SVG icons for you to use in your web projects
