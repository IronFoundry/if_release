Iron Foundry Release
====================

### To build an Iron Foundry Warden/DEA release package on a dev machine:

-	Make sure the machine is configured as a developer machine with Visual Studio 2013.
-	Ensure all prerequisites are installed:
	-	[Git](http://git-scm.com/)
	-	[Go](http://golang.org/)
-	Start a Powershell console with elevated privileges (required to run the entire set of Warden tests).
-	Run .\build.ps1 to build the release package.  
-	This will create a release versioned at 0.0.0 by default. If you want to specify
-	an alternate release version you can specify use the -ReleaseVersion parameter of build to change this.*
-	The resulting release package is at ./release/ironfoundry_0.0.0.exe (or whatever your chosen release version is)

### To install a Iron Foundry Warden/DEA release package on a Windows server:

-	On a separate VM, install a new copy of Windows Server 2012.
-	Execute the ironfoundry_0.0.0.exe self-extracting archive on the server. This location will be the run-time location of the services. We recommend placing the self-extracting archive in a directory outside of the home directory such as C:\IF_Install.
-	Run `install-prerequisites.ps1` to install the Iron Foundry prerequisites. If you specified a release version, you will need to run install-prerequisites.ps1 with the specific version specified, then restart the console to pick up the new environment variables.
-	Obtain a dea.yml config file for your CloudFoundry environment by copying it from an existing Linux DEA in your environment to the Windows server. You can find the dea.yml file at /var/vcap/jobs/dea_next/config on the Linux DEA.
-	Set the primary DNS entry for windows to be the IP address of the microbosh server. Keep your existing DNS entries as additional lookup.
	-	You can obtain the IP address of your microbosh server by running `bosh target` from a linux or Mac workstation with bosh installed and access to the microbosh server or by asking your Cloud Foundry administrator.
-	Run ironfoundry-install.ps1, specifying the path to the dea.yml file and a password for IF Warden user account (IFWardenService by default):`ironfoundry-install.ps1 c:\temp\dea.yml <SomePassword>`
-	Note:
	-	This will create a directory at C:\IronFoundry warden for logs and other information needed by the Windows DEA and Warden. The supplied dea file will be modified a copied to the c:\IronFoundry\dea_ng\config folder.
	-	If you have a release version other than the default 0.0.0 you will need to specify the -ReleaseVersion option for the install.
	-	Note: This install can take a while to run as it must install a number of gem's required by the Windows DEA.
-	Run `start-if-services.ps1` to start the Iron Foundry services.

### NOTE - Avoid password expirations for Iron Foundry services

To prevent the IFWarden user's password from expiring, we disable password expiration for that user during the install process. If this conflicts with an existing password policy or if you choose to re-enable the password expiration policy, then it becomes your responsibility to make sure that the IFWarden password is always valid. If the password does expire, the Iron Foundry services will be unable to restart if needed.

### Using with BOSH Lite

#### Installing for use with Iron Foundry

To run BOSH in your local dev environment, BOSH Lite (https://github.com/cloudfoundry/bosh-lite) sets up a local BOSH server. Follow the installation steps on the README. When installing a Cloud Foundry environment do not use the "Single command deploy". Instead use the "Manual deploy" steps at https://github.com/cloudfoundry/bosh-lite/blob/master/docs/deploy-cf.md. When uploading a Cloud Foundry release run the following to install version 1.7.2 which is most compatible with Iron Foundry:

```
bosh upload release releases/cf-172.yml
```

### To register the CLR stack with the Cloud Controller:

#### If your CloudFoundry environment was set up with BOSH (including on Bosh Lite):

-	Add these sections to your BOSH manifest (note that these are two separate sections under properties and both need to be updated):

```
  properties:
    ccng:
      stacks:
        - name: "lucid64"
          description: "Ubuntu 10.04"
        - name: "windows2012"
          description: "Microsoft Windows / .Net 64 bit"
    cc:
      stacks:
        - name: "lucid64"
          description: "Ubuntu 10.04"
        - name: "windows2012"
          description: "Microsoft Windows / .Net 64 bit"
```

-	Redeploy the BOSH deployment.
-	If your CloudFoundry environment was set up with Nise or manually:
	-	SSH to your cloud controller server.
	-	Edit /var/vcap/jobs/cloud_controller_ng/stacks.yml and add these two lines:

```
  - name: windows2012
    description: Microsoft .NET / Windows 64-bit
```

-	Restart the cloud controller.

### Installing the CLR buildpack

-	All buildpacks are now unbundled from releases of Cloud Foundry, so you need to manually upload the buildpack as the final step of the install. Use this command, `cf create-buildpack clr_buildpack https://github.com/cloudfoundry-incubator/cloudfoundry-buildpack-clr/archive/v1.zip 5` to install the buildpack into your Cloud Foundry instance.
-	The final argument, `5`, can be changed to alter priority of the CLR buidpack in the chain of buildpacks that are executed during staging. Raising the number will cause the buildpack to be tried later in the chain, while lowering it will cause it be attempted earlier.

### To push a Windows application:

-	`cf push myapp -s windows2012`

Troubleshooting
---------------

### Can't find .NET Runtime

If you see this error when running .\build.ps1 it means you haven't installed or made available to user the .NET Framework. Ensure that either Visual Studio 2013 or .NET Framework is installed on dev machine.

### Not able to see IF_Warden

If you see this error then one issue could be that your username has spaces or special characters in it. Change to a user with no spaces or special characters in their username to run install prerequisites and Iron Foundry onto Windows Server.

### Not able to deploy apps onto Windows Server

There could be many reasons for failed app deployment from not completing all the steps above successfully, networking configuration issues, or services failiing to start. Please review the steps above to make sure each has completed successfully and that your networking between Bosh and Windows Server is setup properly. To verify the Iron Foundry services are running on Windows Server you can run the following commands:

```
PS C:\IF_Install> Get-Service if*

Status   Name               DisplayName
------   ----               -----------
Running  IFDeaDirSvc        Iron Foundry DEA Directory Service
Running  IFDeaSvc           Iron Foundry DEA


PS C:\IF_Install> Get-Service iron*

Status   Name               DisplayName
------   ----               -----------
Running  ironfoundry.warden Iron Foundry Warden Service
```
