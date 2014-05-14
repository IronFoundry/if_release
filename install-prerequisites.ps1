param($ReleaseVersion = '0.0.0')

$releaseDir = join-path $PWD $ReleaseVersion
$installScript = join-path $releaseDir "if_prereqs\install.ps1"

. $installScript
