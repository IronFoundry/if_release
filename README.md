Iron Foundry Release
====================

Introduction
------------

Iron Foundry allows .NET applications to be deployed using [Cloud Foundry](http://www.cloudfoundry.org/). The repository provides the ability to build a release of [Iron Foundry](http://www.ironfoundry.org/). The instructions below will walk through the steps of building, deploying and configuring the installation. The major steps in getting Iron Foundry up and running are:

1.	Install [BOSH](https://github.com/cloudfoundry/bosh) and Cloud Foundry
2.	Build Iron Foundry release on Dev machine
3.	Install Iron Foundry on Windows Server 2012
4.	Configure BOSH to use Iron Foundry

There is also a troubleshooting section at the end of this README to help with issues some users have had during this process.

Install Pre-requisites
----------------------

### Install Ruby version 1.9.3-547

In order to install BOSH you will need Ruby installed. We recommend using [rbenv](https://github.com/sstephenson/rbenv). If using rbenv, run the following commands:

```bash
$ rbenv install 1.9.3-p547
$ rbenv global 1.9.3-p547
```

Once Ruby has been installed check the version via the following command:

```bash
$ ruby -v
ruby 1.9.3p547 (2014-05-14 revision 45962) [x86_64-darwin13.4.0]
```

### Install BOSH CLI

If you don't already have BOSH CLI installed then install it via the following command:

```bash
$ gem install bosh_cli
```

### Install Cloud Foundry CLI

Follow the instructions on the [Cloud Foundry CLI](https://github.com/cloudfoundry/cli) README to install. To verify Cloud Foundry CLI is installed run the following command:

```
$ cf -v
cf version 6.7.0-c38c991-2014-11-12T01:45:23+00:00
```

### Install BOSH Lite and Cloud Foundry version 1.9.3 (For Dev environment)

To run BOSH in your local dev environment, [BOSH Lite](https://github.com/cloudfoundry/bosh-lite) sets up a local BOSH server. Follow the installation steps on the README. When installing a Cloud Foundry environment do not use the "Single command deploy". Instead use the "Manual deploy" steps at https://github.com/cloudfoundry/bosh-lite/blob/master/docs/deploy-cf.md.

Install the Cloud Foundry version 1.9.3 release which is currently the most compatible with Iron Foundry. In order to install Cloud Foundry version 1.9.3 the appropriate stemcell must be installed. Run the following commands to install the stemcell:

```
$ bosh download public stemcell bosh-stemcell-389-warden-boshlite-ubuntu-trusty-go_agent.tgz
$ bosh upload stemcell bosh-stemcell-389-warden-boshlite-ubuntu-trusty-go_agent.tgz
```

Now Cloud Foundry version 1.9.3 can be installed via BOSH CLI (within [cf-release](https://github.com/cloudfoundry/cf-release/tree/master/releases)):

```
$ bosh upload release releases/cf-193.yml
```

Build Release on Dev Machine
----------------------------

### Dev Machine Pre-requisites

#### Visual Studio 2013

To build an Iron Foundry release you must have a development machine that is able to build .NET applications. It is best to install Visual Studio 2013 on the development machine. We tend to run a VM with Windows 8.1 using VMWare or VirtualBox.

#### Git and Go

The build process need to access Git repositories and to compile Go code. Ensure these are installed on the dev machine:

-	[Git](http://git-scm.com/)
-	[Go](http://golang.org/)

### Execute Build

On the configured dev machine follow these steps to create an Iron Foundry release executable to be installed on Windows Server 2012.

- Clone this repository via Github command shell on Windows or using the Github for Windows UI to a directory of your choosing. We will use C:\projects\if_release as the location in this README so please replace this with your actual directory location.
-	Start a Powershell console with elevated privileges (required to run the entire set of Warden tests).
-	Build the release package by running the following in the cloned if_release project directory:

```
PS C:\projects\if_release> .\build.ps1
```

**NOTE**: *This will create a release versioned at 0.0.0 by default. If you want to specify an alternate release version you can specify use the -ReleaseVersion parameter of build to change this.*

-	The resulting release package is located in the "release" directory. Copy the release to a location that can be shared with the Windows Server that you want to deploy Iron Foundry onto:

```
PS C:\projects\if_release> cp .\release\ironfoundry_0.0.0.exe [share location]
```

Install Release on Windows Server 2012:
---------------------------------------

**IMPORTANT**: *Avoid installing Iron Foundry with user that has a spaces in their username.*

The Iron Foundry release package is now ready to be installed on Windows Server 2012. In the team's dev environment we usually install Windows Server 2012 onto a VM using VMWare or VirtualBox. When the Windows Server 2012 is up and running, follow these steps to install the Iron Foundry release package:

-	Create an installer directory at root of file system that Iron Foundry will running from

```
PS C:\> mkdir IF_Install
```

-	Execute the self-extracting release archive created on dev machine:

```
PS C:\> .\ironfoundry_0.0.0.exe
```

-	Install the Iron Foundry pre-requisites using the script install-prerequisites.ps1.

```
PS C:\IF_Install> .\install-prerequisites.ps1
```

If you specified a release version, you will need to run install-prerequisites.ps1 with the specific version specified, then restart the console to pick up the new environment variables.

-	Get the dea.yml config file from the existing Cloud Foundry Linux DEA:

```
$ bosh vms | grep runner
| runner_z1/0                        | running | runner_z1     | 10.244.0.26  |

$ bosh scp --download runner_z1 /var/vcap/jobs/dea_next/config/dea.yml [local dir to place dea.yml]
```

-	Upload, or make available, the dea.yml to the Windows Server machine.
-	Set the primary DNS entry for the Windows Server as the IP address of the microbosh server. Make sure to keep your existing DNS entries for additional lookup. To obtain the IP address of your BOSH server run the following command:

```
$ bosh target
Current target is https://192.168.64.138:25555 (Bosh Lite Director)
```

**NOTE**: *If you do not have admin access to the BOSH server, ask your BOSH administrator.*

-	Install Iron Foundry services onto Window Server along with creating a password for the IF Warden user account (NOTE: This install can take a while to run as it must install a number of gem's required by the Windows DEA):

```
PS C:\IF_Install> .\ironfoundry-install.ps1 c:\temp\dea.yml <SomePassword>
```
**NOTE**: *The names of the Iron Foundry services changed in commit ca791f2. If you are are running the install on a server running a previous version, you will have to manually cleanup the old services (IFDeaSvc and IFDeaDirSvc).*

This will create a directory at C:\IronFoundry. Logs and other information will be created in this directory. The supplied DEA file will be modified and copied to the c:\IronFoundry\dea_ng\config folder.

**NOTE**: *If you have a release version other than the default 0.0.0 you will need to specify the -ReleaseVersion option for the install.*

-	Start up the Iron Foundry services:

```
PS C:\IF_Install> .\start-if-services.ps1
```
- Verify all the services are running:

```
PS C:\> get-service Iron*

Status  Name                      DisplayName
------  ----                      -----------
Running IronFoundry.Dea           Iron Foundry DEA
Running IronFoundry.Dea.Directory Iron Foundry DEA Directory Service
Running ironfoundry.warden        Iron Foundry Warden Service
```


**IMPORTANT**: *Avoid password expirations for Iron Foundry services. To prevent the IFWarden user's password from expiring, we disable password expiration for that user during the install process. If this conflicts with an existing password policy or if you choose to re-enable the password expiration policy, then it becomes your responsibility to make sure that the IFWarden password is always valid. If the password does expire, the Iron Foundry services will be unable to restart if needed.*

### Register CLR Stack with Cloud Foundry Cloud Controller

#### Using BOSH Install of Cloud Foundry

-	Add these sections to your BOSH manifest (note that these are two separate sections under properties and both need to be updated):

```
...
  properties:
...
    ccng:
      stacks:
        - name: "lucid64"
          description: "Ubuntu 10.04"
        - name: "windows2012"
          description: "Microsoft Windows / .Net 64 bit"
...
    cc:
      stacks:
        - name: "lucid64"
          description: "Ubuntu 10.04"
        - name: "windows2012"
          description: "Microsoft Windows / .Net 64 bit"
```

-	Redeploy the BOSH deployment.

```
$ bosh deploy
```

#### Using Nise or Manual Install of Cloud Foundry

If your CloudFoundry environment was set up with Nise or manually:

-	SSH to your cloud controller server.
-	Edit /var/vcap/jobs/cloud_controller_ng/stacks.yml and add these two lines:

```
  - name: windows2012
    description: Microsoft .NET / Windows 64-bit
```

-	Restart the cloud controller.

### Install CLR Buildpack on Cloud Foundry

All buildpacks are now unbundled from releases of Cloud Foundry, so you need to manually upload the buildpack as the final step of the install. Use this command:

```
cf create-buildpack clr_buildpack https://github.com/cloudfoundry-incubator/cloudfoundry-buildpack-clr/archive/v1.zip 5
```

The final argument, `5`, can be changed to alter priority of the CLR buidpack in the chain of buildpacks that are executed during staging. Raising the number will cause the buildpack to be tried later in the chain, while lowering it will cause it be attempted earlier.

### Deploy a Windows Application

Now that Cloud Foundry is setup to accept .NET applications for deployment, configure a .NET application for Cloud Foundry and push it into Cloud Foundry:

```
$ cf push myapp -s windows2012 -c app.exe
```


The `-s` argument to the `cf` command is used to tell Cloud Foundry which stack to use. In this case it is telling Cloud Foundry to use the `windows2012` stack configured in the "Register CLR Stack with Cloud Foundry Cloud Controller" section above.

The `-c` argument to the `cf` command is used to specify the startup command. If -c is not used, the clr buildpack will assume the name is 'app.exe'.

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

Status   Name                             DisplayName
------   ----                             -----------
Running  IronFoundry.Dea.Directory        Iron Foundry DEA Directory Service
Running  IronFoundry.Dea                  Iron Foundry DEA


PS C:\IF_Install> Get-Service iron*

Status   Name               DisplayName
------   ----               -----------
Running  IronFoundry.Warden Iron Foundry Warden Service
```
