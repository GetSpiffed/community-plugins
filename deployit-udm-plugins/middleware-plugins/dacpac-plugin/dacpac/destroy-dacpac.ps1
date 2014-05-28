#Determine server name (if deployed is empty use container)
$SqlServer = $deployed.serverName
if(!$SqlServer){
    $SqlServer = $deployed.container.serverName
}
$TargetDatabase = $deployed.targetDatabaseName

# Load the required assemblies
$assemblylist = 
"Microsoft.SqlServer.Smo",
"Microsoft.SqlServer.SMOEnum",
"Microsoft.SqlServer.Management.Smo",
"Microsoft.SqlServer.Management.SMOEnum"

foreach ($asm in $assemblylist)
{
    $asm = [System.Reflection.Assembly]::LoadWithPartialName($asm) | Out-Null
}

$srv = new-Object Microsoft.SqlServer.Management.Smo.Server($SqlServer)
if ($srv.Databases[$TargetDatabase] -ne $null)  
 {  
    $srv.KillAllProcesses($TargetDatabase)
    $srv.Databases[$TargetDatabase].drop()  
    Write-Host "Database $TargetDatabase successfully dropped."
} 
 else {
    Write-Host "Nothing to be done. Database $TargetDatabase not found."
 }
