$ProgressPreference = "SilentlyContinue"

"Installing Hostable Web Core . . ."
pkgmgr "/iu:IIS-WebServerRole;IIS-HostableWebCore;IIS-ISAPIExtensions;IIS-ISAPIFilter;IIS-NetFxExtensibility45;IIS-ASPNET45;NetFx4Extended-ASPNET45;" | out-null

"Installing Go . . ."
Invoke-Webrequest "http://go.googlecode.com/files/go1.2.windows-amd64.msi" -OutFile ~/Downloads/go1.2.windows-amd64.msi
Unblock-File ~/Downloads/go1.2.windows-amd64.msi
~/Downloads/go1.2.windows-amd64.msi /quiet

"Installing Ruby . . ."
Invoke-WebRequest "http://dl.bintray.com/oneclick/rubyinstaller/rubyinstaller-1.9.3-p484.exe?direct" -OutFile ~/Downloads/rubyinstaller-1.9.3-p484.exe
Unblock-File ~/Downloads/rubyinstaller-1.9.3-p484.exe
~/Downloads/rubyinstaller-1.9.3-p484.exe /verysilent lang=en /tasks=modpath | out-null

"Installing Ruby Devkit. . ."
Invoke-WebRequest "http://github.com/downloads/oneclick/rubyinstaller/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe" -OutFile ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe
Unblock-File ~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe
~/Downloads/DevKit-tdm-32-4.5.2-20110712-1620-sfx.exe -o"C:\RubyDevKit" -y | out-null
C:\Ruby193\bin\ruby.exe C:\RubyDevKit\dk.rb init | out-null
C:\Ruby193\bin\ruby.exe C:\RubyDevKit\dk.rb install | out-null

"Installing msysgit for windows..."
Invoke-WebRequest "https://msysgit.googlecode.com/files/Git-1.9.0-preview20140217.exe" -OutFile ~/Downloads/Git-1.9.0-preview20140217.exe
Unblock-file ~/Downloads/Git-1.9.0-preview20140217.exe
~/Downloads/Git-1.9.0-preview20140217.exe /verysilent | out-null
# Can't find a way to trigger the path addition for git, so doing it manually.  Assuming standard install to ProgramFiles.
$systemPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
if ($systemPath -notmatch '\\Git\\cmd') {
    $systemPath += ";${env:ProgramFiles(x86)}\Git\cmd"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH –Value $systemPath
}

"Done."