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

-- populate sp_refreshview data
DECLARE @DatabaseName nvarchar(128) = DB_NAME();
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command])
SELECT 
    @DatabaseName, s.name, v.name, 'RV', 'C',
-- SELECT 
    'EXEC sp_refreshview @viewname = N''' + QUOTENAME(s.name) + '.' + QUOTENAME(v.name) + ''';'
FROM sys.views v
    INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
ORDER BY object_id;
GO
