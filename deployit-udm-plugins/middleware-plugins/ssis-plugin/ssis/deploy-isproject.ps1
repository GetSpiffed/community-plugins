#Variables
#Determine server name (if deployed is empty use container)
$RPTServerName = $deployed.serverName
if(!$RPTServerName){
    $RPTServerName = $deployed.container.serverName
}
$ProjectFilePath = $deployed.file
$ProjectName     = $deployed.projectName
$FolderName      = $deployed.folderName
$CatalogName     = $deployed.catalogName
$CatalogPW       = $deployed.catalogPassword

# Load the required assemblies
$assemblylist = 
"Microsoft.SqlServer.Management.IntegrationServices",
"Microsoft.SqlServer.Smo",
"Microsoft.SqlServer.SMOEnum"

foreach ($asm in $assemblylist)
{
    $asm = [System.Reflection.Assembly]::LoadWithPartialName($asm) | Out-Null
}
 
# Store the IntegrationServices Assembly namespace to avoid typing it every time
$ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
 
Write-Host "Connecting to server ..."
 
# Create a connection to the server
$sqlConnectionString = "Data Source=$RPTServerName;Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
 
# Create the Integration Services object
$integrationServices = New-Object $ISNamespace".IntegrationServices" $sqlConnection
$catalog = $integrationServices.Catalogs[$CatalogName]

# Drop the existing catalog if not shared            
 if (($catalog -and !$deployed.catalogShared) -or !$catalog)             
 {             
	if($catalog -and !$deployed.catalogShared)
	{
		Write-Host "Removing previous catalog ..."            
		$catalog.Drop() 
	}
	
	# Provision a new SSIS Catalog            
	Write-Host "Creating new SSISDB Catalog ..."            
	$catalog = New-Object $ISNamespace".Catalog" ($integrationServices, $CatalogName, $CatalogPW)            
	$catalog.Create() 				
}  

$folder = $catalog.Folders[$FolderName]
if ($folder) {
	Write-Host "SSIS folder $FolderName already exists"
}
else {
	Write-Host "Creating folder $FolderName ..."
	$folder = New-Object $ISNamespace".CatalogFolder" ($catalog, $FolderName, "Folder description")
	$folder.Create()
}

if($folder.Projects[$ProjectName]){
	Write-Host "Dropping existing project [$ProjectName]"
	$folder.Projects[$ProjectName].Drop()
}

Write-Host "Deploying [$ProjectName] project ..."
# Read the project file, and deploy it to the folder
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)
$folder.DeployProject($ProjectName, $projectFile)

$project = $folder.Projects[$ProjectName]

# Add Environments.
foreach ($environment in $deployed.environments) {
	$EnvironmentName = $environment.environmentName
	#Drop an environment if already exists
	if ($folder.Environments[$EnvironmentName]) { 
		Write-Host "Dropping existing environment [$EnvironmentName]"
		$folder.Environments[$EnvironmentName].Drop() 
	}

	Write-Host "Creating environment [$EnvironmentName]"
	$projectEnvironment = New-Object $ISNamespace".EnvironmentInfo" ($folder, "$EnvironmentName", "$($environment.environmentDescription)")
	$projectEnvironment.Create()

	foreach ($envvar in $environment.variables) {
		Write-Host "Adding environment variable $($envvar.variableName)"
		# Adding variable to our environment
		# Constructor args: variable name, type, default value, sensitivity, description
		$projectEnvironment.Variables.Add($envvar.variableName, $envvar.variableType, $envvar.defaultValue, $envvar.sensitivity, $envvar.description) 
	    if($envvar.includeProjectParameterReference){ 
	    	Write-Host "Including project parameter reference to $($envvar.variableName)"
	    	$project.Parameters[$envvar.variableName].Set([Microsoft.SqlServer.Management.IntegrationServices.ParameterInfo+ParameterValueType]::Referenced, $envvar.variableName) 
	    }          
	}           
	$projectEnvironment.Alter()            

	Write-Host "Adding environment reference to project ..."
	# making project refer to this environment
	$project.References.Add($EnvironmentName)
	$project.Alter()
}

if($deployed.jobs.Count -gt 0){
	Write-Host "Creating jobs for project"
	$svr = new-object ('Microsoft.SqlServer.Management.Smo.Server') $RPTServerName
	foreach ($job in $deployed.jobs) {
		if($svr.JobServer.Jobs[$job.jobName]){
			$svr.JobServer.Jobs[$job.jobName].Drop()
		}
		$j = new-object ('Microsoft.SqlServer.Management.Smo.Agent.Job') ($svr.JobServer, $job.jobName)
		$j.Name = $job.jobName
		$j.Description = $job.jobDescription
		$j.IsEnabled = $job.jobEnabled
		$j.EventLogLevel = $job.eventLogLevel
		$j.EmailLevel = $job.emailLevel
		$j.NetSendLevel = $job.netSendLevel
		$j.PageLevel = $job.pageLevel
		$j.DeleteLevel = $job.deleteLevel
		$j.OwnerLoginName = $job.ownerLoginName
		if($job.jobCategory){
			if($svr.JobServer.JobCategories[$job.jobCategory]){
				$svr.JobServer.JobCategories[$job.jobCategory].Drop()
			}
			Write-Host "Creating category $($job.jobCategory)"
			$jc = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobCategory') ($svr.JobServer, $job.jobCategory)
			$jc.Create()
			$j.Category = $job.jobCategory
		}
		$j.Create()

		foreach ($jobStep in $job.jobSteps) {
			$js = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobStep') ($j, $jobStep.stepName)
			$js.Name = $jobStep.stepName
			$js.ID = $jobStep.stepID
			$js.SubSystem = $jobStep.subSystem
			$js.Command = $jobStep.command
			$js.CommandExecutionSuccessCode = $jobStep.commandExecutionSuccessCode
			$js.DatabaseName = $jobStep.databaseName
			$js.JobStepFlags = $jobStep.jobStepFlags
			$js.ProxyName = $jobStep.proxyName
			$js.OnSuccessAction = $jobStep.onSuccessAction
			$js.OnSuccessStep = $jobStep.onSuccessStepID
			$js.OnFailAction = $jobStep.onFailAction
			$js.OnFailStep = $jobStep.onFailStepID
			$js.RetryAttempts = $jobStep.retryAttempts
			$js.RetryInterval = $jobStep.retryInterval
			$js.OSRunPriority = $jobStep.osRunPriority
			$js.Create()
		}

		$j.ApplyToTargetServer("(local)")
		$j.StartStepID = $job.startStepID
		$j.Alter()

		foreach ($jobSchedule in $job.jobSchedules) {
			$jsch = new-object ('Microsoft.SqlServer.Management.Smo.Agent.JobSchedule') ($j, $jobSchedule.scheduleName)
			#$jsch.Parent = $j
			if($jobSchedule.jobScheduleName){
				$jsch.Name = $jobSchedule.jobScheduleName
			}
			else {
				$jsch.Name = $j.Name
			}
			$jsch.FrequencyTypes = $jobSchedule.frequencyTypes
			if($jobSchedule.activeStartDate){
				$jsch.ActiveStartDate = $a=[datetime]::ParseExact($jobSchedule.activeStartDate, "dd/MM/yyyy HH:mm:ss", $null)
			}
			else {
				$jsch.ActiveStartDate = get-date
			}
			$jsch.Create()
		}
	}
}

Write-Host "Project deployment completed successfully."
Exit 0