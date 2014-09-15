# SSAS plugin #

This document describes the functionality provided by the SSAS plugin.

See the **XL Deploy Reference Manual** for background information on XL Deploy and deployment concepts.

# Overview #
This plugin provides functionality to deploy and destroy a SSAS Cube (Dimensional or Tabular) 

# Features #
- Deploys an .asdatabase file to a given server.

# Requirements #

XL Deploy requirements
	-  **Deployit**: version 3.9+
	-  **XL Deploy**: version 4.0+
	-  Requires the database plugin to be installed (see DEPLOYIT_SERVER_HOME/available-plugins)

SQL requirements
	- Supports SQL2012 only for now
	- SQLASCMDLETS on target server
	- access to Microsoft.AnalysisServices.Deployment on target server

# Usage #
- The "file" attribute of the "mssql.ASPackage" element has to point to the build output folder. Depending on you build implementation this will contain the .asdatabase file and some deployment configuration files. You might template this configuration files with deployit placeholders to differ between enviroments
- The "deployableArtifact" element has to point (relative) to the actual .asdatabase file within the folder above.
- The serverName has to contain the server to deploy to.
- The ssasDeploymentTool has to contain the location of the Microsoft.AnalysisServices.Deployment which is used to create a xmla deploy script.


