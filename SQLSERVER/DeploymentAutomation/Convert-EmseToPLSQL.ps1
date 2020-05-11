<#
.SYNOPSIS
	Generates PLSQL "INSERT" statements from the EMSE Master scripts.
.DESCRIPTION
	Converts EMSE files to PLSQL INSERT statements.
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
	.\Convert-EmseToPLSQL.ps1 -SourceFolderName "C:\Accela-Inc\MasterScripts\MasterScripts" -FileExtension "js" -DestinationSQLFileName "C:\TEMP\19.1.4_08_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.1.4" -OutputScriptSequence 8 -PreviousScript "19.1.4_07_emse_oracle.sql" -Verbose
    Generates the file "19.1.4_08_emse_oracle.sql" for Oracle which will be the 8th file of the release, showing Verbose output.
    Abdullah Comment: 
     Run file on local PC: 	
    .\Convert-EmseToPLSQL.ps1 -SourceFolderName "C:\Users\Abdullah\Desktop\Training\Master Script\Master Script Files" -FileExtension "js" -DestinationSQLFileName "C:\Users\Abdullah\Desktop\Training\Master Script\script\19.1.4_08_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.1.4" -OutputScriptSequence 8 -PreviousScript "19.1.4_07_emse_oracle.sql" -Verbose
     or  
    .\Convert-EmseToPLSQL.ps1 -SourceFolderName "C:\Users\Abdullah\Desktop\Training\Master Script\Master Script Files" -FileExtension "js" -DestinationSQLFileName "C:\Users\Abdullah\Desktop\Training\Master Script\script\19.2.0_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.2.0" -OutputScriptSequence 8 -PreviousScript "19.1.4_emse_oracle.sql" -Verbose
    ** new laptop command:
	c) .\Convert-EmseToPLSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 19.2.3" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\19.2.3_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.2.3" -OutputScriptSequence 8 -PreviousScript "19.2.0_emse_oracle.sql" -Verbose
    d) .\Convert-EmseToPLSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 20.1.0" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\20.1.0_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "20.1.0" -OutputScriptSequence 8 -PreviousScript "19.2.3_emse_oracle.sql" -Verbose
    e) .\Convert-EmseToPLSQL.ps1 -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 20.1.1" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\20.1.1_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "20.1.1" -OutputScriptSequence 8 -PreviousScript "20.1.0_emse_oracle.sql" -Verbose
	f).\Convert-EmseToPLSQL.ps1  -SourceFolderName "D:\ACCELA Data\Training\Master Script\Master Script Files\v 20.1.2" -FileExtension "js" -DestinationSQLFileName "D:\ACCELA Data\Training\Master Script\script\20.1.2_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "20.1.2" -OutputScriptSequence 8 -PreviousScript "20.1.1_emse_oracle.sql" -Verbose

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
[IO.StreamReader] $fileReader = $null
[IO.StreamWriter] $fileWriter = $null
[string] $currentLine = ""

# variables related to the PLSQL output
[string] $ScriptName = ""
[string] $ScriptFileHeader = "
CREATE OR REPLACE PROCEDURE ins_master_emse_mig
IS
BEGIN"
[string] $ScriptFileFirstLine = "      lob_pkg.master_lob_ins( '<SERV_PROV_CODE>', '<MASTER_SCRIPT_NAME>', '/*------------------------------------------------------------------------------------------------------/'|| chr(13), '<MASTER_SCRIPT_VERSION>', '<MASTER_SCRIPT_VERSION>' );"
[string] $ScriptFileFooter = "
      COMMIT;
END ins_master_emse_mig;
/

EXEC ins_master_emse_mig;"
[string] $sqlCmd = ""
[string] $sqlCmdTemplate = "      lob_pkg.add_more('<MASTER_SCRIPT_TEXT>' || chr(13) );"

# build an array of files
$FileList = Get-ChildItem -Attributes !Directory -Path $SourceFolderName -File "*.$FileExtension";
Write-Verbose "$($FileList.Count) files found in $SourceFolderName"

# set variables for other parts of the output script


