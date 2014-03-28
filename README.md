Ironfoundry Release
==========

### To build an IronFoundry Warden/DEA release package on a dev machine:
* Ensure all prerequisites are installed:
  * Git
  * Go
* Start a Powershell console with elevated privileges (required for some Warden tests).
* Run .\build.ps1 to build the release package.
* The resulting release package is at ./release/ironfoundry_master.exe.

### To install a IronFoundry Warden/DEA release package on a Windows server:
* Execute the ironfoundry_master.exe self-extracting archive on the server.
* Run install-prerequisites.ps1 to install the Ironfoundry prerequisites, then restart the console to pick up the new environment variables.
* Obtain a dea.yml config file for your CloudFoundry environment by copying it from an existing Linux DEA in your environment to the Windows server.
* Run ironfoundry-install.ps1, specifying the path to the dea.yml file, to install the Windows DEA and Warden.

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
