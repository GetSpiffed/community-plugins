$PSVersionTable
Start-Sleep -s 1
Write-Host "    "

if($PSVersionTable.PSVersion.major -lt 3) {
    Write-Error "Powershell version 3 was not detected. Highest supported major version is $($PSVersionTable.PSVersion.major)"
    Exit 1
}
else {
    Write-Host "Powershell version $($PSVersionTable.PSVersion.major) was detected."
}
