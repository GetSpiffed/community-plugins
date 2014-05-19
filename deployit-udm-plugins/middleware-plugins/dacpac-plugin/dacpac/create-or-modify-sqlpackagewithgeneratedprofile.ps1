Function WriteXmlToScreen($xml)
{
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xml.WriteTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 
}

Function Prepare-Template($profileFile){
    Write-Host "Received path: $profileFile and object: $deployed"
    # Generate profile xml file for deployment
    $template = 
@"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <IncludeCompositeObjects>True</IncludeCompositeObjects>
    <TargetDatabaseName>TBD</TargetDatabaseName>
    <DeployScriptFileName>TBD.sql</DeployScriptFileName>
    <TargetConnectionString>TBD</TargetConnectionString>
    <ProfileVersionNumber>1</ProfileVersionNumber>
  </PropertyGroup>
  <ItemGroup>
    <SqlCmdVariable Include="XLDeployPocVariable">
      <Value>Anything you like!</Value>
    </SqlCmdVariable>
  </ItemGroup>
</Project>
"@
    Write-Host "Export template to $profileFile"
    
    # Load template into XML object
    [xml]$xml = $template

    # Grab Variable to reuse a template
    $variableTemplate = (@($xml.Project.ItemGroup.SqlCmdVariable)[0]).Clone()
    $itemGroup = $xml.Project.ItemGroup

    # Remove variables from template
    $xml.Project.ItemGroup.SqlCmdVariable | ForEach-Object  { 
        [void]$itemGroup.RemoveChild($_) 
    }
    
    $xml.Project.PropertyGroup.IncludeCompositeObjects = [string]$deployed.includeCompositeObjects
    $xml.Project.PropertyGroup.TargetDatabaseName      = $deployed.targetDatabaseName
    $xml.Project.PropertyGroup.DeployScriptFileName    = $deployed.deployScriptFileName
    $xml.Project.PropertyGroup.TargetConnectionString  = $deployed.targetConnectionString
    $xml.Project.PropertyGroup.ProfileVersionNumber    = $deployed.profileVersionNumber

    foreach ($variable in $deployed.variables) {
        Write-Host "Adding variable: $($variable.variableName)"
        $newVariable = $variableTemplate.Clone()
        $newVariable.Include = $variable.variableName
        $newVariable.Value = $variable.variableValue
        WriteXmlToScreen($newVariable)
        $itemGroup.AppendChild($newVariable)
    }

    $xml.Save($profileFile)
    WriteXmlToScreen($xml)
}
$profileFile = "$home\template.xml"

Prepare-Template($profileFile)

Write-Host "& $deployed.sqlPackagePath /Profile:$profileFile /SourceFile:$($deployed.file) /Action:Publish"

& $($deployed.sqlPackagePath) /Profile:$profileFile /SourceFile:$($deployed.file) /Action:Publish

Remove-Item $profileFile