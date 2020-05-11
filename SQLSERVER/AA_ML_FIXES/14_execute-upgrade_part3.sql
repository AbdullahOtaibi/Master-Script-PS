SET NOCOUNT ON;

BEGIN TRY
    -- refresh views
    EXEC [dbo].[usp_ExecuteCommand] @ObjectType = 'RV', @CommandType = 'C';

END TRY
BEGIN CATCH
    THROW;
END CATCH
