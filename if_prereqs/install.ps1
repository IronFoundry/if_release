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

if (FindApp "go.exe" -eq $null)
{
    "Installing Go..."
    Invoke-Webrequest "http://go.googlecode.com/files/go1.2.windows-amd64.msi" -OutFile ~/Downloads/go1.2.windows-amd64.msi
    Unblock-File ~/Downloads/go1.2.windows-amd64.msi
    ~/Downloads/go1.2.windows-amd64.msi /quiet
    # Can't find a way to trigger the path addition for Go, so doing it manually.  Assuming standard install to system drive.
    if ($env:Path -notmatch '\\Go\\bin') {
        $env:Path += ";${env:SystemDrive}\Go\bin"
        [Environment]::SetEnvironmentVariable( "Path", $env:Path, [System.EnvironmentVariableTarget]::Machine )
    }
}
else {
    Write-Host "Found go.exe."
}

if (FindApp "ruby.exe" -eq $null)
{
    "Installing Ruby..."
    Invoke-WebRequest "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-1.9.3-p484.exe?direct" -OutFile ~/Downloads/rubyinstaller-1.9.3-p484.exe
    Unblock-File ~/Downloads/rubyinstaller-1.9.3-p484.exe
    ~/Downloads/rubyinstaller-1.9.3-p484.exe /verysilent lang=en /tasks=modpath | out-null

    "Installing Ruby Devkit..."
    Invoke-WebRequest "http://github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe" -OutFile ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe
    Unblock-File ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe
    ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe -o"C:\RubyDevKit" -y | out-null
    C:\Ruby193\bin\ruby.exe C:\RubyDevKit\dk.rb init | out-null
    C:\Ruby193\bin\ruby.exe C:\RubyDevKit\dk.rb install | out-null

    # Add ruby to the local path because this process doesn't have the updated system path yet
    $env:Path += ";C:\Ruby193\bin"
}
else {
    Write-Host "Found ruby.exe, not install ruby or devkit "
}

"Updating Ruby gems..."
C:\Ruby193\bin\gem.bat update --system --quiet | out-null
C:\Ruby193\bin\gem.bat install bundle --quiet | out-null

if (FindApp "git.exe" -eq $null)
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
