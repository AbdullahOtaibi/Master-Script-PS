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

DECLARE @ObjectType char(2) = 'CX';
DECLARE @DeleteFlag char(1) = 'D';
Declare @CreateFlag char(1) = 'C';

-- remove any previous entries (just in case script is executed twice)
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @DeleteFlag; 
DELETE FROM [dbo].[CommandExec] WHERE [ObjectType] = @ObjectType AND [CommandType] = @CreateFlag;


DECLARE @DatabaseName nvarchar(128)  = DB_NAME();
-- populate DROP CLUSTERED INDEX data
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command])
SELECT 
    @DatabaseName, S.name, B.name, @ObjectType, @DeleteFlag,
-- SELECT 
    CASE WHEN A.[is_primary_key] = 1 THEN
        'ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id])) + ' DROP CONSTRAINT ' + QUOTENAME(A.[Name]) + ';'
    ELSE
        'DROP INDEX ' + QUOTENAME(A.[Name]) + ' ON ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id])) + ';'
    END
FROM sys.indexes A WITH (NOLOCK)
INNER JOIN sys.objects B WITH (NOLOCK) ON A.object_id = B.object_id
INNER JOIN sys.schemas S ON B.schema_id = S.schema_id
INNER JOIN sys.data_spaces C WITH (NOLOCK) ON A.data_space_id = C.data_space_id
INNER JOIN sys.stats D WITH (NOLOCK) ON A.object_id = D.object_id AND A.index_id = D.stats_id
INNER JOIN
    --The below code is to find out what data compression type was used by the index. If an index is not partitioned, it is easy as only one data compression
    --type can be used. If the index is partitioned, then each partition can be configued to use the different data compression. This is hard to generalize,
    --for simplicity, I just use the data compression type used most for the index partitions for all partitions. You can later rebuild the index partition to
    --the appropriate data compression type you want to use
    (
    SELECT object_id
        ,index_id
        ,Data_Compression
        ,ROW_NUMBER() OVER (PARTITION BY object_id,index_id ORDER BY COUNT(*) DESC) AS Main_Compression
    FROM sys.partitions WITH (NOLOCK)
    GROUP BY object_id, index_id, Data_Compression
    ) P ON A.object_id = P.object_id
    AND A.index_id = P.index_id
    AND P.Main_Compression = 1
OUTER APPLY (
    SELECT COL_NAME(A.object_id, E.column_id) AS Partition_Column
    FROM sys.index_columns E WITH (NOLOCK)
    WHERE E.object_id = A.object_id
        AND E.index_id = A.index_id
        AND E.partition_ordinal = 1
    ) F
WHERE A.type = 1 -- clustered only
AND B.Type != 'S'
AND B.name NOT LIKE 'queue_messages_%'
AND B.name NOT LIKE 'filestream_tombstone_%'
AND B.name NOT LIKE 'sys%' --if you have index start with sys then remove it
AND S.name != 'sys'
AND B.name != 'CommandExec'
ORDER BY S.name, B.name;
-- SELECT * FROM [dbo].[CommandExec] WHERE [ObjectType] = 'CX' AND [CommandType] = 'D' ORDER BY [ID] ASC


-- populate CREATE CLUSTERED INDEX data
INSERT INTO [dbo].[CommandExec] (
    [DatabaseName], [SchemaName], [ObjectName], [ObjectType], [CommandType], [Command])
SELECT 
    @DatabaseName, S.name, B.name, @ObjectType, @CreateFlag,
