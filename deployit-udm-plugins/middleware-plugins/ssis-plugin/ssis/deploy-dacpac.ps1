#first check Powershell compatibility
if($PSVersionTable.PSVersion.major -lt 3) {
    Write-Error "This script requires Powershell version 3 or higher to run"
    Exit
}

#Variables
$fullDacPacPath = $deployed.file
$SqlServer      = $deployed.serverName
$TargetDatabase = $deployed.targetDatabase

<#
$assemblylist = 
"Microsoft.SqlServer.Dac",
"Microsoft.SqlServer.Dac.DacServices",
"Microsoft.SqlServer.Management.Dac",
"Microsoft.SqlServer.Management.DacEnum"

foreach ($asm in $assemblylist)
{
    $asm = [System.Reflection.Assembly]::LoadWithPartialName($asm)
}
#>

add-type -path $deployed.dacDllPath
 
Write-Host "Deploying the DB with the following settings" 
Write-Host "SQL Server:   $SqlServer" 
Write-Host "Dacpac: $fullDacPacPath" 
Write-Host "Target Database: $TargetDatabase"

$connectionString = "server=$SqlServer;Trusted_Connection=True;"
if($deployed.userName -and $deployed.password){
    Write-Host "Using provided credentials for user $($deployed.userName)."
    $connectionString = "server=$SqlServer;User Id=$($deployed.userName);Password=$($deployed.password)"
}

$d = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

# register events, if you want 'em 
register-objectevent -in $d -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

# Load dacpac from file & deploy to database named pubsnew
$dp = [Microsoft.SqlServer.Dac.DacPackage]::Load($fullDacPacPath)
$DeployOptions = new-object Microsoft.SqlServer.Dac.DacDeployOptions
$DeployOptions.IncludeCompositeObjects   = $deployed.includeCompositeObjects
$DeployOptions.IgnoreFileSize            = $deployed.ignoreFileSize
$DeployOptions.IgnoreFilegroupPlacement  = $deployed.ignoreFilegroupPlacement
$DeployOptions.IgnoreFileAndLogFilePath  = $deployed.ignoreFileAndLogFilePath
$DeployOptions.AllowIncompatiblePlatform = $deployed.allowIncompatiblePlatform

$d.Deploy($dp, $TargetDatabase,$true,$DeployOptions) 

# clean up event 
unregister-event -source "msg" 