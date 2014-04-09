
Ironfoundry Release
==========

### To build an IronFoundry Warden/DEA release package on a dev machine:
* Ensure all prerequisites are installed:
  * Git
  * Go
* Start a Powershell console with elevated privileges (required to run the entire set of Warden tests).
* Run .\build.ps1 to build the release package.  
*   This will create a release versioned at 0.0.0 by default.  If you want to specify 
*   analternate release version you can specify use the -ReleaseVersion parameter of build to change this.
*
* The resulting release package is at ./release/ironfoundry_0.0.0.exe (or whatever your release verison is)

### To install a IronFoundry Warden/DEA release package on a Windows server:
* Execute the ironfoundry_master.exe self-extracting archive on the server.
* Run `install-prerequisites.ps1` to install the Ironfoundry prerequisites.  If you specified a release version, you will need to run install-prerequisites.ps1 with the specific version specified, then restart the console to pick up the new environment variables.
* Obtain a dea.yml config file for your CloudFoundry environment by copying it from an existing Linux DEA in your environment to the Windows server.
* Run ironfoundry-install.ps1, specifying the path to the dea.yml file and a password for IF Warden user account (IFWardenService by default):
`ironfoundry-install.ps1 c:\temp\dea.yml <SomePassword>`
* Note:
 * This will create a directory at C:\IronFoundry warden for logs and other information needed by the Windows DEA and Warden.  The supplied dea file will be modified a copied to the c:\IronFoundry\dea_ng\config folder.
  * If you have a release version other than the default 0.0.0 you will need to specify the -ReleaseVersion option for the install.
  * Note: This install can take a while to run as it must install a number of gem's required by the Windows DEA.

### To register the CLR stack with the Cloud Controller:
* If your CloudFoundry environment was set up with BOSH:
  * Add this section to your BOSH manifest:
  ```
  properties:
    ccng:
      stacks:
        - name: "lucid64"
          description: "Ubuntu 10.04"    
        - name: "mswin-clr"
          description: "Microsoft Windows / .Net 64 bit"
  ```
  * Redeploy the BOSH deployment.
* If your CloudFoundry environment was set up with Nise or manually:
  * SSH to your cloud controller server.
  * Edit /var/vcap/jobs/cloud_controller_ng/stacks.yml and add these two lines:
  ```
  - name: mswin-clr
    description: Microsoft .NET / Windows 64-bit
  ```
  * Restart the cloud controller.

### To push a Windows application:
* `cf push myapp -s mswin-clr`
