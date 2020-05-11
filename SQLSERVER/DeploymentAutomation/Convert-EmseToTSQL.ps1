<#
.SYNOPSIS
	Generates TSQL "INSERT" statements from the EMSE Master scripts.
.DESCRIPTION
	Converts EMSE files to TSQL INSERT statements.
.PARAMETER SourceFolderName
	The path to the folder containing the EMSE Master scripts. This parameter is mandatory.
.PARAMETER FileExtension
	The file extension for the source files. This parameter is mandatory.
.PARAMETER DestinationSQLFileName
    The destination file name. This parameter is mandatory.
.PARAMETER ServProvCode
    The Agency code used when generating the output file. This parameter is mandatory.
.PARAMETER ReleaseVersion
    The release version used when generating the output file. This parameter is mandatory.
.PARAMETER OutputScriptSequence
    The script sequence number in the list of files packaged in the installer. This parameter is mandatory.
.PARAMETER PreviousScript
    The name of the script which sould have been executed prior to the current one. This parameter is mandatory.
.EXAMPLE
	.\Convert-EmseToTSQL.ps1 -SourceFolderName "C:\Accela-Inc\MasterScripts\MasterScripts" -FileExtension "js" -DestinationSQLFileName "C:\TEMP\19.1.4_08_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.1.4" -OutputScriptSequence 8 -PreviousScript "19.1.4_07_emse_mssql.sql" -Verbose
    Generates the file "19.1.4_08_emse_mssql.sql" for SQL Server which will be the 8th file of the release, showing Verbose output.
    Abdullah Comments: 	
	1) use command : to grant permission to enable execute the above command: 
	                                                                         Set-ExecutionPolicy RemoteSigned 
	2) below line test on abdullah PC:
	a)   .\Convert-EmseToTSQL.ps1 -SourceFolderName "C:\Users\Abdullah\Desktop\Training\Master Script\Master Script Files" -FileExtension "js" -DestinationSQLFileName "C:\Users\Abdullah\Desktop\Training\Master Script\script\19.1.4_08_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.1.4" -OutputScriptSequence 8 -PreviousScript "19.1.4_07_emse_mssql.sql" -Verbose
     or 
	b) .\Convert-EmseToTSQL.ps1 -SourceFolderName "C:\Users\Abdullah\Desktop\Training\Master Script\Master Script Files" -FileExtension "js" -DestinationSQLFileName "C:\Users\Abdullah\Desktop\Training\Master Script\script\19.2.0_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.2.0" -OutputScriptSequence 8 -PreviousScript "19.1.4_emse_mssql.sql" -Verbose
    ** new laptop command : 
    c).\Convert-EmseToTSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 19.2.3" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\19.2.3_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.2.3" -OutputScriptSequence 8 -PreviousScript "19.2.0_emse_mssql.sql" -Verbose
    d).\Convert-EmseToTSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 20.1.0" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\20.1.0_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "20.1.0" -OutputScriptSequence 8 -PreviousScript "19.2.3_emse_mssql.sql" -Verbose
    e).\Convert-EmseToTSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 19.2.2" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\19.2.2_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.2.2" -OutputScriptSequence 8 -PreviousScript "19.2.0_emse_mssql.sql" -Verbose
	f).\Convert-EmseToTSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 20.1.1" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\20.1.1_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "20.1.1" -OutputScriptSequence 8 -PreviousScript "20.1.0_emse_mssql.sql" -Verbose
   g).\Convert-EmseToTSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 20.1.2" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\20.1.2_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "20.1.2" -OutputScriptSequence 8 -PreviousScript "20.1.1_emse_mssql.sql" -Verbose 
 .OUTPUTS
	None, unless -Verbose is specified. In fact, -Verbose is recommended so you can see what's going on and when.
.NOTES
#>
param(
    [Parameter(Mandatory=$true)] [IO.FileInfo] $SourceFolderName,
    [Parameter(Mandatory=$true)] [string] $FileExtension,
    [Parameter(Mandatory=$true)] [string] $DestinationSQLFileName,
    [Parameter(Mandatory=$true)] [string] $ServProvCode,
    [Parameter(Mandatory=$true)] [string] $ReleaseVersion,
    [Parameter(Mandatory=$true)] [int] $OutputScriptSequence,
    [Parameter(Mandatory=$true)] [string] $PreviousScript
)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force;

<#
Functionality:
1. Create the PREEFIX_CHECK stored procedure
2. Run the PREEFIX_CHECK procedure with parameters to:
    • check whether the current script was previously run and if outcome was successful; and
    • check whether the previous script was run successfully
3. Create record in UPGRADE_SCRIPTS table with SCRIPT_APPLIED value = "N"
4. Generate INSERT statements for EMSE code from Master Scripts
5. Update UPGRADE_SCRIPTS record (from step 3) setting APPLIED_STATUS = "Y"
#>

# variables used for EMSE Master Scripts
[string] $FileName = ""
[string] $FileContent = ""

# variables related to the TSQL output
[string] $ScriptName = ""
[string] $ScriptFileHeader = "SET NOCOUNT ON;"
[string] $ScriptFileFooter = ""
[string] $sqlCmd = ""
[string] $sqlCmdTemplate = "
-- EMSE Script: <MASTER_SCRIPT_NAME>
IF EXISTS( SELECT 1 FROM REVT_MASTER_SCRIPT WHERE SERV_PROV_CODE = '<SERV_PROV_CODE>' AND MASTER_SCRIPT_NAME = '<MASTER_SCRIPT_NAME>' AND MASTER_SCRIPT_VERSION = '<MASTER_SCRIPT_VERSION>' )
BEGIN
    DELETE FROM REVT_MASTER_SCRIPT WHERE SERV_PROV_CODE = '<SERV_PROV_CODE>' AND MASTER_SCRIPT_NAME = '<MASTER_SCRIPT_NAME>' AND MASTER_SCRIPT_VERSION = '<MASTER_SCRIPT_VERSION>';
