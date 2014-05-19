# SSIS plugin #

This document describes the functionality provided by the SSIS plugin.

See the **XL Deploy Reference Manual** for background information on XL Deploy and deployment concepts.

# Overview #


##Features##

* Deploys database packages (dacpac) to an [MSSQLClient container](http://docs.xebialabs.com/releases/latest/deployit/databasePluginManual.html#sqlmssqlclient "Database plugin documentation") in three different ways
	* Using powershell API (mssql.Dacpac), requires powershell v3 (checked by the script and available as controltask)
	* Using sqlpackage.exe and profile generated from XL Deploy repository (mssql.SQLPackageWithGeneratedProfile)
	* Using sqlpackage.exe and profile in artifact (mssql.SQLPackageWithProfile)
* Compatible with SQL Server 2005 and up (SQL Server 2012 required for project deployments)

# Requirements #

* **XL Deploy requirements**
	* **Deployit**: version 3.9+
	* **XL Deploy**: version 4.0+
	* Requires the database plugin to be installed (see DEPLOYIT_SERVER_HOME/available-plugins)
	* mssql.Dacpac deployable requries Powershell v3 or higher

# Installation

Place the plugin JAR file into your `DEPLOYIT_SERVER_HOME/plugins` directory.

# Usage #

# mssql.Dacpac:
Deployment of dacpac uing Powershell API. The database project file (.dacpac) is uploaded as the artifact and the required parameters filled in. Upon deployment the scripts checks if Powershell v3 or higher is running (also possible through controltask).
**Known limitation** The mssql.Dacpac deployable will not deploy over WinRM. Alternatives to using WinRM are using a localhost with mssqlclient (requires localhost to run Windows) or use SSH to connect to remote windows host.

# mssql.SQLPackageWithGeneratedProfile
This deployable generates a profile file that is then provided to sqlpackage.exe in order to deploy .dacpac. The mssql.SQLPackageWithGeneratedProfile can have one or more Variables. The artifact should contain the .dacpac file alone.

# mssql.SQLPackageWithProfile
This deployable relies on the deployment profile to be present in the artifact. The artifact should be a folder containing the .dacpac and deployment profile xml file. The Deployment profile file can contain placeholders as usual. 

# Undeployment
For all types the undeployment step is to drop the database specified with the targetDatabaseName property.