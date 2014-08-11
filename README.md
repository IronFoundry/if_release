
Ironfoundry Release
==========

### To build an IronFoundry Warden/DEA release package on a dev machine:
* Make sure the machine is configured as a developer machine with Visual Studio 2013.
* Ensure all prerequisites are installed:
  * Git
  * Go
* Start a Powershell console with elevated privileges (required to run the entire set of Warden tests).
* Run .\build.ps1 to build the release package.  
*   This will create a release versioned at 0.0.0 by default.  If you want to specify 
*   an alternate release version you can specify use the -ReleaseVersion parameter of build to change this.
*
* The resulting release package is at ./release/ironfoundry_0.0.0.exe (or whatever your chosen release version is)

### To install a IronFoundry Warden/DEA release package on a Windows server:
* On a separate VM, install a new copy of Windows Server 2012.
* Execute the ironfoundry_0.0.0.exe self-extracting archive on the server.  This location will be the run-time location of the services.
* Run `install-prerequisites.ps1` to install the Ironfoundry prerequisites.  If you specified a release version, you will need to run install-prerequisites.ps1 with the specific version specified, then restart the console to pick up the new environment variables.
* Obtain a dea.yml config file for your CloudFoundry environment by copying it from an existing Linux DEA in your environment to the Windows server. You can find the dea.yml file at /var/vcap/jobs/dea_next/config on the Linux DEA.
* Set the primary DNS entry for windows to be the IP address of the
  microbosh server. You can obtain the IP address of your microbosh
  server by running `bosh target` from a linux or Mac workstation with bosh installed and access to
  the microbosh server or by asking your Cloud Foundry administrator.
* Run ironfoundry-install.ps1, specifying the path to the dea.yml file and a password for IF Warden user account (IFWardenService by default):
`ironfoundry-install.ps1 c:\temp\dea.yml <SomePassword>`
* Note:
 * This will create a directory at C:\IronFoundry warden for logs and other information needed by the Windows DEA and Warden.  The supplied dea file will be modified a copied to the c:\IronFoundry\dea_ng\config folder.
  * If you have a release version other than the default 0.0.0 you will need to specify the -ReleaseVersion option for the install.
  * Note: This install can take a while to run as it must install a number of gem's required by the Windows DEA.
* Run `start-if-services.ps1` to start the Iron Foundry services.

### To register the CLR stack with the Cloud Controller:
* If your CloudFoundry environment was set up with BOSH:
  * Add these sections to your BOSH manifest (note that these are two separate sections under properties and both need to be updated):
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
  * Redeploy the BOSH deployment.
* If your CloudFoundry environment was set up with Nise or manually:
  * SSH to your cloud controller server.
  * Edit /var/vcap/jobs/cloud_controller_ng/stacks.yml and add these two lines:
  ```
  - name: windows2012
    description: Microsoft .NET / Windows 64-bit
  ```
  * Restart the cloud controller.

### To push a Windows application:
* `cf push myapp -s windows2012`
