$DtsxFullName = $deployed.file
$ServerInstance = $deployed.serverInstance
$PackageFullName = $deployed.packageFullName

try {
	# Get Sql Version
	$SqlVersion = ""
	if($deployed.sqlServerVersion){
		$SqlVersion = $deployed.sqlServerVersion
	}
	else{
		if($deployed.container.type -eq 'overthere.LocalHost'){
			$SqlVersion = Get-SqlVersion -ServerInstance '(local)'
		}
		else{
			$SqlVersion = Get-SqlVersion -ServerInstance $ServerInstance		
		}
	}

	Write-Host "SqlVersion established to be [$SqlVersion]."

	# Set Dtutil Path based on Sql Version
	Set-DtsPaths -SqlVersion $SqlVersion

	##Check for existing package
	if (Test-Packagepath $PackageFullName) {
		Write-Host "Removing old package [$PackageFullName] from [$ServerInstance]."
		Remove-Package -ServerInstance $ServerInstance -PackageFullName $PackageFullName
	}

	Write-Host "Deploying package [$PackageFullName] to [$ServerInstance]."

	#Create path if needed
	Get-FolderList -PackageFullName $PackageFullName |
	where { $(Test-Path -ServerInstance $ServerInstance -FolderPath $_.FullPath) -eq $false } |
	foreach { New-Folder -ServerInstance $ServerInstance -ParentFolderPath $_.Parent -NewFolderName $_.Child }

	#Install SSIS Package
	Install-Package -DtsxFullName $DtsxFullName -ServerInstance $ServerInstance -PackageFullName $PackageFullName

	#Verify Package
	if(Test-Packagepath -ServerInstance $ServerInstance -PackageFullName $PackageFullName){
		Write-Host "Package [$PackageFullName] was found on [$ServerInstance]."
	}
	else{
		Write-Error "Package [$PackageFullName] not found on [$ServerInstance]."
		Exit 1
	}

	if($deployed.executePackage){
		Write-Host "Executing package [$PackageFullName] on [$ServerInstance]."
		$Params = "/U sa /P Dutch007 ";
		foreach($packageVariable in $deployed.packageVariables) {
	        $NameSpace = $packageVariable.propertyNamespace;
	        $PropertyName = $packageVariable.propertyName;
	        $Value = $packageVariable.propertyValue;
	        $PropertyPathValue =  Get-DtExecPropertyPathValue -NameSpace $NameSpace -PropertyName $PropertyName -Value $Value;
	        $Params += "/SET $PropertyPathValue ";
	    } 
		Execute-Package -PackageFullName $PackageFullName -ServerInstance $ServerInstance -Parameters $Params
	}
}
catch {
    Write-Error "$_ `n $("Failed to install DtsxFullName {0} to ServerInstance {1} PackageFullName {2}" -f $DtsxFullName,$ServerInstance,$PackageFullName)"
}