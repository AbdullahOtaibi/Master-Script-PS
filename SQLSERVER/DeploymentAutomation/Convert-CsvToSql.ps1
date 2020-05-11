<#
.SYNOPSIS
	Generates TSQL "INSERT" statements from a CSV file.
.DESCRIPTION
	Generates TSQL "INSERT" statements from a CSV file.
.PARAMETER SourceCSVFileName
	The path to the CSV file that will be used as  the source. This parameter is mandatory.
.PARAMETER DestinationSQLFileName
    The destination SQL file name. This parameter is mandatory.
.PARAMETER DestinationTableName
    The fully qualified table name (i.e. SCHEMA_NAME.TABLE_NAME) affected by the INSERT statements. This parameter is mandatory.
.EXAMPLE
	.\Convert-CsvToSQL.ps1 -SourceCSVFileName "C:\TEMP\sourceFile.csv" -DestinationSQLFileName "C:\TEMP\destinationFile.sql" -DestinationTableName "dbo.MyTable" -Verbose
    Converts a single file to INSERT statements for SQL Server
.EXAMPLE
    Get-ChildItem -Path "C:\TEMP\SourceFolder" -Filter "*.csv" | `
        Select-Object FullName, BaseName | `
        ForEach-Object { .\Convert-CsvToSQL.ps1 -SourceCSVFileName $($_.FullName) -DestinationSQLFileName "C:\TEMP\DestinationFolder\$($_.BaseName).sql" -DestinationTableName "dbo.MyTable" -Verbose }
    Converts all CSV files in the source folder into individual SQL files (in the Destination folder) containing INSERT statements for SQL Server
    
.OUTPUTS
	None, unless -Verbose is specified. In fact, -Verbose is recommended so you can see what's going on and when.
.NOTES
#>
param(
    [Parameter(Mandatory=$true)] [IO.FileInfo] $SourceCSVFileName,
    [Parameter(Mandatory=$true)] [string] $DestinationSQLFileName,
    [Parameter(Mandatory=$true)] [string] $DestinationTableName
)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force;
<#
ASSUMPTIONS: 
    > row 1 contains the header which will be used to map the columns (header names = destination table column names)
    > other rows are the data and will probably contain ASCII characters outside the first 128 (i.e. Unicode)
#>

[IO.StreamReader] $fileReader = $null
[IO.StreamWriter] $fileWriter = $null
[string] $currentLine = ""
[System.Array] $currentLineArray = $null

[string] $ScriptFileHeader = "SET NOCOUNT ON;"

[string] $sqlCmdTemplate = ""
[string] $sqlCmd = ""

# get the column names
[System.Array] $ColumnNames = (Get-Content $SourceCSVFileName | Select-Object -First 1).Split(',')

# build INSERT INTO part as a template
$sqlCmdTemplate = "INSERT INTO $DestinationTableName ("
$sqlCmdTemplate += $($ColumnNames[0])
$ColumnNames[1..$ColumnNames.Length] | ForEach-Object {$sqlCmdTemplate += ", $_"}
$sqlCmdTemplate += ")
VALUES ("
$sqlCmdTemplate += "N'<$($($ColumnNames[0]))>'"
$ColumnNames[1..$ColumnNames.Length] | ForEach-Object {$sqlCmdTemplate += ", N'<$($_)>'"}
$sqlCmdTemplate += ");"

# internal function to remove leading and trailing quotes (for quoted identifiers)
function stripquotes ([string] $a) {
    # note that the double-quotes are "escaped" using the "`"" symbol 
    if (($a.StartsWith("`"") -eq $true) -and $a.EndsWith("`"")) {
        return $a.Substring(1, $a.Length-2);
    }
    return $a;
}

# here we go...
[int] $rowCount = 0
[int] $breakEvery = 100
[int] $i = 0

try {
    Write-Verbose "Creating file $DestinationSQLFileName"
    $fileWriter = [IO.File]::CreateText("{0}" -f ($DestinationSQLFileName))

    # write the output file header
    $fileWriter.WriteLine($ScriptFileHeader);
    $fileWriter.WriteLine("-- $($DestinationTableName): BEGIN");

    # read the file contents (line by line) into a variable
    try {
        $fileReader = [IO.File]::OpenText($SourceCSVFileName)

        # initialize for each line
        while ($fileReader.EndOfStream -ne $true) {
            $currentLine = $fileReader.ReadLine()
            $rowCount += 1
            # skip the first line
            if ($rowCount -gt 1) {
                # replace single quotes with two single one's
                $currentLine = $currentLine.Replace("'", "''");
                # break the current line into parts, taking into consideration quoted strings
                # $currentLineArray = $currentLine.Split(',')
                $currentLineArray = [regex]::Split( $currentLine, ',(?=(?:[^"]|"[^"]*")*$)' )
                # remove quotes from the beginning and end of the strings
                $currentLineArray = $currentLineArray | ForEach-Object { stripquotes $_ };

                # replace line placeholder and append the output file content
                $sqlCmd = $sqlCmdTemplate;
                foreach ($item in $currentLineArray) { 
                    # work my way through each column, dynamically replacing the values
                    $sqlCmd = $sqlCmd.Replace("<$($ColumnNames[$i])>", $item);
                    $i++
                }
                $fileWriter.WriteLine($sqlCmd);
                # MOD the values and check the remainder to include statement breaks
                if  ($($rowCount % $breakEvery) -eq 0) {
                    $sqlCmd = "GO"
                    $fileWriter.WriteLine($sqlCmd);
                    Write-Verbose "$rowCount statements written"
                }
                # reset variables
                $currentLineArray = $null
                $sqlCmd = ""
                $i = 0
            }
        }
    } finally { 
        # clean up
        $fileReader.Dispose();
    }
} finally {
    $sqlCmd = "GO"
    $fileWriter.WriteLine($sqlCmd);
    Write-Verbose "$rowCount statements written"
    Write-Verbose "Closing output file"
    $fileWriter.WriteLine("-- $($DestinationTableName): END");
    # clean up
    $fileWriter.Dispose();
}
