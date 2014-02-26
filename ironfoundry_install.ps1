#
# Assumes:
#  Ruby Installed
#  Ruby DevKit Installed
#  Go Installed
# 
# In Package:
#  dea_ng source
#  eventmachine source
#  
#  Precompiled IFWarden
#  Curl part of distribution ?
#  7Zip
# 

# TODO:
#  
#  Create directory structure (unpack to directory, if made as part of build)
#  
#  Register DEA as service
#  Register and Start Directory Service 
#  Register Warden Service
#    Create Warden User As Admin


# Assume zip is in same directory

$Release = 'if_v156'

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

$IFInstallDirectory='C:\_TestIronFoundry'
$IFSourceDirectory="$PWD\$Release"

Copy-Item $IFSourceDirectory $IFInstallDirectory

SetOwner $IFInstallDirectory "Administrators"
SetFullcontrolPermissions $IFInstallDirectory "NT Authority\Local Service"

# sc.exe 