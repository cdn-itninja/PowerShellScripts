# Script silently installs and runs module and script to collect Windows Autopilot Hardware Hash, then upload to central FTP
# Collect Environment Information
$computername = $env:computername
$hwid = "$computername.csv"
$file = "C:\HWID\$hwid"

# Skips running script if file already exists C:\HWID\*Computername*.csv
if(!(test-path $file)){
try{
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -force
}
catch {
    #Do Nothing
}
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
# Install NuGet if required
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Update Environment Path to include Powershell Scripts folder
$oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
$newpath = "$oldpath;C:\Program Files\WindowsPowershell\Scripts"
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name "PATH" -Value $newpath
# Install Autopilot Hash Collection Script to Powershell Scripts folder
Set-Location -Path "C:\Program Files\WindowsPowershell\Scripts"
Install-Script -Name Get-WindowsAutoPilotInfo -Force
if(!(test-path "C:\HWID")){
    md c:\\HWID
    }
Set-Location c:\\HWID
# Runs Autopilot Script, output to C:\HWID\*Computername*.csv
Get-WindowsAutoPilotInfo.ps1 -OutputFile $hwid

# FTP Config
$Username = "FTP User"
$Password = "FTP Password"
$RemoteFile = "ftp://Address/folder/file"
 
# Create FTP Request Object
$FTPRequest = [System.Net.FtpWebRequest]::Create("$RemoteFile")
$FTPRequest = [System.Net.FtpWebRequest]$FTPRequest
$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$FTPRequest.Credentials = new-object System.Net.NetworkCredential($Username, $Password)
$FTPRequest.UseBinary = $true
$FTPRequest.UsePassive = $true
# Read the File for Upload
$FileContent = gc -en byte $file
$FTPRequest.ContentLength = $FileContent.Length
# Get Stream Request by bytes
$Run = $FTPRequest.GetRequestStream()
$Run.Write($FileContent, 0, $FileContent.Length)
# Cleanup
$Run.Close()
$Run.Dispose()
}else{
    write-host "File Already Run"
}
