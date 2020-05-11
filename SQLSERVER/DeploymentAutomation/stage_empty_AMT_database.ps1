<#
Requirements:
1. Get-Module sqlserver

2. If the sqlserver Module is not installed then start Powershell with Administrative access and execute:
   install-module sqlserver
   import-module sqlserver

3. (Optional) Set the $serv_prov_code variable to create a multi-line list of agencies
$serv_prov_codes = @(
'ALABAMA'
'ARCHCO'
)

4. (Optional) Set the $servers variable to create a multi-line list of database servers. 
*The primary instance should always be first in the $servers list
$servers = @(
'10.150.128.11,14331'
'10.150.128.10,14331'
'10.150.128.12,14331'
)

5. Execute the script using multi-line lists
.\stage_empty_AMT_database.ps1 -serv_prov_codes $serv_prov_codes -Servers $servers
or use a delimited list on the command line
*The primary instance should always be first in the -Servers list
.\stage_empty_AMT_database.ps1 -serv_prov_codes ALABAMA,TACOMA -Servers '10.150.128.11,14331','10.150.128.11,14331','10.150.128.11,14331'

6. Copy the output passwords to LastPass at ("Shared-Accela-DB-Credentials" -> "NONPROD Azure DB Credentials")

7. To reset Login passwords, follow steps 1-4 and then execute the script with the -ResetLoginPasswords switch
.\stage_empty_AMT_database.ps1 -serv_prov_codes $serv_prov_codes -Servers $servers -ResetLoginPasswords 

8. Copy the output passwords to LastPass at ("Shared-Accela-DB-Credentials" -> "NONPROD Azure DB Credentials")
#>

param(
  [Array]$serv_prov_codes,
  [Array]$servers,
  [Switch]$ResetLoginPasswords
)

Add-Type -AssemblyName System.web
 
function Copy-SQLLogins{
    [cmdletbinding()]
    param([parameter(Mandatory=$true)][string] $source
            ,[string] $ApplyTo
            ,[string[]] $logins
            ,[string] $outputpath=([Environment]::GetFolderPath("MyDocuments")))
#Load assemblies
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
 
#create initial SMO object
$smosource = new-object ('Microsoft.SqlServer.Management.Smo.Server') $source
 
#Make sure we script out the SID
$so = new-object microsoft.sqlserver.management.smo.scriptingoptions
$so.LoginSid = $true
 
$outfile = 'script_logins.sql'
Remove-Item -Path $outfile
 
#If no logins explicitly declared, assume all non-system logins
if(!($logins)){
    $logins = ($smosource.Logins | Where-Object {$_.IsSystemObject -eq $false}).Name.Trim()
}
 
foreach($loginname in $logins){
    #get login object
    $login = $smosource.Logins[$loginname]
 
    #Script out the login, remove the "DISABLE" statement included by the .Script() method
    $lscript = $login.Script($so) | Where {$_ -notlike 'ALTER LOGIN*DISABLE'}
    $lscript = $lscript -join ' '
 
    #If SQL Login, sort password, insert into script
    if($login.LoginType -eq 'SqlLogin'){
 
      $sql = "SELECT convert(varbinary(256),password_hash) as hashedpass FROM sys.sql_logins where name='"+$loginname+"'"
      $hashedpass = ($smosource.databases['tempdb'].ExecuteWithResults($sql)).Tables.hashedpass
      $passtring = ConvertTo-SQLHashString $hashedpass
      $rndpw = $lscript.Substring($lscript.IndexOf('PASSWORD'),$lscript.IndexOf(', SID')-$lscript.IndexOf('PASSWORD'))
 
      $comment = $lscript.Substring($lscript.IndexOf('/*'),$lscript.IndexOf('*/')-$lscript.IndexOf('/*')+2)
      $lscript = $lscript.Replace($comment,'')
      $lscript = $lscript.Replace($rndpw,"PASSWORD = $passtring HASHED")
    }
 
    #script login to out file
    $lscript | Out-File -Append -FilePath $outfile
 
    #if ApplyTo is specified, execute the login creation on the ApplyTo instance
    If($ApplyTo){
        $smotarget = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ApplyTo
 
        if(!($smotarget.logins.name -contains $loginname)){
            $smotarget.Databases['tempdb'].ExecuteNonQuery($lscript)
            $outmsg='Login ' + $login.name + ' created.'
            }
        else{
            $outmsg='Login ' + $login.name + ' skipped, already exists on target.'
            }
        Write-Verbose $outmsg
    }
  }
}
 
function ConvertTo-SQLHashString {
  param([parameter(Mandatory=$true)] $binhash)
 
  $outstring = '0x'
  $binhash | ForEach-Object {$outstring += ('{0:X}' -f $_).PadLeft(2, '0')}
 
  return $outstring
}

function Get-CustomPassword {
  return -join ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNPPQRSTUVWXYZ01234567890123456789$$$!!!@@@???'.ToCharArray() | Get-Random -Count 15);
}
 
