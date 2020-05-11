<#
.SYNOPSIS
	Exports an Agency's transactional data to disk.
.DESCRIPTION
	Exports an Agency's transactional data to to a separate database, backs up the database to the specified location, then drop the database.
.PARAMETER server
	The SQL Server name, including instance and/or TCP port. This parameter is mandatory.
.PARAMETER db_accela
  The AA database name. This parameter is mandatory.
.PARAMETER db_jetspeed
  The Jetspeed database name. This parameter is mandatory.
.PARAMETER db_user
  The SQL Login name that will be used to connect to the SQL Server database. If not defined the script will use Windows Authentication. This parameter is NOT mandatory.
.PARAMETER db_pass
  The password for the SQL Login defined in the db_user parameter. This parameter is NOT mandatory if Windows Authentication is used.
.PARAMETER serv_prov_code
  The Agency code/identifier. This parameter is mandatory.
.PARAMETER backupFolder
  The server location where the backup will be stored. This parameter is mandatory.
.EXAMPLE
	.\Export-Agency.ps1 -server "ACCC-DB01" -db_accela "AccelaTest" -db_jetspeed "JetspeedTest" -db_user "AccelaTest" -db_pass "pw4Accela1" -serv_prov_code "NEWMARKET" -backupFolder "E:\Backup" -Verbose
    Exports Agency data to an alternate database using SQL Authentication.
  
  .\Export-Agency.ps1 -server "ACCC-DB01" -db_accela "AccelaTest" -db_jetspeed "JetspeedTest" -serv_prov_code "NEWMARKET" -backupFolder "E:\Backup" -Verbose
    Exports Agency data to an alternate database using Windows Authentication.
.OUTPUTS
	None, unless -Verbose is specified. In fact, -Verbose is recommended so you can see what's going on and when.
.NOTES
  Add some notes for the operator here.
#>
param(
    [Parameter(Mandatory=$true)]  [string]  $server,
    [Parameter(Mandatory=$true)]  [string]  $db_accela,
    [Parameter(Mandatory=$true)]  [string]  $db_jetspeed,
    [Parameter(Mandatory=$false)] [string]  $db_user,
    [Parameter(Mandatory=$false)] [string]  $db_pass,
    [Parameter(Mandatory=$true)]  [string]  $serv_prov_code,
    [Parameter(Mandatory=$true)]  [string]  $backupFolder
)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force;
[string] $TSqlCmd = "";
[string] $date_time = (Get-Date -Format yyyyMMddHHmmss).ToString()

# internal function to execute TSQL command/s using either SQL or Windows Authentication
function Execute-Sqlcmd ([string] $Sqlcmd) {
  # use Windows Authentication
  if ($db_user -eq "") { Invoke-Sqlcmd -ServerInstance $server -Database $db_accela -Query $Sqlcmd -QueryTimeout 3600 }
  # use SQL Authentication
  else { Invoke-Sqlcmd -ServerInstance $server -Database $db_accela -Query $Sqlcmd -Username $db_user -Password $db_pass -QueryTimeout 3600 }
  # Write-Host $Sqlcmd
  return
}


$TSqlCmd = "SELECT APO_SRC_SEQ_NBR FROM dbo.RSERV_PROV WHERE SERV_PROV_CODE = '${serv_prov_code}'"
$src = Execute-Sqlcmd -Sqlcmd $TSqlCmd | Select-Object -Property apo_src_seq_nbr
$source_seq_nbr = $src.apo_src_seq_nbr
Write-Output $source_seq_nbr

Write-Output "Creating temporary database export_${serv_prov_code}_${date_time}"
$TSqlCmd = "CREATE DATABASE [export_${serv_prov_code}_${date_time}];"
Execute-Sqlcmd -Sqlcmd $TSqlCmd
$TSqlCmd = "ALTER DATABASE [export_${serv_prov_code}_${date_time}] SET RECOVERY BULK_LOGGED;"
Execute-Sqlcmd -Sqlcmd $TSqlCmd

Write-Output "Performing Dynamic SQL CTAS and INSERT statements"
$TSqlCmd = "SET NOCOUNT ON;
DECLARE @cjob as CURSOR;
DECLARE @cjob_import as CURSOR;
DECLARE @sql_create as NVARCHAR(max);
DECLARE @sql_insert as NVARCHAR(max);
DECLARE @sql_import as NVARCHAR(max);

