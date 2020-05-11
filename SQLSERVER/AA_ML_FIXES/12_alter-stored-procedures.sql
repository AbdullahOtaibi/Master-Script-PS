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

ALTER PROCEDURE [dbo].[key_gen_insert] 
                @p_ivr_nbr BIGINT,
                @p_flag    INT OUTPUT
AS
BEGIN
    BEGIN TRY
        INSERT INTO RECORD_IVR_NBR (TRACKING_NBR, REC_DATE, REC_FUL_NAM, REC_STATUS) VALUES (@p_ivr_nbr, GETDATE(), N'ADMIN', N'A')
        SET @p_flag = 1
    END TRY
    BEGIN CATCH
        IF @@error <> 0
        BEGIN
            SET @p_flag = 0
        END
    END CATCH         
END
GO

ALTER PROCEDURE [dbo].[key_gen]
    @sServProvCode NVARCHAR(15),
    @keyNbr bigint output
AS
    declare @servProvNbr int
    declare @i int
    declare @randomNbr bigint
    declare @returnNbr bigint
    declare @len  int
    declare @flag int
BEGIN
    SELECT @servProvNbr = isnull(serv_prov_nbr,0) FROM rserv_prov WHERE serv_prov_code = @sServProvCode
    set @i = 1
    while @i <= 1000
    begin
        SET @randomNbr = cast(rand()*100000000 as int)
        set @len = len(@randomNbr)
        set @returnNbr = cast(ltrim(rtrim(str(@servProvNbr))) + replicate(N'0',(8 - @len)) + ltrim(rtrim(str(@randomNbr))) as bigint)
        exec DBO.key_gen_insert @returnNbr ,@flag output
        if @flag = 1
            break
        else
        set @i = @i + 1
            continue
    end
    set @keyNbr = @returnNbr  
END
GO
