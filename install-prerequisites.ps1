param($ReleaseVersion = '0.0.0')

$releaseDir = join-path $PWD $ReleaseVersion
$installScript = join-path $releaseDir "if_prereq\install.ps1"

.\$installScript
