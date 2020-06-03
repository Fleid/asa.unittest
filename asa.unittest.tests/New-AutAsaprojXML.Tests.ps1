### If tests are in ModuleRoot\Whatever, and scripts reachable via a module at ModuleRoot\Module\Module.psm1

$projectRoot = Resolve-Path "$PSScriptRoot\.." #ModuleRoot\Whatever becomes \ModuleRoot with ..
$moduleRoot = Split-Path (Resolve-Path "$projectRoot\*\*.psd1") #Look for the manifest to get to ModuleRoot\Module
$moduleName = Split-Path $moduleRoot -Leaf #Extract the module name from above
Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force

#############################################################################################################
# Invoke-Pester .\New-AutAsaprojXML.Tests.ps1 -CodeCoverage .\..\asa.unittest\public\New-AutAsaprojXML.ps1


Describe "New-AutAsaprojXML Nominal" {

    $sourceAsaprojMockJSON = "{
        `"name`": `"asaproject`",
        `"startFile`": `"asaproject.asaql`",
        `"configurations`": [
            {
                `"filePath`": `"Inputs\\Local_input.json`",
                `"subType`": `"InputMock`"
            },
            {
                `"filePath`": `"Inputs\\Local_input2.json`",
                `"subType`": `"InputMock`"
            },
            {
                `"filePath`": `"JobConfig.json`",
                `"subType`": `"JobConfig`"
            },
            {
                `"filePath`": `"Functions\\jsFunction1.js.json`",
                `"subType`": `"JSFunction`"
            },
        ]
    }"
    $sourceAsaprojMock = $sourceAsaprojMockJSON | ConvertFrom-Json

    $outputXMLstring ="<Project ToolsVersion=`"4.0`" DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`">
<ItemGroup>
<Script Include=`"asaproject.asaql`"/>
<ScriptCode Include=`"asaproject.asaql.cs`">
  <DependentUpon>asaproject.asaql</DependentUpon>
</ScriptCode>
</ItemGroup>
<ItemGroup>
<Configure Include=`"Inputs\Local_input.json`">
<SubType>InputMock</SubType>
</Configure>
<Configure Include=`"Inputs\Local_input2.json`">
<SubType>InputMock</SubType>
</Configure>
<Configure Include=`"JobConfig.json`">
<SubType>JobConfig</SubType>
</Configure>
<Configure Include=`"Functions\jsFunction1.js.json`">
<SubType>JSFunction</SubType>
</Configure>
</ItemGroup>
</Project>
"
    It "returns a valid XML for on a minimal input" {
        New-AutAsaprojXML -sourceAsaproj $sourceAsaprojMock  |
        Should -be $outputXMLstring
    }

    It "returns a valid XML for on a minimal input via the pipeline" {
        $sourceAsaprojMock | New-AutAsaprojXML |
        Should -be $outputXMLstring
    }

    It "does nothing on -WhatIf" {
        $sourceAsaprojMock | New-AutAsaprojXML -Whatif |
        Should -be $null
    }

}

Describe "New-AutAsaprojXML missing/empty startFile" {

    $sourceAsaprojMockJSON = "{
        `"name`": `"asaproject`",
        `"startFile`": `"`",
        `"configurations`": [
            {
                `"filePath`": `"Inputs\\Local_input.json`",
                `"subType`": `"InputMock`"
            },
            {
                `"filePath`": `"JobConfig.json`",
                `"subType`": `"JobConfig`"
            }
        ]
    }"

    $sourceAsaprojMock = $sourceAsaprojMockJSON | ConvertFrom-Json

    It "fails if startFile(asaql) is missing from input" {
        {New-AutAsaprojXML -sourceAsaproj $sourceAsaprojMock}  |
        Should -throw "Error : startFile (aka .asaql path) is missing or empty from input asaProj file"
    }

    $sourceAsaprojMockJSON = "{
        `"name`": `"asaproject`",
        `"configurations`": [
            {
                `"filePath`": `"Inputs\\Local_input.json`",
                `"subType`": `"InputMock`"
            },
            {
                `"filePath`": `"JobConfig.json`",
                `"subType`": `"JobConfig`"
            }
        ]
    }"

    $sourceAsaprojMock = $sourceAsaprojMockJSON | ConvertFrom-Json

    It "fails if startFile(asaql) is empty in input" {
        {New-AutAsaprojXML -sourceAsaproj $sourceAsaprojMock}  |
        Should -throw "Error : startFile (aka .asaql path) is missing or empty from input asaProj file"
    }
}


Describe "New-AutAsaprojXML missing JobConfig" {

    $sourceAsaprojMockJSON = "{
        `"name`": `"asaproject`",
        `"startFile`": `"asaproject.asaql`",
        `"configurations`": [
            {
                `"filePath`": `"Inputs\\Local_input.json`",
                `"subType`": `"InputMock`"
            }
        ]
    }"

    $sourceAsaprojMock = $sourceAsaprojMockJSON | ConvertFrom-Json

    It "fails if startFile(asaql) is missing from input" {
        {New-AutAsaprojXML -sourceAsaproj $sourceAsaprojMock}  |
        Should -throw "Error : JobConfig path is missing or empty from input asaProj file"
    }

}
