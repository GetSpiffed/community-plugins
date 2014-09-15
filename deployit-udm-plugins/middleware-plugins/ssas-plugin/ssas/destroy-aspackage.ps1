#Determine server name (if deployed is empty use container)
$ServerInstance = $deployed.serverName
if(!$ServerInstance){
    $ServerInstance = $deployed.container.serverName
}

try {
	$artifactPath =  $deployed.file
	Set-Location -Path $artifactPath
	
	$deployableArtifact = $artifactPath +"\" +$deployed.deployableArtifact
	
	Write-Host $("DeployableArtifact: " + $deployableArtifact)
	Write-Host $("ArtifactPath: " + $artifactPath)

	# Load asdatabase file ($deployableArtifact) into an xml document
	[xml]$ASDatabase = LoadAsDatabase -InputFileLocation $deployableArtifact

	# Get databaseID from ASDatabase
	$DatabaseID = GetDatabaseID -Xml $ASDatabase

	# Create Delete xmla file
	$XmlaFile = "$($artifactPath)\$($DatabaseID)_Delete.xmla"
	GenerateDeleteXmla -DatabaseID $DatabaseID -OutputFileLocation $XmlaFile

	# Deploy XMLA file
	ExecuteXmla -inputScript $XmlaFile -Server $deployed.serverName
}
catch {
    Write-Error "$_ `n $("Failed to remove [$DatabaseID] from [$deployed.serverName]")"
}