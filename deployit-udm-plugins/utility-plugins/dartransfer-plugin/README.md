# DAR transfer plugin #

This document describes the functionality provided by the DAR transfer plugin.

See the **XL Deploy Reference Manual** for background information on XL Deploy and deployment concepts.

# Overview #


##Features##

* Deploys a application package (dar) to another XL Deploy instance

# Requirements #

* **XL Deploy requirements**
	* **XL Deploy**: version 4.0+
	* Apache HTTP components (devloped and tested with v4.3.2) present in 'DEPLOYIT_SERVER_HOME/lib' folder
		* httpclient-4.2.1.jar (version packaged with XL Deploy)
		* httpcore-4.2.1.jar (version packaged with XL Deploy)
		* httpmime-4.2.1.jar
		* commons-codec-1.7.jar (already included in XL Deploy v4.0.0)
		* commons-logging-1.1.1.jar


# Installation

Place the plugin JAR file into your 'DEPLOYIT_SERVER_HOME/plugins' directory.

# Usage #

* Under infrastructure create a host (localhost recommended)
* On that host create a xldeploy.Server with the address, port and credentials for the XL Deploy instance you want to deploy to.
* Put this xldeploy.Server in an environment
* Add a xldeploy.DarPackage to your deployment package.
* Deploy the package to the XL Deploy environment and it should only map the DarPackage deployable
* After deployment the deployment package should be available in the next XL Deploy instance

Undeployment does nothing and tranfered packages need to be removed manually from target server.