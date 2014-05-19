#######################

$ErrorActionPreference = "Stop"
$Script:dtutil = $null
$Script:dtexec = $null
$exitCode = @{
    0="The utility executed successfully."
    1="The utility failed."
    4="The utility cannot locate the requested package."
    5="The utility cannot load the requested package."
    6="The utility cannot resolve the command line because it contains either syntactic or semantic errors"
}

[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ManagedDTS") > $null

#######################
function Get-SqlVersion
{
    param($ServerInstance)
    
    Write-Host "Getting SQL Server version for [$ServerInstance]."
    
    #write-verbose "sqlcmd -S `"$ServerInstance`" -d `"master`" -Q `"SET NOCOUNT ON; SELECT SERVERPROPERTY('ProductVersion')`" -h -1 -W"

    $SqlVersion = sqlcmd -S "$ServerInstance" -d "master" -Q "SET NOCOUNT ON; SELECT SERVERPROPERTY('ProductVersion')" -h -1 -W
<#
    if ($lastexitcode -ne 0) {
        Write-Host "SqlVersion could not be established [$SqlVersion]."
        Exit 1
    }
    else {
        Write-Host "SqlVersion established to be [$SqlVersion]."
        $SqlVersion
    }
#>  
    return $SqlVersion  
} #Get-SqlVersion

function Set-DtsPaths {
    param($SqlVersion)
    
    $Script:dtexec = 'DTExec';
    $Script:dtutil += 'dtutil';

    $dtutilPath = $false;
    $dtExecPath = $false;

    if(Get-Command $Script:dtutil  -errorAction SilentlyContinue){ $dtutilPath=$true }
    if(Get-Command $Script:dtexec  -errorAction SilentlyContinue){ $dtexecPath=$true }

    if(-not $dtexecPath -or -not $dtutilPath){
        $SqlShort=""
        if($SqlVersion.indexOf(".") -eq -1){
            $SqlShort=$SqlVersion
        }
        else{
            $SqlShort = $SqlVersion.subString(0, $SqlVersion.indexOf(".")) +'0';
        }

        $paths = [Environment]::GetEnvironmentVariable("Path", "Machine") -split ";"

        $dtsPath = $paths | where { 
            $_ -like "*Microsoft SQL Server\$SqlShort\DTS\Binn\" 
        }

        if ($dtsPath -eq $null) {
            Write-Host "DTS path for SQL Server Version [$SqlVersion] not found."
            Exit 1
        }
        else {
            if(-not $dtexecPath){
                $Script:dtexec = $dtsPath + 'DTExec.exe'
            }
            if(-not $dtutilPath){
                $Script:dtutil = $dtsPath + 'dtutil.exe'
            }
        }
    }
}
  
#######################
function Install-Package
{
    param($DtsxFullName, $ServerInstance, $PackageFullName)

    $result = & $Script:dtutil /File "$DtsxFullName" /DestServer "$ServerInstance" /Copy SQL`;"$PackageFullName" /Quiet
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Cannot install package at [$PackageFullName]. $result"
        Exit 1
    }
} #install-package

#######################
function Get-DtExecPropertyPathValue() {
    param(
        $NameSpace = 'User',
        $PropertyName = '',
        $Value = ''
    );
    "\Package.Variables[$NameSpace::$PropertyName].Properties[Value];$Value"
}

function Execute-Package
{
    param($PackageFullName, $ServerInstance, $Parameters)

    $result = & $Script:dtexec /Rep V /Server "$ServerInstance" /SQL "$PackageFullName" $Parameters
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host $result
        Write-Host "Failed to execute package at [$PackageFullName]. Last exit code: [$lastexitcode]."
        Exit 1
    }

    <#
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Cannot execute package on [$ServerInstance]."
        Exit 1
    }
    #>

} #install-package

#######################
function Remove-Package
{
    param($ServerInstance, $PackageFullName)
    
    $result = & $Script:dtutil /SourceServer "$ServerInstance" /SQL "$PackageFullName" /Delete /Quiet
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Failed to remove package at [$PackageFullName]. Last exit code: [$lastexitcode]."
        Exit 1
    }

} #remove-package


#######################
function Test-Packagepath
{
    param($ServerInstance, $PackageFullName)

    #write-verbose "$Script:dtutil /SourceServer `"$ServerInstance`" /SQL `"$PackageFullName`" /EXISTS"
    
    $result = & $Script:dtutil /SourceServer "$ServerInstance" /SQL "$PackageFullName" /EXISTS

    if ($lastexitcode -eq 0 -and $result -and $result[4] -eq "The specified package exists.") {
        $true
    }
    else{
    	$false
    }

} #test-packagepath

#######################
function New-ISApplication
{
   new-object ("Microsoft.SqlServer.Dts.Runtime.Application") 

} #New-ISApplication

#######################
function Test-ISPath
{
    param([string]$path=$(throw 'path is required.'), [string]$serverName=$(throw 'serverName is required.'), [string]$pathType='Any')

    #If serverName contains instance i.e. server\instance, convert to just servername:
    $serverName = $serverName -replace "\\.*"

    #Note: Don't specify instance name

    $app = New-ISApplication

    switch ($pathType)
    {
        'Package' { trap { $false; continue } $app.ExistsOnDtsServer($path,$serverName) }
        'Folder'  { trap { $false; continue } $app.FolderExistsOnDtsServer($path,$serverName) }
        'Any'     { $p=Test-ISPath $path $serverName 'Package'; $f=Test-ISPath $path $serverName 'Folder'; [bool]$($p -bor $f)}
        default { throw 'pathType must be Package, Folder, or Any' }
    }

} #Test-ISPath

#######################
function Get-ISPackage
{
    param([string]$path, [string]$serverName)

    #If serverName contains instance i.e. server\instance, convert to just servername:
    $serverName = $serverName -replace "\\.*"

    $app = New-ISApplication

    #SQL Server Store
    if ($path -and $serverName)
    { 
        if (Test-ISPath $path $serverName 'Package')
        { $app.LoadFromDtsServer($path, $serverName, $null) }
        else
        { Write-Error "Package $path does not exist on server $serverName" }
    }
    #File Store
    elseif ($path -and !$serverName)
    { 
        if (Test-Path -literalPath $path)
        { $app.LoadPackage($path, $null) }
        else
        { Write-Error "Package $path does not exist" }
    }
    else
    { throw 'You must specify a file path or package store path and server name' }
    
} #Get-ISPackage

#######################
function New-Folder
{
    param($ServerInstance, $ParentFolderPath, $NewFolderName)

    $result = & $Script:dtutil /SourceServer "$ServerInstance" /FCreate SQL`;"$ParentFolderPath"`;"$NewFolderName"
    $result = $result -join "`n"

    if ($lastexitcode -ne 0) {
        Write-Host "Cannot create folder [$NewFolderName] for package [$PackageFullName]."
        Exit 1
    }

} #new-folder

#######################
function Get-FolderList
{
    param($PackageFullName)

    if ($PackageFullName -match '\\') {
        $folders = $PackageFullName  -split "\\"
        0..$($folders.Length -2) | foreach { 
        new-object psobject -property @{
            Parent=$(if($_-gt 0) { $($folders[0..$($_ -1)] -join "\") } else { "\" })
            FullPath=$($folders[0..$_] -join "\")
            Child=$folders[$_]}}
    }

} #Get-FolderList