-- SELECT 
    CAST(CASE 
            WHEN A.type = 1 AND A.[is_primary_key] = 1 THEN 'ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id])) + ' ADD CONSTRAINT ' + + QUOTENAME(A.[Name]) + ' PRIMARY KEY CLUSTERED '
            WHEN A.type = 1 AND A.[is_unique] = 1 THEN 'CREATE UNIQUE CLUSTERED INDEX ' + QUOTENAME(A.[Name]) + ' ON ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id]))
            WHEN A.type = 1 AND A.[is_unique] = 0 THEN 'CREATE CLUSTERED INDEX ' + QUOTENAME(A.[Name]) + ' ON ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id]))
            WHEN A.type = 2 AND A.[is_unique] = 0 AND A.[is_unique_constraint] = 0 THEN 'CREATE NONCLUSTERED INDEX ' + QUOTENAME(A.[Name]) + ' ON ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id]))
            WHEN A.type = 2 AND A.[is_unique] = 1 AND A.[is_unique_constraint] = 0 THEN 'CREATE UNIQUE NONCLUSTERED INDEX ' + QUOTENAME(A.[Name]) + ' ON ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id]))
            WHEN A.type = 2 AND A.[is_unique] = 1 AND A.[is_unique_constraint] = 1 THEN 'ALTER TABLE ' + QUOTENAME(S.name) + '.' + QUOTENAME(OBJECT_NAME(A.[object_id])) + ' ADD CONSTRAINT ' + + QUOTENAME(A.[Name]) + ' UNIQUE NONCLUSTERED '
          END + ' (' 
        + STUFF((
                SELECT ',[' + COL_NAME(A.[object_id], C.column_id) + 
                    CASE 
                        WHEN C.is_descending_key = 1 THEN '] DESC' 
                        ELSE '] ASC' 
                    END
                FROM sys.index_columns C WITH (NOLOCK)
                WHERE A.[Object_ID] = C.object_id
                    AND A.Index_ID = C.Index_ID
                    AND C.is_included_column = 0
                ORDER BY C.key_Ordinal ASC
                FOR XML Path('')
                ), 1, 1, '') + ') ' 
        + CASE WHEN A.type = 1 THEN ''
            ELSE COALESCE('INCLUDE (' 
                + STUFF((
                    SELECT ',' + QUOTENAME(COL_NAME(A.[object_id], C.column_id))
                    FROM sys.index_columns C WITH (NOLOCK)
                    WHERE A.[Object_ID] = C.object_id
                        AND A.Index_ID = C.Index_ID
                        AND C.is_included_column = 1
                    ORDER BY C.index_column_id ASC
                    FOR XML Path('')
                    ), 1, 1, '') + ') ', '')
          END 
        + CASE WHEN A.has_filter = 1 THEN 'WHERE ' + A.filter_definition
            ELSE ''
            END 
        --SORT_IN_TEMPDB = ON is recommended but based on your own environment.
        + ' WITH (SORT_IN_TEMPDB = ON'
        --when the same index exists you'd better to set the DROP_EXISTING = ON
        --+ CASE A.is_unique_constraint WHEN 0 THEN ', DROP_EXISTING = OFF' ELSE '' END
        + ', FILLFACTOR = ' + CAST(CASE WHEN A.fill_factor = 0 THEN 100 ELSE A.fill_factor END AS VARCHAR(3)) 
        + ', PAD_INDEX = ' + CASE WHEN A.[is_padded] = 1 THEN 'ON' ELSE 'OFF' END 
        + ', STATISTICS_NORECOMPUTE = ' + CASE WHEN D.[no_recompute] = 1 THEN 'ON' ELSE 'OFF' END 
        + ', IGNORE_DUP_KEY = ' + CASE WHEN A.[ignore_dup_key] = 1 THEN 'ON' ELSE 'OFF' END 
        + ', ALLOW_ROW_LOCKS = ' + CASE WHEN A.[ALLOW_ROW_LOCKS] = 1 THEN 'ON' ELSE 'OFF' END 
        + ', ALLOW_PAGE_LOCKS = ' + CASE WHEN A.[ALLOW_PAGE_LOCKS] = 1 THEN 'ON' ELSE 'OFF' END 
        + ', DATA_COMPRESSION = ' + CASE P.[data_compression] WHEN 0 THEN 'NONE' WHEN 1 THEN 'ROW' ELSE 'PAGE' END 
        + ') ON ' 
        + CASE WHEN C.type = 'FG' THEN QUOTENAME(C.name)
            ELSE QUOTENAME(C.name) + '(' + F.Partition_Column + ')'
            END + ';' --if it uses partition scheme then need partition column
        AS nvarchar(MAX))
FROM sys.indexes A WITH (NOLOCK)
INNER JOIN sys.objects B WITH (NOLOCK) ON A.object_id = B.object_id
INNER JOIN sys.schemas S ON B.schema_id = S.schema_id
INNER JOIN sys.data_spaces C WITH (NOLOCK) ON A.data_space_id = C.data_space_id
INNER JOIN sys.stats D WITH (NOLOCK) ON A.object_id = D.object_id AND A.index_id = D.stats_id
INNER JOIN
    --The below code is to find out what data compression type was used by the index. If an index is not partitioned, it is easy as only one data compression
    --type can be used. If the index is partitioned, then each partition can be configued to use the different data compression. This is hard to generalize,
    --for simplicity, I just use the data compression type used most for the index partitions for all partitions. You can later rebuild the index partition to
    --the appropriate data compression type you want to use
    (
    SELECT object_id
        ,index_id
        ,Data_Compression
        ,ROW_NUMBER() OVER (PARTITION BY object_id,index_id ORDER BY COUNT(*) DESC) AS Main_Compression
    FROM sys.partitions WITH (NOLOCK)
    GROUP BY object_id, index_id, Data_Compression
    ) P ON A.object_id = P.object_id
    AND A.index_id = P.index_id
    AND P.Main_Compression = 1
OUTER APPLY (
    SELECT COL_NAME(A.object_id, E.column_id) AS Partition_Column
    FROM sys.index_columns E WITH (NOLOCK)
    WHERE E.object_id = A.object_id
        AND E.index_id = A.index_id
        AND E.partition_ordinal = 1
    ) F
WHERE A.type = 1 -- clustered only
AND B.Type != 'S'
AND B.name NOT LIKE 'queue_messages_%'
AND B.name NOT LIKE 'filestream_tombstone_%'
AND B.name NOT LIKE 'sys%' --if you have index start with sys then remove it
AND S.name != 'sys'
AND B.name != 'CommandExec'
ORDER BY S.name, B.name;
-- SELECT * FROM [dbo].[CommandExec] WHERE [ObjectType] = 'CX' AND [CommandType] = 'C' ORDER BY [ID] ASC

EXEC [dbo].[usp_CompareObjectCounts] @ObjectType = @ObjectType;
GO
