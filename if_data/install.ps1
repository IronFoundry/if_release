param(
    $InstallTargetDir,    
    $DeaConfigFile
    )

# Assumes IronFoundry folder is relative to this working directory
if ( (Test-Path $InstallTargetDir) -eq $false)
{
    New-Item $InstallTargetDir -Force -ItemType directory | Out-Null
}
Copy-Item IronFoundry\* $InstallTargetDir -Container -Recurse -Force

# Remove marker files if present
Get-ChildItem $InstallTargetDir -include __marker.txt -recurse | Remove-Item

Copy-Item $DeaConfigFile $InstallTargetDir\dea_ng\config\dea.yml
