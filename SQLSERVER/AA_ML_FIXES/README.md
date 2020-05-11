# AA Multi-Language FIXES

Scripts to convert a single-language AA database to one that supports a multi-language environment.

The scripts in this folder will reverse-engineer/generate all the TSQL commands that would be required to convert all CHAR and VARCHAR columns to NCHAR and NVARCHAR resepctively. The process is not a simple once since all FOREIGN KEY constats, NONCLUSTERED and CLUSTERED INDEX structures and COMPUTED COLUMN objects would have to be dropped and recreated in a specific order to ensure the success of the conversion.

The scripts supplied are based on a standard Accela AA database schema and the process might fail if additional objects have been created.

Two of the scripts, namely "00_database-backup.sql" and "15_clean-up.sql" have only been included as placeholders.

These scripts can be run manually or using the PowerShell script under the "Scripts-Deployment" folder.
