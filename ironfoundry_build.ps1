
#Assumes
#  git in path
#

#
# Build Source and Update Submodules
#
$ReleaseName='if_v156'
$IFSourceDirectory = $PWD
$StagingRootDir = "$PWD\staging"
$StagingDir = "$StagingRootDir\$ReleaseName"
$ToolsDir = "$PWD\tools"
$ZipCmd = "$ToolsDir\7zip\7za.exe"
$LogFile = "$PWD\$ReleaseName_build.log"

.\IFwarden\build.bat 

Set-Location $IFSourceDirectory\dea_ng
git submodule update --init


Set-Location $IFSourceDirectory\dea_ng\go\
$env:GOPATH="$IFSourceDirectory\dea_ng\go"
go build winrunner

Set-Location $IFSourceDirectory
#
# Stage items for zipping
#
New-Item $StagingDir -itemtype directory

$dirs = @(
    'buildpack_cache', 
    'dea_ng\crashes', 
    'dea_ng\db', 
    'dea_ng\droplets', 
    'dea_ng\instances', 
    'dea_ng\staging', 
    'dea_ng\tmp', 
    'log',
    'package_cache',
    'run',
    'warden\containers')

ForEach ($dir in $dirs)
{
    New-Item $StagingDir\$dir -itemtype directory    
}

Copy-Item -Recurse $IFSourceDirectory\dea_ng $StagingDir\dea_ng\app -Container | Out-Null
Copy-Item -Recurse $IFSourceDirectory\eventmachine $StagingDir\eventmachine -Container | Out-Null
Copy-Item -Recurse $IFSourceDirectory\warden $StagingDir\warden\app -Container | Out-Null
Copy-Item -Recurse $IFSourceDirectory\tools $StagingDir\tools -Container | Out-Null

Copy-Item $IFSourceDirectory\ironfoundry_install.ps1 $StagingRootDir -Container | Out-Null


Set-Location $StagingRootDir
. $ZipCmd a -tzip -r -y "$ReleaseName".zip $Stagingdir

Set-Location $IFSourceDirectory