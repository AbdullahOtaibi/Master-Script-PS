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

DECLARE @ObjectType char(2) = 'CC';
DECLARE @DeleteFlag char(1) = 'D';
Declare @CreateFlag char(1) = 'C';

-- remove any previous entries (just in case script is executed twice)
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @DeleteFlag; 
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @CreateFlag;


DECLARE @DatabaseName nvarchar(128)  = DB_NAME();
-- populate DROP COMPUTED COLUMN data
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command])
SELECT 
    @DatabaseName, s.name, t.name, @ObjectType, @DeleteFlag,
-- SELECT 
    'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' DROP COLUMN ' + QUOTENAME(cc.name) + ';'
FROM sys.computed_columns cc
    INNER JOIN sys.tables t ON cc.object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id 
    INNER JOIN sys.types y ON cc.system_type_id = y.system_type_id
WHERE t.object_id > 100
ORDER BY s.name, t.name, cc.column_id;
-- SELECT * FROM [dbo].[CommandExec] WHERE [ObjectType] = 'CC' AND [CommandType] = 'D' ORDER BY [ID] ASC


-- populate CREATE COMPUTED COLUMN data
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command])
SELECT 
    @DatabaseName, s.name, t.name, @ObjectType, @CreateFlag,
-- SELECT 
    'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' ADD ' + QUOTENAME(cc.name) + 
        ' AS ' + cc.[definition] + ' ;'
FROM sys.computed_columns cc
    INNER JOIN sys.tables t ON cc.object_id = t.object_id
        INNER JOIN sys.schemas s ON t.schema_id = s.schema_id 
    INNER JOIN sys.types y ON cc.system_type_id = y.system_type_id
WHERE t.object_id > 100
ORDER BY s.name, t.name, cc.column_id;
-- SELECT * FROM [dbo].[CommandExec] WHERE [ObjectType] = 'CC' AND [CommandType] = 'C' ORDER BY [ID] ASC


EXEC [dbo].[usp_CompareObjectCounts] @ObjectType = @ObjectType;
GO
