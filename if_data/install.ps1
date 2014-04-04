param(
    $InstallTargetDir,    
    $DeaConfigFile
    )

# Assumes IronFoundry folder is relative to this working directory
Copy-Item IronFoundry $InstallTargetDir -Recurse -Force

# Remove marker files if present
Get-ChildItem $InstallTargetDir -include __marker.txt -recurse | Remove-Item

Copy-Item $DeaConfigFile $InstallTargetDir\dea_ng\config\dea.yml
