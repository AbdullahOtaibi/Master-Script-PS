SET NOCOUNT ON;

BEGIN TRY
    -- create computed columns
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'CC', @CommandType = 'C';
    
    -- create clustered indexes
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'CX', @CommandType = 'C';
    
    -- create nonclustered indexes
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'IX', @CommandType = 'C';
    
    -- create foreign key constraints
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'FK', @CommandType = 'C';

END TRY
BEGIN CATCH
    THROW;
END CATCH
