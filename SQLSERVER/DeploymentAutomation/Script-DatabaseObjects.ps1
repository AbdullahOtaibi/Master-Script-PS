<#
.SYNOPSIS
	Exports an Accela AA database's worth of DDL statements for tables, views, indexes, and more to be used as the base schema in deployment packages.
.DESCRIPTION
	This script will take all the Accela AA database's objects and script them out to separate files in the desiganted folder.
.PARAMETER serverName
	The name of the server you want to get the objects from.
.PARAMETER instanceName
	The instance name of the server you want to get the objects from. Defaults to DEFAULT if not provided (for non-named instances). This is an optional parameter.
.PARAMETER databaseName
	The instance name of the database you want to collect object DDL information from. The script will collect all databases and all objects if not provided. This is an optional parameter.
.PARAMETER sqlAuthCredential
    The PSCredential object holding the credentials used for SQL Authentication. This is an optional parameter.
    Example: 
        $username="testuser"
        $pass = ConvertTo-SecureString "testuserpassword" -AsPlainText -Force
        $securecred = New-Object System.Management.Automation.PSCredential ($username, $pass)
.PARAMETER filePath
	The full path to the target folder. Does not need to exist. This parameter is required.
.EXAMPLE
	./Get-DatabaseObjects.ps1 -servName "localhost" -databaseName "AdventureWorks2014" -filePath "C:\temp"
	Connects to a locally hosted instace of SQL Server, scripts out all objects in the database, and creates a set of .sql files in the C:\temp directory of the local machine.
.OUTPUTS
	None, unless -Verbose is specified. In fact, -Verbose is reccomended so you can see what's going on and when.
.NOTES
#>
param(
    [Parameter(Mandatory=$true)]  [string] $serverName,
    [Parameter(Mandatory=$false)] [string] $instanceName = "DEFAULT",
    [Parameter(Mandatory=$false)] [string] $databaseName,
    [Parameter(Mandatory=$false)] [PSCredential] $sqlAuthCredential,
    [Parameter(Mandatory=$false)] [string] $filePath
)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force;

if ($(Get-Module SqlServer).Name -eq "") { Import-Module SqlServer }

$scanDate = Get-Date
$timestamp = Get-Date -UFormat "%Y%m%d_%H%M%S"

Write-Verbose "Starting script"
Write-Verbose "Creating folder structure"
# create the folder structure
if (!( Test-Path -path "$filePath\$timestamp" )) { # create it if not existing
    Try { New-Item "$filePath\$timestamp" -type Directory | Out-Null }
    Catch [system.exception] {
        Write-Error "Error while creating '$filePath\$timestamp' $_"
        Return
    }
}

Write-Verbose "Creating database connection objects..."

