<#
.SYNOPSIS
	Splits a text file into smaller and more manageable files.
.DESCRIPTION
	Splits athe text file into chunks, depending on the linesPerFile parameter
.PARAMETER inputfilePath
	The file you want to split. This parameter is NOT optional
.PARAMETER linesPerFile
	The number of lines per file. This is an optional parameter which defaults to 10,000.
.PARAMETER breakOnMatch
    A value that will be used as the anchor to split the files. Useful for TSQL files where breaks would have to happen after a "GO". This is an optional parameter.
.PARAMETER outputFolder
    The folder where the split files will be output. This is an optional parameter which defaults to the same folder defined for the input file.
.PARAMETER outputExtension
    The extension that will be used for the output files. This is an optional parameter which defaults to the same as the input file.
.EXAMPLE
	./Split-File.ps1 -inputfilePath "C:\TEMP\largefile.sql" -linesPerFile 100 -breakOnMatch "GO" -outputFolder "C:\TEMP" -outputExtension ".sql" -Verbose
.OUTPUTS
	None, unless -Verbose is specified. In fact, -Verbose is recommended so you can see what's going on and when.
.NOTES
#>
param(
    [Parameter(Mandatory=$true)] [IO.FileInfo] $inputfilePath,
    [Parameter(Mandatory=$false)] [int] $linesPerFile = 10000,
    [Parameter(Mandatory=$true)] [string] $breakOnMatch,
    [Parameter(Mandatory=$true)] [string] $outputFolder,
    [Parameter(Mandatory=$false)] [string] $outputExtension
)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force;

# split
$stopWatch = New-Object System.Diagnostics.Stopwatch
$stopWatch.Start()

# checks
if (!$outputFolder) { $outputFolder = $inputfilePath.DirectoryName }
if (!$outputExtension) { $outputExtension = $inputfilePath.Extension }
# set default values
[int] $fileCount = 1
[IO.StreamReader] $fileReader = $null
[IO.StreamWriter] $fileWriter = $null
[string] $fileName = $inputfilePath.BaseName
[string] $currentLine = ""
try {
    $fileReader = [IO.File]::OpenText($inputfilePath)
    try {
        Write-Verbose "Creating file number $fileCount"
        $fileWriter = [IO.File]::CreateText("{0}\{1}_{2}.{3}" -f ($outputFolder,$fileName,$fileCount.ToString("000"),$outputExtension))
        $fileCount++
        $lineCount = 0

        while ($fileReader.EndOfStream -ne $true) {
            Write-Verbose "Reading $linesPerFile"
            while ( ($lineCount -lt $linesPerFile) -and ($fileReader.EndOfStream -ne $true)) {
                $currentLine = $fileReader.ReadLine()
                $fileWriter.WriteLine($currentLine);
                if (!$breakOnMatch) { $lineCount++ }
                else { 
                    # increment the counter on every matching occurance
                    if ($currentLine -eq $breakOnMatch ) { $lineCount++ } 
                }
            }

            if($fileReader.EndOfStream -ne $true) {
                Write-Verbose "Closing file"
                $fileWriter.Dispose();

                Write-Verbose "Creating file number $fileCount"
                $fileWriter = [IO.File]::CreateText("{0}\{1}_{2}.{3}" -f ($outputFolder,$fileName,$fileCount.ToString("000"),$outputExtension))
                $fileCount++
                $lineCount = 0
            }
        }
    } finally {
        $fileWriter.Dispose();
    }
} finally {
    $fileReader.Dispose();
}
$stopWatch.Stop()
Write-Verbose "Split complete in $($stopWatch.Elapsed.TotalSeconds) seconds"