foreach ($serv_prov_code in $serv_prov_codes) 
{
  $primary_server = $null
  $i = 0
  foreach ($server in $servers) 
  {
    if ($ResetLoginPasswords) 
    {
      if ($i -eq 0)
      {
        $script:password = Get-CustomPassword
        Write-Output "$(${serv_prov_code}.ToLower()) ${script:password}"

        $script:Password_adhoc = Get-CustomPassword
        Write-Output "$(${serv_prov_code}.ToLower())_adhoc ${script:password_adhoc}"

        $script:Password_report = Get-CustomPassword
        Write-Output "$(${serv_prov_code}.ToLower())_report ${script:password_report}"

        Write-Output ""
        $i += 1;
      }
      
      $alter_login = "ALTER LOGIN $(${serv_prov_code}.ToLower()) WITH PASSWORD = '${script:password}'"
      Invoke-Sqlcmd -ServerInstance $server -Database master -Query $alter_login -AbortOnError -QueryTimeout 200 -Verbose
      
      $alter_login = "ALTER LOGIN $(${serv_prov_code}.ToLower())_adhoc WITH PASSWORD = '${script:password_adhoc}'"
      Invoke-Sqlcmd -ServerInstance $server -Database master -Query $alter_login -AbortOnError -QueryTimeout 200 -Verbose
      
      $alter_login = "ALTER LOGIN $(${serv_prov_code}.ToLower())_report WITH PASSWORD = '${script:password_report}'"
      Invoke-Sqlcmd -ServerInstance $server -Database master -Query $alter_login -AbortOnError -QueryTimeout 200 -Verbose
    } 
    else 
    {
      if ($i -eq 0) 
      {
        Add-DnsServerResourceRecordCName -ComputerName "us.accela.com" -ZoneName "us.accela.com" -Name "$(${serv_prov_code}.ToLower()).supp.db" -HostNameAlias "sdbctr05ag02.us.accela.com."
        Get-DnsServerResourceRecord      -ComputerName "us.accela.com" -ZoneName "us.accela.com" -Name "$(${serv_prov_code}.ToLower()).supp.db"
        
        $primary_server = $server
        
        Invoke-Sqlcmd -ServerInstance $server -Database master -Query "create database ${serv_prov_code};" -AbortOnError -QueryTimeout 200 -Verbose
        
        $Password = Get-CustomPassword
        Write-Host "$(${serv_prov_code}.ToLower()) ${Password}"
        $create_login = "If not exists (select * from sys.server_principals where name = '$(${serv_prov_code}.ToLower())') CREATE LOGIN $(${serv_prov_code}.ToLower()) WITH PASSWORD = '${Password}', DEFAULT_DATABASE = ${serv_prov_code}, CHECK_POLICY = ON, CHECK_EXPIRATION = OFF"
        Invoke-Sqlcmd -ServerInstance $server -Database master -Query $create_login -AbortOnError -QueryTimeout 200 -Verbose
        
        $Password = Get-CustomPassword
        Write-Host "$(${serv_prov_code}.ToLower())_adhoc ${Password}"
        $create_login_adhoc = "If not exists (select * from sys.server_principals where name = '$(${serv_prov_code}.ToLower())_adhoc')  CREATE LOGIN $(${serv_prov_code}.ToLower())_adhoc WITH PASSWORD = '${Password}', DEFAULT_DATABASE = ${serv_prov_code}, CHECK_POLICY = ON, CHECK_EXPIRATION = OFF"
        Invoke-Sqlcmd -ServerInstance $server -Database master -Query $create_login_adhoc -AbortOnError -QueryTimeout 200 -Verbose
        
        $Password = Get-CustomPassword
        Write-Host "$(${serv_prov_code}.ToLower())_report ${Password}"
        $create_login_report = "If not exists (select * from sys.server_principals where name = '$(${serv_prov_code}.ToLower())_report') CREATE LOGIN $(${serv_prov_code}.ToLower())_report WITH PASSWORD = '${Password}', DEFAULT_DATABASE = ${serv_prov_code}, CHECK_POLICY = ON, CHECK_EXPIRATION = OFF"
        Invoke-Sqlcmd -ServerInstance $server -Database master -Query $create_login_report -AbortOnError -QueryTimeout 200 -Verbose
        
        $create_users = @"
use ${serv_prov_code}
if not exists (select * from sys.database_principals where name='db_executer') create role db_executer;
grant execute to db_executer;
 
if not exists (select * from sys.database_principals where name='Adhoc') create role Adhoc;
--grant insert, update, delete, select on RADHOC_CUSTOM_DATA to Adhoc;
--grant insert, update, delete, select on RADHOC_REPORTS to Adhoc;
 
if not exists (select 1 from sys.database_principals where name='${serv_prov_code}') create user ${serv_prov_code} for login ${serv_prov_code};
exec sp_addrolemember 'db_datareader', '${serv_prov_code}';
exec sp_addrolemember 'db_datawriter', '${serv_prov_code}';
exec sp_addrolemember 'db_executer'  , '${serv_prov_code}';
 
if not exists (select 1 from sys.database_principals where name='${serv_prov_code}_adhoc') create user ${serv_prov_code}_adhoc for login ${serv_prov_code}_adhoc;
exec sp_addrolemember 'db_datareader', '${serv_prov_code}_adhoc';
Exec sp_addrolemember 'adhoc', '${serv_prov_code}_adhoc'
 
if not exists (select 1 from sys.database_principals where name='${serv_prov_code}_report') create user ${serv_prov_code}_report for login ${serv_prov_code}_report;
exec sp_addrolemember 'db_datareader', '${serv_prov_code}_report';
exec sp_addrolemember 'db_executer'  , '${serv_prov_code}_report';
go
"@;
        Invoke-Sqlcmd -ServerInstance $server -Database $serv_prov_code -Query $create_users -AbortOnError -QueryTimeout 200 -Verbose
      }
      else
      {
        Copy-SQLLogins -source $primary_server -ApplyTo $server -logins @("$(${serv_prov_code}.ToLower())","$(${serv_prov_code}.ToLower())_adhoc","$(${serv_prov_code}.ToLower())_report")
      }
      $i += 1
    }
  }
}