$serverPath = "SQLSERVER:\SQL\$serverName\$instanceName\databases"
$smoServerName = $serverName
if ($instanceName -ne "DEFAULT") {$smoServerName = $serverName + "\" + $instanceName}
# $databases = Get-ChildItem -Path $serverPath
# if ($databaseName) { $databases = $databases | Where-Object {$_.Name -eq $databaseName} }

# start script options - see "https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.management.smo.scriptingoptions.aspx" for details
Write-Verbose "Setting SqlServer.Management.SMO.Scripter options..."
$scriptingSrv = New-Object Microsoft.SqlServer.Management.Smo.Server ($smoServerName)
if (!$sqlAuthCredential) {
    Write-Verbose "Windows Authentication selected"
    # use Windows Authentication
    $scriptingSrv.ConnectionContext.LoginSecure = $true
}
else {
    Write-Verbose "SQL Authentication selected"
    # use SQL Authentication
    $scriptingSrv.ConnectionContext.StatementTimeout = 0
    $scriptingSrv.ConnectionContext.LoginSecure = $false
    $scriptingSrv.ConnectionContext.Login=$username
    $scriptingSrv.ConnectionContext.set_SecurePassword($securecred.Password)

}
$scriptingOptions = New-Object Microsoft.SqlServer.Management.Smo.Scripter ($scriptingSrv)
$scriptingOptions.Options.BatchSize = 1
$scriptingOptions.Options.ScriptBatchTerminator = $true
$scriptingOptions.options.DriPrimaryKey = $false # do not script primary key constraints as part of the CREATE TABLE statement 
$scriptingOptions.Options.AppendToFile = $true
$scriptingOptions.Options.ScriptSchema = $true
$scriptingOptions.Options.ScriptData = $false

# get the list of databases
$databases = Get-ChildItem -Path $serverPath
if ($databaseName) { $databases = $databases | Where-Object {$_.Name -eq $databaseName} }

Write-Verbose "Server name that contains objects to collect: $serverName\$instanceName"


function ScriptObjects($dbn, $objects, $typeName) {
    $totalObjects = 0;
    if ($objects.length -ne $null) { $totalObjects = $objects.length }
    $statusMessage = "Scripting: " + $typename + " which has " + $totalObjects + " objects"
    Write-Verbose $statusMessage
    if ($totalObjects -gt 0) {
        foreach ($o in $objects) { 
            if ($o -ne $null) {
                $objectCode = $scriptingOptions.Script($o)
            }
        }
    }
}

function ScriptData($dbn, $objects, $typeName) {
    $totalObjects = 0;
    if ($objects.length -ne $null) { $totalObjects = $objects.length }
    $statusMessage = "Scripting: " + $typename + " which has " + $totalObjects + " objects"
    Write-Verbose $statusMessage
    if ($totalObjects -gt 0) {
        foreach ($s in $scriptingOptions.EnumScript($objects.Urn)) { <# just do it! #> }
    }
}

[string] $fileName = "";

foreach ($d in $databases) {
    $currentDatabase = $d.Name
    Write-Verbose "Scanning database: $currentDatabase"
    
    # ---------- FILE: 1_create_database_and_user_mssql.sql ----------

    # ---------- FILE: 2_create_tables.sql ----------
    $fileName = "$filePath\$timestamp\2_create_tables.sql";
    $scriptingOptions.options.FileName = $fileName
    Write-Verbose "Writing file $fileName"
    # all user-defined schemas (there shouldn't be any)
    ScriptObjects $currentDatabase ($d.Schemas | Where-Object { -Not $_.IsSystemObject }) "Schemas"
    # export ONLY these functions
    ScriptObjects $currentDatabase ($d.UserDefinedFunctions | Where-Object { $_.Name -In ("FN_IS_DATE", "FN_IS_NUMERIC") } ) "Functions"
    # all tables
    ScriptObjects $currentDatabase ($d.Tables | Where-Object { -Not $_.IsSystemObject }) "Tables"
    Write-Verbose "----------"

    # ---------- FILE: 3_create_views.sql ----------
    $fileName = "$filePath\$timestamp\3_create_views.sql";
    $scriptingOptions.options.FileName = $fileName
    Write-Verbose "Writing file $fileName"
    # export ONLY these functions
    ScriptObjects $currentDatabase ($d.UserDefinedFunctions | Where-Object { $_.Name -In ("CONVERTBYTES") } ) "Functions"
    # all views
    ScriptObjects $currentDatabase ($d.Views | Where-Object { -Not $_.IsSystemObject }) "Views"
    Write-Verbose "----------"

    # ---------- FILE: 4_create_fun_packages.sql ----------
    $fileName = "$filePath\$timestamp\4_create_fun_packages.sql";
    $scriptingOptions.options.FileName = $fileName
    Write-Verbose "Writing file $fileName"
    # export all functions EXCEPT the above
    ScriptObjects $currentDatabase ($d.UserDefinedFunctions | Where-Object { -Not $_.IsSystemObject } | Where-Object { $_.Name -NotIn ("CONVERTBYTES", "FN_IS_DATE", "FN_IS_NUMERIC") } ) "Functions"
    # export all stored procedures
    ScriptObjects $currentDatabase ($d.StoredProcedures | Where-Object { -Not $_.IsSystemObject }) "Stored Procedures"
    Write-Verbose "----------"

    # ---------- FILE: 5_initial_data.sql ----------
    $fileName = "$filePath\$timestamp\5_initial_data.sql";
    $scriptingOptions.options.FileName = $fileName
    # set options to script data
    $scriptingOptions.Options.ScriptSchema = $false
    $scriptingOptions.Options.ScriptData = $true
    Write-Verbose "Writing file $fileName"
    # all tables
    ScriptData $currentDatabase ($d.Tables | Where-Object { -Not $_.IsSystemObject }) "Tables"
    # reset options
    $scriptingOptions.Options.ScriptSchema = $true
    $scriptingOptions.Options.ScriptData = $false

    # ---------- FILE: 6_initial_data.sql ----------
    # TODO: Split the data file into two equally sized files

    # ---------- FILE: 7_misc.sql ----------
    $fileName = "$filePath\$timestamp\7_misc.sql";
    $scriptingOptions.options.FileName = $fileName
    Write-Verbose "Writing file $fileName"
    # export all clustered indexes
	ScriptObjects $currentDatabase ($d.tables.indexes | Where-object { -Not $_.IsSystemObject -and ($_.IndexKeyType.ToString()) -eq "DriPrimaryKey"}) "Indexes"
    # export all nonclustered indexes
	ScriptObjects $currentDatabase ($d.tables.indexes | Where-object { -Not $_.IsSystemObject -and ($_.IndexKeyType.ToString()) -ne "DriPrimaryKey"}) "Indexes"
    # export all foreign keys
	ScriptObjects $currentDatabase ($d.tables.foreignKeys | Where-object { -Not $_.IsSystemObject }) "Foreign Keys"
    Write-Verbose "----------"
}
# clean up
$scriptingSrv = $null
$scriptingOptions = $null
Write-Verbose "Scripting complete"
