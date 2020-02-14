$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

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
            }
        ]
    }"
    $sourceAsaprojMock = $sourceAsaprojMockJSON | ConvertFrom-Json

    $outputXMLstring ="<Project ToolsVersion=`"4.0`" DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`">
<ItemGroup>
<Script Include=`"asaproject.asaql`"/>
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
