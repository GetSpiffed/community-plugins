#Determine server name (if deployed is empty use container)
$ServerInstance = $deployed.serverName
if(!$ServerInstance){
    $ServerInstance = $deployed.container.serverName
}
$PackageFullName = $deployed.packageFullName

try {
    # Get Sql Version
    if($deployed.container.type -eq 'overthere.LocalHost'){
        $SqlVersion = Get-SqlVersion -ServerInstance '(local)'
    }
    else{
        $SqlVersion = Get-SqlVersion -ServerInstance $ServerInstance        
    }

	# Set Dtutil Path based on Sql Version
	Set-DtsPaths -SqlVersion $SqlVersion
	
    Write-Host "Removing package [$PackageFullName] on [$ServerInstance]."
    Remove-Package  -ServerInstance $ServerInstance -PackageFullName $PackageFullName
    
    #Verify Package
    if(Test-Packagepath -ServerInstance $ServerInstance -PackageFullName $PackageFullName){
    	Write-Host "Package [$PackageFullName] still exists on [$ServerInstance]."
    	Exit 1
    }
    else{
    	Write-Host "Package [$PackageFullName] no longer found on [$ServerInstance]."
    	Exit 0
    }
}
catch {
    Write-Error "$_ `n $("Failed to remove [$PackageFullName] from [$ServerInstance]")"
}