Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$Dea_Yml_File, 

    [Parameter(Mandatory=$True,Position=2)]
    [string] $IF_WardenUser_Password,
    
    [string] $IF_WardenUser = "IFWardenService",

    [string] $DefaultInstallDir = "C:\IronFoundry",

    [string] $ReleaseVersion = '0.0.0',

    [int] $DEAMemoryMB = -1,
    [int] $DEADiskMB = -1
    )


#
# Assumes:
#  Ruby Installed
#  Ruby DevKit Installed
#  Go Installed
#  Git installed
# 
# In Path:
#   gem
#   bundle
#   Git
#
# In Package:
#  if_data
#  if_warden
#  dea_ng source
#  Curl
#  7Zip

$ErrorActionPreference = "Stop"
# General install information
$StartDirectory = resolve-path $PWD
$ReleaseDir = join-path $StartDirectory $ReleaseVersion
$InstallRootDir = $DefaultInstallDir


# App locations
$rubyApp = $null
$rubyPath = $null


#
# Helper routines
#
function IsAdmin()
{
  $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
  $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  $IsAdmin=$prp.IsInRole($adm)
  return $IsAdmin
}

function FindApp($appName)
{
    # Search path for app
    foreach ($path  in $env:PATH.Split(";") ) {
        $name = "${path}\${appName}"
        $name = $name.Replace("`"", "")      
        if (test-path $name) {
            return $name
        }
    }    

    return $null
}

function CreateLocalUser([string]$userName, [string]$password)
{
    # Approach taken from: http://blogs.technet.com/b/heyscriptingguy/archive/2010/11/23/use-powershell-to-create-local-user-accounts.aspx
    $computer = [ADSI]("WinNT://$env:computername")
    $objUser = $computer.Create("user", $userName)
    $objUser.SetPassword($password)
    $objUser.SetInfo()

    # Set password not to expire
    $ADS_UF_DONT_EXPIRE_PASSWD = 0x10000
    $objUser.UserFlags = $objUser.UserFlags[0] -bor $ADS_UF_DONT_EXPIRE_PASSWD
    $objUser.SetInfo()
}

function DeleteLocaluser($userName)
{
    $computer = [ADSI]"WinNT://$env:computername"
    Try
	{
		$computer.Delete("User", $userName)
	}
	Catch
	{
		Write-Host "Unable to delete user $userName. This is normal on first install since the user does not exist yet."
	}
}

function AddUserToGroup($userName, $groupName)
{
    $group = [ADSI]("WinNT://$env:computername/$groupName,group") 
    $user = [ADSI]("WinNT://$env:computername/$userName,user")
    $group.Add($user.Path)
}

#
# Install and uninstall actions
#
function VerifyDependencies()
{
    Write-Host "Verifying dependencies"    

    $success = $true

    $script:rubyApp = (FindApp "ruby.exe")
    $script:rubyPath = split-path $rubyApp

    if ($rubyApp -eq $null) {
        $success = $false
        Write-Error "Unable to find ruby.exe"
    }


    if ((FindApp "go.exe") -eq $null) {
        $success = $false
        Write-Error "Unable to find Go"
    }

    if ((FindApp "git.exe") -eq $null) {
        $success = $false
        Write-Error "Unable to find git.exe"
    }    

    return $success
}

function UpdateConfigFile($sourceConfig, $targetConfig)
{
    Write-Host "Updating configuration file into to $targetConfig"

	Set-Location $StartDirectory
	
	$deaYmlFile = "$(resolve-path $sourceConfig)" -Replace "\\", "/"
	$configRubyPath = $rubyPath -Replace "\\", "/"
    $targetConfigRubyPath = $targetConfig -Replace "\\", "/"

    $configureArgs = @(
        '--source-config', $deaYmlFile,
        '--ruby-path', $configRubyPath,
        '--ironfoundry-path', $InstallRootDir,
        '--output', $targetConfigRubyPath
    )

    if ($DEAMemoryMB -gt 0) {
        $configureArgs += '--memory-mb', $DEAMemoryMB
    }

    if ($DEADiskMB -gt 0) {
        $configureArgs += '--disk-mb', $DEADiskMB
    }
    
	& $rubyApp "$ReleaseDir\if_data\configure-dea.rb" @configureArgs
}

function CreateLocalAdminUser($user, $password)
{
    Write-Host "Creating local user $user and adding to Administrators"
    DeleteLocaluser $user
    CreateLocalUser $user $password
    AddUserToGroup $user "Administrators"
}

#
# Unpack folder and set permissions
#
if ( (IsAdmin) -eq $false)
{
    Write-Error "This script must be run as admin."
    Exit 1
}

if ( (VerifyDependencies) -eq $false)
{
    Write-Error "Failed to verify dependencies."
    Exit 1
}

& $ReleaseDir\if_data\install.ps1 $InstallRootDir $Dea_Yml_File

$configured_Dea_Yml_File = (join-path $InstallRootDir "dea_ng\config\dea.yml")
UpdateConfigFile $Dea_Yml_File $configured_Dea_Yml_File

& $ReleaseDir\dea_ng\install.ps1 $InstallRootDir

CreateLocalAdminUser $IF_WardenUser $IF_WardenUser_Password
& $ReleaseDir\if_warden\install.ps1 (join-path $ReleaseDir if_warden) $IF_WardenUser $IF_WardenUser_Password $InstallRootDir

Set-Location $StartDirectory
    
Write-Host "IronFoundry Installed"
