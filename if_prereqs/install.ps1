$ProgressPreference = "SilentlyContinue"

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

"Installing Hostable Web Core . . ."
Dism /online /enable-feature /all /featurename:IIS-WebServerRole /featurename:IIS-HostableWebCore /featurename:IIS-WebSockets /featurename:IIS-ASPNET /featurename:IIS-NetFxExtensibility
Dism /online /enable-feature /all /featurename:Application-Server /featurename:Application-Server-WebServer-Support /featurename:AS-NET-Framework
Dism /online /enable-feature /all /featurename:IIS-HttpErrors /featurename:IIS-RequestMonitor /featurename:IIS-HttpTracing

$GoVersion = "1.4.1";
$installedGo = get-wmiobject win32_product | where { $_.Name -match 'Go Programming Language' };
if ($installedGo -and ($installedGo.Name -notlike "*go${GoVersion}*"))
{
   $installedGoName = $installedGo.Name;
   write-host "Uninstalling installed Go version: ${installedGoName}" 
   $installedGo.Uninstall() | out-null;
}    

if ((FindApp "go.exe") -eq $null)
{
    $goFileName = "go${GoVersion}.windows-amd64.msi"
    "Installing Go..."
    Invoke-Webrequest "https://storage.googleapis.com/golang/${GoFileName}" -OutFile "~/Downloads/${GoFileName}"
    Unblock-File "~/Downloads/${GoFileName}"
    & "~/Downloads/${GoFileName}" /quiet
    # Can't find a way to trigger the path addition for Go, so doing it manually.  Assuming standard install to system drive.
    if ($env:Path -notmatch '\\Go\\bin') {
        $env:Path += ";${env:SystemDrive}\Go\bin"
        [Environment]::SetEnvironmentVariable( "Path", $env:Path, [System.EnvironmentVariableTarget]::Machine )
    }
}
else {
    Write-Host "Found go.exe."
}

if ( (FindApp "ruby.exe") -eq $null)
{
    "Installing Ruby..."
    Invoke-WebRequest "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-1.9.3-p484.exe?direct" -OutFile ~/Downloads/rubyinstaller-1.9.3-p484.exe
    Unblock-File ~/Downloads/rubyinstaller-1.9.3-p484.exe
    ~/Downloads/rubyinstaller-1.9.3-p484.exe /verysilent lang=en /tasks=modpath | out-null

    # Add ruby to the local path because this process doesn't have the updated system path yet
    $env:Path += ";${env:SystemDrive}\Ruby193\bin"
}
else {
    Write-Host "Found ruby.exe, not install ruby"
}

if ( !(Test-Path "${env:SystemDrive}\RubyDevKit"))
{
    "Installing Ruby Devkit..."
    Invoke-WebRequest "http://github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe" -OutFile ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe
    Unblock-File ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe
    ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe -o"C:\RubyDevKit" -y | out-null
    & "${env:SystemDrive}\Ruby193\bin\ruby.exe" ${env:SystemDrive}\RubyDevKit\dk.rb init | out-null
    & "${env:SystemDrive}\Ruby193\bin\ruby.exe" ${env:SystemDrive}\RubyDevKit\dk.rb install | out-null    
}
else
{
    Write-Host "Found ${env:SystemDrive}\RubyDevKit, not installing RubyDevKit."
}


"Updating Ruby gems..."
& "${env:SystemDrive}\Ruby193\bin\gem.bat" update --system --quiet | out-null
& "${env:SystemDrive}\Ruby193\bin\gem.bat" install bundle --quiet | out-null

if ( (FindApp "git.exe") -eq $null)
{
    "Installing msysgit for windows..."
    Invoke-WebRequest "https://msysgit.googlecode.com/files/Git-1.9.0-preview20140217.exe" -OutFile ~/Downloads/Git-1.9.0-preview20140217.exe
    Unblock-file ~/Downloads/Git-1.9.0-preview20140217.exe
    ~/Downloads/Git-1.9.0-preview20140217.exe /verysilent | out-null
    # Can't find a way to trigger the path addition for git, so doing it manually.  Assuming standard install to ProgramFiles.
    if ($env:Path -notmatch '\\Git\\cmd') {
        $env:Path += ";${env:ProgramFiles(x86)}\Git\cmd"        
    }
}
else {
    Write-Host "Found git.exe, not installing mysisgit"
}

[Environment]::SetEnvironmentVariable( "Path", $env:Path, [System.EnvironmentVariableTarget]::Machine )

"Done."
