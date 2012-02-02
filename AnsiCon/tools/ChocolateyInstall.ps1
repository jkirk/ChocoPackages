$packageName = ''
$fileType = ''
$silentArgs = ''
$url = 'http://adoxa.110mb.com/ansicon/ansi140.zip'
$url64bit = ''

Install-ChocolateyPackage $packageName $fileType $silentArgs $url $url64bit

$unzipLocation = Join-Path $env:TEMP "chocolatey" | Join-Path "$packageName"
$file = Join-Path $unzipLocation "$($packageName)Install.zip"
$toolsDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
$contentDir = $($toolsDir | Split-Path | Join-Path -ChildPath "content")

#Install-ChocolateyZipPackage $packageName $url $unzipLocation

# Add a symlink/batch file to the path
$binary = $packageName
$exePath = "$binary\$binary.exe"
$useSymLinks = $false # You can set this value to $true if the executable does not depend on external dlls

# If the program installs somewhere other than "Program Files"
# set the $programFiles variable accordingly
$is64bit = (Get-WmiObject Win32_Processor).AddressWidth -eq 64
$programFiles = $env:programfiles
if ($is64bit) {
    if($url64bit){
        $programFiles = $env:ProgramW6432}
    else{
        $programFiles = ${env:ProgramFiles(x86)}
        }
}

try {
    $executable = join-path $programFiles $exePath
    $fsObject = New-Object -ComObject Scripting.FileSystemObject
    $executable = $fsObject.GetFile("$executable").ShortPath

    $symLinkName = Join-Path $nugetExePath "$binary.exe"
    $batchFileName = Join-Path $nugetExePath "$binary.bat"

    # delete the batch file if it exists.
    if(Test-Path $batchFileName){
      Remove-Item "$batchFileName"}

    if($useSymLinks -and ((gwmi win32_operatingSystem).version -ge 6)){
        Start-ChocolateyProcessAsAdmin "if(Test-Path $symLinkName){Remove-Item $symLinkName}; $env:comspec /c mklink /H $symLinkName $executable"
      }
    else{
    "@echo off
    start $executable %*" | Out-File $batchFileName -encoding ASCII
        }
    Write-ChocolateySuccess $packageName
} catch {
  Write-ChocolateyFailure $packageName "$($_.Exception.Message)"
  throw
}