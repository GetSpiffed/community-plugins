#first check Powershell compatibility
if($PSVersionTable.PSVersion.major -lt 3) {
    Write-Error "This script requires Powershell version 3 or higher to run"
    Exit
}

#Variables
#Determine server name (if deployed is empty use container)
$SqlServer = $deployed.serverName
if(!$SqlServer){
    $SqlServer = $deployed.container.serverName
}

Write-Host $("PSScriptRoot: " + $PSScriptRoot)
$currentExecutingPath = $PSScriptRoot

#somehow we get ".1" at the end of the $PSScriptRoot path. We need to replace it to get a valid path
$currentExecutingPath = $currentExecutingPath.Replace(".1", "")

Write-Host $("fullDacPacPath: " +$currentExecutingPath +"\" + $deployed.deployableLocation)
$fullDacPacPath = $($currentExecutingPath +"\" + $deployed.deployableLocation)

$TargetDatabase = $deployed.targetDatabaseName

$assemblylist = 
"Microsoft.SqlServer.Smo",
"Microsoft.SqlServer.SMOEnum",
"Microsoft.SqlServer.Management.Smo",
"Microsoft.SqlServer.Management.SMOEnum"

foreach ($asm in $assemblylist)
{
    $asm = [System.Reflection.Assembly]::LoadWithPartialName($asm)
}

add-type -path $deployed.dacDllPath
 
Write-Host "Deploying the DB with the following settings" 
Write-Host "SQL Server: $SqlServer" 
Write-Host "Target Database: $TargetDatabase"

$connectionString = "server=$SqlServer;Trusted_Connection=True;"
if($deployed.userName -and $deployed.password){
    Write-Host "Using provided credentials for user $($deployed.userName)."
    $connectionString = "server=$SqlServer;User Id=$($deployed.userName);Password=$($deployed.password)"
}

$d = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

# register events, if you want 'em 
register-objectevent -in $d -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

$ErrorActionPreference = "Continue" #To force script to run to completion

# Load dacpac from file & deploy to database named pubsnew
$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load($fullDacPacPath)
$DeployOptions = new-object Microsoft.SqlServer.Dac.DacDeployOptions
$DeployOptions.IncludeCompositeObjects     = $deployed.includeCompositeObjects
$DeployOptions.IgnoreFileSize              = $deployed.ignoreFileSize
$DeployOptions.IgnoreFilegroupPlacement    = $deployed.ignoreFilegroupPlacement
$DeployOptions.IgnoreFileAndLogFilePath    = $deployed.ignoreFileAndLogFilePath
$DeployOptions.AllowIncompatiblePlatform   = $deployed.allowIncompatiblePlatform
$DeployOptions.RegisterDataTierApplication = $deployed.registerDataTierApplication
$DeployOptions.BlockWhenDriftDetected      = $deployed.blockWhenDriftDetected
$DeployOptions.BlockOnPossibleDataLoss     = $deployed.BlockOnPossibleDataLoss
$DeployOptions.GenerateSmartDefaults       = $deployed.GenerateSmartDefaults 

foreach ($variable in $deployed.variables) {
	Write-Host "Adding variable: $($variable.variableName)|$($variable.variablevalue)"
	$DeployOptions.SqlCommandVariableValues.Add($($variable.variableName), $($variable.variablevalue))
}

$d.Deploy($dp, $TargetDatabase, $true, $DeployOptions) 

# clean up event 
unregister-event -source "msg" 

$srv = new-Object Microsoft.SqlServer.Management.Smo.Server($SqlServer)
if ($srv.Databases[$TargetDatabase] -ne $null){
    Write-Host "Database $targetDatabase successfully created."
    Exit 0
}
else{
    Write-Error "Database $targetDatabase was not created."
    Exit 1
}