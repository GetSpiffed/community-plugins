$DtsxFullName = $deployed.file
$ServerInstance = $deployed.serverInstance
$PackageFullName = $deployed.packageFullName

try {
	# Get Sql Version
	$SqlVersion = Get-SqlVersion -ServerInstance $ServerInstance

	# Set Dtutil Path based on Sql Version
	Set-DtutilPath -SqlVersion $SqlVersion
	
	##Check for existing package
	if (test-packagepath $PackageFullName) {
		Write-Host "Removing old package [$PackageFullName] from [$ServerInstance]."
		remove-package -ServerInstance $ServerInstance -PackageFullName $PackageFullName
	}

	Write-Host "Deploying package [$PackageFullName] to [$ServerInstance]."

	#Create path if needed
	Get-FolderList -PackageFullName $PackageFullName |
	where { $(test-path -ServerInstance $ServerInstance -FolderPath $_.FullPath) -eq $false } |
	foreach { new-folder -ServerInstance $ServerInstance -ParentFolderPath $_.Parent -NewFolderName $_.Child }

	#Install SSIS Package
	install-package -DtsxFullName $DtsxFullName -ServerInstance $ServerInstance -PackageFullName $PackageFullName

	#Verify Package
	if(test-packagepath -ServerInstance $ServerInstance -PackageFullName $PackageFullName){
		Write-Host "Package [$PackageFullName] was found on [$ServerInstance]."
	}
	else{
		Write-Error "Package [$PackageFullName] not found on [$ServerInstance]."
		Exit 1
	}
}
catch {
    Write-Error "$_ `n $("Failed to install DtsxFullName {0} to ServerInstance {1} PackageFullName {2}" -f $DtsxFullName,$ServerInstance,$PackageFullName)"
}