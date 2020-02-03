# Unit testing Azure Stream Analytics

Unit testing for [Azure Stream Analytics](https://docs.microsoft.com/en-us/azure/stream-analytics/) (ASA), the complex event processing (stateful) service running in Azure.

## Description

At the time of writing, there is no available option to run unit tests from the major IDEs supporting ASA: [VSCode](https://code.visualstudio.com/) and [Visual Studio](https://visualstudio.microsoft.com/vs/).

So this solution was developed to offer the basic features required for unit testing:

- fully local, repeatable executions over multiple test cases
- automated evaluation of the resulting outputs against the expected ones

For that it leverages the **local testing with sample data** capabilities of either [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) or [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run), as unit testing should not rely on external services (no live input).

Local runs are scripted thanks to the `sa.exe` tool from the [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) package.

The results are then evaluated against reference data sets thanks to [jsondiffpatch](https://github.com/benjamine/JsonDiffPatch).

The whole thing is wired together in a **PowerShell** script based on a predefined test fixture (folder structure + naming convention):

![figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)

*[figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)*

This repository provides an **installation script**, in addition to the test script, to automate most of the setup. This installation script also allows automated executions in a continuous build pipeline such as **Azure DevOps Pipelines**.

Please note that this solution is currently available **only on Windows** since it depends on *Microsoft.Azure.StreamAnalytics.CICD*.

## Requirements

This solution leverages PowerShell, a nuget package and a npm package to enable unit testing:

- For **PowerShell**, any [recent version](https://github.com/PowerShell/PowerShell/releases) should do (*assets* tab under a specific release)
- The **npm CLI** must also be installed manually (available with [Node.JS](https://nodejs.org/en/download/))
- The nuget CLI will be downloaded via the provided installation script, but it requires the [.NET Framework 4.7.2 or above](https://dotnet.microsoft.com/download/dotnet-framework) to run.

From there, the installation script will take care of the other dependencies (including the nuget CLI).

To be noted that those requirements are installed by default on every Azure DevOps Pipelines agents.

## Getting started

### Hello World

The following steps show how to download and run the solution with a Hello World ASA project:

1. Check all requirements are installed
1. Clone/download this repository (as it includes a basic ASA project `ASAHelloWorld` and a couple of pre-configured tests in *unittest\1_arrange* )
1. **Only once** - execute the installer in the *unittest\2_act* folder: `unittest_install.ps1`
   - Open a Powershell host (terminal, ISE...)
   - Navigate to `asa.unittest\unittest\2_act`
   - Run `.\unittest_install.ps1 -solutionPath "C:\Users\florian\Repos\asa.unittest" -verbose` with the right `-solutionPath` (absolute paths)
   - ![Screenshot of a terminal run of the installation script](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_install_terminal.png?raw=true)
   - In case of issues see **troubleshooting**
1. Execute the test runner in the *unittest\2_act* folder: `unittest_prun.ps1`
   - Open a Powershell host (terminal, ISE...)
   - Navigate to `asa.unittest\unittest\2_act`
   - Run `.\unittest_prun.ps1 -asaProjectName "ASAHelloWorld" -solutionPath "C:\Users\florian\Repos\asa.unittest" -assertPath "C:\Users\florian\Repos\asa.unittest\unittest\3_assert"-verbose` with the right `-solutionPath` and `-assertPath` (absolute paths)
   - ![Screenshot of a terminal run of the installation script](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_prun_terminal.png?raw=true)
   - Here it is expected that the test ends with 2 errors, in test case *003*
   - In case of issues see **troubleshooting**

### Installation

The following steps show how to download and run the solution on an existing ASA project:

1. Check all requirements are installed
1. If it doesn't exist, **create a solution folder** (simple top folder)
1. Prepare the ASA Project
   - Copy or move the existing ASA project to the solution folder
   - If the project was developed with VSCode (not necessary for Visual Studio), add an `.asaproj` file to the ASA project as explained below
   - In ASA, add local inputs for every source used in the query (see [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) / [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run))
1. Clone/download this repository, copy or move the *unittest* folder to the solution folder
1. **Only once** - execute the installer in the *unittest\2_act* folder: `unittest_install.ps1`
   - Open a Powershell host (terminal, ISE...)
   - Navigate to `unittest\2_act` in the solution folder
   - Run `.\unittest_install.ps1 -solutionPath "C:\<SOLUTIONFOLDERPATH>" -verbose` with the right `-solutionPath` (absolute paths)
   - In case of issues see **troubleshooting**
1. Configure a test case as explained below
1. Execute the test runner in the *unittest\2_act* folder: `unittest_prun.ps1`
   - Open a Powershell host (terminal, ISE...)
   - Navigate to `unittest\2_act` in the solution folder
   - Run `.\unittest_prun.ps1 -asaProjectName "<ASAPROJECTNAME>" -solutionPath "C:\<SOLUTIONFOLDERPATH>" -assertPath "C:\<SOLUTIONFOLDERPATH>\unittest\3_assert"-verbose` with the right `-solutionPath` and `-assertPath` (absolute paths)
   - In case of issues see **troubleshooting**

### Configuring the asaproj file

This step is only required for ASA project created with **VSCode**.

An ASA project created with VSCode has an **asaproj** JSON file in the form of `asaproj.json`. The tool allowing command line executions (`sa.exe`) currently expects an XML version as generated by Visual Studio. It is required to manually create that file before for the test runner to call `sa.exe` successfully.

To do so, create a new file **in the ASA project folder** named `<ASAPROJECTNAME>.asaproj` after the ASA project name (same name as the `.asaql`) with the following content, replacing:

- `ASAHelloWorld.asaql` by `<ASAPROJECTNAME>.asaql` after the ASA project name
- For every local inputs, an item group of subtype `InputMock` with the proper relative path `Inputs\Local_MYINPUT01.json` pointing to the local configuration file (not data file). If those doesn't already exist in the ASA project, create them by [adding local source](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) for existing inputs
- **No other items are required** (no outputs, no functions...), only local inputs, other that the JobConfig as illustrated below

```XML
<Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">

  <ItemGroup>
    <Script Include="ASAHelloWorld.asaql" />
  </ItemGroup>

  <ItemGroup>

    <Configure Include="Inputs\Local_MYINPUT01.json">
      <SubType>InputMock</SubType>
    </Configure>

    <Configure Include="Inputs\Local_MYINPUT02.json">
      <SubType>InputMock</SubType>
    </Configure>

    <Configure Include="JobConfig.json">
      <SubType>JobConfig</SubType>
    </Configure>

  </ItemGroup>
  
</Project>
```

Most errors in the test runner come from a faulty XML asaproj file, it is important to make sure it's wired properly.

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

## High level picture

As detailed in the following section, the solution uses the required components via a PowerShell script, and expects a certain folder structure and file naming convention to do so successfully:

![figure 2 - Detailed overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overviewFull.png?raw=true)

*[figure 2 - Detailed overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overviewFull.png?raw=true)*

### Scenario and components

This solution uses the following components:

- the [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) nuget package, which provides `sa.exe`, a Windows-only executable that allows to run an ASA job [via command line](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-tools-for-visual-studio-cicd)
  - the [nuget CLI](https://docs.microsoft.com/en-us/nuget/reference/nuget-exe-cli-reference), to download and install the package above
- the **jsondiffpatch** npm package ([GitHub]((https://github.com/benjamine/JsonDiffPatch) ), [npm](https://www.npmjs.com/package/jsondiffpatch)) which allows to compare json files
  - the [npm CLI](https://docs.npmjs.com/cli-documentation/) to install the package above, available with [Node.JS](https://nodejs.org/en/download/)
- [PowerShell](https://github.com/PowerShell/PowerShell/releases) as the shell to run intermediary tasks and execute the required commands

These components are used in a script as follow:

![figure 1 - Schema of the unit testing setup - it is detailed below](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_solution.png?raw=true)

[figure 1 - Schema of the unit testing setup]()

The script will expect the following folder structure to run properly:

- **mySolutionFolder** <- *Potentially new top solution folder*
  - **ASATest1** <- *Existing ASA project folder, containing the `.asaql` file and inputs folder*
  - **unittest** <- *New folder for the test project*
    - 1_arrange <- *New folder that will contain test cases*
    - 2_act <- *New folder that will contain dependencies and scripts*
    - 3_assert <- *New folder that will contain test run results*

### unittest\1_arrange

The folder `1_arrange` will contain test cases described by at least 2 files each: one **Input** and one **Output**. Both files contain data:

- Input files will contain the data to be used as local input during the test
- Output files will contain the data expected to be found as the result of the run

For input files, the main test script will update the **local** configuration file of that data source in the ASA project (and reverse that change to the starting value at the end).

The following naming convention must be used:

- `xxx~direction~dataSource~testLabel.extension` with:
  - `xxx` : Test case number, used to match multiple files in a single test case
  - `direction` : Input or Output. Input will make the script replaces the **local** input configuration file for   the data source below in the ASA project
  - `dataSource` : The name of the data source that will have its **local** configuration altered to point toward   this file
  - `testLabel` : Label of the test
  - `extension` : JSON, CSV...

### unittest\2_act

The folder `2_act` will contain the solution dependencies (`nuget and npm packages`, PowerShell install script) and the main PowerShell script: `unittest_run.ps1`.

### unittest\3_assert

The folder `3_assert` will be **automatically** filled with test results at runtime.

Each execution will add a new folder named after the timestamp of the run, inside of which each test case will generate a new sub-folder:

- 3_assert
  - 20200106122200
    - 001
    - 002
    - 003
  - 20200106122551
    - 001
    - 002
    - 003

## Local setup

## Build automation in Azure DevOps

## Shortcomings

- Slow execution
- No integration to the usual IDEs
- No cross-platform options
