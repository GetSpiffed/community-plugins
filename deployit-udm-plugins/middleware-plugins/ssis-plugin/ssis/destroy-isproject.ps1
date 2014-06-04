#Variables
#Determine server name (if deployed is empty use container)
$RPTServerName = $deployed.serverName
if(!$RPTServerName){
    $RPTServerName = $deployed.container.serverName
}
$ProjectName 		= $deployed.projectName
$FolderName 		= $deployed.folderName
$CatalogName		= $deployed.catalogName

# Load the IntegrationServices Assembly
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.IntegrationServices") | Out-Null;
 
# Store the IntegrationServices Assembly namespace to avoid typing it every time
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
 
Write-Host "Connecting to server ..."
 
# Create a connection to the server
$sqlConnectionString = "Data Source=$RPTServerName;Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
 
# Create the Integration Services object
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection
$catalog = $integrationServices.Catalogs[$CatalogName]

if(!$deployed.catalogShared){
	Write-Host "Dropping exclusive catalog [$CatalogName]"
	$catalog.Drop()
}
else {
	$folder = $catalog.Folders[$FolderName]
	$project = $folder.Projects[$ProjectName]

	foreach ($environment in $deployed.environments) {
		$EnvironmentName = $environment.environmentName
		Write-Host "Dropping environment [$EnvironmentName]"
	    if($folder.Environments[$EnvironmentName]) { 
	    	$folder.Environments[$EnvironmentName].Drop()
	    }
	}

	Write-Host "Removing project [$ProjectName]"
	if($project) {
		$project.Drop()
	}

	## Drop the folder if it is empty            
	if ($folder.Projects.Count -eq 0 -and $folder.Environments.Count -eq 0)             
	{             
		Write-Host "Removing empty folder ..."            
		$folder.Drop()             
	}  
	if($deployed.jobs.Count -gt 0){
	Write-Host "Removing jobs for project"
	$svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') $RPTServerName
	foreach ($job in $deployed.jobs) {
		if($svr.JobServer.JobCategories[$job.jobCategory]){
			$svr.JobServer.JobCategories[$job.jobCategory].Drop()
		}
		if($svr.JobServer.Jobs[$job.jobName]){
			$svr.JobServer.Jobs[$job.jobName].Drop()
		}
	}
}
          
}
Write-Host "Project removal completed"       