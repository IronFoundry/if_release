Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$CloudController, 

    [Parameter(Mandatory=$True,Position=2)]
    [string]$CloudDomain, 

    [Parameter(Mandatory=$True,Position=3)]
    [string] $IF_WardenUser_Password,
    
    [string] $IF_WardenUser = "IFWardenService",

    [string] $DefaultInstallDir = "C:\IronFoundry",

    [string] $NatsUser = 'nats',
    [string] $NatsPassword = 'c1oudc0w'
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
#  dea_ng source
#  eventmachine source
#  Precompiled IFWarden
#  Curl
#  7Zip

# General install information
$installContext = @{}
$Release = 'if_v156'

#
# Helper routines
#
function SetFullcontrolPermissions($folder, $user)
{
    $acl = Get-Acl $folder
    $fcacl = New-Object  system.security.accesscontrol.filesystemaccessrule($user,"FullControl","Allow")
    $acl.SetAccessRule($fcacl)
    Set-Acl $folder $acl
    Get-ChildItem $folder -Recurse | Set-Acl -AclObject $acl
}

function SetOwner($folder, $user)
{
    $acl = Get-Acl $folder
    $objUser = New-Object System.Security.Principal.NTAccount($user)    
    $acl.SetOwner($objUser)
    Set-Acl $folder $acl  
    Get-ChildItem $folder -Recurse | Set-Acl -AclObject $acl
}

function AddFirewallRules($exePath, $ruleName )
{
    . netsh.exe advfirewall firewall add rule name="$ruleName"-allow dir=in action=allow program="$exePath"
    . netsh.exe advfirewall firewall add rule name="$ruleName"-out-allow dir=out action=allow program="$exePath"
}

function RemoveFirewallRules($ruleName)
{
     . netsh.exe advfirewall firewall delete rule name="$ruleName"-allow
     . netsh.exe advfirewall firewall delete rule name="$ruleName"-allow-out
}

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
}

