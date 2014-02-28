
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
$if_warden_version='0.0.0'

Write-Host "Building Warden"
.\if_warden\build.bat 

Write-Host "Updating dea_ng submodules"
Set-Location $IFSourceDirectory\dea_ng
git submodule update --init


Write-Host "Building GO WinRunner"
Set-Location $IFSourceDirectory\dea_ng\go\
$env:GOPATH="$IFSourceDirectory\dea_ng\go"
go build winrunner

Set-Location $IFSourceDirectory
#
# Stage items for zipping
#
New-Item $StagingDir -itemtype directory | Out-Null

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
    New-Item $StagingDir\$dir -itemtype directory | Out-Null 
}

Copy-Item -Recurse $IFSourceDirectory\dea_ng $StagingDir\dea_ng\app -Container 
Copy-Item -Recurse $IFSourceDirectory\if_warden\output\$if_warden_version\binaries $StagingDir\warden\app -Container 
Copy-Item -Recurse $IFSourceDirectory\tools $StagingDir\tools -Container 

$additionalFiles = @( 
    'ironfoundry_install.ps1', 
    'start-if-services.ps1', 
    'stop-if-services.ps1')

ForEach($file in $additionalFiles)
{
    Copy-Item $file $StagingRootDir -Container     
}


Set-Location $StagingRootDir | Out-Null

Write-Host $ZipCmd a -sfx "$RelaseName".exe -r -y $Stagingdir
. $ZipCmd a -sfx "$RelaseName".exe -r -y $Stagingdir | Out-Null

Set-Location $IFSourceDirectory