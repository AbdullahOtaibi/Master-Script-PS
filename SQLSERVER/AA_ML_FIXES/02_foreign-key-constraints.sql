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

DECLARE @ObjectType char(2) = 'FK';
DECLARE @DeleteFlag char(1) = 'D';
Declare @CreateFlag char(1) = 'C';

-- remove any previous entries (just in case script is executed twice)
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @DeleteFlag; 
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @CreateFlag;


DECLARE @DatabaseName nvarchar(128)  = DB_NAME();
-- populate DROP CONSTRAINT (Foreign Key) data
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command] )
SELECT 
    @DatabaseName, cs.name, ct.name, @ObjectType, @DeleteFlag,
-- SELECT 
    N'ALTER TABLE ' + QUOTENAME(cs.name) + '.' + QUOTENAME(ct.name) + ' DROP CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys AS fk
    INNER JOIN sys.tables AS ct ON fk.parent_object_id = ct.[object_id]
    INNER JOIN sys.schemas AS cs ON ct.[schema_id] = cs.[schema_id]
WHERE cs.name != 'sys'
ORDER BY cs.name, ct.name;
-- SELECT * FROM [dbo].[CommandExec] WHERE [ObjectType] = 'FK' AND [CommandType] = 'D' ORDER BY [ID] ASC


-- populate CREATE CONSTRAINT (Foreign Key) data
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command] )
SELECT 
    @DatabaseName, cs.name, ct.name, @ObjectType, @CreateFlag,
-- SELECT 
    N'ALTER TABLE ' + QUOTENAME(cs.name) + '.' + QUOTENAME(ct.name) 
    + ' WITH NOCHECK' -- constraint is not trusted (enforced) at this point, however it is created - see further down
    + ' ADD CONSTRAINT ' + QUOTENAME(fk.name) 
    + ' FOREIGN KEY (' 
    -- get all the columns in the constraint table
    + STUFF((
        SELECT ',' + QUOTENAME(c.name)
        FROM sys.columns AS c 
            INNER JOIN sys.foreign_key_columns AS fkc ON fkc.parent_column_id = c.column_id AND fkc.parent_object_id = c.[object_id]
        WHERE fkc.constraint_object_id = fk.[object_id]
        ORDER BY fkc.constraint_column_id 
        FOR XML PATH(N''), TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'') 
        + ') REFERENCES ' + QUOTENAME(rs.name) + '.' + QUOTENAME(rt.name) + '(' 
    -- get all the referenced columns
    + STUFF((
        SELECT ',' + QUOTENAME(c.name)
        FROM sys.columns AS c 
            INNER JOIN sys.foreign_key_columns AS fkc ON fkc.referenced_column_id = c.column_id AND fkc.referenced_object_id = c.[object_id]
        WHERE fkc.constraint_object_id = fk.[object_id]
        ORDER BY fkc.constraint_column_id 
        FOR XML PATH(N''), TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 1, N'') + ');'
    + ' '
    + N'ALTER TABLE ' + QUOTENAME(cs.name) + '.' + QUOTENAME(ct.name) 
    + (CASE fk.is_not_trusted WHEN 0 THEN ' WITH CHECK' WHEN 1 THEN ' WITH NOCHECK' ELSE '' END) -- constraint is trusted/not trusted
    + (CASE fk.is_disabled WHEN 0 THEN ' CHECK' WHEN 1 THEN ' NOCHECK' END) -- constraint is checked/not checked
    + ' CONSTRAINT ' + QUOTENAME(fk.name) + ';'
FROM sys.foreign_keys AS fk
    INNER JOIN sys.tables AS rt ON fk.referenced_object_id = rt.[object_id] -- referenced table 
    INNER JOIN sys.schemas AS rs ON rt.[schema_id] = rs.[schema_id]
    INNER JOIN sys.tables AS ct ON fk.parent_object_id = ct.[object_id] -- constraint table
    INNER JOIN sys.schemas AS cs ON ct.[schema_id] = cs.[schema_id]
WHERE rt.is_ms_shipped = 0 AND ct.is_ms_shipped = 0
AND cs.name != 'sys'
ORDER BY cs.name, ct.name;
-- SELECT * FROM [dbo].[CommandExec] WHERE [ObjectType] = 'FK' AND [CommandType] = 'C' ORDER BY [ID] ASC

EXEC [dbo].[usp_CompareObjectCounts] @ObjectType;
GO