try {
    Write-Verbose "Creating file $DestinationSQLFileName"
    $fileWriter = [IO.File]::CreateText("{0}" -f ($DestinationSQLFileName))

    # write the output file header
    $fileWriter.WriteLine("-- EMSE: BEGIN");

    # set Oracle params
    $fileWriter.WriteLine("SET ECHO ON");
    $fileWriter.WriteLine("");
    $fileWriter.WriteLine("WHENEVER SQLERROR EXIT SQL.SQLCODE");

    # set variables for other parts of the output script
    [IO.FileInfo] $OutputFileName = $DestinationSQLFileName
    [string] $StoredProcPrefixCheck = .\Get-StoredProcPrefixCheck.ps1 -RDBMS ORACLE
    [string] $CallStoredProcPrefixCheck = .\Get-CallStoredProcPrefixCheck.ps1 -RDBMS ORACLE
    [string] $UpgradeScriptsInsert = .\Get-UpgradeScripts.ps1 -RDBMS ORACLE -TypeName INSERT
    [string] $UpgradeScriptsUpdate = .\Get-UpgradeScripts.ps1 -RDBMS ORACLE -TypeName UPDATE

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
    $fileWriter.WriteLine($StoredProcPrefixCheck);
    $fileWriter.WriteLine($CallStoredProcPrefixCheck);
    # start logging
    $fileWriter.WriteLine("SPOOL '&1\$($OutputFileName.BaseName).log'");
    $fileWriter.WriteLine($UpgradeScriptsInsert);
    # the UPDATE happens at the end - see below

    ForEach($file in $FileList) {
        # generate PLSQL statement and append to output file
        # get some properties
        $FileName = "$($file.Directory)\$($file.Name)"
        $ScriptName = $file.BaseName
        Write-Verbose "Processing file $($file.Name)"

        # replace placeholders and write the header
        $sqlCmd = $ScriptFileHeader;
        $sqlCmd = $sqlCmd.Replace("<SERV_PROV_CODE>", $ServProvCode);
        $sqlCmd = $sqlCmd.Replace("<MASTER_SCRIPT_NAME>", $ScriptName);
        $sqlCmd = $sqlCmd.Replace("<MASTER_SCRIPT_VERSION>", $ReleaseVersion);
        $sqlCmd = $sqlCmd.Replace("<DESCRIPTION>", $ReleaseVersion);
        $fileWriter.WriteLine($sqlCmd);
        # adding First Line Code and fixing the paramters values:  
        $ScriptFileFirstLine = $ScriptFileFirstLine.Replace("<SERV_PROV_CODE>", $ServProvCode);
        $ScriptFileFirstLine = $ScriptFileFirstLine.Replace("<MASTER_SCRIPT_NAME>", $ScriptName);
        $ScriptFileFirstLine = $ScriptFileFirstLine.Replace("<MASTER_SCRIPT_VERSION>", $ReleaseVersion);
		$fileWriter.WriteLine($ScriptFileFirstLine);
        # read the file contents (line by line) into a variable
        try {
            $fileReader = [IO.File]::OpenText($FileName)

            # initialize for each line
            while ($fileReader.EndOfStream -ne $true) {
                $currentLine = $fileReader.ReadLine()
                # replace single quotes with two single one's
                $currentLine = $currentLine.Replace("'", "''");

                # replace line placeholder and append the output file content
                $sqlCmd = $sqlCmdTemplate;
                $sqlCmd = $sqlCmd.Replace("<MASTER_SCRIPT_TEXT>", $currentLine);
                $fileWriter.WriteLine($sqlCmd);
            }
        } finally { 
            $fileReader.Dispose();
        }

        # write the footer
        $fileWriter.WriteLine($ScriptFileFooter);
    }

    # the UPDATE which was mentioned as happenning at the end
    $fileWriter.WriteLine($UpgradeScriptsUpdate);

    # commit transaction
    $fileWriter.WriteLine("COMMIT;");

    # stop logging
    $fileWriter.WriteLine("SPOOL OFF");

    # end execution
    $fileWriter.WriteLine("EXIT");

    # append the output file footer
    $fileWriter.WriteLine("-- EMSE: END");
} finally {
    Write-Verbose "Closing output file"
    $fileWriter.Dispose();
}
Write-Verbose "Process complete"
