SET NOCOUNT ON;

-- check if the supporting objects were created
IF ((OBJECT_ID('[dbo].[CommandExec]') IS NULL) OR 
    (OBJECT_ID('[dbo].[usp_ExecuteCommand]') IS NULL) OR
    (OBJECT_ID('[dbo].[usp_CompareObjectCounts]') IS NULL))
BEGIN
    RAISERROR('No supporting objects for this functionality could be found in this database.', 16, 1);
    RETURN
END
GO

DECLARE @ObjectType char(2) = 'CL';
DECLARE @DeleteFlag char(1) = 'D';
Declare @CreateFlag char(1) = 'C';

-- remove any previous entries (just in case script is executed twice)
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @DeleteFlag; 
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @CreateFlag;

DECLARE @DatabaseName nvarchar(128) = DB_NAME();

WITH cteSource AS (
    SELECT 
        c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, c.DATA_TYPE,
        c.CHARACTER_MAXIMUM_LENGTH, c.IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS c
        INNER JOIN INFORMATION_SCHEMA.TABLES t ON 
            c.TABLE_SCHEMA = t.TABLE_SCHEMA AND
            c.TABLE_NAME = t.TABLE_NAME
    WHERE t.TABLE_TYPE = 'BASE TABLE' 
    AND c.DATA_TYPE IN (
        'char','varchar'
        --,'text'
        )
    AND c.TABLE_NAME NOT IN ('CommandExec')
)
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command])
SELECT 
    @DatabaseName, TABLE_SCHEMA, TABLE_NAME, @ObjectType, @CreateFlag,
-- filtering on columns which do not support unicode, prefixing the DATA_TYPE column with an "n"
-- SELECT 
    'ALTER TABLE ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + 
    ' ALTER COLUMN ' + QUOTENAME(COLUMN_NAME) + 
    ' n' + DATA_TYPE + 
        (CASE DATA_TYPE WHEN 'text' THEN '' ELSE '(' + 
            (CASE 
                WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' 
                WHEN CHARACTER_MAXIMUM_LENGTH > 4000 THEN 'MAX'
                ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS varchar(15)) 
             END) 
            + ') ' 
         END) + ' ' +
    (CASE IS_NULLABLE WHEN 'YES' THEN 'NULL' ELSE 'NOT NULL' END) + ';'
FROM cteSource;

EXEC [dbo].[usp_CompareObjectCounts] @ObjectType = @ObjectType;
GO
