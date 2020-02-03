# Unit testing an Azure Stream Analytics project

This document describes a workaround solution to implement unit testing for an [Azure Stream Analytics](https://docs.microsoft.com/en-us/azure/stream-analytics/) (ASA) project.

## Description

As of writing, there is no available option to run unit tests from the major IDEs supporting ASA: VSCode and Visual Studio.

This solution is an attempt at offering the basic features required for unit testing:

- fully local, repeatable executions over multiple test cases
- automated evaluation of the resulting outputs against the expected ones

For that it leverages the **local testing with sample data** capabilities of either [VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) or [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run), in addition to [Microsoft.Azure.StreamAnalytics.CICD](https://www.nuget.org/packages/Microsoft.Azure.StreamAnalytics.CICD/) and [jsondiffpatch](https://github.com/benjamine/JsonDiffPatch), via a PowerShell script and predefined folder structure and file naming convention:

![figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)

*[figure 1 - High level overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overview.png?raw=true)*

Please note that this solution is currently available **only on Windows** since it depends on *Microsoft.Azure.StreamAnalytics.CICD*.

## Quick start

### Hello World

The following steps show how to download and run the solution with a Hello World ASA project:

1. Install [Node.JS](https://nodejs.org/en/download/) to get the npm CLI, and a recent version (6+) of [PowerShell](https://github.com/PowerShell/PowerShell/releases) (*assets* tab under a specific release)
1. Download the sample package (it includes a basic ASA project with a couple of pre-configured tests)
1. **Only once** - execute the installer in the *unittest\2_act* folder: `unittest_install.ps1` (mind the argument/parameter for target folder)
1. Execute the test runner in the *unittest\2_act* folder: `unittest_run.ps1`  (mind the arguments/parameters for project/output folder)

### Quick installation

The following steps show how to download and run the solution on an existing ASA project:

1. Install [Node.JS](https://nodejs.org/en/download/) to get the npm CLI, and a recent version (6+) of [PowerShell](https://github.com/PowerShell/PowerShell/releases) (*assets* tab under a specific release)
1. Download the main package (it includes the test folder structure and scripts)
1. If it doesn't exist, create a solution folder (simple top folder) for the ASA project
1. Move both the ASA project and the unittest folder in that new solution folder
1. If using VSCode (and not Visual Studio), add an `.asaproj` file as explained below
1. Add local inputs for every source used in the query ([VSCode](https://docs.microsoft.com/en-us/azure/stream-analytics/visual-studio-code-local-run) / [Visual Studio](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-vs-tools-local-run))
1. Configure a test case as explained below
1. **Only once** - execute the installer in the *unittest\2_act folder*: `unittest_install.ps1` (mind the argument/parameter for target folder)
1. Execute the test runner in the *unittest\2_act folder* folder: `unittest_run.ps1`  (mind the arguments/parameters for project/output folder)

### Configuring the asaproj file

This step is only required for VSCode project, as Visual Studio manages that file automatically.

...

### Configuring a test case

...

1. In the ASA Project : configure local input(s) for every input source to be tested
2. In `1_arrange` : create a local input file (using live extract if necessary) for the test case, FILE NAME CONVENTION
3. In `1_arrange` : create the expected output file (using a local run on sample data of necessary) for the test case, FILE NAME CONVENTION

## High level picture

As detailed in the following section, the solution uses the required components via a PowerShell script, and expects a certain folder structure and file naming convention to do so successfully:

![figure 2 - Detailed overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overviewFull.png?raw=true)

*[figure 2 - Detailed overview](https://github.com/Fleid/fleid.github.io/blob/master/_posts/202001_asa_unittest/ut_overviewFull.png?raw=true)*

### Requirements

As detailed below, this solution leverages PowerShell, a nuget package and a npm package to enable unit testing:

- For **PowerShell**, any [recent version](https://github.com/PowerShell/PowerShell/releases) should do (*assets* tab under a specific release)
- The **npm CLI** must also be installed manually (available with [Node.JS](https://nodejs.org/en/download/))
- The nuget CLI will be downloaded via the provided installation script

The reason for that is that the installation script is provided to be run in Azure DevOps Build pipelines, whose agents have PowerShell and npm pre-installed, but not the nuget CLI.

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