WITH tab_cols AS (
    SELECT t.table_name, s.name column_name
    FROM (
        SELECT object_id, name table_name 
        FROM sys.tables 
        WHERE SCHEMA_NAME(schema_id) = 'dbo'
        AND name IN (
            SELECT object_name
            FROM dbo.aa_objects
            WHERE object_type = 'TABLE')
        ) t
        INNER JOIN sys.all_columns s ON s.object_id = t.object_id
    WHERE s.name IN (
        'SERV_PROV_CODE', --SPC
        'SOURCE_SEQ_NBR', --SRC
        'AGENCY', --SPC
        'GEN_SOURCE', --SRC
        'TENANTID', --SPC
        'ACTION_BY_ORGANIZATION_ID' --SPC
        )
    AND NOT (t.table_name = 'GLUCENE_AUDIT_DATA' AND s.name = 'SERV_PROV_CODE')
),
expdp_temp AS (
    SELECT table_name,
        STUFF((
            SELECT ' OR ' + 
                CASE tc2.column_name
                    WHEN 'SERV_PROV_CODE' THEN ' SERV_PROV_CODE=''${serv_prov_code}'' '
                    WHEN 'SOURCE_SEQ_NBR' THEN ' SOURCE_SEQ_NBR=''${source_seq_nbr}'' '
                    WHEN 'AGENCY' THEN ' AGENCY=''${serv_prov_code}'' '
                    WHEN 'GEN_SOURCE' THEN ' GEN_SOURCE=''${source_seq_nbr}'' '
                    WHEN 'TENANTID' THEN ' TENANTID=''${serv_prov_code}'' '
                    WHEN 'ACTION_BY_ORGANIZATION_ID' THEN ' ACTION_BY_ORGANIZATION_ID=''${serv_prov_code}'' '
                END
            FROM tab_cols tc2
            WHERE tc2.table_name = tc.table_name
            ORDER BY tc2.table_name
            FOR XML PATH('')), 1, LEN(' OR '), ''
        ) AS columns_where
    FROM tab_cols tc
    GROUP BY tc.table_name
)
SELECT sql_create,
       sql_insert,
       sql_import
