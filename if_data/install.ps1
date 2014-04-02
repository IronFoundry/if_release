param(
    $InstallTargetDir,    
    $DeaConfigFile
    )

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

Write-Host "Copy IronFoundry data structure to $InstallTargetDir"

$IFData = join-path (Get-ScriptDirectory) "IronFoundry"

if ( (Test-Path $InstallTargetDir) -eq $false)
{
    New-Item $InstallTargetDir -Force -ItemType directory | Out-Null
}
Copy-Item $IFData\* $InstallTargetDir -Container -Recurse -Force

# Remove marker files if present
Get-ChildItem $InstallTargetDir -include __marker.txt -recurse | Remove-Item

Copy-Item $DeaConfigFile $InstallTargetDir\dea_ng\config\dea.yml
