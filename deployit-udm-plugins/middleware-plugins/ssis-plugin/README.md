# SSIS plugin #

This document describes the functionality provided by the SSIS plugin.

See the **XL Deploy Reference Manual** for background information on XL Deploy and deployment concepts.

# Overview #


##Features##

* Deploys SSIS (dts) packages to an [MSSQLClient container](http://docs.xebialabs.com/releases/latest/deployit/databasePluginManual.html#sqlmssqlclient "Database plugin documentation")
* Deploys SSIS (ispac) projects to an [MSSQLClient container](http://docs.xebialabs.com/releases/latest/deployit/databasePluginManual.html#sqlmssqlclient "Database plugin documentation")
* Deploys database packages (dacpac) to an [MSSQLClient container](http://docs.xebialabs.com/releases/latest/deployit/databasePluginManual.html#sqlmssqlclient "Database plugin documentation")
* Compatible with SQL Server 2005 and up (SQL Server 2012 required for project deployments)

# Requirements #

* **XL Deploy requirements**
	* **Deployit**: version 3.9+
	* **XL Deploy**: version 4.0+
	* Requires the database plugin to be installed (see DEPLOYIT_SERVER_HOME/available-plugins)

# Installation

Place the plugin JAR file into your `DEPLOYIT_SERVER_HOME/plugins` directory.

# Usage #

An SSIS package is bundled in a single dtsx file. 

The plugin copies the provided dtsx file (the artefact) to the container's server. From there is determines the version of SQL Server and uses that to determine the location of the dtutil utility.
The dtsx package is deployed using the SQL Server dtutil utility to the provided server and path.

A SSIS project is bundled in a single ispac file

The plugin copies the provided ipac file (the artefact) to the container's server. On the server it connects to the SSIS instance. In the SSIS instance it tries to connect to the provided SSIS catalog (default value is SSISDB). If the catalog isn't shared it's removed. If no catalog is found a new one is created with the provided password. 
A folder is created with the provided name (if a folder with that name is found it is used). 
Within the folder:
	*The project with the given projectName is created, if a project with that name is found it is first removed. 
	*The sepcified environments are created, if an environment exists it is first removed.
	*Specified environment variables are created and if specified a project parameter is created with a reference
	*The environment is referenced to the project

When the ISProject is destroyed the catalog is removed if it is not shared. Otherwise only project & environments are removed. If the folderName is empty after project & environment removal it is also removed.

An database package is bundled in a single dacpac file. 

The plugin copies the provided dacpac file (the artefact) to the container's server. Where it is deployed using powershell. Requires powershell v3, which is checked by the script. It also requires a trusted connection, so native winrm (available when XL Deploys runs on windows machine) or a winrs proxy with credential delegation is needed.