INTO #export_${serv_prov_code}_${date_time}
FROM (
SELECT 'IF NOT EXISTS (SELECT * FROM export_${serv_prov_code}_${date_time}.sys.tables WHERE name = N''' + table_name + ''') SELECT * INTO export_${serv_prov_code}_${date_time}.dbo.' + table_name + ' FROM ${db_accela}.dbo.' + table_name + ' WHERE 1=2;' sql_create,
       'INSERT INTO export_${serv_prov_code}_${date_time}.dbo.' + table_name + ' WITH (TABLOCK) SELECT * FROM ${db_accela}.dbo.' + table_name + ' WHERE ' + columns_where + ';' sql_insert,
       'INSERT INTO [<import_database_accela>].[<import_schema_accela>].' + table_name + ' SELECT * FROM export_${serv_prov_code}_${date_time}.dbo.' + table_name + ';' sql_import
FROM expdp_temp
UNION ALL
SELECT 'SELECT * INTO export_${serv_prov_code}_${date_time}.dbo.TURBINE_USER FROM ${db_jetspeed}.dbo.TURBINE_USER WHERE 1=2;' sql_create,
       'SET IDENTITY_INSERT export_${serv_prov_code}_${date_time}.dbo.TURBINE_USER ON; ' +
       'INSERT INTO export_${serv_prov_code}_${date_time}.dbo.TURBINE_USER WITH (TABLOCK) (USER_ID,LOGIN_NAME,PASSWORD_VALUE,FIRST_NAME,LAST_NAME,EMAIL,CONFIRM_VALUE,MODIFIED,CREATED,LAST_LOGIN,DISABLED,OBJECTDATA,PASSWORD_CHANGED) SELECT * FROM ${db_jetspeed}.dbo.TURBINE_USER WHERE LOGIN_NAME LIKE ''${serv_prov_code}%CONSOLE'';' sql_insert,
       'INSERT INTO [<import_database_jetspeed>].[<import_schema_jetspeed>].TURBINE_USER SELECT * FROM export_${serv_prov_code}_${date_time}.dbo.TURBINE_USER;' sql_import
UNION ALL
SELECT 'SELECT * INTO export_${serv_prov_code}_${date_time}.dbo.JETSPEED_USER_PROFILE FROM ${db_jetspeed}.dbo.JETSPEED_USER_PROFILE WHERE 1=2;' sql_create,
       'SET IDENTITY_INSERT export_${serv_prov_code}_${date_time}.dbo.JETSPEED_USER_PROFILE ON; ' +
       'INSERT INTO export_${serv_prov_code}_${date_time}.dbo.JETSPEED_USER_PROFILE WITH (TABLOCK) (PSML_ID,USER_NAME,MEDIA_TYPE,LANGUAGE,COUNTRY,PAGE,PROFILE) SELECT * FROM ${db_jetspeed}.dbo.JETSPEED_USER_PROFILE WHERE USER_NAME LIKE ''%${serv_prov_code}%'';' sql_insert,
       'INSERT INTO [<import_database_jetspeed>].[<import_schema_jetspeed>].JETSPEED_USER_PROFILE SELECT * FROM export_${serv_prov_code}_${date_time}.dbo.JETSPEED_USER_PROFILE;' sql_import
UNION ALL
SELECT 'SELECT * INTO export_${serv_prov_code}_${date_time}.dbo.PUBLICUSER FROM ${db_accela}.dbo.PUBLICUSER WHERE 1=2;' sql_create,
       'INSERT INTO export_${serv_prov_code}_${date_time}.dbo.PUBLICUSER WITH (TABLOCK) SELECT * FROM ${db_accela}.dbo.PUBLICUSER WHERE USER_SEQ_NBR IN (SELECT USER_SEQ_NBR FROM ${db_accela}.dbo.XPUBLICUSER_SERVPROV WHERE SERV_PROV_CODE=''${serv_prov_code}'');' sql_insert,
       'INSERT INTO [<import_database_accela>].[<import_schema_accela>].PUBLICUSER SELECT * FROM export_${serv_prov_code}_${date_time}.dbo.PUBLICUSER;' sql_import
UNION ALL
SELECT 'SELECT * INTO export_${serv_prov_code}_${date_time}.dbo.GLUCENE_AUDIT_DATA FROM ${db_accela}.dbo.GLUCENE_AUDIT_DATA WHERE 1=2;' sql_create,
       'SET IDENTITY_INSERT export_${serv_prov_code}_${date_time}.dbo.GLUCENE_AUDIT_DATA ON; ' +
       'INSERT INTO export_${serv_prov_code}_${date_time}.dbo.GLUCENE_AUDIT_DATA WITH (TABLOCK) (SERV_PROV_CODE,DATA_SEQ,TABLE_NAME,TABLE_PKS,ACTION_TYPE,REC_DATE,REC_FUL_NAM,REC_STATUS) SELECT * FROM ${db_accela}.dbo.GLUCENE_AUDIT_DATA WHERE SERV_PROV_CODE=''${serv_prov_code}'';' sql_insert,
       'INSERT INTO [<import_database_accela>].[<import_schema_accela>].GLUCENE_AUDIT_DATA SELECT * FROM export_${serv_prov_code}_${date_time}.dbo.GLUCENE_AUDIT_DATA;' sql_import
) bob;

SET @cjob = CURSOR LOCAL FORWARD_ONLY FOR
  SELECT sql_create, sql_insert FROM #export_${serv_prov_code}_${date_time};
OPEN @cjob;
FETCH NEXT FROM @cjob INTO @sql_create, @sql_insert;
WHILE (@@FETCH_STATUS = 0)
BEGIN
  PRINT @sql_create;
  BEGIN TRY
    EXECUTE sp_executesql @sql_create;
  END TRY
  BEGIN CATCH
    PRINT 'ERROR CREATE: ' + @sql_create
    PRINT ERROR_MESSAGE()
  END CATCH

  PRINT @sql_insert;
  BEGIN TRY
    EXECUTE sp_executesql @sql_insert;
  END TRY
  BEGIN CATCH
    PRINT 'ERROR INSERT: ' + @sql_insert
    PRINT ERROR_MESSAGE()
  END CATCH

  FETCH NEXT FROM @cjob INTO @sql_create, @sql_insert;
END
CLOSE @cjob;
DEALLOCATE @cjob;

SET @cjob_import = CURSOR LOCAL FORWARD_ONLY FOR
  SELECT DISTINCT sql_import FROM #export_${serv_prov_code}_${date_time};
OPEN @cjob_import;
FETCH NEXT FROM @cjob_import INTO @sql_import
WHILE (@@FETCH_STATUS = 0)
BEGIN
  PRINT @sql_import;
  FETCH NEXT FROM @cjob_import INTO @sql_import;
END
CLOSE @cjob_import;
DEALLOCATE @cjob_import;
"
Execute-Sqlcmd -Sqlcmd $TSqlCmd

Write-Output "Exporting temporary database export_${serv_prov_code}_${date_time}"
$TSqlCmd = "
USE export_${serv_prov_code}_${date_time};  
GO  
BACKUP DATABASE export_${serv_prov_code}_${date_time}  
TO DISK = '${backupFolder}\export_${serv_prov_code}_${date_time}.Bak'  
   WITH INIT, COPY_ONLY, COMPRESSION, STATS=5;
GO  
RESTORE VERIFYONLY FROM DISK = '${backupFolder}\export_${serv_prov_code}_${date_time}.Bak';
GO
"
Execute-Sqlcmd -Sqlcmd $TSqlCmd
Write-Output "Database backed up to: '${backupFolder}\export_${serv_prov_code}_${date_time}.Bak'"

Write-Output "Dropping temporary database export_${serv_prov_code}_${date_time}"
$TSqlCmd = "DROP DATABASE [export_${serv_prov_code}_${date_time}];"
Execute-Sqlcmd -Sqlcmd $TSqlCmd

Write-Output "Done."