END
GO
INSERT INTO REVT_MASTER_SCRIPT (SERV_PROV_CODE, MASTER_SCRIPT_NAME, MASTER_SCRIPT_VERSION, MASTER_SCRIPT_TEXT, DESCRIPTION, REC_DATE, REC_FUL_NAM, REC_STATUS)
VALUES ('<SERV_PROV_CODE>', '<MASTER_SCRIPT_NAME>', '<MASTER_SCRIPT_VERSION>', '<MASTER_SCRIPT_TEXT>', '<DESCRIPTION>', CURRENT_TIMESTAMP, 'ADMIN', 'A' );
GO"

# build an array of files
$FileList = Get-ChildItem -Attributes !Directory -Path $SourceFolderName -File "*.$FileExtension";
Write-Verbose "$($FileList.Count) files found in $SourceFolderName"

# write the output file header
# use Set-Content to initialize the file
Write-Verbose "Creating file $DestinationSQLFileName"
Set-Content -Path $DestinationSQLFileName -Value "-- EMSE: BEGIN" -Encoding String
Add-Content -Path $DestinationSQLFileName -Value $ScriptFileHeader -Encoding String

# set variables for other parts of the output script
[IO.FileInfo] $OutputFileName = $DestinationSQLFileName
[string] $StoredProcPrefixCheck = .\Get-StoredProcPrefixCheck.ps1 -RDBMS MSSQL
[string] $CallStoredProcPrefixCheck = .\Get-CallStoredProcPrefixCheck.ps1 -RDBMS MSSQL
[string] $UpgradeScriptsInsert = .\Get-UpgradeScripts.ps1 -RDBMS MSSQL -TypeName INSERT
[string] $UpgradeScriptsUpdate = .\Get-UpgradeScripts.ps1 -RDBMS MSSQL -TypeName UPDATE

# replace any placeholders
$CallStoredProcPrefixCheck = $CallStoredProcPrefixCheck.Replace("<SCRIPT_SEQUENCE>", $OutputScriptSequence);
$CallStoredProcPrefixCheck = $CallStoredProcPrefixCheck.Replace("<MASTER_SCRIPT_VERSION>", $ReleaseVersion);
$CallStoredProcPrefixCheck = $CallStoredProcPrefixCheck.Replace("<RELEASE_SCRIPT>", $($OutputFileName.BaseName));
$CallStoredProcPrefixCheck = $CallStoredProcPrefixCheck.Replace("<PREVIOUS_SCRIPT>", $PreviousScript);

$UpgradeScriptsInsert = $UpgradeScriptsInsert.Replace("<SCRIPT_SEQUENCE>", $OutputScriptSequence);
$UpgradeScriptsInsert = $UpgradeScriptsInsert.Replace("<RELEASE_SCRIPT>", $($OutputFileName.BaseName));
$UpgradeScriptsInsert = $UpgradeScriptsInsert.Replace("<MASTER_SCRIPT_VERSION>", $ReleaseVersion);

$UpgradeScriptsUpdate = $UpgradeScriptsUpdate.Replace("<SCRIPT_SEQUENCE>", $OutputScriptSequence);
$UpgradeScriptsUpdate = $UpgradeScriptsUpdate.Replace("<MASTER_SCRIPT_VERSION>", $ReleaseVersion);

# write variable values to file
Add-Content -Path $DestinationSQLFileName -Value $StoredProcPrefixCheck -Encoding String
Add-Content -Path $DestinationSQLFileName -Value $CallStoredProcPrefixCheck -Encoding String
Add-Content -Path $DestinationSQLFileName -Value $UpgradeScriptsInsert -Encoding String
# the UPDATE happens at the end - see below


ForEach($file in $FileList) {
    # generate TSQL statement and append to output file
    # get some properties
    $FileName = "$($file.Directory)\$($file.Name)"
    $ScriptName = $file.BaseName
    Write-Verbose "Processing file $($file.Name)"

    # read the file contents into a variable
    $FileContent = Get-Content -Path $FileName -Raw;
    # replace single quotes with two single one's
    $FileContent = $FileContent.Replace("'", "''");

    # initialize for each line
    $sqlCmd = $sqlCmdTemplate;
    $sqlCmd = $sqlCmd.Replace("<SERV_PROV_CODE>", $ServProvCode);
    $sqlCmd = $sqlCmd.Replace("<MASTER_SCRIPT_NAME>", $ScriptName);
    $sqlCmd = $sqlCmd.Replace("<MASTER_SCRIPT_VERSION>", $ReleaseVersion);
    $sqlCmd = $sqlCmd.Replace("<MASTER_SCRIPT_TEXT>", $FileContent);
    $sqlCmd = $sqlCmd.Replace("<DESCRIPTION>", $ReleaseVersion);

    # append the output file content
    Add-Content -Path $DestinationSQLFileName -Value $sqlCmd -Encoding String
}

# the UPDATE which was mentioned as happenning at the end
Add-Content -Path $DestinationSQLFileName -Value $UpgradeScriptsUpdate -Encoding String

# write the footer
Add-Content -Path $DestinationSQLFileName -Value $ScriptFileFooter -Encoding String

# append the output file footer
Write-Verbose "Closing output file"
Add-Content -Path $DestinationSQLFileName -Value "-- EMSE: END" -Encoding String
Write-Verbose "Process complete"
