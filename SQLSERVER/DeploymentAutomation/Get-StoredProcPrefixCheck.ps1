# function Get-StoredProcPrefixCheck {
param (
    [Parameter(Mandatory=$true)] 
    [ValidateSet("ORACLE", "MSSQL")] 
    [string] $RDBMS
)
    # TODO: put PLSQL and TSQL code in an external JSON config file
    [string] $procedureCode = 
    switch ($RDBMS) {
        "ORACLE"    {"
CREATE OR REPLACE PROCEDURE prefix_check (
   p_seq             IN NUMBER,
   p_rel             IN VARCHAR2,
   p_sname           IN VARCHAR2
)
IS
l_count_1 NUMBER;
l_count_2 NUMBER;
BEGIN
    IF p_seq IS NOT NULL THEN
	    SELECT COUNT(*) INTO l_count_1 FROM UPGRADE_SCRIPTS 
        WHERE RELEASE_VERSION = p_rel AND SCRIPT_SEQ = p_seq;
        SELECT COUNT(*) INTO l_count_2 FROM UPGRADE_SCRIPTS 
        WHERE RELEASE_VERSION = p_rel AND SCRIPT_SEQ = p_seq 
        AND SCRIPT_NAME = p_sname AND SCRIPT_APPLIED = 'Y';
	    IF (l_count_1 > 0 and l_count_2 <= 0) THEN 
	        --The current script is applied, but failure
		    raise_application_error((-20000-224), 'The current script is not applied successfully!' );
	    END IF;
	    IF (l_count_1 > 0 and l_count_2 > 0) THEN 
	        --The current script is applied successfully
		    raise_application_error((-20000-230), 'The current script is applied successfully, please continue to apply next script!' );
	    END IF;
    ELSE
        SELECT COUNT(*) INTO l_count_2 FROM UPGRADE_SCRIPTS 
        WHERE RELEASE_VERSION = p_rel 
        AND SCRIPT_NAME = p_sname AND SCRIPT_APPLIED = 'Y';
        IF (l_count_2 <= 0) THEN
            --If the previous script is not applied successfully
            raise_application_error((-20000-224), 'The previous script is not applied successfully!' );
        END IF;
    END IF;
END prefix_check;
/"
            }
        "MSSQL"     {"
IF NOT EXISTS (SELECT 1 FROM sys.procedures WHERE [name] = 'PREFIX_CHECK' AND [type] = 'P')
    EXEC sp_executesql N'CREATE PROCEDURE [dbo].[PREFIX_CHECK] AS SELECT CURRENT_TIMESTAMP;';
GO

ALTER PROCEDURE dbo.prefix_check
   @p_seq             INT = NULL, 
   @p_rel             VARCHAR(20),
   @p_sname           VARCHAR(500)
AS 
BEGIN
    SET NOCOUNT ON;
    DECLARE @V_COUNT_1 TINYINT,
            @V_COUNT_2 TINYINT
    DECLARE @ErrorMessage nvarchar(500);

    SET @V_COUNT_1 = 0
    SET @V_COUNT_2 = 0
    -- control checks for current script
    IF (@p_seq IS NOT NULL)
    BEGIN
        --check whether that current script is already applied and successfully or not
        SET @V_COUNT_1 = (
            SELECT COUNT(*) FROM UPGRADE_SCRIPTS 
            WHERE RELEASE_VERSION = @p_rel AND SCRIPT_SEQ = @p_seq);
        SET @V_COUNT_2 = (
            SELECT COUNT(*) FROM UPGRADE_SCRIPTS 
            WHERE RELEASE_VERSION = @p_rel AND SCRIPT_SEQ = @p_seq 
            AND SCRIPT_NAME = @p_sname AND SCRIPT_APPLIED = 'Y');
	    --The current script is applied, but failure
	    IF (@V_COUNT_1 > 0 AND @V_COUNT_2 <= 0)
	    BEGIN
            SET @ErrorMessage = N'The current script is not applied successfully! Please check the log and fix it!';
		    RAISERROR(@ErrorMessage, 18, 127, '1', '1')
        END
        --The current script is applied successfully
	    IF (@V_COUNT_1 > 0 AND @V_COUNT_2 > 0) 
	    BEGIN
		    SET @ErrorMessage = N'The current script is applied successfully! Please continue to next scripts';
		    RAISERROR(@ErrorMessage, 18, 127, '1', '1')
        END
    END
    ELSE
    -- control checks for previous script
    BEGIN
        --check whether that current script is already applied and successfully or not
        SET @V_COUNT_2 = (
            SELECT COUNT(*) FROM UPGRADE_SCRIPTS 
            WHERE RELEASE_VERSION = @p_rel 
            AND SCRIPT_NAME = @p_sname AND SCRIPT_APPLIED = 'Y')
	    --The current script is applied, but failure
	    IF (@V_COUNT_2 <= 0)
	    BEGIN
            SET @ErrorMessage = N'The previous script is not applied successfully, please check the log and fix it!';
		    RAISERROR(@ErrorMessage, 18, 127, '1', '1')
        END
    END
END
GO"
        }
    }
    return $procedureCode
# }