function DeleteLocaluser($userName)
{
    $computer = [ADSI]"WinNT://$env:computername"
    $computer.Delete("User", $userName)
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
function VerifyDependencies($context)
{
    Write-Host "Verifying dependencies"    

    $rubyApp = FindApp "rubyw.exe"
    if ($rubyApp -eq $null) {
        Write-Error "Unable to find Ruby"
    }
    $context['rubyPath'] = Split-Path $rubyApp -Parent    

    if ((FindApp "go.exe") -eq $null) {
        Write-Error "Unable to find Go"
    }

    if ((FindApp "git.exe") -eq $null) {
        Write-Error "Unable to find git.exe"
    }    
}

function GoServiceInstall($context)
{
    Write-Host "Install GO Directory Service"    

    $runnerExe = resolve-path "$($context['InstallRootDir'])\dea_ng\app\go\winrunner.exe"
    . $runnerExe remove
    
    if ($context['action'] -eq 'install') {
        Write-Host "Installing IF WinRunner Service"

        . $runnerExe install $context['configFile']
        AddFirewallRules $runnerExe "IF_runner"
    }
    else {
        RemoveFirewallRules "IF_runner"
    }
}

function CopySourceDirectoryAction($context)
{
    Write-Host "Copy files to target directory"

    Copy-Item -Recurse $context['SourceDir'] $context['InstallRootDir']

    SetOwner $context['InstallRootDir'] "Administrators"
    SetFullcontrolPermissions $context['InstallRootDir'] "NT Authority\Local Service"

    $context['deaAppPath'] = "$($context['InstallRootDir'])\dea_ng\app"
    $context['wardenAppPath'] = resolve-path "$($context['InstallRootDir'])\warden\app"
    $context['configFile'] = resolve-path "$($context['deaAppPath'])\config\dea_mswin-clr.yml"
}

function DEAInstallAction($context)
{
    Write-Host "Install DEA dependent gems (this may take a while)"

    if ($context['action'] -eq 'install')
    {
        Write-Host "Update gem packages for dea_ng"
        . gem update --system --quiet
        . gem install bundle --quiet

        Set-Location $context['deaAppPath']
        . bundle install --quiet
    }
}

function DEAServiceInstall($context)
{
    Write-Host "Install DEA service entry"

    . sc.exe delete IFDeaSvc
    RemoveFirewallRules "rubyw-193"

    if ($context['action'] -eq 'install') {
        $rubywExe = "$($context['rubyPath'])\rubyw.exe"
          
        . sc.exe create IFDeaSvc start=delayed-auto binPath="$rubywExe -C $($context['deaApppath'])\bin dea_winsvc.rb $($context['configFile'])" DisplayName= "Iron Foundry DEA"
        . sc.exe failure IFDeaSvc reset=86400 actions="restart/600000/restart/600000/restart/600000"

        AddFirewallRules $rubywExe "rubyw-193"
    }  
}

function RebuildEventMachineAction($context)
{
    Write-Host "Build and install custom event machine"
    if ($context['action'] -eq 'install') {
        Write-Host "Building and installing custom eventmachine gem"
        Set-Location "$($context['InstallRootDir'])"
        git clone https://github.com/IronFoundry/eventmachine.git eventmachine

        Set-Location "$($context['InstallRootDir'])\eventmachine"
        . gem uninstall eventmachine --force --version 1.0.3 --quiet
        . gem build eventmachine.gemspec --quiet
        . gem install eventmachine-1.0.3.gem --quiet
    }
}

function WardenServiceInstall($context)
{
    Write-Host "Install warden service"
    #
    # Install Warden Service
    #
    $wardenService = "$($context['wardenAppPath'])\IronFoundry.Warden.Service.exe"
    . $wardenService uninstall

    if ($context['action'] -eq 'install')
    {
        CreateLocalUser $IF_WardenUser $IF_WardenUser_Password
        AddUserToGroup $IF_WardenUser "Administrators"
        
        . $wardenService install -username:"$env:computername\$IF_WardenUser" -password:"$IF_WardenUser_Password" --autostart
        if ($? -eq $false)
        {
            Write-Error "Unable to install warden service"
        }
    }
    else {
        RemoveLocaluser $IF_WardenUser
    }
}

function UpdateConfigFile($context)
{
    $configFilePath = $context['configFile']
    $configFile = Get-Content $configFilePath

    $installerRootDirRubified = $context['InstallRootDir'] -replace "\\","/"
    $rubyPathRubified = $context['rubyPath'] -replace "\\","/"

    $configFile = $configFile | 
                %{ $_ -replace "C\:/IronFoundry/", "$installerRootDirRubified/"} |
                %{ $_ -replace "(router\:)(.+?)($)", "`$1 $($CloudController):3456" } |
                %{ $_ -replace "(nats\:)(.+?)($)", "`$1//${NatsUser}:$NatsPassword@$($CloudController):4222" } |
                %{ $_ -replace "(domain\:)(.+?)($)", "`$1 `"$($CloudDomain)`"" } |
                %{ $_ -replace "C\:[\\,/]Ruby193[\\,/]bin", "$rubyPathRubified" }

    Set-Content $configFilePath $configFile
}

#
# Unpack folder and set permissions
#
$StartDirectory = resolve-path $PWD

$installContext['action'] = 'install'
$installContext['InstallRootDir'] = $DefaultInstallDir
$installContext['SourceDir'] = "$PWD\$Release"

VerifyDependencies $installContext
CopySourceDirectoryAction $installContext
DEAInstallAction $installContext
RebuildEventMachineAction $installContext
DEAServiceInstall $installContext 
GoServiceInstall $installContext
WardenServiceInstall $installContext
UpdateConfigFile $installContext

Set-Location $StartDirectory
    
Write-Host "IronFoundry Installed"
