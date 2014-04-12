param(
    $NuGetPackageUrl = '',
    $NuGetApiKey = '',
    $ReleaseVersion = '0.0.0'  
    )
#Assumes
#  git in path
#

# 
# TeamCity variables that may be set
# 

$BuildVersion = $ReleaseVersion
if ($env:BUILD_NUMBER -ne $null) {
    $BuildVersion = $env:BUILD_NUMBER
}

$BuildBranch = 'DevLocal'
if ($env:BUILD_BRANCH -ne $null) {
    $BuildBranch = $env:BUILD_BRANCH

    if ($BuildBranch -eq '<default>') {
        $BuildBranch = 'master'
    }
}   

$BuildIsPrivate = ($BuildBranch -ne 'master')

if ($NuGetPackageUrl -eq '' -and $env:NUGET_PACKAGE_URL -ne $null) {
    $NuGetPackageUrl = $env:NUGET_PACKAGE_URL
}

if ($NuGetApikey -eq '' -and $env:NUGET_API_KEY -ne $null) {
    $NuGetApiKey = $env:NUGET_PACKAGE_URL
}

if ($BuildIsPrivate -eq $true) {
    $NuGetVersion = $BuildVersion + $BuildBranch
}
else {
    $NuGetVersion = $BuildVersion
}

#
# Base directories
#
$IFSourceDirectory = Convert-Path $PWD
$BuildRootDir = "$IFSourceDirectory\Build"
$ToolsDir = "$IFSourceDirectory\tools"

# Nuget properties
$NuGetExe = "$BuildRootDir\nuget\nuget.exe"
$NuGetNuSpec = "$BuildRootDir\Default.Deploy.nuspec"

# Staging Properties
$StagingRootDir = "$IFSourceDirectory\staging"
$StagingDir = "$StagingRootDir\$BuildVersion"
$StagingIFDataRoot = "$StagingDir\if_data"
$StagingDeaPackageRoot = "$StagingDir\dea_ng"
$StagingWardenPackageRoot = "$StagingDir\if_warden"
$StagingIFPreReqs = "$StagingDir\if_prereqs"

$ReleaseDir = "$IFSourceDirectory\release"
$ZipCmd = "$ToolsDir\7zip\7za.exe"
$LogFile = "$IFSourceDirectory\$BuildVersion-build.log"

function UpdateSubmodules
{
    Write-Host "Updating submodules"
    git submodule sync --recursive
    git submodule update --init --recursive
}

function BuildWarden()
{
    Write-Host "Building Warden: $BuildVersion"
    .\if_warden\build.bat Default /verbosity:minimal /p:BuildNumber="$BuildVersion"
}

function BuildDirectoryServer()
{
    Write-Host "Building GO WinRunner"
    Set-Location $IFSourceDirectory\dea_ng\go\
    $env:GOPATH="$IFSourceDirectory\dea_ng\go"
    go build winrunner
    Set-Location $IFSourceDirectory
}

function StageRelease()
{
    Write-Host "Staging the release"

    Remove-Item $StagingRootDir -force -recurse -erroraction silentlycontinue | Out-Null
    New-Item $StagingDir -itemtype directory -Force | Out-Null

    Copy-Item -Recurse $IFSourceDirectory\if_data $StagingIFDataRoot -Container -Force
    # NuGet pack cannot package empty directories, so add marker files.  Install.ps1 will remove these.
    Get-ChildItem $StagingIFDataRoot -Recurse | Where-Object { $_.PSIsContainer } | ForEach-Object { "" > "$($_.FullName)\__marker.txt"}

    Copy-Item -Recurse $IFSourceDirectory\dea_ng $StagingDeaPackageRoot -Container -Force
    Copy-Item -Recurse $IFSourceDirectory\if_warden\output\$BuildVersion\binaries $StagingWardenPackageRoot -Container -Force
    Copy-Item -Recurse $IFSourceDirectory\if_prereqs $StagingIFPreReqs -Container -Force
    Copy-Item -Recurse $IFSourceDirectory\tools $StagingDir\tools -Container -Force

    $additionalFiles = @( 
        'ironfoundry-install.ps1', 
        'start-if-services.ps1', 
        'stop-if-services.ps1',
    	'install-prerequisites.ps1',
    	'README.md')

    ForEach($file in $additionalFiles)
    {
        Copy-Item $file $StagingRootDir -Container -Force
    }
}

function CleanRelease {
    Remove-Item $ReleaseDir -recurse -force -erroraction silentlycontinue | Out-Null
    New-Item $ReleaseDir -itemtype directory -force | Out-Null 
}

function ZipRelease()
{
    Write-Host "Creating the release"

    . $ZipCmd a -sfx "$ReleaseDir\ironfoundry-$BuildVersion-$BuildBranch.exe" -r -y $StagingRootDir\* | Out-Null
}

function CreateNuSpecs()
{
    Write-Host "Creating nuspec packages"
    & $NuGetExe pack "$NuGetNuspec" -Version $NuGetVersion -Prop "Id=ironfoundry.pre-reqs" -BasePath "$StagingIFPreReqs" -NoPackageAnalysis -NoDefaultExcludes -OutputDirectory "$ReleaseDir"
    & $NuGetExe pack "$NuGetNuSpec" -Version $NuGetVersion -Prop "Id=ironfoundry.data" -BasePath "$StagingIFDataRoot" -NoPackageAnalysis -NoDefaultExcludes -OutputDirectory "$ReleaseDir"
    & $NuGetExe pack "$NuGetNuSpec" -Version $NuGetVersion -Prop "Id=ironfoundry.dea_ng" -BasePath "$StagingDeaPackageRoot" -NoPackageAnalysis -NoDefaultExcludes -OutputDirectory "$ReleaseDir"
    & $NuGetExe pack "$NuGetNuSpec" -Version $NuGetVersion -Prop "Id=ironfoundry.warden.service" -BasePath "$StagingWardenPackageRoot" -NoPackageAnalysis -NoDefaultExcludes -OutputDirectory "$ReleaseDir"
}

function NuGetPush {
    Write-Host "Pushing to nuget url: $NuGetPackageUrl"

    Get-ChildItem "$ReleaseDir\*.$NuGetVersion.nupkg" | ForEach-Object {
        . $NuGetExe push -Source $NuGetPackageUrl -ApiKey "$NuGetApiKey" "$($_.FullName)"
    }
}

UpdateSubmodules
BuildWarden
BuildDirectoryServer
StageRelease
CleanRelease
ZipRelease
if ($NuGetPackageUrl -ne '')
{
    CreateNuSpecs
    NuGetPush
}

Set-Location $IFSourceDirectory