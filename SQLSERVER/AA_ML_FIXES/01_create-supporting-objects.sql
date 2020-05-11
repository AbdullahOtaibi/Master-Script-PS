SET NOCOUNT ON;

DECLARE @DebugMode bit = 0;

IF (@DebugMode = 1) AND (OBJECT_ID('[dbo].[CommandExec]') IS NOT NULL)
BEGIN
    IF EXISTS(SELECT * FROM [dbo].[CommandExec])
    BEGIN
        RAISERROR('The table structure contains data. Please review and rerun the script.', 16, 1);
        RETURN
    END
END
GO

-- prepare structure
IF OBJECT_ID('[dbo].[CommandExec]') IS NOT NULL
    DROP TABLE [dbo].[CommandExec];
GO
CREATE TABLE [dbo].[CommandExec] (
    [ID] int IDENTITY (1,1) NOT NULL,
    [DatabaseName] nvarchar(128) NULL,
    [SchemaName] nvarchar(128) NULL,
    [ObjectName] nvarchar(128) NULL,
    [ObjectType] char(2) NULL,
    [CommandType] char(1) NOT NULL,
    [Command] nvarchar(max) NOT NULL,
    [StartTime] datetime NULL,
    [EndTime] datetime NULL,
    [Outcome] bit NULL,
    [ErrorNumber] int NULL,
    [ErrorMessage] nvarchar(max) NULL
);
GO
CREATE UNIQUE CLUSTERED INDEX [CX_CommandExec_ID] ON [dbo].[CommandExec] ( [ID] ASC )
WITH (
    PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, IGNORE_DUP_KEY = OFF, 
    DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON
)
GO
-- TRUNCATE TABLE [dbo].[CommandExec];


IF OBJECT_ID('[dbo].[usp_ExecuteCommand]') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_ExecuteCommand];
GO
CREATE PROCEDURE [dbo].[usp_ExecuteCommand]
    @ObjectType char(2),
    @CommandType char(1)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Command nvarchar(max);
    DECLARE @StartTime datetime;
    DECLARE @EndTime datetime;
    DECLARE @ErrorNumber int;
    DECLARE @ErrorMessage nvarchar(max);

    DECLARE @OutputMessage nvarchar(256);
    DECLARE @ObjectTypeName nvarchar(128) = (
        CASE @ObjectType
            WHEN 'CC' THEN 'Computed Columns'
            WHEN 'CL' THEN 'Table Columns'
            WHEN 'CX' THEN 'Clustered Indexes'
            WHEN 'FK' THEN 'Foreign Keys'
            WHEN 'IX' THEN 'NonClustered Indexes'
            WHEN 'RV' THEN 'Refresh Views'
            ELSE ''
        END);

    SET @OutputMessage = N'Starting ' + (CASE @CommandType WHEN 'C' THEN 'CREATE' WHEN 'D' THEN 'DROP' END) + ' for ' + @ObjectTypeName;
    PRINT @OutputMessage;

    DECLARE CommandCursor CURSOR LOCAL KEYSET
    FOR 
        SELECT [Command]
        FROM [dbo].[CommandExec] 
        WHERE [ObjectType] = @ObjectType AND [CommandType] = @CommandType
        AND [Outcome] IS NULL
        ORDER BY [ID] ASC
    FOR UPDATE OF [StartTime], [EndTime], [Outcome], [ErrorNumber], [ErrorMessage];

    OPEN CommandCursor;
    FETCH NEXT FROM CommandCursor INTO @Command;
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        -- store the start time
        SET @StartTime = CURRENT_TIMESTAMP;
        UPDATE [dbo].[CommandExec] SET [StartTime] = @StartTime 
        WHERE CURRENT OF CommandCursor;
    
        BEGIN TRY
            -- do the magic
            --PRINT @Command;
            EXEC sys.sp_executesql @Command;

            -- store the end time
            SET @EndTime = CURRENT_TIMESTAMP;
            -- store the completion time and status
            UPDATE [dbo].[CommandExec] SET [EndTime] = @EndTime, [Outcome] = 1
            WHERE CURRENT OF CommandCursor;

            FETCH NEXT FROM CommandCursor INTO @Command;
        END TRY
        BEGIN CATCH
            -- store the end time
            SET @EndTime = CURRENT_TIMESTAMP;
        
            -- retrieve error information
            SET @ErrorNumber = ERROR_NUMBER();
            SET @ErrorMessage = ERROR_MESSAGE();

            -- store the completion time, status, and error information
            UPDATE [dbo].[CommandExec] SET [EndTime] = @EndTime, [Outcome] = 0,
                [ErrorNumber] = @ErrorNumber, [ErrorMessage] = @ErrorMessage
            WHERE CURRENT OF CommandCursor;

            -- escalate the error to the UI and exit
            --RAISERROR(@ErrorMessage, 16, 1);
            PRINT @Command;
            THROW;
        END CATCH
    END
    CLOSE CommandCursor;
    DEALLOCATE CommandCursor;
END
GO


IF OBJECT_ID('[dbo].[usp_CompareObjectCounts]') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_CompareObjectCounts];
GO
CREATE PROCEDURE [dbo].[usp_CompareObjectCounts]
    @ObjectType char(2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CreatedItemCount int;
    DECLARE @DroppedItemCount int;
    DECLARE @ObjectTypeName nvarchar(128) = (
        CASE @ObjectType
            WHEN 'CC' THEN 'Computed Columns'
            WHEN 'CL' THEN 'Table Columns'
            WHEN 'CX' THEN 'Clustered Indexes'
            WHEN 'FK' THEN 'Foreign Keys'
            WHEN 'IX' THEN 'NonClustered Indexes'
            WHEN 'RV' THEN 'Refresh Views'
            ELSE ''
        END);

    SET @CreatedItemCount = (
        SELECT COUNT(*) FROM [dbo].[CommandExec]
        WHERE [ObjectType] = @ObjectType 
        AND [Command] = 'C');
    
    SET @DroppedItemCount = (
        SELECT COUNT(*) FROM [dbo].[CommandExec]
        WHERE [ObjectType] = @ObjectType 
        AND [Command] = 'D');

    IF (@CreatedItemCount != @DroppedItemCount)
    BEGIN
        RAISERROR('The number of CREATE scripts for %s does not match the DROP', 16, 1, @ObjectTypeName);
        RETURN -1
    END
    RETURN
END
GO
