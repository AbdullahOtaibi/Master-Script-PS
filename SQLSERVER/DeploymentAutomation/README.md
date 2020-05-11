# Deployment Automation scripts for SQL Server

**File: Convert-EmseToTSQL.ps1** 

Generates SQL Server TSQL "INSERT" statements from the EMSE Master scripts.

Usage:
```powershell
.\Convert-EmseToTSQL.ps1 -SourceFolderName "C:\Accela-Inc\MasterScripts\MasterScripts" -FileExtension "js" -DestinationSQLFileName "C:\TEMP\19.1.4_08_emse_mssql.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.1.4" -OutputScriptSequence 8 -PreviousScript "19.1.4_07_emse_mssql.sql" -Verbose
```
-----

**File: Convert-EmseToPLSQL.ps1** 

Generates Oracle PLSQL "INSERT" statements from the EMSE Master scripts.

Usage:
```powershell
.\Convert-EmseToPLSQL.ps1 -SourceFolderName "C:\Accela-Inc\MasterScripts\MasterScripts" -FileExtension "js" -DestinationSQLFileName "C:\TEMP\19.1.4_08_emse_oracle.sql" -ServProvCode "STANDARDDATA" -ReleaseVersion "19.1.4" -OutputScriptSequence 8 -PreviousScript "19.1.4_07_emse_oracle.sql" -Verbose
```
-----

**File: Get-StoredProcPrefixCheck.ps1** 

Used by the Convert-EmseToTSQL.ps1 and Convert-EmseToPLSQL.ps1 processes to CREATE the stored procedure

Usage:
```powershell
.\Get-StoredProcPrefixCheck.ps1 -RDBMS ORACLE

.\Get-StoredProcPrefixCheck.ps1 -RDBMS MSSQL
```
-----

**File: Get-CallStoredProcPrefixCheck.ps1** 

Used by the Convert-EmseToTSQL.ps1 and Convert-EmseToPLSQL.ps1 processes to generate stored procedure EXEC commands

Usage:
```powershell
.\Get-CallStoredProcPrefixCheck.ps1 -RDBMS ORACLE

.\Get-CallStoredProcPrefixCheck.ps1 -RDBMS MSSQL
```
-----

**File: Get-UpgradeScripts.ps1** 

Used by the Convert-EmseToTSQL.ps1 and Convert-EmseToPLSQL.ps1 processes to generate INSERT or UPDATE statements

Usage:
```powershell
.\Get-UpgradeScripts.ps1 -RDBMS ORACLE -TypeName INSERT

.\Get-UpgradeScripts.ps1 -RDBMS ORACLE -TypeName UPDATE

.\Get-UpgradeScripts.ps1 -RDBMS MSSQL -TypeName INSERT

.\Get-UpgradeScripts.ps1 -RDBMS MSSQL -TypeName UPDATE
```
-----

**File: Script-DatabaseObjects.ps1** 

Exports an Accela AA database's worth of DDL statements for tables, views, indexes, and more to be used as the base schema in deployment packages.

Usage:
```powershell
./Get-DatabaseObjects.ps1 -servName "localhost" -databaseName "AdventureWorks2014" -filePath "C:\temp"
```
-----

**File: Split-File.ps1** 

Splits a text file into smaller and more manageable files.

Usage:
```powershell
./Split-File.ps1 -inputfilePath "C:\TEMP\largefile.sql" -linesPerFile 100 -breakOnMatch "GO" -outputFolder "C:\TEMP" -outputExtension ".sql" -Verbose
```
-----

**File: Convert-CsvToSql.ps1** 

Generates TSQL "INSERT" statements from a CSV file.

Usage:
Example 1
Converts a single file to INSERT statements for SQL Server
```powershell
.\Convert-CsvToSQL.ps1 -SourceCSVFileName "C:\TEMP\sourceFile.csv" -DestinationSQLFileName "C:\TEMP\destinationFile.sql" -DestinationTableName "dbo.MyTable" -Verbose
```
Example 2
Converts all CSV files in the source folder into individual SQL files (in the Destination folder) containing INSERT statements for SQL Server
```powershell
.\Get-ChildItem -Path "C:\TEMP\SourceFolder" -Filter "*.csv" | 
    Select-Object FullName, BaseName | 
    ForEach-Object { .\Convert-CsvToSQL.ps1 -SourceCSVFileName $($_.FullName) -DestinationSQLFileName "C:\TEMP\DestinationFolder\$($_.BaseName).sql" -DestinationTableName "dbo.MyTable" -Verbose }
```

-----
