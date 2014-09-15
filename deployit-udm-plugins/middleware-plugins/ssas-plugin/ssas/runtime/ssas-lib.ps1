#####################################################################
# Import SQL AS commandlets
#####################################################################
Import-Module 'C:\Program Files (x86)\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLASCMDLETS'

#####################################################################
function GetSqlVersion
{
    param($ServerInstance)
    
	Write-Host "***Start: GetSqlVersion"  
    Write-Host "Getting SQL Server version for [$ServerInstance]."
    
    #write-verbose "sqlcmd -S `"$ServerInstance`" -d `"master`" -Q `"SET NOCOUNT ON; SELECT SERVERPROPERTY('ProductVersion')`" -h -1 -W"

    $SqlVersion = sqlcmd -S "$ServerInstance" -d "master" -Q "SET NOCOUNT ON; SELECT SERVERPROPERTY('ProductVersion')" -h -1 -W
    return $SqlVersion  
} #Get-SqlVersion

#####################################################################
function LoadAsDatabase
{
	param($InputFileLocation)
	Write-Host "***Start: LoadAsDatabase"  
	Write-Host "InputFileLocation: $($InputFileLocation)"  
	
	[xml]$xml = Get-Content $InputFileLocation;
	
	return $xml
}

#####################################################################
function GetDatabaseID
{
    param($Xml)

	Write-Host "***Start: GetDatabaseID"  
    
    $DatabaseID = $Xml.Database.ID 
	Write-Host "DatabaseID: $($DatabaseID)"  
	
    return $DatabaseID 
} #Get-DatabaseID

#####################################################################
function GetDatabaseName
{
    param($Xml)
	
	Write-Host "***Start: Get-DatabaseName"  
    
    $DatabaseName = $Xml.Database.Name
	Write-Host "DatabaseName: $($DatabaseName)"  
	
    return $DatabaseName 
} #Get-DatabaseName

#####################################################################
function ExecuteXmla
{
	param($inputScript, $Server)
	
	Write-Host "***Start: Execute-Xmla"  
	Write-Host "InputScript: $($inputScript)"  
	Write-Host "Server: $($Server)"  
    
	# Deploy XMLA
	Invoke-ASCmd -InputFile $inputScript -Server $Server -ErrorAction Continue	
	
} #Execute-Xmla


#####################################################################
function GenerateCreateXmla
{
    param($SourceDb, $OutputFileLocation)
	Write-Host "***Start: GenerateCreateXmla"

	Write-Host $("SourceDb = " +$SourceDb)
	Write-Host $("OutputFileLocation = " +$OutputFileLocation)
	
	& $($deployed.ssasDeploymentTool) "$($SourceDb)" /s /o:"$($OutputFileLocation)" | Write-Output
	
	return ,$outputScript
}

#####################################################################
function GenerateDeleteXmla
{
    param($DatabaseID, $OutputFileLocation)

	Write-Host "***Start: GenerateDeleteXmla"  
	Write-Host "DatabaseID: $($DatabaseID)"  
	Write-Host "OutputFileLocation: $($OutputFileLocation)"  
	
    $template = 
@"
<Delete xmlns="http://schemas.microsoft.com/analysisservices/2003/engine">
    <Object>
        <DatabaseID>TBD</DatabaseID>
    </Object>
</Delete>
"@

    # Load template into XML object
    [xml]$xml = $template
	
	#set DatabaseID
    $xml.Delete.Object.DatabaseID = $DatabaseID
	
	$xml.ToString() |out-file -filepath $OutputFileLocation	

	#Write to screen
    WriteXmlToScreen($xml)	
	
	#Write to file
    $xml.Save($OutputFileLocation)
}

#######################
Function WriteXmlToScreen($xml)
{
	Write-Host "***Start: WriteXmlToScreen"
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xml.WriteTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 
}


#####################################################################
function PrintDir
{
    param($Path)
	Write-Host "***Start: PrintDir"

	$items = Get-ChildItem -Path $Path
 
	# enumerate the items array
	foreach ($item in $items)
	{
		  # if the item is NOT a directory, then process it.
		  # if ($item.Attributes -ne "Directory")
		  if ($item.Attributes)
		  {
				Write-Host $item.Name
		  }
	}
	Write-Host "***End: PrintDir"
}