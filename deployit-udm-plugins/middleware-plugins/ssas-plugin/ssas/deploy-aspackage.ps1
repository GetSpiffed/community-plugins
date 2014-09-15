#Determine server name (if deployed is empty use container)
$ServerInstance = $deployed.serverName
if(!$ServerInstance){
    $ServerInstance = $deployed.container.serverName
}

try {
	$artifactPath =  $deployed.file
	Set-Location -Path $artifactPath
	
	$DeployableArtifact = $artifactPath +"\" +$deployed.deployableArtifact
	
	Write-Host $("artifactPath: " + $artifactPath)
	Write-Host $("DeployableArtifact: " + $DeployableArtifact)
	
	# Load asdatabase file into an xml document
	[xml]$ASDatabase = LoadAsDatabase -InputFileLocation $DeployableArtifact

	# Get databaseID from ASDatabase
	$DatabaseID = ""
	$DatabaseID = GetDatabaseID -Xml $ASDatabase

	# Get databaseID from ASDatabase
	$DatabaseName = ""
	$DatabaseName = GetDatabaseName -Xml $ASDatabase
	
	# Create xmla file and return the location
	$XmlaFile = [System.IO.Path]::ChangeExtension($DeployableArtifact,"xmla")
	GenerateCreateXmla -SourceDb $DeployableArtifact -OutputFileLocation $XmlaFile

	# Deploy XMLA file
	ExecuteXmla -inputScript $XmlaFile -Server $deployed.serverName
}
catch {
    Write-Error "$_ `n $("Failed to install ASdatabase {0} to ServerInstance {1}" -f $deployed.file,$deployed.serverName)"
}