SET NOCOUNT ON;

BEGIN TRY
    -- drop foreign key constraints - FK
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'FK', @CommandType = 'D';

    -- drop nonclustered indexes - IX
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'IX', @CommandType = 'D';
    
    -- drop clustered indexes - CX
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'CX', @CommandType = 'D';
    
    -- drop computed columns - CC
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'CC', @CommandType = 'D';
    
    -- alter table columns
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'CL', @CommandType = 'C';
    
END TRY
BEGIN CATCH
    THROW;
END CATCH
