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

ALTER FUNCTION [dbo].[FN_GET_ADDRESS_PARTIAL_ALL]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5),
         @Format NVARCHAR(10),
	 @Delimiter NVARCHAR(500)
	 )
RETURNS NVARCHAR(4000) AS
/*  Author           :   Arthur Miao
    Create Date      :   07/14/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: All property addresses for the application, in the format specified by {Format}, separated by {Delimiter}. 
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, Format ('L' for line (exclude City, State and Zip),'B' for Block (exclude City, State and Zip), 'LALL' for line (include City, State and Zip),'BALL' for Block (include City, State and Zip), Delimiter (default is single line break).
  Revision History :	 Arthur Miao initial design 07/14/2005
*/
BEGIN 
DECLARE
	@VSTR	              NVARCHAR(4000),
	@Result	  	      NVARCHAR(4000);
	set  @VSTR=N'';
	DECLARE CURSOR_1 CURSOR FOR
	SELECT	
	  CASE UPPER(@Format) 
	    when N'L' THEN
   		case when B1_HSE_NBR_START is not null then ltrim(str(B1_HSE_NBR_START)) else N'' end+
		case when ISNULL(B1_HSE_FRAC_NBR_START,N'')<>N'' then N' '+B1_HSE_FRAC_NBR_START else N'' end+    		
  		case when (ISNULL(B1_HSE_NBR_START,N'')<>N'' or ISNULL(B1_HSE_FRAC_NBR_START,N'')<>N'') and (ISNULL(B1_HSE_NBR_END,N'')<>N''or ISNULL(B1_HSE_FRAC_NBR_END,N'')<>N'') then N' -' else N'' end+
		case when B1_HSE_NBR_END is not null then N' '+ltrim(str(B1_HSE_NBR_END)) else N'' end+	
		case when ISNULL(B1_HSE_FRAC_NBR_END,N'')<>N'' then N' '+B1_HSE_FRAC_NBR_END else N'' end+
		case when ISNULL(B1_STR_DIR,N'')<>N'' then N' '+B1_STR_DIR else N'' end+   		
		case when ISNULL(B1_STR_NAME,N'')<>N'' then N' '+B1_STR_NAME else N'' end+
		case when ISNULL(B1_STR_SUFFIX,N'')<>N'' then N' '+B1_STR_SUFFIX else N'' end+
		case when ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')<>N''
			AND ISNULL(B1_UNIT_TYPE,N'')<>N'' then N', '+B1_UNIT_TYPE+N'#' 
		     WHEN ISNULL(B1_UNIT_TYPE,N'')<>N'' THEN B1_UNIT_TYPE+N'##' 
		     ELSE N'' end+
		case when ISNULL(B1_UNIT_START,N'')<>N'' then N' '+B1_UNIT_START else N'' end+
		case when ISNULL(B1_UNIT_START,N'')<>N'' AND ISNULL(B1_UNIT_END,N'')<>N'' then N' - '+B1_UNIT_END 
		     when ISNULL(B1_UNIT_END,N'')<>N'' THEN N' '+B1_UNIT_END
		     else N'' end
	  WHEN N'LALL' THEN 
		case when B1_HSE_NBR_START is not null then ltrim(str(B1_HSE_NBR_START)) else N'' end+
		case when ISNULL(B1_HSE_FRAC_NBR_START,N'')<>N'' then N' '+B1_HSE_FRAC_NBR_START else N'' end+    		
  		case when (ISNULL(B1_HSE_NBR_START,N'')<>N'' or ISNULL(B1_HSE_FRAC_NBR_START,N'')<>N'') and (ISNULL(B1_HSE_NBR_END,N'')<>N''or ISNULL(B1_HSE_FRAC_NBR_END,N'')<>N'') then N' -' else N'' end+
		case when B1_HSE_NBR_END is not null then N' '+ltrim(str(B1_HSE_NBR_END)) else N'' end+	
		case when ISNULL(B1_HSE_FRAC_NBR_END,N'')<>N'' then N' '+B1_HSE_FRAC_NBR_END else N'' end+
		case when ISNULL(B1_STR_DIR,N'')<>N'' then N' '+B1_STR_DIR else N'' end+   		
		case when ISNULL(B1_STR_NAME,N'')<>N'' then N' '+B1_STR_NAME else N'' end+
		case when ISNULL(B1_STR_SUFFIX,N'')<>N'' then N' '+B1_STR_SUFFIX else N'' end+
		case when ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')<>N''
			AND ISNULL(B1_UNIT_TYPE,N'')<>N'' then N', '+B1_UNIT_TYPE+N'#' 
		     WHEN ISNULL(B1_UNIT_TYPE,N'')<>N'' THEN B1_UNIT_TYPE+N'##' 
		     ELSE N'' end+
		case when ISNULL(B1_UNIT_START,N'')<>N'' then N' '+B1_UNIT_START else N'' end+
		case when ISNULL(B1_UNIT_START,N'')<>N'' AND ISNULL(B1_UNIT_END,N'')<>N'' then N' - '+B1_UNIT_END 
		     when ISNULL(B1_UNIT_END,N'')<>N'' THEN N' '+B1_UNIT_END
		     else N'' end+
		CASE WHEN ISNULL(B1_SITUS_CITY,N'')<>N'' THEN
			CASE WHEN ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')+ISNULL(B1_UNIT_TYPE,N'')+ISNULL(B1_UNIT_START,N'')+ISNULL(B1_UNIT_END,N'')<>N''
			     THEN N', '+B1_SITUS_CITY
			   ELSE B1_SITUS_CITY
			END
		     ELSE N'' END+
		CASE WHEN ISNULL(B1_SITUS_STATE,N'')<>N'' THEN
			CASE WHEN ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')+ISNULL(B1_UNIT_TYPE,N'')+ISNULL(B1_UNIT_START,N'')+ISNULL(B1_UNIT_END,N'')+ISNULL(B1_SITUS_CITY,N'')<>N''
			     THEN N', '+B1_SITUS_STATE
			   ELSE B1_SITUS_STATE
			END
		     ELSE N'' END+
		N' '+isnull(B1_SITUS_ZIP,N'')
	  WHEN N'BALL' THEN 
		case when B1_HSE_NBR_START is not null then ltrim(str(B1_HSE_NBR_START)) else N'' end+
		case when ISNULL(B1_HSE_FRAC_NBR_START,N'')<>N'' then N' '+B1_HSE_FRAC_NBR_START else N'' end+    		
  		case when (ISNULL(B1_HSE_NBR_START,N'')<>N'' or ISNULL(B1_HSE_FRAC_NBR_START,N'')<>N'') and (ISNULL(B1_HSE_NBR_END,N'')<>N''or ISNULL(B1_HSE_FRAC_NBR_END,N'')<>N'') then N' -' else N'' end+
		case when B1_HSE_NBR_END is not null then N' '+ltrim(str(B1_HSE_NBR_END)) else N'' end+	
		case when ISNULL(B1_HSE_FRAC_NBR_END,N'')<>N'' then N' '+B1_HSE_FRAC_NBR_END else N'' end+
		case when ISNULL(B1_STR_DIR,N'')<>N'' then N' '+B1_STR_DIR else N'' end+   		
		case when ISNULL(B1_STR_NAME,N'')<>N'' then N' '+B1_STR_NAME else N'' end+
		case when ISNULL(B1_STR_SUFFIX,N'')<>N'' then N' '+B1_STR_SUFFIX else N'' end+
		case when ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')<>N''
			AND ISNULL(B1_UNIT_TYPE,N'')<>N'' then N', '+B1_UNIT_TYPE+N'#' 
		     WHEN ISNULL(B1_UNIT_TYPE,N'')<>N'' THEN B1_UNIT_TYPE+N'##' 
		     ELSE N'' end+
		case when ISNULL(B1_UNIT_START,N'')<>N'' then N' '+B1_UNIT_START else N'' end+
		case when ISNULL(B1_UNIT_START,N'')<>N'' AND ISNULL(B1_UNIT_END,N'')<>N'' then N' - '+B1_UNIT_END 
		     when ISNULL(B1_UNIT_END,N'')<>N'' THEN N' '+B1_UNIT_END
		     else N'' end+
		CASE WHEN ISNULL(B1_SITUS_CITY,N'')<>N'' THEN
			CASE WHEN ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')+ISNULL(B1_UNIT_TYPE,N'')+ISNULL(B1_UNIT_START,N'')+ISNULL(B1_UNIT_END,N'')<>N''
			     THEN CHAR(10)+B1_SITUS_CITY
			   ELSE B1_SITUS_CITY
			END
		     ELSE N'' END+
		CASE WHEN ISNULL(B1_SITUS_STATE,N'')<>N'' THEN
			CASE WHEN ISNULL(LTRIM(STR(B1_HSE_NBR_START)),N'')+ISNULL(LTRIM(STR(B1_HSE_NBR_END)),N'')+ISNULL(B1_HSE_FRAC_NBR_START,N'')+ISNULL(B1_HSE_FRAC_NBR_END,N'')+ISNULL(B1_STR_DIR,N'')+ISNULL(B1_STR_NAME,N'')+ISNULL(B1_STR_SUFFIX,N'')+ISNULL(B1_UNIT_TYPE,N'')+ISNULL(B1_UNIT_START,N'')+ISNULL(B1_UNIT_END,N'')+ISNULL(B1_SITUS_CITY,N'')<>N''
			     THEN N', '+B1_SITUS_STATE
			   ELSE B1_SITUS_STATE
			END
		     ELSE N'' END+
		N' '+isnull(B1_SITUS_ZIP,N'')
	  --ELSE ''
	  END
  	FROM 
    		B3ADDRES 
 	WHERE
    		REC_STATUS = N'A' AND  
    		UPPER(B1_ADDR_SOURCE_FLG)=N'ADR' AND 
    		SERV_PROV_CODE  = @CLIENTID AND
    		B1_PER_ID1 = @PID1 AND
    		B1_PER_ID2 = @PID2 AND
    		B1_PER_ID3 = @PID3
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	WHILE @@FETCH_STATUS = 0
	BEGIN
	  SET @VSTR=LTRIM(RTRIM(@VSTR))
	if (@VSTR <> N'')
		if (ISNULL(@Result,N'') = N'')
			SET @Result = @VSTR
		else
		     if @Delimiter <> N''
			SET @Result = @Result + @Delimiter + @VSTR
		     ELSE
		     	SET @Result = @Result + CHAR(10) + @VSTR
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO

ALTER FUNCTION [dbo].[FN_GET_APP_CONDITION](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5)
                                      ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sandy Yin
    Create Date      :   11/29/2004
    Version          :   AA5.3
    Detail           :   RETURNS: Conditions attached to the application, as a comma-delimited list.
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
    Revision History :
*/
BEGIN 
	DECLARE
		@TEM           NVARCHAR(4000),
		@Result        NVARCHAR(4000);
		set  @TEM=N'';
		set @Result =N'';
DECLARE my_cursor CURSOR FOR 
	SELECT
		DISTINCT ISNULL(B1_CON_COMMENT,N'')
	FROM
		B6CONDIT
	WHERE
		B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID 
OPEN my_cursor
FETCH NEXT FROM my_cursor INTO @TEM
WHILE @@FETCH_STATUS = 0
	BEGIN
	  IF (@Result  =N'')
	  begin
	    IF (@TEM<>N'' )
	      SET @Result =@Result + @TEM;
	  end 
	  else
	    IF (@TEM <>N'' )
		 SET @Result = @Result+N', '+@TEM;  
              FETCH NEXT FROM my_cursor INTO @TEM
	END;
CLOSE my_cursor;
DEALLOCATE my_cursor;
return(@Result); 			
END
GO

ALTER FUNCTION [dbo].[FN_GET_APP_HIERARCHY_ROOT]
		 (
		@CLIENTID NVARCHAR(30),
		@PID1 NVARCHAR(5),
		@PID2 NVARCHAR(5),
		@PID3 NVARCHAR(5)
)  
RETURNS NVARCHAR(500) AS  
/*  Author           :   	Arthur Miao
    Create Date      :   	12/07/2004
    Version          :  	AA5.3 MSSQL
    Detail           :   	RETURNS: root  application name of current application.
                        		ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History :
*/
BEGIN 
DECLARE @APPNAME NVARCHAR(30)
DECLARE @CID NVARCHAR(30)
DECLARE @CID1 NVARCHAR(5)
DECLARE @CID2 NVARCHAR(5)
DECLARE @CID3 NVARCHAR(5)
DECLARE @CNT INT
SELECT @CNT=1
WHILE  @CNT!=0
BEGIN
        select TOP 1
	@CID1=x.b1_master_id1, 
	@CID2=x.b1_master_id2, 
	@CID3=x.b1_master_id3
          From XAPP2REF x
         where x.serv_prov_code = @CLIENTID
           and x.b1_per_id1 = @PID1
           and x.b1_per_id2 = @PID2
           and x.b1_per_id3 = @PID3
           and x.rec_status = N'A'
       SELECT @PID1=@CID1 
       SELECT @PID2=@CID2 
       SELECT @PID3=@CID3
       SELECT @CNT=COUNT(*) FROM XAPP2REF WHERE serv_prov_code = @CLIENTID and b1_per_id1 = @PID1 and b1_per_id2 = @PID2  and b1_per_id3 = @PID3 and rec_status = N'A'
END
SELECT 
	@APPNAME=B1_ALT_ID 
FROM 
	B1PERMIT
WHERE 
	SERV_PROV_CODE=@CLIENTID
	AND B1_PER_ID1=@PID1
	AND B1_PER_ID2=@PID2
	AND B1_PER_ID3=@PID3    
return(@APPNAME)
END
GO

ALTER FUNCTION [dbo].[FN_GET_APP_OCCUPANCY](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5)
                                      ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sandy Yin
    Create Date      :   11/29/2004
    Version          :   AA5.3 MSSQL
    Detail           :   RETURNS: Occupancy types associated with the application, in a comma-delimited list.
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
    Revision History :
*/
BEGIN 
	DECLARE
		@TEM           NVARCHAR(4000),
		@Result        NVARCHAR(4000);
		set  @TEM=N'';
		set @Result =N'';
DECLARE my_cursor CURSOR FOR 
	SELECT
		DISTINCT ISNULL(B1_USE_TYP,N'')
	FROM
		BCALC_VALUATN
	WHERE
		B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID 
OPEN my_cursor
FETCH NEXT FROM my_cursor INTO @TEM
WHILE @@FETCH_STATUS = 0
	BEGIN
	  IF (@Result  =N'')
	  begin
	    IF (@TEM<>N'' )
	      SET @Result =@Result + @TEM;
	  end 
	  else
	    IF (@TEM <>N'' )
		 SET @Result = @Result+N', '+@TEM;  
              FETCH NEXT FROM my_cursor INTO @TEM
	END;
CLOSE my_cursor;
DEALLOCATE my_cursor;
return(@Result); 			
END
GO


ALTER FUNCTION [dbo].[FN_GET_APP_OCCUPANCY_TYPE](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5)
                                      ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sandy Yin
    Create Date      :   11/29/2004
    Version          :   AA5.3 MSSQL
    Detail           :   RETURN: Construction types associated with the application, in a comma-delimited list.
                         ARGUMENTS:  ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
    Revision History :
*/
BEGIN 
	DECLARE
		@TEM           NVARCHAR(4000),
		@Result        NVARCHAR(4000);
		set  @TEM=N'';
		set @Result =N'';
DECLARE my_cursor CURSOR FOR 
	SELECT
		DISTINCT ISNULL(B1_CON_TYP,N'')
	FROM
		BCALC_VALUATN
	WHERE
		B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID 
OPEN my_cursor
FETCH NEXT FROM my_cursor INTO @TEM
WHILE @@FETCH_STATUS = 0
	BEGIN
	  IF (@Result  =N'')
	  begin
	    IF (@TEM<>N'' )
	      SET @Result =@Result + @TEM;
	  end 
	  else
	    IF (@TEM <>N'' )
		 SET @Result = @Result+N', '+@TEM;  
              FETCH NEXT FROM my_cursor INTO @TEM
	END;
CLOSE my_cursor;
DEALLOCATE my_cursor;
return(@Result); 			
END
GO


ALTER FUNCTION [dbo].[FN_GET_ASI_TABLE_VALUE] (@ClientID  NVARCHAR(15),
                                               @PID1  NVARCHAR(5),
                                               @PID2  NVARCHAR(5),
                                               @PID3  NVARCHAR(5),
                                               @P_KeyColumnName  NVARCHAR(100),
                                               @P_KeyColumnValue  NVARCHAR(4000),
                                               @P_ColumnName  NVARCHAR(100),
                                               @P_TableName   NVARCHAR (30)
                                              ) RETURNS NVARCHAR(4000) AS
/* Author      : Lydia Lim
   Create Date : 08/02/2006
   Version     : AA 6.2 MSSQL
   Detail      : RETURNS: The value of the column called {ColumnName} that is related to (i.e. in the same row as) the value {KeyColumnValue} in column {KeyColumnName} of the App Spec Info Table {TableName}.  For example, an application has the following App Spec Info Table called TEAM_INFO with two rows of values:
	STAFF_ROLE       NAME          PHONE_NUMBER
	-------------------------------------------
	Project Leader	 TOM SMITH     415-777-1234
	Plan Reviewer	 JANICE WHITE  415-273-9988	
To retrieve the name of the Project Leader (i.e., TOM SMITH), the ARW expression is FN_GET_ASI_TABLE_VALUE (&$$agencyid$$, B1PERMIT.B1_PER_ID1, B1PERMIT.B1_PER_ID2, B1PERMIT.B1_PER_ID3, 'STAFF_ROLE', 'Project Leader', 'NAME', 'TEAM_INFO').
                 ARGUMENTS: ClientID,
                            PrimaryTrackingID1,			
                            PrimaryTrackingID2,
                            PrimaryTrackingID3,
                            KeyColumnName,
                            KeyColumnValue,
                            ColumnName,
                            TableName 
  Revision History :      08/02/2006   Lydia Lim Initial Design
                          02/09/2007   Sandy Yin Convert from Oracle version
                          05/09/2007   Lydia Lim Correct parameter character lengths             
		    06/13/2007   Add Coalesce() so that NULL can be used instead of ''
*/
BEGIN
declare
@COLUMNVALUE  NVARCHAR(4000)
  SELECT 
        @COLUMNVALUE = A.ATTRIBUTE_VALUE
  FROM
         BAPPSPECTABLE_VALUE A
  WHERE
         A.SERV_PROV_CODE = @ClientID AND
	 A.B1_PER_ID1 = @PID1 AND
	 A.B1_PER_ID2 = @PID2 AND
	 A.B1_PER_ID3 = @PID3 AND
	 A.REC_STATUS = N'A' AND
         UPPER(A.COLUMN_NAME) = UPPER(@P_ColumnName) AND
	 EXISTS (SELECT  N'Y'
                 FROM    BAPPSPECTABLE_VALUE B
                 WHERE   B.SERV_PROV_CODE = @ClientID AND
                         B.B1_PER_ID1 = @PID1 AND
                         B.B1_PER_ID2 = @PID2 AND
                         B.B1_PER_ID3 = @PID3 AND
                         B.REC_STATUS = N'A' AND
		         (COALESCE(@P_TableName,N'')=N'' OR UPPER(B.TABLE_NAME) = UPPER(@P_TableName)) AND
                         UPPER(B.COLUMN_NAME) = UPPER(@P_KeyColumnName) AND
                         UPPER(B.ATTRIBUTE_VALUE) = UPPER(@P_KeyColumnValue) AND
                         A.TABLE_NAME = B.TABLE_NAME AND
                         A.ROW_INDEX = B.ROW_INDEX) 
  RETURN (@COLUMNVALUE)
END
GO


ALTER FUNCTION [dbo].[FN_GET_ASI_TABLE_VALUE_BYROW] (@CLIENTID     NVARCHAR(15),
                                                    @PID1         NVARCHAR(5),
                                                    @PID2         NVARCHAR(5),
                                                    @PID3         NVARCHAR(5),
                                                    @ROWNUMBER    INT,
                                                    @COLUMNNAME   NVARCHAR(100),
                                                    @COLUMNNUMBER INT,
                                                    @TABLENAME    NVARCHAR(30)
                                                   ) RETURNS NVARCHAR (200)  AS
/*  Author           :   Lydia Lim
    Create Date      :   02/07/2007
    Version          :   AA6.3 MSSQL
    Detail           :   RETURNS: The value for column {ColumnName} in row number {RowNumber} for the App Spec Info Table {TableName}.  The column number {ColumnNumber} may be used instead of {ColumnName}.  Note that Accela Automation assigns row numbers and column numbers beginning with zero, i.e., 0, 1, 2, etc.
                 ARGUMENTS: ClientID,
                            PrimaryTrackingID1,			
                            PrimaryTrackingID2,
                            PrimaryTrackingID3,
                            RowNumber,
                            ColumnName (optional if ColumnNumber is used),
                            ColumnNumber (optional if ColumnName is used),
                            TableName (Optional)
Revision History:   02/07/2007  Lydia Lim    Initial
*/
BEGIN 
	DECLARE
	    @COLUMNVALUE NVARCHAR(200);
	SET @COLUMNVALUE = N'';
	SELECT TOP 1
	    @COLUMNVALUE = ISNULL(A.ATTRIBUTE_VALUE,N'')     
	FROM
	    BAPPSPECTABLE_VALUE A
	WHERE
	    A.SERV_PROV_CODE = @CLIENTID AND
	    A.B1_PER_ID1 = @PID1 AND
	    A.B1_PER_ID2 = @PID2 AND
	    A.B1_PER_ID3 = @PID3 AND
	    A.REC_STATUS = N'A' AND
	    A.ROW_INDEX = @ROWNUMBER AND
	    ( @COLUMNNAME is NULL OR 
	     @COLUMNNAME = N'' OR
	     UPPER(A.COLUMN_NAME) = UPPER(@COLUMNNAME)
	    ) AND
	    ( @COLUMNNUMBER is NULL OR 
	      @COLUMNNUMBER = N'' OR
	      A.COLUMN_INDEX = @COLUMNNUMBER
	    ) AND
	    ( @TABLENAME is NULL OR 
	      @TABLENAME = N'' OR
	      UPPER(A.TABLE_NAME) = UPPER(@TABLENAME)
	    );
	RETURN(@COLUMNVALUE);
END
GO


ALTER FUNCTION [dbo].[FN_GET_CITATION_INFO](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5),
                                      @Get_Field NVARCHAR(20),
                                      @CASE_NBR NVARCHAR(100) 
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author           :   Sandy Yin
    Create Date      :   07/11/2005
    Version          :   AA5.3
    Detail           :   RETURNS: Information about Citation Number {CitationCaseNum}, if {CitationCaseNum} is not specified, returns information about the first Citation on the Case. If {Get_Field} is 'COMMENT', returns violation comment; if {Get_Field} is 'NUMBER', returns citation number.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, Get_Field ('COMMENT' for Citation Comment, 'NUMBER' for Citation Number), CitationCaseNum (optional)
    Revision History :   07/11/2005  sandy Yin Initial Design
*/
BEGIN 
 	DECLARE
		@TEM        NVARCHAR(250),
		@C3_CITATION_CASE_NBR  NVARCHAR(250),
  	        @C3_CITATION_SEQ_NBR INT,
  	        @C3_VIOLATION_EVIDENCE   NVARCHAR(250);
	SELECT
	  	TOP 1
	  	@C3_CITATION_CASE_NBR  = C3_CITATION_CASE_NBR,
  	        @C3_CITATION_SEQ_NBR   = C3_CITATION_SEQ_NBR,
  	        @C3_VIOLATION_EVIDENCE = C3_VIOLATION_EVIDENCE
	  FROM
	  	C3CITATION
	  WHERE
	  	REC_STATUS = N'A' AND
	  	((@CASE_NBR<>N'' AND C3_CITATION_CASE_NBR=@CASE_NBR) OR @CASE_NBR =N'') AND
	  	B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID 
 IF UPPER(@Get_Field)=N'NUMBER'  
   	SET 	@TEM=@C3_CITATION_CASE_NBR 
  ELSE IF UPPER(@Get_Field)=N'SEQ_NBR'  
	SET 	@TEM=@C3_CITATION_SEQ_NBR
  ELSE IF UPPER(@Get_Field)=N'COMMENT'
	SET 	@TEM=@C3_VIOLATION_EVIDENCE
	 RETURN(@TEM)
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONDITION_ALL]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5),
         @Get_Field NVARCHAR(15),
	 @Delimiter NVARCHAR(500)
	 )
RETURNS NVARCHAR(4000) AS
/*  Author           :   Arthur Miao
    Create Date      :   11/04/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: All conditions for application, separated by {Separator}. Returns field value as specified by {Get_Field}.  If {Get_Field} is 'NAME' OR '', returns condition name; if {Get_Field} is 'COMMENT', returns condition comment. 
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    Get_Field (options: 'NAME' (default), 'COMMENT'), 
                                    Separator (default is single line break).
  Revision History :	 11/04/2005 Arthur Miao initial design 
                         12/01/2005 Arthur Miao add 'OR (@OrderLen IS NULL)' 
			 02/20/2006 Arthur Miao add @Get_Field='COMMENT1' function
			 03/02/2006 Arthur Miao modified for bug 05SSP-00277.B60228
*/
BEGIN 
DECLARE
	@VSTR	              NVARCHAR(4000),
	@Result	  	      NVARCHAR(4000),
	@OrderLen	      int
	set  @VSTR=N'';
----- Get the maximal Order Number ----------------------
	SELECT	
		@OrderLen=max(B6CONDIT.B1_DISPLAY_ORDER)
  	FROM 
    		B6CONDIT 
 	WHERE
    		REC_STATUS = N'A' AND  
    		SERV_PROV_CODE  = @CLIENTID AND
    		B1_PER_ID1 = @PID1 AND
    		B1_PER_ID2 = @PID2 AND
    		B1_PER_ID3 = @PID3 AND
		LTRIM(ISNULL(B6CONDIT.B1_CON_COMMENT,N''))<>N''
---- Get Display Order and Comments /Condition name-----------------------------	
DECLARE CURSOR_1 CURSOR FOR
     	SELECT	
	  CASE WHEN UPPER(@Get_Field)=N'NAME' OR ISNULL(@Get_Field,N'')=N'' THEN ISNULL(B1_CON_DES,N'')
	       WHEN UPPER(@Get_Field)=N'COMMENT' THEN
			CASE WHEN (@OrderLen<10)  THEN	
			--Max number of Order less then 10
				CASE WHEN B1_DISPLAY_ORDER IS NULL THEN N'.   '
					ELSE (convert(NVARCHAR(10), B6CONDIT.B1_DISPLAY_ORDER) + N'. ')
				END
			WHEN @OrderLen<100 THEN		
			--Max number of Order between 10 and 99
				CASE WHEN B1_DISPLAY_ORDER IS NULL THEN N'.      '
					ELSE 
					   CASE WHEN B1_DISPLAY_ORDER<10 THEN (convert(NVARCHAR(10), B6CONDIT.B1_DISPLAY_ORDER) + N'.    ')
						ELSE (convert(NVARCHAR(10), B6CONDIT.B1_DISPLAY_ORDER) + N'. ')
					   END
				END
			END
			+ LTRIM(ISNULL(B6CONDIT.B1_CON_COMMENT,N''))
		WHEN UPPER(@Get_Field)=N'COMMENT1' THEN
			LTRIM(ISNULL(B6CONDIT.B1_CON_COMMENT,N''))
	  END
  	FROM 
    		B6CONDIT 
 	WHERE
    		REC_STATUS = N'A' AND  
    		SERV_PROV_CODE  = @CLIENTID AND
    		B1_PER_ID1 = @PID1 AND
    		B1_PER_ID2 = @PID2 AND
    		B1_PER_ID3 = @PID3 AND
		(UPPER(@Get_Field)!=N'COMMENT1' OR
			(
			B1_CON_TYP=N'BLDG FINAL' AND 
		 	B1_CON_STATUS=N'Applied' AND 
		 	UPPER(@Get_Field)=N'COMMENT1'
			)
		) AND
		LTRIM(ISNULL(B6CONDIT.B1_CON_COMMENT,N''))<>N''
	ORDER BY B1_DISPLAY_ORDER
OPEN CURSOR_1
FETCH NEXT FROM CURSOR_1 INTO @VSTR
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @VSTR=RTRIM(@VSTR)
	if (@VSTR <> N'')
		if (ISNULL(@Result,N'') = N'')
			SET @Result = @VSTR
		else
		     if @Delimiter <> N''
			SET @Result = @Result + @Delimiter + @VSTR
		     ELSE
		     	SET @Result = @Result + CHAR(10) + @VSTR
FETCH NEXT FROM CURSOR_1 INTO @VSTR
END 
CLOSE CURSOR_1;
DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONDITION_ORDER_ALL]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5),
         @Con_Type NVARCHAR(10),
         @Get_Field NVARCHAR(15),
	 @Delimiter NVARCHAR(500)
	 )
RETURNS NVARCHAR(4000) AS
/*  Author           :   Cece Wang
    Create Date      :   09/13/2006
    Version          :   AA6.2 MS SQL
    Detail           :   RETURNS: All conditions for application by order[like 1. comment 2. comment  ....], separated by {Separator}. Returns field value as specified by {Get_Field}.  If {Get_Field} is 'NAME' OR '', returns condition name; if {Get_Field} is 'COMMENT', returns condition comment. 
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    Condition Type,
                                    Get_Field (options: 'NAME' (default), 'COMMENT'), 
                                    Separator (default is single line break).
  Revision History :	09/13/2006  Initial Design based on dbo.FN_GET_CONDITION_ALL  
*/
BEGIN 
DECLARE
	@VSTR	              NVARCHAR(4000),
	@Result	  	      NVARCHAR(4000),
	@OrderLen	      INT,     
        @Order                INT;
	SET  @VSTR=N'';
        SET  @Order =1;
DECLARE CURSOR_1 CURSOR FOR
     	SELECT	
	  CASE WHEN UPPER(@Get_Field)=N'NAME' OR ISNULL(@Get_Field,N'')=N'' THEN ISNULL(B1_CON_DES,N'')
	       WHEN UPPER(@Get_Field)=N'COMMENT' THEN
			LTRIM(ISNULL(B6CONDIT.B1_CON_COMMENT,N''))
	  END
  	FROM 
    		B6CONDIT 
 	WHERE
    		REC_STATUS = N'A' AND  
    		SERV_PROV_CODE  = @CLIENTID AND
    		B1_PER_ID1 = @PID1 AND
    		B1_PER_ID2 = @PID2 AND
    		B1_PER_ID3 = @PID3 AND
               (ISNULL(@Con_Type,N'')=N'' OR (UPPER(B1_CON_TYP) LIKE UPPER(@Con_Type))) 
	ORDER BY B1_DISPLAY_ORDER
OPEN CURSOR_1
FETCH NEXT FROM CURSOR_1 INTO @VSTR
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @VSTR=RTRIM(@VSTR)
	if (@VSTR <> N'')
		if (ISNULL(@Result,N'') = N'')
		        SET @Result = CONVERT(NVARCHAR,@Order)  + N'. '+@VSTR
		else
		     if @Delimiter <> N''
			SET @Result = @Result + @Delimiter + CONVERT(NVARCHAR,@Order)  + N'. ' +@VSTR
		     ELSE
		     	SET @Result = @Result + CHAR(10) +CONVERT(NVARCHAR,@Order)  + N'. '+ @VSTR
SET @Order = @Order +1 
FETCH NEXT FROM CURSOR_1 INTO @VSTR
END 
CLOSE CURSOR_1;
DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONST_TYPE_DESC](
	@CLIENTID NVARCHAR(15),
	@PID1 NVARCHAR(5),
	@PID2 NVARCHAR(5),
	@PID3 NVARCHAR(5)
	)  
RETURNS NVARCHAR(2000) AS  
/*  Author           :   	Arthur Miao
    Create Date      :   	12/29/2004
    Version          :  	AA6.0 MS SQL
    Detail           :   	RETURNS: Construction type description 
                        	ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History   :		12/29/2004  Arthur Miao Initial Design
				10/17/2005  Lucky Song renames the function name as FN_GET_CONST_TYPE_DESC
                                02/06/2006  Lydia Lim Add code to drop function before creating it.
                                06/13/2007  Lydia Lim Add missing condition to 2nd query.
*/
BEGIN 
DECLARE @VSTR NVARCHAR(2000),
	    @CNT INT
SELECT	
	@CNT=COUNT (SERV_PROV_CODE) 
FROM	
	RBIZDOMAIN_VALUE
WHERE	
	SERV_PROV_CODE =@CLIENTID AND
	BIZDOMAIN=N'CENSUS_BUREAU_CONSTRUCTION_TYPE_CODE' AND
	REC_STATUS = N'A'
SELECT	
	 @VSTR=RB.VALUE_DESC
FROM	
	BPERMIT_DETAIL BPE,
	RBIZDOMAIN_VALUE RB
WHERE	
	RB.SERV_PROV_CODE = (CASE @CNT WHEN 0 THEN N'STANDARDDATA' ELSE @CLIENTID END) AND
	BPE.SERV_PROV_CODE = @CLIENTID AND	
	BPE.REC_STATUS = N'A' AND
	BPE.B1_PER_ID1 =@PID1 AND
	BPE.B1_PER_ID2 = @PID2 AND
	BPE.B1_PER_ID3 = @PID3 AND
	BPE.CONST_TYPE_CODE = RB.BIZDOMAIN_VALUE AND
	RB.BIZDOMAIN=N'CENSUS_BUREAU_CONSTRUCTION_TYPE_CODE'
	RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONSTRUCTION](@CLIENTID NVARCHAR(15),
				        @CONS_TYPE NVARCHAR(250))
				        RETURNS NVARCHAR(2000) AS
/*  Author           :   Glory Wang
    Create Date      :   12/29/2004
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Construction code + '-' + Construction description
    ARGUMENTS        :   ClientId ,construction code
  Revision History :   12/29/2004 Glory Wang  Initial Design 
                               05/10/2007 Lucky Song Correct parameter character lengths
*/
BEGIN
  DECLARE 
    @V_VALUE_DESC NVARCHAR(2000)
  SELECT 
	@V_VALUE_DESC = BIZDOMAIN_VALUE + N'-' + VALUE_DESC
  FROM
	RBIZDOMAIN_VALUE
  WHERE
	SERV_PROV_CODE = @CLIENTID
  AND	BIZDOMAIN = N'CENSUS_BUREAU_CONSTRUCTION_TYPE_CODE'
  AND   BIZDOMAIN_VALUE = @CONS_TYPE
  AND   REC_STATUS = N'A'
RETURN (@V_VALUE_DESC)
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONTACT_ATTRIBUTE](@CLIENTID  NVARCHAR(15),
                                              @PID1  NVARCHAR(5),
                                              @PID2  NVARCHAR(5),
                                              @PID3  NVARCHAR(5),
                                              @CONTACTTYPE  NVARCHAR(30),
                                              @ATTRIBUTENAME NVARCHAR(70),
                                              @PRIMARYCONTACTFLA NVARCHAR(1))
                                              RETURNS NVARCHAR(200) AS
/*  Author           :   Glory Wang
    Create Date      :   06/27/2005
    Version          :   AA6.01 MSSQL
    Detail           :   RETURNS: Custom attribute {ContactAttribute} for the primary contact if {PrimaryContactFlag} is 'Y'. If {PrimaryContactFlag} is '', retrieves the primary contact if available, else the first contact found. If {ContactType} is also specified, selects the first contact of {ContactType} that also meets the {PrimaryContactFlag} criteria.  Note that {ContactAttribute} is the attribute name, not the attribute label.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    ContactType (optional), 
                                    ContactAttribute (wildcard % may be used), 
                                    PrimaryContactFlag (options: 'Y', '')
  Revision History   :	 06/27/2005  Glory Wang  Inital Design
                         10/12/2005  Cece Wang   Added "ORDER BY B1_FLAG DESC" for the 2nd query: If {PrimaryContactFlag} is 'N', primary contact is given selection priority.
                         10/19/2005  Lydia Lim   Edit comments
                         06/14/2007  Lydia Lim   Add Coalesce() to allow NULL instead of '';  Allow wildcard % in @AttributeName; Add code to delete function before creating
*/
BEGIN
  DECLARE
    @V_NBR NVARCHAR(30),
    @V_VALUE NVARCHAR(200);
 IF @PRIMARYCONTACTFLA= N'Y' 
  BEGIN
     SELECT TOP 1
             @V_NBR = B1_CONTACT_NBR
     FROM   
            B3CONTACT
     WHERE 
            SERV_PROV_CODE = @CLIENTID
     AND    B1_PER_ID1 = @PID1
     AND    B1_PER_ID2 = @PID2
     AND    B1_PER_ID3 = @PID3
     AND    REC_STATUS = N'A'
     AND    (UPPER(B1_CONTACT_TYPE) = UPPER(@CONTACTTYPE) OR COALESCE(@CONTACTTYPE,N'') = N'')
     AND    B1_FLAG = N'Y'
  END
 ELSE
    BEGIN
     SELECT TOP 1
            @V_NBR = B1_CONTACT_NBR
     FROM   
            B3CONTACT
     WHERE 
           SERV_PROV_CODE = @CLIENTID
    AND    B1_PER_ID1 = @PID1
    AND    B1_PER_ID2 = @PID2
    AND    B1_PER_ID3 = @PID3
    AND    REC_STATUS = N'A'
    AND    (UPPER(B1_CONTACT_TYPE) = UPPER(@CONTACTTYPE) OR COALESCE(@CONTACTTYPE,N'') = N'')
    ORDER BY B1_FLAG DESC
   END
  IF @V_NBR IS NOT NULL
    SELECT TOP 1
           @V_VALUE = B1_ATTRIBUTE_VALUE
    FROM   B3CONTACT_ATTRIBUTE
    WHERE  SERV_PROV_CODE = @CLIENTID
    AND    B1_PER_ID1 = @PID1
    AND    B1_PER_ID2 = @PID2
    AND    B1_PER_ID3 = @PID3
    AND    REC_STATUS = N'A'
    AND    B1_CONTACT_NBR = @V_NBR
    AND    (UPPER(B1_CONTACT_TYPE) = UPPER(@CONTACTTYPE) OR COALESCE(@CONTACTTYPE,N'') = N'')
    AND    UPPER(B1_ATTRIBUTE_NAME) LIKE UPPER(@ATTRIBUTENAME)
  ELSE
    SET @V_VALUE = NULL
  RETURN @V_VALUE
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONTACT_NAME_N_ORG] (@CLIENTID  NVARCHAR(15),
 				      	    @PID1    NVARCHAR(5),
 				      	    @PID2    NVARCHAR(5),
 				      	    @PID3   NVARCHAR(5)
 				      	    ) RETURNS NVARCHAR (200)  AS
/*  Author           :   Glory Wang
    Create Date      :   12/01/2004
    Version          :   AA6.0 MSSQL
    Detail           :   First name and Long Name and organization (separated by space & comma)of the primary contact whose Relationship is Builder, this needs to be First Name & Last Name & "," & Organization Name
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ChecklistDescription.
  Revision History :
*/
BEGIN 
DECLARE 	
  @VSTR NVARCHAR(200),
  @B1_FNAME NVARCHAR(20),
  @B1_LNAME NVARCHAR(40),
  @B1_BUSINESS_NAME NVARCHAR(80)
  SET @VSTR = N''
  SELECT
    @VSTR = B1_FNAME+B1_LNAME+B1_BUSINESS_NAME,
    @B1_FNAME = B1_FNAME,
    @B1_LNAME = B1_LNAME,    
    @B1_BUSINESS_NAME = B1_BUSINESS_NAME 
  FROM   
    B3CONTACT
  WHERE  SERV_PROV_CODE  =@CLIENTID
  AND    B1_PER_ID1 = @PID1
  AND	 B1_PER_ID2 = @PID2
  AND 	 B1_PER_ID3 = @PID3
  AND    REC_STATUS = N'A'
  AND  	 B1_FLAG=N'Y'
  AND    UPPER(B1_RELATION) = N'BUILDER'
  IF @VSTR = N'' 
    BEGIN
      SELECT TOP 1
        @B1_FNAME = B1_FNAME,
        @B1_LNAME = B1_LNAME,    
        @B1_BUSINESS_NAME = B1_BUSINESS_NAME 
      FROM   
        B3CONTACT
      WHERE  SERV_PROV_CODE  =@CLIENTID
      AND    B1_PER_ID1 = @PID1
      AND    B1_PER_ID2 = @PID2
      AND    B1_PER_ID3 = @PID3
      AND    REC_STATUS = N'A'
      AND    UPPER(B1_RELATION) = N'BUILDER'
    END
  SET @VSTR = @B1_FNAME
  IF @B1_LNAME  <> N'' SET @VSTR = CASE WHEN @VSTR = N'' THEN @B1_LNAME ELSE @VSTR + N' ' + @B1_LNAME END
  IF @B1_BUSINESS_NAME  <> N'' SET @VSTR = CASE WHEN @VSTR = N'' THEN @B1_BUSINESS_NAME ELSE @VSTR + N', ' + @B1_BUSINESS_NAME END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_DATE_FORMATTED]
 ( @CLIENTID NVARCHAR(15),
   @Date Datetime, 
   @DateFormat NVARCHAR(50)
)
RETURNS NVARCHAR(30) 
AS
/*   Author            :   Sandy Yin 
     Create Date       :   11/11/2005
     Version           :   AA6.1 MS SQL
     Detail            :   RETURNS:  {Date} in the format specified by {DateFormat}. If {DateFormat} is 'DAY_DATE_FULL', 
returns date in the format "Day, Month ddth Year", e.g. Thursday, July 7th 2005. 
    			   ARGUMENTS: ClientID, Date, DateFormat (options: 'DAY_DATE_FULL')
  Revision History     :   Sandy Yin initial design 11/11/2005
*/
BEGIN
	DECLARE  @Result NVARCHAR(30);
	IF @DateFormat=N'DAY_DATE_FULL'
	SET @Result= convert(NVARCHAR,datename(weekday,@Date) +N', '+datename(month ,@Date)+N' '+convert(NVARCHAR,day(@Date))+
		     CASE WHEN convert(NVARCHAR,day(@Date)) =N'1' THEN N'st ' 
		     WHEN convert(NVARCHAR,day(@Date)) =N'2' THEN N'nd ' 
		     WHEN convert(NVARCHAR,day(@Date)) =N'3' THEN N'rd '
		     WHEN convert(NVARCHAR,day(@Date)) =N'21' THEN N'st '
		     WHEN convert(NVARCHAR,day(@Date)) =N'22' THEN N'nd '
		     WHEN convert(NVARCHAR,day(@Date)) =N'23' THEN N'rd ' 
		     WHEN convert(NVARCHAR,day(@Date)) =N'31' THEN N'st '
		     ELSE N'th ' END 
		     +convert(NVARCHAR,year(@Date)))
	Return @Result ;
END
GO


ALTER FUNCTION [dbo].[FN_GET_FEE_APPLIED] (@CLIENTID      NVARCHAR(15),
 				      	                 @PID1          NVARCHAR(5),
                                      	 @PID2          NVARCHAR(5),
                                      	 @PID3          NVARCHAR(5),
										 @FEEITEMSEQNBR BIGINT,
										 @GET_FIELD     NVARCHAR(20)
                                      	) RETURNS NVARCHAR(30)  AS
/*  Author           :   Lydia Lim
    Create Date      :   2/13/2007
    Version          :   AA6.3 MS SQL
    Detail           :   RETURNS: If {Get_Field} is 'AMOUNT' or '', returns sum of payments applied to the fee whose sequence number is {FeeitemSeqNbr}. If {Get_Field} is 'DATE', returns date when the latest payment was applied to the fee whose sequence number is {FeeitemSeqNbr}.  If {Get_Field} is 'RECEIPT NBR', returns receipt number of the latest payment that was applied to the fee whose sequence number is {FeeitemSeqNbr}.  If {Get_Field} is 'RECEIPT CUSTOM', returns custom receipt number of the latest payment that was applied to the fee whose sequence number is {FeeitemSeqNbr}.
    ARGUMENTS        :   ClientID, 
	                     PrimaryTrackingID1, 
						 PrimaryTrackingID2, 
						 PrimaryTrackingID3, 
						 FeeitemSeqNbr,
						 Get_Field (options: 'AMOUNT','DATE','RECEIPT NBR','RECEIPT CUSTOM', 'CASHIER ID','APPLIED BY')
    Revision History :   2/13/2007  Lydia Lim  Create from Oracle version (07SSP-00063).
			     4/10/2007  Ben Holmes Changed Return (@RET) size to VARCHAR(30) and added V_CUSTOM_RECEIPT variable to account for string type custom 
						receipt numbers in Sacramento County
*/
BEGIN 
	DECLARE 
		@V_AMOUNT NUMERIC(15,2),
		@V_DATE DATETIME,
		@V_RECEIPT BIGINT,
		@V_CUSTOM_RECEIPT NVARCHAR(30),
		@V_NAME NVARCHAR(70),
		@RET NVARCHAR(30);
		SET @RET=N''
  IF UPPER(@GET_FIELD)=N'DATE'
    BEGIN
		SELECT 
		  @V_DATE = MAX(TRAN_DATE)
		FROM   
		  ACCOUNTING_AUDIT_TRAIL
		WHERE  
		         SERV_PROV_CODE = @CLIENTID
		  AND    B1_PER_ID1 = @PID1
		  AND    B1_PER_ID2 = @PID2
	      AND    B1_PER_ID3 = @PID3
	      AND    FEEITEM_SEQ_NBR = @FEEITEMSEQNBR
	      AND    REC_STATUS = N'A'
	      AND    ACTION in (N'Payment Applied')
		SET @RET = CONVERT(CHAR,@V_DATE,101)
	END
  ELSE IF UPPER(@GET_FIELD)=N'RECEIPT NBR'
    BEGIN
	  SELECT TOP 1
	    @V_RECEIPT=RECEIPT_NBR
	  FROM
	    F4PAYMENT
	  WHERE
	        SERV_PROV_CODE=@CLIENTID
	    AND B1_PER_ID1 = @PID1
		AND B1_PER_ID2 = @PID2
	    AND B1_PER_ID3 = @PID3
		AND REC_STATUS = N'A' 
		AND PAYMENT_SEQ_NBR =
			(SELECT 
				MAX(PAYMENT_SEQ_NBR)
			 FROM   
				ACCOUNTING_AUDIT_TRAIL
			 WHERE  
			         SERV_PROV_CODE = @CLIENTID
			  AND    B1_PER_ID1 = @PID1
			  AND    B1_PER_ID2 = @PID2
		      AND    B1_PER_ID3 = @PID3
		      AND    FEEITEM_SEQ_NBR = @FEEITEMSEQNBR
		      AND    REC_STATUS = N'A'
		      AND    ACTION in (N'Payment Applied')
			 )
	  SET @RET = RTRIM(LTRIM(CAST(@V_RECEIPT AS CHAR)))
	END
  ELSE IF UPPER(@GET_FIELD)=N'RECEIPT CUSTOM'
    BEGIN
	  SELECT TOP 1
	    @V_CUSTOM_RECEIPT=RECEIPT_CUSTOMIZED_NBR
      FROM
	    F4RECEIPT
	  WHERE
	    SERV_PROV_CODE=@CLIENTID
		AND RECEIPT_NBR =
		( SELECT 
		    RECEIPT_NBR 
		  FROM
		    F4PAYMENT
		  WHERE
		        SERV_PROV_CODE=@CLIENTID
		    AND B1_PER_ID1 = @PID1
			AND B1_PER_ID2 = @PID2
		    AND B1_PER_ID3 = @PID3
			AND REC_STATUS = N'A' 
			AND PAYMENT_SEQ_NBR =
				(SELECT 
					MAX(PAYMENT_SEQ_NBR)
				 FROM   
					ACCOUNTING_AUDIT_TRAIL
				 WHERE  
				         SERV_PROV_CODE = @CLIENTID
				  AND    B1_PER_ID1 = @PID1
				  AND    B1_PER_ID2 = @PID2
			      AND    B1_PER_ID3 = @PID3
			      AND    FEEITEM_SEQ_NBR = @FEEITEMSEQNBR
			      AND    REC_STATUS = N'A'
			      AND    ACTION in (N'Payment Applied')
				 )
		)
	  SET @RET = RTRIM(LTRIM(CAST(@V_CUSTOM_RECEIPT AS CHAR)))
	END
  ELSE IF UPPER(@GET_FIELD) IN (N'CASHIER ID',N'APPLIED BY')
    BEGIN
	  SELECT TOP 1
	    @V_NAME = CASE UPPER(@GET_FIELD) WHEN N'CASHIER ID' THEN CASHIER_ID
		                                 WHEN N'APPLIED BY' THEN REC_FUL_NAM
										 END
	  FROM
		ACCOUNTING_AUDIT_TRAIL
	  WHERE
			SERV_PROV_CODE=@CLIENTID
		AND B1_PER_ID1 = @PID1
		AND B1_PER_ID2 = @PID2
		AND B1_PER_ID3 = @PID3
		AND REC_STATUS = N'A' 
		AND FEEITEM_SEQ_NBR = @FEEITEMSEQNBR
		AND ACTION in (N'Payment Applied')
	  ORDER BY
	    PAYMENT_SEQ_NBR DESC
	  SET @RET = @V_NAME
	END
  ELSE 
  --default is 'AMOUNT'
    BEGIN
		SELECT 
		  @V_AMOUNT=SUM(TRAN_AMOUNT)
		FROM   
		  ACCOUNTING_AUDIT_TRAIL
		WHERE  
		         SERV_PROV_CODE = @CLIENTID
		  AND    B1_PER_ID1 = @PID1
		  AND    B1_PER_ID2 = @PID2
		  AND    B1_PER_ID3 = @PID3
		  AND    FEEITEM_SEQ_NBR = @FEEITEMSEQNBR
		  AND    REC_STATUS = N'A'
		  AND    ACTION in (N'Payment Applied',N'Void Payment Applied',N'Refund Applied')
		SET @RET = RTRIM(LTRIM(STR(@V_AMOUNT,36,2)))
	END  
  RETURN @RET
END
GO


ALTER FUNCTION [dbo].[FN_GET_FEE_ASSESSED_TOTAL](@CLIENTID  NVARCHAR(50),
 				      	    @PID1    NVARCHAR(50),
 				      	    @PID2    NVARCHAR(50),
 				      	    @PID3   NVARCHAR(50)
 				      	    ) RETURNS FLOAT AS
/*  Author           :   Arthur Miao
    Create Date      :   05/18/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Total value of assessed fees, excluding voided and credited fees.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History   :   Arthur Miao             Initial Design
                         Lydia Lim   06/24/2005  Exclude voided and credited fees
*/	
begin
DECLARE	  @AssessedFee NUMERIC(15,2) 
set @AssessedFee=0 
         begin
		SELECT
   			@AssessedFee=isnull(SUM(GF_FEE),0) 
		FROM
			F4FEEITEM
		WHERE  
		       SERV_PROV_CODE = @CLIENTID AND
		       UPPER(REC_STATUS) = N'A' AND
		       B1_PER_ID1 = @PID1 AND		
		       B1_PER_ID2 = @PID2 AND		
		       B1_PER_ID3 = @PID3 AND
                       GF_ITEM_STATUS_FLAG IN (N'NEW',N'INVOICED')
           end
return @AssessedFee
end
GO


ALTER FUNCTION [dbo].[FN_GET_FEE_DESC_FEE_ALL](@CLIENTID  NVARCHAR(15),
																								 @PID1    NVARCHAR(5),
																								 @PID2    NVARCHAR(5),
																								 @PID3    NVARCHAR(5)
																								 ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sunny Chen
    Create Date      :   09/02/2005
    Version          :   AA5.3
    Detail           :   RETURNS: List of all invoiced fees, in the format [Fee Description $Fee Amount]. Each fee is on a new line.  Fees appear in the same order as on AA's Assess Fee screen.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
    Revision History :	 Sunny Chen Initial Design
*/
BEGIN 
DECLARE
	@TEM	  NVARCHAR(4000),
	@Result	  NVARCHAR(4000);
	set  @TEM=N'';
	set  @Result =N'';
	DECLARE CURSOR_1 CURSOR FOR
	SELECT
	      LTRIM(RTRIM(GF_DES)) + N' $' + LTRIM(RTRIM(STR(GF_FEE,36,2)))
	FROM 
	      F4FEEITEM
	WHERE B1_PER_ID1 = @PID1 
	  AND B1_PER_ID2 = @PID2 
	  AND B1_PER_ID3 = @PID3 
	  AND SERV_PROV_CODE = @CLIENTID 
	  AND REC_STATUS =N'A' 
          AND GF_ITEM_STATUS_FLAG=N'INVOICED'
	ORDER BY GF_DISPLAY,GF_SUB_GROUP,GF_DES,GF_COD
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @TEM
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if (@TEM <> N'')
			if (@Result = N'')
				SET @Result = @TEM
			else
				SET @Result = @Result + CHAR(10) + @TEM
				FETCH NEXT FROM CURSOR_1 INTO @TEM
	END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_FEE_FIRST] (@CLIENTID NVARCHAR(15),
				         @PID1 NVARCHAR(5),
                                         @PID2 NVARCHAR(5),
                                         @PID3 NVARCHAR(5),
                                         @GET_FIELD NVARCHAR(100) ,
                                         @FEECODE NVARCHAR(100),
                                         @ISINVOICED NVARCHAR(1),
                                         @PAYSTATUS NVARCHAR(15)
					 )RETURNS NVARCHAR(100) AS
/*  Author         :   Lydia Lim
     Create Date   :   08/25/2006
     Version       :   AA6.2 MS SQL
     Detail        :   RETURNS: Info about earliest assessed fee on the application whose fee code is like {FeeItemCode}; if {IsInvoiced} is 'Y', returns fee only if it is invoiced. If {PaymentStatus} is 'PAID FULL', returns fee only if is paid in full. If {Get_Field} is 'AMOUNT', returns the fee amount; if {Get_Field} is 'DOLLAR AMT', returns fee amount in currency format, if {Get_Field} is 'DATE' and {IsInvoice} is 'Y', returns invoice date in format MM/DD/YYYY; if {Get_Field} is 'DATE' and {IsInvoice} is 'N', returns assessed date in format MM/DD/YYYY. Returns NULL if no fee is found.
                       ARGUMENTS: ClientID, 
                                  PrimaryTrackingID1, 
                                  PrimaryTrackingID2, 
                                  PrimaryTrackingID3, 
                                  Get_Field (Options: 'AMOUNT'(default),'DOLLAR AMT','DATE','DESCRIPTION','INVOICE NUM'),
				  FeeItemCode (optional, % wildcard may be used),
                                  IsInvoiced (Options: 'Y'(default), 'N'),
                                  PaymentStatus (Optional; Options: 'PAID FULL','')
  Revision History :   08/25/2006 Lydia Lim  Modified from FN_GET_FEE_LATEST			
*/
BEGIN
declare @V_RET NVARCHAR(100) 
declare @TMPPOS INT
declare @SEQNUM BIGINT
SET @SEQNUM = 0
   BEGIN
      SELECT TOP 1 
               @V_RET = 
                   CASE UPPER(@GET_FIELD)  
                     WHEN N'SEQ NBR'         THEN CAST(F4.FEEITEM_SEQ_NBR AS NVARCHAR)  
                     WHEN N'DATE'            THEN CONVERT(NVARCHAR,F4.REC_DATE,101)                             
                     WHEN N'AMOUNT'          THEN CAST (F4.GF_FEE AS NVARCHAR)
                     WHEN N'DOLLAR AMT DATE' THEN N'$'+CONVERT(NVARCHAR,CAST(F4.GF_FEE AS MONEY),1)+N' '+CONVERT(NVARCHAR,F4.REC_DATE ,101)
		     WHEN N'DOLLAR AMT'      THEN N'$'+CONVERT(NVARCHAR,CAST(F4.GF_FEE AS MONEY),1)
                     WHEN N'DESCRIPTION'     THEN GF_DES
                     ELSE                        CAST (F4.GF_FEE AS NVARCHAR)    
                   END,
               @SEQNUM = F4.FEEITEM_SEQ_NBR
      FROM
        F4FEEITEM F4
      WHERE
    	F4.SERV_PROV_CODE = @CLIENTID	AND 
    	F4.B1_PER_ID1 = @PID1 		AND 
    	F4.B1_PER_ID2 = @PID2 		AND 
	F4.B1_PER_ID3 = @PID3 		AND 
	F4.REC_STATUS=N'A' 		AND
	(@ISINVOICED=N'N' AND F4.GF_ITEM_STATUS_FLAG=N'NEW' OR F4.GF_ITEM_STATUS_FLAG=N'INVOICED') AND
	 F4.REC_STATUS = N'A'   AND
	(@FEECODE=N'' OR( @FEECODE<>N'' AND UPPER(F4.GF_COD) like UPPER(@FEECODE))) AND
        (@PAYSTATUS = N'' OR  @PAYSTATUS<>N'' AND UPPER(@PAYSTATUS)=N'PAID FULL' AND
         f4.GF_FEE <= 0  )                                        
     ORDER BY F4.GF_FEE_APPLY_DATE     
IF UPPER(@GET_FIELD)=N'INVOICE NUM' AND @SEQNUM<>0
  BEGIN
    SELECT TOP 1
      @V_RET = CAST(X.INVOICE_NBR AS NVARCHAR) 
    FROM
      X4FEEITEM_INVOICE X
    WHERE
      X.SERV_PROV_CODE = @CLIENTID AND
      X.FEEITEM_SEQ_NBR = @SEQNUM
  END
RETURN(@V_RET)
END
END
GO


ALTER FUNCTION [dbo].[FN_GET_FEE_LATEST] (@CLIENTID NVARCHAR(15),
				         @PID1 NVARCHAR(5),
                                         @PID2 NVARCHAR(5),
                                         @PID3 NVARCHAR(5),
                                         @GET_FIELD NVARCHAR(100) ,
                                         @FEECODELIST NVARCHAR(100),
                                         @ISINVOICED NVARCHAR(1)
					 )RETURNS NVARCHAR(100) AS
/*  Author         :   Sandy Yin 
     Create Date   :   07/03/2006
     Version       :   AA6.1 MS SQL
     Detail        :   RETURNS: Info about latest fee on the application whose fee code is in the list {FeeCodeList}; if {IsInvoiced} is 'Y', returns fee only if it is invoiced. If {Get_Field} is 'AMOUNT', returns the fee amount; if {Get_Field} is 'DOLLAR AMT', returns fee amount in currency format, if {Get_Field} is 'DATE' and {IsInvoice} is 'Y', returns invoice date in format MM/DD/YYYY; if {Get_Field} is 'DATE' and {IsInvoice} is 'N', returns assessed date in format MM/DD/YYYY. Returns NULL if no fee is found.
                       ARGUMENTS: ClientID, 
                                  PrimaryTrackingID1, 
                                  PrimaryTrackingID2, 
                                  PrimaryTrackingID3, 
                                  Get_Field (Options: 'AMOUNT'(default),'DOLLAR AMT','DATE','DESCRIPTION'),
				  FeeCodeList (may be comma-delimited list),
                                  IsInvoiced (Options: 'Y'(default), 'N')
  Revision History :   04/04/2006 Sandy Yin Initial Design			
*/
BEGIN
declare @V_RET NVARCHAR(100) 
declare @VSTR NVARCHAR(4000)
declare @VTEM NVARCHAR(4000)
declare @LASTSTRING NVARCHAR(4000)
declare @STARTPOS INT
declare @ENDPOS INT
declare @TMPPOS INT
SET @STARTPOS = 1
SET @TMPPOS = 1
SET @VSTR = N''
if CHARINDEX(N',',@FEECODELIST)=0 AND @FEECODELIST <> N'' AND @FEECODELIST IS NOT NULL
   BEGIN
	 SELECT TOP 1 
                    @V_RET = 
                     CASE UPPER(@GET_FIELD)  
                     WHEN N'SEQ NBR'         THEN CAST(F4.FEEITEM_SEQ_NBR AS NVARCHAR)  
                     WHEN N'DATE'            THEN CONVERT(NVARCHAR,F4.REC_DATE,101)                             
                     WHEN N'AMOUNT'          THEN CAST (F4.GF_FEE AS NVARCHAR)
                     WHEN N'DOLLAR AMT DATE' THEN N'$'+CONVERT(NVARCHAR,CAST(F4.GF_FEE AS SMALLMONEY),1)+N' '+CONVERT(NVARCHAR,F4.REC_DATE ,101)
		     WHEN N'DOLLAR AMT'      THEN N'$'+CONVERT(NVARCHAR,CAST(F4.GF_FEE AS SMALLMONEY),1)
                     WHEN N'DESCRIPTION'     THEN GF_DES
                     ELSE                        CAST (F4.GF_FEE AS NVARCHAR)    
                     END
  FROM
    	F4FEEITEM F4
  WHERE
    	F4.SERV_PROV_CODE = @CLIENTID	AND 
    	F4.B1_PER_ID1 = @PID1 		AND 
    	F4.B1_PER_ID2 = @PID2 		AND 
	F4.B1_PER_ID3 = @PID3 		AND 
	F4.REC_STATUS=N'A' 		AND
	(@ISINVOICED=N'N' AND F4.GF_ITEM_STATUS_FLAG=N'NEW' OR F4.GF_ITEM_STATUS_FLAG=N'INVOICED') AND
	F4.REC_STATUS = N'A'   AND
	F4.GF_COD =@FEECODELIST
      ORDER BY F4.REC_DATE DESC
 END
ELSE 
 BEGIN
 WHILE (@TMPPOS<=LEN(@FEECODELIST))
	BEGIN
		IF (SUBSTRING(@FEECODELIST,@TMPPOS,1) = N',')
	                 BEGIN
		            	SET @VTEM = LTRIM(RTRIM(SUBSTRING(@FEECODELIST,@STARTPOS,@TMPPOS-@STARTPOS)))                
				IF (@VTEM != N'')
				      BEGIN
					    IF (@VSTR != N'')
					     	 SET @VSTR=@VSTR+N','''+@VTEM+N''''
				  	    ELSE
			               	   	 SET @VSTR=N''''+@VTEM+N''''
				      END
		    		SET @TMPPOS = @TMPPOS +1
				SET @STARTPOS = @TMPPOS
	                END
		ELSE
	                   SET @TMPPOS = @TMPPOS +1			
	END
  SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@FEECODELIST,@STARTPOS,@TMPPOS-@STARTPOS)))
	IF (@LASTSTRING != N'')
		BEGIN
			IF (@VSTR=N'')
				SET @VSTR =@VSTR + N''''+ @LASTSTRING+N''''
			ELSE
				SET @VSTR =@VSTR +  N','''+@LASTSTRING+N''''
		END  
      BEGIN    
      SELECT TOP 1                                      
                   @V_RET = 
                     CASE UPPER(@GET_FIELD)  
                     WHEN N'SEQ NBR'         THEN CAST(F4.FEEITEM_SEQ_NBR AS NVARCHAR)  
                     WHEN N'DATE'            THEN CONVERT(NVARCHAR,F4.REC_DATE,101)                             
                     WHEN N'AMOUNT'          THEN CAST (F4.GF_FEE AS NVARCHAR)
                     WHEN N'DOLLAR AMT DATE' THEN N'$'+CONVERT(NVARCHAR,CAST(F4.GF_FEE AS SMALLMONEY),1)+N' '+CONVERT(NVARCHAR,F4.REC_DATE ,101)
		     WHEN N'DOLLAR AMT'      THEN N'$'+CONVERT(NVARCHAR,CAST(F4.GF_FEE AS SMALLMONEY),1)
                     WHEN N'DESCRIPTION'     THEN GF_DES
                     ELSE                        CAST (F4.GF_FEE AS NVARCHAR)    
                     END
  FROM
    	F4FEEITEM F4
  WHERE
    	F4.SERV_PROV_CODE = @CLIENTID	AND 
    	F4.B1_PER_ID1 = @PID1 		AND 
    	F4.B1_PER_ID2 = @PID2 		AND 
	F4.B1_PER_ID3 = @PID3 		AND 
	F4.REC_STATUS=N'A' 		AND
	(@ISINVOICED=N'N' AND F4.GF_ITEM_STATUS_FLAG=N'NEW' OR F4.GF_ITEM_STATUS_FLAG=N'INVOICED') AND
	F4.REC_STATUS = N'A'   AND	      
       ( (@FEECODELIST <> N'' and @FEECODELIST is not null and CHARINDEX(UPPER(F4.GF_COD),UPPER(@VSTR))>0 ) OR  (@FEECODELIST = N'' or @FEECODELIST is null))
      ORDER BY F4.REC_DATE DESC
   END
 END 
RETURN(@V_RET)
END
GO


ALTER FUNCTION [dbo].[FN_GET_FEEITEM_INFO](@CLIENTID  NVARCHAR(15),
 				      @FeeSchedule    NVARCHAR(12),
                                      @FeeItemCode    NVARCHAR(15),
                                      @FeePaymentPeriod   NVARCHAR(15),
				      @GET_FIELD   NVARCHAR(15)
                                      ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   12/19/2005
    Version          :   AA6.1.1 MSSQL
    Detail           :   RETURNS: configuration infomation, as specified in GET_FIELD, for the fee item whose fee schedule, fee code and payment period are {FeeSchedule}, {FeeItemCode} and {FeePaymentPeriod} respectively. 
    ARGUMENTS        :   ClientID, FeeSchedule, FeeItemCode, FeePaymentPeriod, Get_Field ('GF_FORMULA' for Calc Variable)
    Revision History :   David Zheng Initial Design 
                                05/10/2007 Lucky Song Correct character length for variable @R1_GF_FORMULA                                                                
*/
BEGIN 
 	DECLARE
		@TEM        NVARCHAR(4000),
		@R1_GF_FORMULA  NVARCHAR(4000)
	SELECT
		TOP 1
	  	@R1_GF_FORMULA  =R1_GF_FORMULA
	  FROM
	  	RFEEITEM
	  WHERE
	  	UPPER(R1_FEE_CODE)= UPPER(@FeeSchedule) AND
	  	UPPER(R1_GF_COD) = UPPER(@FeeItemCode)  AND
		UPPER(R1_GF_FEE_PERIOD) = UPPER(@FeePaymentPeriod) AND
		SERV_PROV_CODE = @CLIENTID AND
		REC_STATUS = N'A'
 IF UPPER(@GET_FIELD)=N'GF_FORMULA'  
   	SET 	@TEM=@R1_GF_FORMULA 
 /* ELSE IF UPPER(@GET_FIELD)='XXX'  
	SET 	@TEM=@XXX */
	 RETURN(@TEM)
END
GO


ALTER FUNCTION [dbo].[FN_GET_FISCAL_YEAR]( @Client              NVARCHAR(15),
                                        @Date                DATETIME,
                                        @FiscalYrStartMonth  INT,
                                        @FiscalYrFormat      NVARCHAR(15)
                                      ) RETURNS NVARCHAR(15) AS
/*  Author           :   Lydia Lim
    Create Date      :   04/24/2006
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: Fiscal year of {Date} in the format {FiscalYrFormat}. The fiscal year begins with the month represented by integer {FiscalYrStartMonth} (e.g., if fiscal year begins on July 1, {FiscalYrStartMonth} is 7). If {FiscalYrFormat} is 'YYYY', returns the 2nd calendar year of fiscal year (e.g. 2006), if {FiscalYrFormat} is 'RRRR-YY', returns both calendar years of fiscal year, e.g. (2005-06).  Returns NULL if {Date} is null or ''.
                         ARGUMENTS: ClientID,
                                    Date,
                                    FiscalYrStartMonth (default is 7),
                                    FiscalYrFormat (options: 'YYYY','RRRR/YYYY','RRRR-YY','RRRR/YY'(default))
    Revision History :   04/24/2006  Lydia Lim		Initial
*/
BEGIN
  DECLARE 
    @RET NVARCHAR(15),
    @MTH INT,
    @RRRR NVARCHAR(4),
    @YYYY NVARCHAR(4)
  IF @Date is NULL or @Date = N''
    RETURN (NULL)
  IF @FiscalYrStartMonth is NULL OR @FiscalYrStartMonth>12 OR @FiscalYrStartMonth<1
    SET @MTH = 7
  ELSE
    SET @MTH = CAST(@FiscalYrStartMonth AS INT)
  IF DATEPART(Month, @Date) >= @MTH 
    BEGIN
      SET @RRRR = CAST( DATEPART(Year, @Date)   AS NVARCHAR(4))
      SET @YYYY = CAST( DATEPART(Year, @Date)+1 AS NVARCHAR(4))
    END
  ELSE
    BEGIN
      SET @RRRR = CAST( DATEPART(Year, @Date)-1 AS NVARCHAR(4))
      SET @YYYY = CAST( DATEPART(Year, @Date)   AS NVARCHAR(4))
    END
  SELECT @RET = CASE UPPER(@FiscalYrFormat)
                  WHEN N'YYYY'      THEN @YYYY
                  WHEN N'RRRR/YYYY' THEN @RRRR + N'/' + @YYYY
                  WHEN N'RRRR-YY'   THEN @RRRR + N'-' + SUBSTRING(@YYYY,3,2)
                  ELSE                  @RRRR + N'/' + SUBSTRING(@YYYY,3,2)
                END
  RETURN(@RET)
END
GO


ALTER FUNCTION [dbo].[FN_GET_G6ACTION_ORDERBY](@P_G6_ACT_DD DATETIME,
                                           @P_G6_ACT_T1 NVARCHAR(10),
                                           @P_G6_ACT_T2 NVARCHAR(10))
RETURNS NVARCHAR(30) AS
BEGIN
    DECLARE @V_ORDERBY     NVARCHAR(30)
    DECLARE @V_G6_ACT_DD   NVARCHAR(30)
    DECLARE @V_G6_ACT_T1   NVARCHAR(30)
    DECLARE @V_G6_ACT_T2   NVARCHAR(30)
    SET @V_G6_ACT_DD =N''
    SET @V_G6_ACT_T1 =N''
    SET @V_G6_ACT_T2 =N''
    SELECT @V_G6_ACT_DD = CONVERT(NVARCHAR,@P_G6_ACT_DD,111) 
    IF CHARINDEX(N'AM', @P_G6_ACT_T1) > 0 
        BEGIN
             SET @V_G6_ACT_T1 =N'AM'
        END
     ELSE IF CHARINDEX(N'PM', @P_G6_ACT_T1) > 0 
        BEGIN
             SET @V_G6_ACT_T1 =N'PM'
        END 	
     ELSE
         BEGIN
             SET @V_G6_ACT_T1 =N''
         END 
    --
    IF @P_G6_ACT_T2 IS NOT NULL OR @P_G6_ACT_T2 <> N''
    BEGIN
       IF CHARINDEX(N':', @P_G6_ACT_T2) = 2
       BEGIN
           SET @V_G6_ACT_T2 = N'0'+ @P_G6_ACT_T2
       END
       ELSE IF CHARINDEX(N':', @P_G6_ACT_T2) = 3
           IF SUBSTRING(@P_G6_ACT_T2,1,CHARINDEX(N':', @P_G6_ACT_T2)-1) = N'12'
           BEGIN
               SET @V_G6_ACT_T2 = N'00'+SUBSTRING(@P_G6_ACT_T2,CHARINDEX(N':', @P_G6_ACT_T2),DATALENGTH(@P_G6_ACT_T2))
           END    
       ELSE
       BEGIN
           SET @V_G6_ACT_T2 = @P_G6_ACT_T2
       END
    END
    ELSE
    BEGIN
        SET @V_G6_ACT_T2 = N''
    END
    SET @V_ORDERBY = @V_G6_ACT_DD+@V_G6_ACT_T1+@V_G6_ACT_T2
    RETURN @V_ORDERBY
END
GO


ALTER FUNCTION [dbo].[FN_GET_GUIDESHEET_ITEM_INFO](@CLIENTID  NVARCHAR(15),
                                           @PID1    NVARCHAR(5),
                                           @PID2    NVARCHAR(5),
                                           @PID3   NVARCHAR(5),
                                           @GET_FIELD NVARCHAR(200),
                                           @GuidesheetType NVARCHAR(4000),
                                           @GuidesheetItems NVARCHAR(4000),
                                           @GuidesheetStatus NVARCHAR(100)
                                           ) RETURNS NVARCHAR(200)  AS
/*  Author           :   Sandy Yin
    Create Date      :   08/14/2006
    Version          :   AA6.2 MSSQL
    Detail           :   RETURNS:  Info about the first guidesheet item called {GuideSheetItemText} in the inspection guidesheet {GuideSheetName}.  If the item status {Status} is specified, selects only the item with the specified status.
                         ARGUMENTS  :   ClientID, 
                                        PrimaryTrackingID1, 
                                        PrimaryTrackingID2, 
                                        PrimaryTrackingID3, 
                                        Get_Field (Options: 'COMMENTS', 'GUIDESHEET NAME', 'ITEM', 'STATUS'), 
                                        GuideSheetName (optional),
                                        GuideSheetItemText (optional),
                                        Status (optional).
  Revision History   :	 08/14/2006  Sandy Yin   Inital Design      
                         08/23/2006  Lydia Lim   Make parameters case insensitive                   
*/
BEGIN 
  DECLARE 	
    @VCOMMETS NVARCHAR(4000),
    @VGuidesheetType NVARCHAR(100),
    @VGuidesheetStatus NVARCHAR(100),
    @VGuidesheetItems NVARCHAR(4000),
    @V_VALUE  NVARCHAR(4000) SET  @V_VALUE=N''
  SELECT  TOP 1
	 @VCOMMETS = GGUIDESHEET_ITEM .GUIDE_ITEM_COMMENT,
	 @VGuidesheetType = GGUIDESHEET_ITEM .GUIDE_TYPE,
	 @VGuidesheetStatus = GGUIDESHEET_ITEM .GUIDE_ITEM_STATUS,
         @VGuidesheetItems =  GGUIDESHEET_ITEM.GUIDE_ITEM_TEXT
  FROM
	 GGUIDESHEET, 
	 GGUIDESHEET_ITEM 
WHERE 
	  GGUIDESHEET.SERV_PROV_CODE = @CLIENTID AND
          GGUIDESHEET.B1_PER_ID1 = @PID1 AND
          GGUIDESHEET.B1_PER_ID2 = @PID2 AND
          GGUIDESHEET.B1_PER_ID3 = @PID3 AND
          GGUIDESHEET.REC_STATUS = N'A' AND
          GGUIDESHEET.SERV_PROV_CODE =GGUIDESHEET_ITEM.SERV_PROV_CODE AND  
          GGUIDESHEET.GUIDESHEET_SEQ_NBR=GGUIDESHEET_ITEM.GUIDESHEET_SEQ_NBR AND
          GGUIDESHEET_ITEM.REC_STATUS=N'A' AND
         ((@GuidesheetType<>N'' AND UPPER(GGUIDESHEET_ITEM .GUIDE_TYPE)=UPPER(@GuidesheetType))OR @GuidesheetType=N'') AND
          ((@GuidesheetStatus<>N'' AND UPPER(GGUIDESHEET_ITEM .GUIDE_ITEM_STATUS)=UPPER(@GuidesheetStatus) ) OR @GuidesheetStatus=N'') AND
          ((@GuidesheetItems<>N'' AND UPPER(GGUIDESHEET_ITEM.GUIDE_ITEM_TEXT)=UPPER(@GuidesheetItems)) OR @GuidesheetItems=N'')
  IF UPPER(@GET_FIELD) = N'COMMENTS'
    SET @V_VALUE = @VCOMMETS
 IF UPPER(@GET_FIELD) IN (N'TYPE',N'GUIDESHEET NAME')
    SET @V_VALUE = @VGuidesheetType
  IF UPPER(@GET_FIELD) = N'STATUS'
    SET @V_VALUE = @VGuidesheetStatus
  IF UPPER(@GET_FIELD) IN (N'ITEMS',N'ITEM')
    SET @V_VALUE = @VGuidesheetItems
  RETURN @V_VALUE
END
GO


ALTER FUNCTION [dbo].[FN_GET_GUIDESHEETITEM_CNT](
					      @CLIENTID 		NVARCHAR(15),
                                              @PID1  			NVARCHAR(5),
                                              @PID2  			NVARCHAR(5),
                                              @PID3  			NVARCHAR(5),
					      @GUIDE_TYPE  		NVARCHAR(30),
					      @GUIDE_ITEM_TEXT 		NVARCHAR(2000),
					      @GUIDE_ITEM_STATUS  	NVARCHAR(30),
                                              @G6_ACT_TYP               NVARCHAR(50)
 				              ) RETURNS  INT  AS
/*  Author           :   David Zheng
    Create Date      :   08/23/2006
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: The number of guidesheet items on the application whose item text is like {GuideSheetItemText} and whose status is like {Status}.  Guidesheet items can also be filtered by guidesheet name {GuideSheetName} and inspection description {ActivityType}.
                         ARGUMENTS: CLIENTID, 
                                    PrimaryTrackingID1, 
				    PrimaryTrackingID2, 
				    PrimaryTrackingID3,
				    GuideSheetName (optional, % wildcard may be used),
				    GuideSheetItemText (optional, % wildcard may be used),
				    Status (% wildcard may be used),
                                    ActivityType (optional, % wildcard may be used)
    Revision History :   08/23/2006  David Zheng Initial Design
                         08/23/2006  Lydia Lim   Edit parameters and query to make function more flexible
*/
BEGIN
	DECLARE
              @V_COUNT INT
	SELECT 
		@V_COUNT =  COUNT(GI.GUIDE_ITEM_SEQ_NBR)
	FROM 
		DBO.B1PERMIT P,
		DBO.GGUIDESHEET G,
		DBO.GGUIDESHEET_ITEM GI  
	WHERE 
		P.SERV_PROV_CODE=@CLIENTID AND
		P.B1_PER_ID1=@PID1 AND 
		P.B1_PER_ID2=@PID2 AND
		P.B1_PER_ID3=@PID3 AND
		P.REC_STATUS=N'A' AND
		P.SERV_PROV_CODE=G.SERV_PROV_CODE AND
		P.B1_PER_ID1=G.B1_PER_ID1 AND 
		P.B1_PER_ID2=G.B1_PER_ID2 AND
		P.B1_PER_ID3=G.B1_PER_ID3 AND
		G.REC_STATUS=N'A' AND
		(UPPER(G.GUIDE_TYPE) LIKE UPPER(@GUIDE_TYPE) OR @GUIDE_TYPE = N'') AND
		G.SERV_PROV_CODE = GI.SERV_PROV_CODE AND
		G.GUIDESHEET_SEQ_NBR = GI.GUIDESHEET_SEQ_NBR AND
		(UPPER(GI.GUIDE_ITEM_TEXT) LIKE UPPER(@GUIDE_ITEM_TEXT) OR @GUIDE_ITEM_TEXT=N'') AND
		UPPER(GI.GUIDE_ITEM_STATUS) LIKE UPPER(@GUIDE_ITEM_STATUS) AND
                (@G6_ACT_TYP=N'' OR G.G6_ACT_NUM IN (SELECT G6.G6_ACT_NUM
                                                    FROM   DBO.G6ACTION G6
                                                    WHERE  G6.SERV_PROV_CODE=@CLIENTID AND
                                                           G6.B1_PER_ID1=@PID1 AND 
                                                           G6.B1_PER_ID2=@PID2 AND 
                                                           G6.B1_PER_ID3=@PID3 AND 
                                                           G6.REC_STATUS=N'A' AND
                                                           UPPER(G6.G6_ACT_TYP) LIKE UPPER(@G6_ACT_TYP) ) )
	RETURN @V_COUNT		
END
GO


ALTER FUNCTION [dbo].[FN_GET_HEARING_LATEST] (@CLIENTID  NVARCHAR(15),
                                           @PID1    NVARCHAR(5),
                                           @PID2    NVARCHAR(5),
                                           @PID3   NVARCHAR(5),
                                           @GET_FIELD NVARCHAR(200),
                                           @HEARINGBODY NVARCHAR(100)
                                           ) RETURNS NVARCHAR(200)  AS
/*  Author           :   Glory Wang
    Create Date      :   05/25/2005
    Version          :   AA6.01 MSSQL
    Detail           :   RETURNS:  Info about the latest hearing scheduled for the application for the hearing body {HearingBody}. If {HearingBody} is not specified in arguments, returns info about the latest hearing scheduled for the application. If {Get_Field} is 'DATE', returns hearing date with format MM/DD/YYYY; If {Get_Field} is 'TIME', returns hearing time with format HH:MI A.M., e.g. 3:30 P.M.; If {Get_Field} is 'DAY', returns hearing day of week; If {Get_Field} is 'DURATION', returns hearing duration in minutes; If {Get_Field} is 'LOCATION', returns hearing location.
    ARGUMENTS        :   ClientID, 
                         PrimaryTrackingID1, 
                         PrimaryTrackingID2, 
                         PrimaryTrackingID3, 
                         Get_Field (Options: 'DATE', 'TIME', 'DAY', 'DURATION', 'LOCATION','HEARING BODY'), 
                         HearingBody (optional).                                    
  Revision History   :	 Glory Wang 05/25/2005 Inital Design
                         Sandy Yin  08/03/2006 Change Time format :00;
                         Lucky Song 06/14/2007 Revised function to match Oracle Version.  (Reviesed time format, added {Get_Field} = 'HEARING BODY' ) 
*/
BEGIN 
  DECLARE 	
    @V_VALUE NVARCHAR(200),
    @V_DATE DATETIME,
    @V_CODE NVARCHAR(100),
    @V_TIME NVARCHAR(8),
    @V_DOFWK NVARCHAR(9),
    @V_DURATION NVARCHAR(8),    
    @V_HEARINGBODY NVARCHAR(100),
    @V_GET_FIELD NVARCHAR(200)
  SELECT @V_HEARINGBODY = UPPER(@HEARINGBODY), @V_GET_FIELD = UPPER(@GET_FIELD) 
 SELECT  TOP 1
          @V_DATE = P3_SCHED_DATE,
          @V_TIME = CASE WHEN  CHARINDEX(P3_SCHED_TIME,N':00')>0 THEN P3_SCHED_TIME ELSE P3_SCHED_TIME+N':00' END,
          @V_DOFWK = P3_SCHED_DOFWK,
          @V_DURATION = P3_SCHED_DURATION,
          @V_CODE = P3_SCHED_PLACE_CODE, 
          @V_HEARINGBODY = P3_SCHED_ACT_DESC 
  FROM
          PHCALEND
  WHERE			
          SERV_PROV_CODE = @CLIENTID AND
          B1_PER_ID1 = @PID1 AND
          B1_PER_ID2 = @PID2 AND
          B1_PER_ID3 = @PID3 AND
          REC_STATUS = N'A' AND
          (UPPER(P3_SCHED_ACT_DESC) = @V_HEARINGBODY OR @V_HEARINGBODY = N'')
  ORDER BY	
          P3_SCHED_DATE DESC 
  IF @V_GET_FIELD = N'DATE'
    SET @V_VALUE = CONVERT(CHAR,@V_DATE,101)
  IF @V_GET_FIELD = N'TIME'       
    BEGIN 
       SELECT @V_VALUE = RIGHT(CONVERT(CHAR(20),CONVERT(DATETIME,@V_TIME), 100),8)       
       SET @V_VALUE = RTRIM(REPLACE(REPLACE ( @V_VALUE, N'PM', N' P.M.'),N'AM',N' A.M.'))  
    END 
  IF @V_GET_FIELD = N'DAY'
    SET @V_VALUE = @V_DOFWK
  IF @V_GET_FIELD = N'DURATION'
    SET @V_VALUE = @V_DURATION
  IF @V_GET_FIELD = N'LOCATION'
    SET @V_VALUE = @V_CODE
  IF @V_GET_FIELD = N'HEARING BODY'   
    SET @V_VALUE = @V_HEARINGBODY  
  RETURN @V_VALUE
END
GO


ALTER FUNCTION [dbo].[FN_GET_INITCAP](@CLIENTID  NVARCHAR(15), 
				    @text NVARCHAR(4000)
 				      	    ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   04/12/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: {Text} with case changed to Initial Capitals (Title Case).
    			 ARGUMENTS: ClientID, Text
  Revision History   :	 David Zheng Inital Design
  			 Bright add "if(@length=0)return ''", if @text is null then return ''.
  			 06/28/2005  Sunny Chen add "@char = char(10)", if the text is one a new line, the first letter will not be a lower case.
                         02/06/2006  Lydia Lim Drop Function before creating it.
*/
begin
	declare 	
		@counter int, 
		@length int,
		@char char(1),
		@textnew NVARCHAR(4000)
	set @text	= rtrim(@text)
	set @text	= lower(@text)
	set @length 	= len(@text)
	set @counter 	= 1
	if(@length=0)return N''
	set @text = upper(left(@text, 1) ) + right(@text, @length - 1) 
	while @counter <> @length 
	--+ 1
	begin
		select @char = substring(@text, @counter, 1)
		IF @char = space(1)  or @char =  N'_' or @char = N','  or @char = N'.' or @char = N'\'
 				or @char = N'/' or @char = N'(' or @char = N')' or @char = char(10)
		begin
			set @textnew = left(@text, @counter)  + upper(substring(@text, 
					@counter+1, 1)) + right(@text, (@length - @counter) - 1)
			set @text = @textnew
		end
		set @counter = @counter + 1
	end
	return @text
end
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_COMMENT] (@CLIENTID     NVARCHAR(15),
 				      	           @PID1         NVARCHAR(5),
 				      	           @PID2         NVARCHAR(5),
 				      	           @PID3         NVARCHAR(5),
                                                   @Act_Num      NVARCHAR(50),
 				      	           @COMMENTTYPE  NVARCHAR(50)
                                                   ) RETURNS NVARCHAR (4000) AS
/*  Author           :   Jack.Wang
    Create Date      :   09/01/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS:  Comments for the inspection whose activity number is {ActivityNum}.  If {CommentType} is 'SCHEDULE', returns Schedule Comments; if {CommentType} is 'RESULT', returns Result Comments.
                         ARGUMENTS: CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ActivityNum, CommentType (options: 'SCHEDULE','RESULT').
    Revision History :   09/01/2005  JackWang   Initial Design
			 09/20/2005  Lydia Lim  Remove Upper() function on comments (function will return comments in original case); Fix CommentType logic.
*/
BEGIN
	DECLARE
           @TEXT NVARCHAR(4000),
           @VSTR NVARCHAR(4000)				    
	IF UPPER(@COMMENTTYPE)=N'SCHEDULE'
	   BEGIN	
               SELECT TOP 1
			  @TEXT = TEXT
		FROM 
			  BACTIVITY_COMMENT
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND 	
			  G6_ACT_NUM = @Act_Num    AND
			  COMMENT_TYPE = N'Inspection Request Comment'
		SET @VSTR = @TEXT
 	    END
	ELSE 
	   BEGIN	
               SELECT TOP 1
			  @TEXT = TEXT
		FROM 
			  BACTIVITY_COMMENT
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND 	
			  G6_ACT_NUM = @Act_Num    AND
			  COMMENT_TYPE = N'Inspection Result Comment'
		SET @VSTR = @TEXT
 	    END
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_COMPLETED_FIRST] (@CLIENTID     NVARCHAR(15),
 				      	           @PID1         NVARCHAR(5),
 				      	           @PID2         NVARCHAR(5),
 				      	           @PID3         NVARCHAR(5),
                                                   @ActivityDesc NVARCHAR(70),
 				      	           @Get_Field    NVARCHAR(15), 	
 				      	           @CASE         NVARCHAR(1),
                                                   @Add_Days     INT ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   
    Create Date      :   08/05/2006
    Version          :   AA6.2 MS SQL
    Detail           :   RETURNS: Info about the First Completed inspection whose Inspection Name is {ActivityDesc}, if {ActivityDesc} is not specified in arguments, returns info about the latest completed inspection.  If {Get_Field} is 'INSPECTION', returns inspection name; if {Get_Field} is 'INSPECTOR', returns inspector's name in the format [First] [Middle] [Last], if {Get_Field} is 'INSP DATE', returns inspection Completed date in the format MM/DD/YYYY; if {Get_Field} is 'FOLLOW UP DATE', returns inspection Completed date plus {Add_Days} days in the format MM/DD/YYYY, if {Get_Field} is 'COMMENT', returns inspection comment.  
                         ARGUMENTS: CLIENTID, 
                         	    PrimaryTrackingID1, 
                         	    PrimaryTrackingID2, 
                         	    PrimaryTrackingID3, 
                         	    ActivityDesc (optional), 
                         	    Get_Field (Options: 'INSPECTION', 'INSPECTOR', 'INSP DATE', 'FOLLOW UP DATE', 'COMMENT'), 
                         	    Case ('U' for uppercase, 'I' for initial-caps, blank for original case), 
                         	    Add_Days (number, optional).
    Revision History :   08/05/2005  Sandy Yin Initial Design
                                05/10/2007  Lucky Song Correct parameter character lengths   
*/
BEGIN
	DECLARE
           @NAME1 NVARCHAR(100),
           @DATE1 NVARCHAR(20),
           @DATE2 NVARCHAR(20),
           @ACT_NUM BIGINT,
           @TEXT NVARCHAR(4000),
           @VSTR NVARCHAR(4000),
           @ACT_DES NVARCHAR(70),
           @NUM_DAYS INT
        IF @ADD_DAYS = 0
             SET @NUM_DAYS = 0
        ELSE
             SET @NUM_DAYS = @ADD_DAYS
	BEGIN				
		SELECT 	  TOP 1 
			  @NAME1 = GA_FNAME + CASE WHEN GA_MNAME IS NULL THEN N'' ELSE CASE WHEN GA_FNAME IS NULL THEN GA_MNAME ELSE N' ' + GA_MNAME END END  +  
			  	   CASE WHEN GA_LNAME IS NULL THEN N'' ELSE CASE WHEN isnull(GA_FNAME,N'') + isnull(GA_MNAME,N'')=N''  THEN GA_LNAME ELSE N' ' + GA_LNAME END END ,
                          @DATE1 =  CASE WHEN ISNULL(G6_COMPL_DD,N'')<> N'' THEN CONVERT(NVARCHAR(20),G6_COMPL_DD,101)+N' '+isnull(G6_COMPL_T2,N'')+isnull(G6_COMPL_T1 ,N'')
                                    ELSE CONVERT(NVARCHAR(20),G6_ACT_DD,101)+N' '+isnull(G6_ACT_T2,N'')+isnull(G6_ACT_T1 ,N'')  
                                    END ,
			  @DATE2 = CASE WHEN ISNULL(G6_COMPL_DD,N'')<> N'' THEN SUBSTRING(CONVERT(CHAR(10),G6_COMPL_DD+@Num_Days,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),G6_COMPL_DD,1)))
			            ELSE  SUBSTRING(CONVERT(CHAR(10),G6_ACT_DD+@Num_Days,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),G6_ACT_DD,1)))
			            END,			            
			  @ACT_NUM = G6_ACT_NUM,
                          @ACT_DES = G6_ACT_DES
		FROM 
			  G6ACTION
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND
			  UPPER(G6_ACT_GRP) = N'INSPECTION' AND
			  G6_DOC_DES in (N'Insp Completed', N'Insp Compeleted') AND
                          ((@ActivityDesc <> N'' AND UPPER(G6_ACT_DES) = UPPER(@ActivityDesc))OR
                           @ActivityDesc = N'') 
		ORDER BY  G6_COMPL_DD, G6_COMPL_T1, G6_COMPL_T2     
		SELECT 
			  @TEXT = TEXT
		FROM 
			  BACTIVITY_COMMENT
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND 	
			  G6_ACT_NUM = @Act_Num    AND
			  UPPER(COMMENT_TYPE) = N'INSPECTION RESULT COMMENT'			      		      	  				
	END	
	IF UPPER(@Get_Field) = N'INSPECTOR' 
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @NAME1 = UPPER(@NAME1)
			ELSE IF UPPER(@CASE) = N'I'
				SET @NAME1 = DBO.FN_GET_INITCAP(@CLIENTID, @NAME1)
			SET @VSTR = @NAME1
		END
	ELSE IF UPPER(@Get_Field) = N'INSP DATE'
		SET @VSTR = @DATE1
	ELSE IF UPPER(@Get_Field) = N'FOLLOW UP DATE'
		SET @VSTR = @DATE2	
	ELSE IF UPPER(@Get_Field) LIKE N'COMMENT%'
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @TEXT = UPPER(@TEXT)
			ELSE IF UPPER(@CASE) = N'I'
				SET @TEXT = DBO.FN_GET_INITCAP(@CLIENTID, @TEXT)
			SET @VSTR = @TEXT
		END
        ELSE IF UPPER(@Get_Field) = N'INSPECTION'
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES
		END
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_COMPLETED_LATEST] (@CLIENTID     NVARCHAR(15),
 				      	           @PID1         NVARCHAR(5),
 				      	           @PID2         NVARCHAR(5),
 				      	           @PID3         NVARCHAR(5),
                                                   @ActivityDesc NVARCHAR(70),
 				      	           @Get_Field    NVARCHAR(15), 	
 				      	           @CASE         NVARCHAR(1),
                                                   @Add_Days     INT ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   05/19/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Info about the latest completed inspection whose Inspection Name is {ActivityDesc},[if {ActivityDesc} is 'N' returns the latest completed info where UPPER(G6_ACT_DES)<>'FINAL INSPECTION', if {ActivityDesc} is not specified in arguments, returns info about the latest completed inspection.  If {Get_Field} is 'INSPECTION', returns inspection name; if {Get_Field} is 'INSPECTOR', returns inspector's name in the format [First] [Middle] [Last], if {Get_Field} is 'INSP DATE', returns inspection completion date in the format MM/DD/YYYY; if {Get_Field} is 'FOLLOW UP DATE', returns inspection completion date plus {Add_Days} days in the format MM/DD/YYYY, if {Get_Field} is 'COMMENT', returns inspection comment.  
                         ARGUMENTS: CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ActivityDesc (optional), Get_Field (Options: 'INSPECTION', 'INSPECTOR', 'INSP DATE', 'FOLLOW UP DATE', 'COMMENT'), Case ('U' for uppercase, 'I' for initial-caps, blank for original case), Add_Days (number, optional).
    Revision History :   05/19/2005  David Zheng Initial Design
			 06/23/2005  Arthur Miao correct "GA_FNAME + GA_MNAME IS NULL" to "isnull(GA_FNAME,'') + isnull(GA_MNAME,'')=''"
                         08/16/2006  Cece Wang add 'IF UPPER(@Get_Field) = 'INSP DATE ONLY''
                         02/14/2007  Lydia Lim Add 'INSPECTOR LAST NAME' Get_Field option (07-063)
                         05/10/2007  Lucky Song Correct parameter character lengths    
*/
BEGIN
	DECLARE
           @NAME1 NVARCHAR(100),
           @LNAME NVARCHAR(25),
           @DATE  NVARCHAR(20),
           @DATE1 NVARCHAR(20),
           @DATE2 NVARCHAR(20),
           @ACT_NUM BIGINT,
           @TEXT NVARCHAR(4000),
           @VSTR NVARCHAR(4000),
           @ACT_DES NVARCHAR(70),
           @NUM_DAYS INT
        IF @ADD_DAYS = 0
             SET @NUM_DAYS = 0
        ELSE
             SET @NUM_DAYS = @ADD_DAYS
	BEGIN				
		SELECT 	  TOP 1 
			  @NAME1 = GA_FNAME + CASE WHEN GA_MNAME IS NULL THEN N'' ELSE CASE WHEN GA_FNAME IS NULL THEN GA_MNAME ELSE N' ' + GA_MNAME END END  +  
			  	   CASE WHEN GA_LNAME IS NULL THEN N'' ELSE CASE WHEN isnull(GA_FNAME,N'') + isnull(GA_MNAME,N'')=N''  THEN GA_LNAME ELSE N' ' + GA_LNAME END END ,
			  @DATE =  CONVERT(NVARCHAR(20),G6_COMPL_DD,101),
                          @DATE1 = SUBSTRING(CONVERT(CHAR(10),G6_COMPL_DD,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),G6_COMPL_DD,1))),
			  @DATE2 = SUBSTRING(CONVERT(CHAR(10),G6_COMPL_DD+@Num_Days,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),G6_COMPL_DD,1))),
			  @ACT_NUM = G6_ACT_NUM,
                          @ACT_DES = G6_ACT_DES,
                          @LNAME = GA_LNAME
		FROM 
			  G6ACTION
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND
			  UPPER(G6_STATUS) NOT IN (N'SCHEDULED',N'RESCHEDULED',N'PENDING',N'CANCELLED', N'CANCELED',N'INSP SCHEDULED') AND 
			  UPPER(G6_STATUS) NOT LIKE N'PENDING%' AND
			  UPPER(G6_ACT_GRP) = N'INSPECTION' AND
			  G6_Doc_Des <> N'Insp Scheduled' AND 
                          ((@ActivityDesc <> N''AND UPPER(G6_ACT_DES) = UPPER(@ActivityDesc))OR
                          @ActivityDesc = N'') AND
			  G6_COMPL_DD IS NOT NULL
		ORDER BY  G6_COMPL_DD DESC, G6_Status_DD DESC     
		SELECT 
			  @TEXT = TEXT
		FROM 
			  BACTIVITY_COMMENT
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND 	
			  G6_ACT_NUM = @Act_Num    AND
			  UPPER(COMMENT_TYPE) = N'INSPECTION RESULT COMMENT'			      		      	  				
	END	
	IF UPPER(@Get_Field) = N'INSPECTOR' 
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @NAME1 = UPPER(@NAME1)
			ELSE IF UPPER(@CASE) = N'I'
				SET @NAME1 = DBO.FN_GET_INITCAP(@CLIENTID, @NAME1)
			SET @VSTR = @NAME1
		END
        ELSE IF UPPER(@Get_Field) = N'INSP DATE ONLY'
		SET @VSTR = @DATE
	ELSE IF UPPER(@Get_Field) = N'INSP DATE'
		SET @VSTR = @DATE1
	ELSE IF UPPER(@Get_Field) = N'FOLLOW UP DATE'
		SET @VSTR = @DATE2	
	ELSE IF UPPER(@Get_Field) LIKE N'COMMENT%'
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @TEXT = UPPER(@TEXT)
			ELSE IF UPPER(@CASE) = N'I'
				SET @TEXT = DBO.FN_GET_INITCAP(@CLIENTID, @TEXT)
			SET @VSTR = @TEXT
		END
        ELSE IF UPPER(@Get_Field) = N'INSPECTOR LAST NAME'
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @LNAME = UPPER(@LNAME)
			ELSE IF UPPER(@CASE) = N'I'
				SET @TEXT = DBO.FN_GET_INITCAP(@CLIENTID, @LNAME)
			SET @VSTR = @LNAME
		END
        ELSE IF UPPER(@Get_Field) = N'INSPECTION'
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES
		END
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_LATEST](@CLIENTID     NVARCHAR(15),
 				      	           @PID1        NVARCHAR(5),
 				      	           @PID2          NVARCHAR(5),
 				      	           @PID3         NVARCHAR(5),
                                                   @ACTIVITYDESC  NVARCHAR(64),
 				      	           @GET_FIELD     NVARCHAR(30),
 				      	           @PCASE         NVARCHAR (10),
                                                   @DAYNUB        INT,
                                                   @PDOC_DES  NVARCHAR(200),
                                                   @PDATE  NVARCHAR (20),
                                                   @PSTATUS  NVARCHAR(100),
                                                   @PCOMMENT_TYPE NVARCHAR(200))
                                    RETURNS NVARCHAR(4000) AS
/*  Author           :   Sandy Yin
    Create Date      :   02/09/2007
    Version          :   AA6.3 MS SQL
    Detail           :   RETURNS: Info about the latest inspection. Selects the inspection by inspection description {ActivityDesc}, by disposition type {DispositionType}, by inspection date {InspDate}, and by inspection result {Status}. If {Get_Field} is 'INSPECTION', returns inspection name; if {Get_Field} is 'INSPECTOR', returns inspector's name in the format [First] [Middle] [Last], if {Get_Field} is 'INSP DATE', returns inspection date in the format MM/DD/YYYY; if {Get_Field} is 'FOLLOW UP DATE', returns inspection date plus {Add_Days} days in the format MM/DD/YYYY, if {Get_Field} is 'COMMENT', returns inspection comment.
                         ARGUMENTS: CLIENTID,
                                    PrimaryTrackingID1,
                                    PrimaryTrackingID2,
                                    PrimaryTrackingID3,
                                    ActivityDesc (optional),
                                    Get_Field (Options: 'INSPECTION'(default), 'INSPECTOR', 'INSP DATE', 'FOLLOW UP DATE', 'RESULT','COMMENT', 'INSP N DATE'),
                                    Case ('U' for uppercase, 'I' for initial-caps, '' for original case),
                                    Add_Days (number, optional).
                                    DispositionType ('SCHEDULED'(default),'COMPLETED', 'DENIED'(cancelled), 'RESULTED'(completed or cancelled)),
                                    InspDate (optional),
                                    Status (optional),
                                    CommentType (Optional, 'Inspection Request Comment', 'Inspection Result Comment')                                         
    Revision History :   02/09/2007  Sandy Yin  Create function using Oracle version as base (07SSP-00068)
                         05/10/2007  Rainy Yu  Change @ACTIVITYDESC VARCHAR(64)
                         06/13/2007  Lydia Lim  Edit script comments; Add Coalesce() to allow NULL parameter value
*/
BEGIN
DECLARE
 @INS_TYPE  NVARCHAR(100),
 @G6_STATUS NVARCHAR(100),
 @LASTNAME  NVARCHAR(100),
 @NAME1     NVARCHAR(100),
 @DATE1     NVARCHAR(20),
 @DATE2     NVARCHAR(20),
 @ACT_NUM   INT,
 @COMMENTTEXT      NVARCHAR(4000),
 @VSTR      NVARCHAR(4000),
 @ACT_DES   NVARCHAR(100),
 @NUM_DAYS  INT,
 @P_DOC NVARCHAR(400),
 @CommentType NVARCHAR(4000);
	  BEGIN
	        IF @DAYNUB = 0 OR COALESCE(@DAYNUB,N'')=N'' 
	            SET  @NUM_DAYS = 0
	        ELSE
	            SET  @NUM_DAYS = @DAYNUB
	 END
	      BEGIN  
	        IF UPPER(@PDOC_DES)=N'SCHEDULED'  
	            BEGIN
	 		    SET @P_DOC=N'Insp Scheduled';
		            SET @CommentType = N'Inspection Request Comment';
                    END
			ELSE IF UPPER(@PDOC_DES)=N'COMPLETED'  
	            BEGIN
	                    SET @P_DOC=N'Insp Completed' + CHAR(39)+N'Insp Compeleted';
		            SET @CommentType = N'Inspection Result Comment';
				END
	        ELSE IF  UPPER(@PDOC_DES)=N'DENIED' 
                   BEGIN
		            SET @P_DOC=N'Insp Cancelled';
		            SET @CommentType = N'Inspection Result Comment';
                   END
	       ELSE IF UPPER(@PDOC_DES)=N'RESULTED'  
                    BEGIN
		            SET @P_DOC=N'Insp Completed' + CHAR(44)+N'Insp Compeleted' + CHAR(44) + N'Insp Cancelled';
		            SET @CommentType = N'Inspection Result Comment';
                    END
	       ELSE    
                    BEGIN
		            SET @P_DOC= N'Insp Scheduled';  
		            SET @CommentType = N'Inspection Request Comment';
                   END
	    END
    BEGIN
               SELECT
		TOP 1
	          @INS_TYPE= G6_ACT_TYP,
                  @LASTNAME= GA_LNAME,
                  @G6_STATUS=G6_STATUS,
		  @NAME1=ISNULL(GA_FNAME,N'')+
                  CASE WHEN ISNULL(GA_MNAME,N'') =N'' THEN N'' ELSE 
                  CASE WHEN ISNULL(GA_FNAME,N'') =N'' THEN ISNULL(GA_MNAME,N'') ELSE N' ' + ISNULL(GA_MNAME,N'') END END  +
	  	  CASE WHEN ISNULL(GA_LNAME,N'') =N'' THEN N'' ELSE 
                  CASE WHEN ISNULL(GA_FNAME,N'') +ISNULL(GA_MNAME,N'')=N''  THEN ISNULL(GA_LNAME,N'') ELSE N' ' +  ISNULL(GA_LNAME,N'') END END  ,
		  @DATE1=CONVERT(NVARCHAR,CASE WHEN @PDOC_DES=N'SCHEDULED' THEN G6_ACT_DD ELSE G6_COMPL_DD END ,101)  ,
		  @DATE2=CONVERT(NVARCHAR, CASE WHEN @PDOC_DES=N'SCHEDULED' THEN G6_ACT_DD ELSE G6_COMPL_DD END+@NUM_DAYS,101) ,
		  @ACT_NUM= G6_ACT_NUM,
                  @ACT_DES=G6_ACT_DES
	         FROM
	           G6ACTION
	          WHERE
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND
			  B1_PER_ID1 = @PID1 AND
			  B1_PER_ID2 = @PID2 AND
			  B1_PER_ID3 = @PID3 AND
			  (COALESCE(@PSTATUS,N'')=N'' OR
				    (COALESCE(@PSTATUS,N'')<>N''AND UPPER(G6_STATUS)=UPPER(@PSTATUS))
			     ) AND
			    G6_ACT_GRP = N'Inspection'   AND
			  (
			   (COALESCE(@ACTIVITYDESC,N'') <>N'' AND CHARINDEX(UPPER(G6_ACT_DES),UPPER(@ACTIVITYDESC))>0 )
                                  OR COALESCE(@ActivityDesc,N'') =N''
                           ) AND
                           (COALESCE(@PDOC_DES,N'') =N'' OR
				    (COALESCE(@PDOC_DES,N'') <>N'' AND CHARINDEX (G6ACTION.G6_DOC_DES,@P_DOC)>0 )
			     ) AND
			    (COALESCE(@PDATE,N'') =N'' OR
				    (COALESCE(@PDATE,N'') <>N'' AND CASE WHEN @PDOC_DES =N'SCHEDULED'THEN G6_ACT_DD ELSE G6_COMPL_DD END =@PDATE)
			     ) 
		   ORDER BY CASE WHEN @PDOC_DES=N'SCHEDULED' THEN G6_ACT_DD ELSE G6_COMPL_DD END DESC , G6_ACT_NUM DESC 
		END
   BEGIN
         IF UPPER(@Get_Field) = N'INS_TYPE'  
              begin
		 IF UPPER(@PCASE) = N'U' 
			SET @VSTR = UPPER(@INS_TYPE);
		 ELSE IF UPPER(@PCASE) = N'I' 
			 SET @VSTR= DBO.FN_GET_INITCAP(N'',@INS_TYPE);
		  ELSE
		   SET @VSTR= @INS_TYPE;   
             end
	 ELSE IF UPPER(@Get_Field) = N'LASTNAME'  
		   begin 
	               IF UPPER(@PCASE) = N'U' 
				SET @VSTR = UPPER(@LASTNAME);
			ELSE IF UPPER(@PCASE) = N'I' 
			   SET @VSTR= DBO.FN_GET_INITCAP(N'',@LASTNAME);
			  ELSE
		 		SET @VSTR= @LASTNAME;
                    end
   	ELSE IF UPPER(@Get_Field) IN (N'G6_STATUS',N'RESULT') 
	  begin
             IF UPPER(@PCASE) = N'U' 
			set @VSTR = UPPER(@G6_STATUS);
		ELSE IF UPPER(@PCASE) = N'I' 
		   set @VSTR= DBO.FN_GET_INITCAP(N'',@G6_STATUS);
		  ELSE
		 	set @VSTR= @G6_STATUS;
	    end
	ELSE IF UPPER(@Get_Field) = N'INSPECTOR'  
 	 begin 
            IF UPPER(@PCASE) = N'U' 
			set @VSTR = UPPER(@NAME1);
		ELSE IF UPPER(@PCASE) = N'I' 
		  set  @VSTR= DBO.FN_GET_INITCAP(N'',@NAME1);
		  ELSE
		  set @VSTR= @NAME1;
         END
	ELSE IF UPPER(@Get_Field) = N'INSP DATE' 
		set @VSTR = @DATE1;
	ELSE IF UPPER(@Get_Field) = N'FOLLOW UP DATE' 
		set @VSTR = @DATE2;
    ELSE IF UPPER(@Get_Field) in (N'INS_COMMENT',N'COMMENT') 
      begin
			SELECT 
				 top 1 @COMMENTTEXT = TEXT
			FROM 
				  BACTIVITY_COMMENT
			WHERE 
				  REC_STATUS = N'A' AND
				  SERV_PROV_CODE = @CLIENTID AND		
				  B1_PER_ID1 = @PID1 AND		
				  B1_PER_ID2 = @PID2 AND		
				  B1_PER_ID3 = @PID3 AND 	
				  G6_ACT_NUM = @Act_Num AND
				 ( UPPER(COMMENT_TYPE) = upper(@PCOMMENT_TYPE)  OR  COALESCE(@PCOMMENT_TYPE,N'')=N'')
        IF UPPER(@PCASE) = N'U' 
		  SET  @VSTR= UPPER(@COMMENTTEXT);
		ELSE IF UPPER(@PCASE) = N'I' 
		 SET @VSTR= DBO.FN_GET_INITCAP(N'',@COMMENTTEXT);
		ELSE
		SET @VSTR = @COMMENTTEXT;
	 END
	ELSE IF UPPER(@Get_Field) = N'INSP N DATE' 
           BEGIN  
	          IF UPPER(@PCASE) = N'U'  
	 		     SET @VSTR= UPPER(@ACT_DES) ;
			   ELSE IF UPPER(@PCASE) = N'I' 
			    SET  @VSTR= DBO.FN_GET_INITCAP(N'',@ACT_DES);
			    ELSE
				SET  @VSTR = @ACT_DES+N' '+@DATE1;
            END
       ELSE
           IF UPPER(@PCASE) = N'U' 
		set @VSTR= UPPER(@ACT_DES);
	 ELSE IF UPPER(@PCASE) = N'I' 
	  	 set @VSTR= DBO.FN_GET_INITCAP(N'', @ACT_DES);
		ELSE set @VSTR = @ACT_DES;
     END 
     RETURN @VSTR;
END
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_LATEST_EXCLUDE] (@CLIENTID           NVARCHAR(15),
 				      	           @PID1              NVARCHAR(5),
 				      	           @PID2              NVARCHAR(5),
 				      	           @PID3              NVARCHAR(5),
                                                   @DispositionType   NVARCHAR(30), 
                                                   @ActivityDesc      NVARCHAR(70),
 				      	           @Get_Field         NVARCHAR(15), 	
 				      	           @CASE              NVARCHAR(1),
                                                   @Add_Days          INT
                                                   ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Cece Wang
    Create Date      :   09/01/2006
    Version          :   AA6.2 MS SQL
    Detail           :   RETURNS: Info about the last inspection, excluding the inspection called {ActivityDescription}. If {DispositionType} is 'SCHEDULED', selects the last scheduled inspection; if {DispositionType} is 'COMPLETED', selects the last completed inspection that did not receive a Denied-type result; if {DispositionType} is 'DENIED', selects the last inspection that received a Denied-type result or was cancelled. {Get_Field} specifies the info to be returned about the last inspection. {Case} specifies the case of the return value.  {Add_Days} is the number of days to be added to the inspection date to produce the 'FOLLOW UP DATE'.
                         ARGUMENTS: CLIENTID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    DispositionType (options: 'SCHEDULED','COMPLETED','DENIED')
                                    ActivityDescription (optional), 
                                    Get_Field (Options: 'INSPECTION', 'INSPECTOR', 'INSP DATE', 'FOLLOW UP DATE', 'RESULT','COMMENT'),
                                    Case ('U' for uppercase, 'I' for initial-caps, blank for original case), 
                                    Add_Days (number, optional).
    Revision History :   09/01/2006 Cece Wang Initial Design 
                                05/10/2007  Lucky Song Correct parameter character lengths   
*/
BEGIN 
	DECLARE
           @NAME1 NVARCHAR(100),
           @DATE  NVARCHAR(20),
           @DATE1 NVARCHAR(20),
           @DATE2 NVARCHAR(20),
           @ACT_NUM BIGINT,
           @TEXT NVARCHAR(4000),
           @VSTR NVARCHAR(4000),
           @ACT_DES NVARCHAR(70),
           @NUM_DAYS INT,
           @DOC_DES NVARCHAR(30),
           @STATUS NVARCHAR(30)
        IF @ADD_DAYS = 0 OR @ADD_DAYS = N''
             SET @NUM_DAYS = 0
        ELSE
             SET @NUM_DAYS = @ADD_DAYS
        SET @DOC_DES = CASE UPPER(@DispositionType) 
                         WHEN N'SCHEDULED'     THEN N'Insp Scheduled'
                         WHEN N'COMPLETED'     THEN N'''Insp Completed'',''Insp Compeleted'''
                         WHEN N'DENIED'        THEN N'Insp Cancelled'
                         ELSE                      N'Insp Scheduled'
                         END
	BEGIN				
		SELECT 	  TOP 1 
			  @NAME1 = GA_FNAME + CASE WHEN GA_MNAME IS NULL THEN N'' ELSE CASE WHEN GA_FNAME IS NULL THEN GA_MNAME ELSE N' ' + GA_MNAME END END  +  
			  	   CASE WHEN GA_LNAME IS NULL THEN N'' ELSE CASE WHEN isnull(GA_FNAME,N'') + isnull(GA_MNAME,N'')=N''  THEN GA_LNAME ELSE N' ' + GA_LNAME END END ,
			  @DATE =  CONVERT(NVARCHAR(20),ISNULL(G6_COMPL_DD,G6_ACT_DD),101),
                          @DATE1 = SUBSTRING(CONVERT(CHAR(10),ISNULL(G6_COMPL_DD,G6_ACT_DD),1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),ISNULL(G6_COMPL_DD,G6_ACT_DD),1))),
			  @DATE2 = SUBSTRING(CONVERT(CHAR(10),ISNULL(G6_COMPL_DD,G6_ACT_DD)+@Num_Days,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),ISNULL(G6_COMPL_DD,G6_ACT_DD),1))),
			  @ACT_NUM = G6_ACT_NUM,
                          @ACT_DES = G6_ACT_DES,
                          @STATUS = G6_STATUS
		FROM 
			  G6ACTION
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND
			  G6_ACT_GRP = N'Inspection' AND
                          ((@DOC_DES <> N'' and CHARINDEX(UPPER(G6_Doc_Des),UPPER(@DOC_DES))>0 ) OR @DOC_DES = N'')	 and
                          (@ActivityDesc=N'' OR UPPER(G6_ACT_DES)<>UPPER(@ActivityDesc)) 
		ORDER BY  ISNULL(G6_COMPL_DD,G6_ACT_DD) DESC, G6_Status_DD DESC     
            IF @DOC_DES = N'Insp Scheduled' AND @STATUS<>N'Scheduled' 
            --Scheduled inspections that don't have Pending-type results	
              BEGIN
		SELECT 
			  @TEXT = TEXT
		FROM 
			  BACTIVITY_COMMENT
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND 	
			  G6_ACT_NUM = @Act_Num    AND
			  COMMENT_TYPE = N'Inspection Request Comment'
              END
            ELSE
              BEGIN
		SELECT 
			  @TEXT = TEXT
		FROM 
			  BACTIVITY_COMMENT
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND 	
			  G6_ACT_NUM = @Act_Num    AND
			  COMMENT_TYPE = N'Inspection Result Comment'
              END         		      		      	  				
	END	
	IF UPPER(@Get_Field) = N'INSPECTOR' 
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @NAME1 = UPPER(@NAME1)
			ELSE IF UPPER(@CASE) = N'I'
				SET @NAME1 = DBO.FN_GET_INITCAP(@CLIENTID, @NAME1)
			SET @VSTR = @NAME1
		END
        ELSE IF UPPER(@Get_Field) = N'INSP DATE ONLY'
		SET @VSTR = @DATE
	ELSE IF UPPER(@Get_Field) = N'INSP DATE'
		SET @VSTR = @DATE1
	ELSE IF UPPER(@Get_Field) = N'FOLLOW UP DATE'
		SET @VSTR = @DATE2	
	ELSE IF UPPER(@Get_Field) LIKE N'COMMENT%'
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @TEXT = UPPER(@TEXT)
			ELSE IF UPPER(@CASE) = N'I'
				SET @TEXT = DBO.FN_GET_INITCAP(@CLIENTID, @TEXT)
			SET @VSTR = @TEXT
		END
        ELSE IF UPPER(@Get_Field) = N'INSPECTION'
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES
		END
        ELSE IF UPPER(@Get_Field) = N'RESULT'
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @STATUS = UPPER(@STATUS) 
			ELSE IF UPPER(@CASE) = N'I'
				SET @STATUS  = DBO.FN_GET_INITCAP(@CLIENTID, @STATUS)
			SET @VSTR = @STATUS 
		END
        ELSE
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES
		END	
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_RESULTED_LATEST] (@CLIENTID     NVARCHAR(15),
 				      	           @PID1         NVARCHAR(5),
 				      	           @PID2         NVARCHAR(5),
 				      	           @PID3         NVARCHAR(5),
                                                   @ActivityDesc NVARCHAR(70),
 				      	           @Get_Field    NVARCHAR(30), 	
 				      	           @CASE         NVARCHAR(1),
                                                   @Add_Days     INT ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Lydia Lim
    Create Date      :   03/31/2006
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: Info about the latest inspection where a result was assigned, whose Inspection Name is {ActivityDesc}, if {ActivityDesc} is not specified in arguments, returns info about the latest resulted inspection. May include inspections assigned PENDING-type results.  If {Get_Field} is 'INSPECTION', returns inspection name; if {Get_Field} is 'INSPECTOR', returns inspector's name in the format [First] [Middle] [Last], if {Get_Field} is 'INSP DATE', returns inspection date in the format MM/DD/YYYY; if {Get_Field} is 'FOLLOW UP DATE', returns inspection date plus {Add_Days} days in the format MM/DD/YYYY. 
                         ARGUMENTS: CLIENTID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3,
                                    ActivityDesc (optional), 
                                    Get_Field (Options: 'INSPECTION', 'INSPECTOR', 'INSP DATE', 'FOLLOW UP DATE', 'INSP-RESULT DATE', 'RESULT', 'INSP ID', 'INSPECTOR LAST NAME'), 
                                    Case ('U' for uppercase, 'I' for initial-caps, blank for original case),
                                    Add_Days (number, optional).
    Revision History :   03/31/2006  Lydia Lim  Initial Design, based on FN_GET_INSP_COMPLETED_LATEST.
                         04/05/2006  Lydia Lim  Add 'INSP-RESULT DATE' option, make 'INSPECTION' the default.
		         11/07/2006  Lydia/Ran  Add 'RESULT' option and 'INSP ID' option
                         02/14/2007  Lydia Lim  Add 'INSPECTOR LAST NAME' Get_Field option (07SSP-00062)
                         05/11/2007  Lucky Song Correct parameter character lengths  
*/
BEGIN
	DECLARE
           @NAME1 NVARCHAR(100),
           @LNAME NVARCHAR(25),
           @DATE1 NVARCHAR(20),
           @DATE2 NVARCHAR(20),
           @ACT_NUM BIGINT,
           @TEXT NVARCHAR(4000),
           @ACT_DES NVARCHAR(70),
           @INSP_RESULT NVARCHAR(30),
           @NUM_DAYS INT,
           @VSTR NVARCHAR(4000)
        IF @ADD_DAYS = 0 OR @ADD_DAYS IS NULL
             SET @NUM_DAYS = 0
        ELSE
             SET @NUM_DAYS = @ADD_DAYS
	BEGIN				
		SELECT TOP 1 
			  @NAME1 = GA_FNAME + CASE WHEN GA_MNAME IS NULL THEN N'' ELSE CASE WHEN GA_FNAME IS NULL THEN GA_MNAME ELSE N' ' + GA_MNAME END END  +  
			  	   CASE WHEN GA_LNAME IS NULL THEN N'' ELSE CASE WHEN isnull(GA_FNAME,N'') + isnull(GA_MNAME,N'')=N''  THEN GA_LNAME ELSE N' ' + GA_LNAME END END ,
			  @DATE1 = SUBSTRING(CONVERT(CHAR(10),G6_COMPL_DD,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),G6_COMPL_DD,1))),
			  @DATE2 = SUBSTRING(CONVERT(CHAR(10),G6_COMPL_DD+@Num_Days,1),1,6) + CONVERT(CHAR(4),YEAR(CONVERT(CHAR(10),G6_COMPL_DD,1))),
			  @ACT_NUM = G6_ACT_NUM,
                          @ACT_DES = G6_ACT_DES,
                          @INSP_RESULT = G6_STATUS,
                          @LNAME = GA_LNAME
		FROM 
			  G6ACTION
		WHERE 
			  REC_STATUS = N'A' AND
			  SERV_PROV_CODE = @CLIENTID AND		
			  B1_PER_ID1 = @PID1 AND		
			  B1_PER_ID2 = @PID2 AND		
			  B1_PER_ID3 = @PID3 AND
			  G6_ACT_GRP = N'Inspection' AND
                          (@ActivityDesc IS NOT NULL AND UPPER(G6_ACT_DES) = UPPER(@ActivityDesc) OR
                           @ActivityDesc IS NULL) AND
			  G6_STATUS NOT IN (N'Scheduled',N'Rescheduled',N'Insp Rescheduled',N'Cancelled')
		ORDER BY  ISNULL(G6_COMPL_DD,G6_ACT_DD) DESC, G6_Status_DD DESC     		      		      	  				
	END	
	IF UPPER(@Get_Field) = N'INSPECTOR' 
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @NAME1 = UPPER(@NAME1)
			ELSE IF UPPER(@CASE) = N'I'
				SET @NAME1 = DBO.FN_GET_INITCAP(@CLIENTID, @NAME1)
			SET @VSTR = @NAME1
		END
	ELSE IF UPPER(@Get_Field) = N'INSP DATE'
		SET @VSTR = @DATE1
	ELSE IF UPPER(@Get_Field) = N'FOLLOW UP DATE'
		SET @VSTR = @DATE2
	ELSE IF UPPER(@Get_Field) = N'INSP ID'
		SET @VSTR = @ACT_NUM
        ELSE IF UPPER(@Get_Field) = N'INSP-RESULT DATE'
                BEGIN
                        SET @VSTR = @ACT_DES+N' - '+@INSP_RESULT+N' '+@DATE1
			IF UPPER(@CASE) = N'U' 
				SET @VSTR = UPPER(@VSTR)
			ELSE IF UPPER(@CASE) = N'I'
				SET @VSTR = DBO.FN_GET_INITCAP(@CLIENTID, @VSTR)
		END
	ELSE IF UPPER(@Get_Field) = N'RESULT'
                BEGIN
                        SET @VSTR = @INSP_RESULT
			IF UPPER(@CASE) = N'U' 
				SET @VSTR = UPPER(@VSTR)
			ELSE IF UPPER(@CASE) = N'I'
				SET @VSTR = DBO.FN_GET_INITCAP(@CLIENTID, @VSTR)
		END
	ELSE IF UPPER(@Get_Field) = N'INSPECTOR LAST NAME' 
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @LNAME = UPPER(@LNAME)
			ELSE IF UPPER(@CASE) = N'I'
				SET @LNAME = DBO.FN_GET_INITCAP(@CLIENTID, @LNAME)
			SET @VSTR = @LNAME
		END
        ELSE    /* default: 'INSPECTION' */
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES
		END
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_INSP_SCHEDULED_LATEST] (@CLIENTID     NVARCHAR(15),
 				      	           @PID1         NVARCHAR(5),
 				      	           @PID2         NVARCHAR(5),
 				      	           @PID3         NVARCHAR(5),
                                                   @ActivityDesc NVARCHAR(70),
 				      	           @Get_Field    NVARCHAR(30), 	
 				      	           @CASE         NVARCHAR(1),
                                                   @Add_Days     INT) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   05/19/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Info about the latest scheduled inspection whose Inspection Name is {ActivityDesc}, if {ActivityDesc} is not specified in arguments, returns info about the latest scheduled inspection.  If {Get_Field} is 'INSPECTION', returns inspection name; if {Get_Field} is 'INSPECTOR', returns inspector's name in the format [First] [Middle] [Last], if {Get_Field} is 'INSP DATE', returns inspection date in the format MM/DD/YYYY; if {Get_Field} is 'FOLLOW UP DATE', returns inspection date plus {Add_Days} days in the format MM/DD/YYYY, if {Get_Field} is 'COMMENT', returns inspection comment.  
                         ARGUMENTS: CLIENTID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3,
                                    ActivityDesc (optional), 
                                    Get_Field (Options: 'INSPECTION'(default), 'INSPECTOR', 'INSP DATE', 'FOLLOW UP DATE', 'COMMENT', 'INSP N DATE'), 
                                    Case ('U' for uppercase, 'I' for initial-caps, '' for original case),                                                Add_Days (number, optional).
    Revision History :   05/19/2005  David Zheng Initial Design
                         06/22/2005  Arthur Miao correct "GA_FNAME+GA_MNAME is null" to "ISNULL(GA_FNAME,'') + ISNULL(GA_MNAME,'')=''"
                         03/31/2006  Lydia Lim  Allow for '' as @ADD_DAYS value; simplify code for dates; change datatype for @ADD_DAYS and @NUM_DAYS to INT
                         04/05/2006  Lydia Lim  Add 'INSP N DATE' option, make 'INSPECTION' the default
                         05/10/2007   Lucky Song Correct parameter character lengths  
*/
BEGIN
	DECLARE
           @NAME1 NVARCHAR(100),
           @DATE1 NVARCHAR(20),
           @DATE2 NVARCHAR(20),
           @ACT_NUM BIGINT,
           @TEXT NVARCHAR(4000),
           @VSTR NVARCHAR(4000),
           @ACT_DES NVARCHAR(50),
           @NUM_DAYS INT
        IF @ADD_DAYS = 0 OR @ADD_DAYS IS NULL
             SET @NUM_DAYS = 0
        ELSE
             SET @NUM_DAYS = @ADD_DAYS
		BEGIN				
			SELECT 	  TOP 1 
				  @NAME1 = GA_FNAME + CASE WHEN GA_MNAME IS NULL THEN N'' ELSE CASE WHEN GA_FNAME IS NULL THEN GA_MNAME ELSE N' ' + GA_MNAME END END  +  
				  	   CASE WHEN GA_LNAME IS NULL THEN N'' ELSE CASE WHEN ISNULL(GA_FNAME,N'') + ISNULL(GA_MNAME,N'')=N''  THEN GA_LNAME ELSE N' ' + GA_LNAME END END ,
				  @DATE1 = CONVERT(NVARCHAR(20),G6_ACT_DD,101),
				  @DATE2 = CONVERT(NVARCHAR(20),DATEADD(Day,@NUM_DAYS,G6_ACT_DD),101),
				  @ACT_NUM = G6_ACT_NUM,
                                  @ACT_DES = G6_ACT_DES
			FROM 
				  G6ACTION
			WHERE 
				  REC_STATUS = N'A' AND
				  SERV_PROV_CODE = @CLIENTID AND		
				  B1_PER_ID1 = @PID1 AND		
				  B1_PER_ID2 = @PID2 AND		
				  B1_PER_ID3 = @PID3 AND
				  (UPPER(G6_STATUS) = N'SCHEDULED'
                                   OR
				   UPPER(G6_STATUS) LIKE N'PENDING%') AND
				  G6_ACT_GRP = N'Inspection' AND
                                  (@ActivityDesc IS NOT NULL AND UPPER(G6_ACT_DES) = UPPER(@ActivityDesc) OR
                                   @ActivityDesc IS NULL) 
			ORDER BY  G6_ACT_DD DESC     
			SELECT 
				  @TEXT = TEXT
			FROM 
				  BACTIVITY_COMMENT
			WHERE 
				  REC_STATUS = N'A' AND
				  SERV_PROV_CODE = @CLIENTID AND		
				  B1_PER_ID1 = @PID1 AND		
				  B1_PER_ID2 = @PID2 AND		
				  B1_PER_ID3 = @PID3 AND 	
				  G6_ACT_NUM = @Act_Num    AND
				  UPPER(COMMENT_TYPE) = N'INSPECTION REQUEST COMMENT';			      		      	  				
		END	
	IF UPPER(@Get_Field) = N'INSPECTOR' 
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @NAME1 = UPPER(@NAME1)
			ELSE IF UPPER(@CASE) = N'I'
				SET @NAME1 = DBO.FN_GET_INITCAP(@CLIENTID, @NAME1)
			SET @VSTR = @NAME1
		END
	ELSE IF UPPER(@Get_Field) = N'INSP DATE'
		SET @VSTR = @DATE1
	ELSE IF UPPER(@Get_Field) = N'FOLLOW UP DATE'
		SET @VSTR = @DATE2	
	ELSE IF UPPER(@Get_Field) LIKE N'COMMENT%'
		BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @TEXT = UPPER(@TEXT)
			ELSE IF UPPER(@CASE) = N'I'
				SET @TEXT = DBO.FN_GET_INITCAP(@CLIENTID, @TEXT)
			SET @VSTR = @TEXT
		END
        ELSE IF UPPER(@Get_Field) = N'INSP N DATE'
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES+N' '+@DATE1
		END
        ELSE    /* default: 'INSPECTION' */
                BEGIN
			IF UPPER(@CASE) = N'U' 
				SET @ACT_DES = UPPER(@ACT_DES)
			ELSE IF UPPER(@CASE) = N'I'
				SET @ACT_DES = DBO.FN_GET_INITCAP(@CLIENTID, @ACT_DES)
			SET @VSTR = @ACT_DES
		END
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_INVOICE_LATEST] (@CLIENTID NVARCHAR(15),
					    @PID1 NVARCHAR(5),
					    @PID2 NVARCHAR(5),
				            @PID3 NVARCHAR(5),
					    @GET_FIELD NVARCHAR(100) 
					 )RETURNS NVARCHAR(30) AS
/*  Author         :   Lydia Lim
     Create Date   :   04/04/2006
     Version       :   AA6.1 MS SQL
     Detail        :   RETURNS: Info about latest invoice on the application.  If {Get_Field} = 'NBR', returns invoice number; if {Get_Field} = 'DATE', returns invoice date in format MM/DD/YYYY; if {Get_Field} = 'AMOUNT', returns invoice amount. Returns NULL if no invoice is found.
                       ARGUMENTS: ClientID, 
                                  PrimaryTrackingID1, 
                                  PrimaryTrackingID2, 
                                  PrimaryTrackingID3, 
                                  Get_Field (Options: 'NBR'(default),'DATE','AMOUNT','DOLLAR AMT DATE')
  Revision History :   04/04/2006  Lydia Lim Initial Design			
*/
BEGIN
declare @V_RET NVARCHAR(30) 
 BEGIN 
     SELECT TOP 1 
                    @V_RET = 
                     CASE UPPER(@GET_FIELD)  
                     WHEN N'NBR'             THEN CAST(F.INVOICE_NBR AS NVARCHAR)  
                     WHEN N'DATE'            THEN CONVERT(NVARCHAR,F.INVOICE_DATE,101)                             
                     WHEN N'AMOUNT'          THEN CAST (F.INVOICE_AMOUNT AS NVARCHAR)
                     WHEN N'DOLLAR AMT DATE' THEN N'$'+CONVERT(NVARCHAR,CAST(F.INVOICE_AMOUNT AS SMALLMONEY),1)+N' '+CONVERT(NVARCHAR,F.INVOICE_DATE,101)
                     ELSE                    CAST(F.INVOICE_NBR AS NVARCHAR)     
                     END
      FROM
                     F4INVOICE F,
                     X4FEEITEM_INVOICE x
      WHERE 	
	             X.REC_STATUS = N'A'  AND
                     X.SERV_PROV_CODE = @CLIENTID AND
                     X.B1_PER_ID1 = @PID1 AND
                     X.B1_PER_ID2 = @PID2 AND
                     X.B1_PER_ID3 = @PID3 AND
                     X.INVOICE_NBR = F.INVOICE_NBR AND
                     X.SERV_PROV_CODE = F.SERV_PROV_CODE AND
                     X.REC_STATUS = F.REC_STATUS AND
                     ISNULL(F.INVOICE_STATUS,N'A') <> N'VOID'
      ORDER BY F.INVOICE_DATE DESC
 END
  RETURN @V_RET 
END
GO


ALTER FUNCTION [dbo].[FN_GET_INVOICE_PAYMENT_LAST] ( @CLIENTID NVARCHAR(15),
                                                    @PID1 NVARCHAR(5),
                                                    @PID2 NVARCHAR(5),
                                                    @PID3 NVARCHAR(5),
                                                    @GET_FIELD NVARCHAR(100) ,
                                                    @INV_NBR int ,
                                                    @SEQ_NBR int 
 				           	   )RETURNS NVARCHAR(100) AS
/*  Author         :   Sandy Yin
     Create Date   :   08/22/2006
     Version       :   AA6.3 MS SQL
     Detail        :   RETURNS: Info about latest payment made to invoice {InvoiceNum}.  If {FeeItemSeqNum} is specified, returns info about the latest payment made for the fee whose sequence number is {FeeItemSeqNum}.  
                       ARGUMENTS: ClientID, 
                                  Get_Field (Options: 'AMOUNT'(default),'DATE','CASHIER_ID')
                                  InvoiceNum
                                  FeeItemSeqNum (optional)
  Revision History :   08/22/2006 Sandy Yin Initial Design	
                              05/10/2007   Lucky Song Correct RETURN character lengths  		
*/
BEGIN
declare @V_RET NVARCHAR(100) 
  BEGIN 
       SELECT   TOP 1
                @V_RET = CASE WHEN UPPER(@GET_FIELD)=N'CASHIER_ID'             THEN F4.CASHIER_ID
                              WHEN UPPER(@GET_FIELD) in (N'PAYDATE',N'DATE')    THEN CONVERT(CHAR(20),F4.PAYMENT_DATE,101)
                                                                              ELSE  N'$'+CONVERT(NVARCHAR,CAST(X.FEE_ALLOCATION AS MONEY),1)
                         END  	   
       FROM 
                X4PAYMENT_FEEITEM X,
                F4PAYMENT F4			
WHERE  
		X.INVOICE_NBR=@INV_NBR AND
		(X.FEEITEM_SEQ_NBR =@SEQ_NBR OR @SEQ_NBR=N'') AND
		X.PAYMENT_SEQ_NBR=F4.PAYMENT_SEQ_NBR AND
		X.SERV_PROV_CODE =F4.SERV_PROV_CODE AND
		X.B1_PER_ID1 =F4.B1_PER_ID1 AND
		X.B1_PER_ID2 =F4.B1_PER_ID2 AND
		X.B1_PER_ID3 =F4.B1_PER_ID3 AND
		X.REC_STATUS= F4.REC_STATUS   AND
		F4.B1_PER_ID1 =@PID1 AND
		F4.B1_PER_ID2 =@PID2 AND
		F4.B1_PER_ID3 =@PID3 AND
		X.REC_STATUS=N'A'    AND
                X.SERV_PROV_CODE = @CLIENTID AND
                X.FEE_ALLOCATION<>0
       ORDER BY PAYMENT_DATE DESC 
 END
  RETURN @V_RET 
END
GO


ALTER FUNCTION [dbo].[FN_GET_INVOICED_FEE_QTY_TOT](@CLIENT NVARCHAR(50),
					    @PID1 NVARCHAR(50),
					    @PID2 NVARCHAR(50),
					    @PID3 NVARCHAR(50),
					    @ITEMSTAT NVARCHAR(30),
					    @FEEITEM  NVARCHAR(100)
					    )RETURNS FLOAT
/*  Author           :   Angel Feng
    Create Date      :   04/05/2007
    Version          :   AA6.3 MSSQL
    Detail           :   RETURNS: Sum of fee quantity on the application for fees whose status is {FeeItemStatusFlag} and whose description is {FeeItemDescription}.  If {FeeItemStatusFlag} is '', sums quantity for all invoiced fees; if {FeeItemDescription} is '', sums quantity for all fees regardless of description.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    FeeItemStatusFlag (optional, default is 'INVOICED'), 
                                    FeeItemDescription (optional, may be comma-delimited list, default is all).
  Revision History :     04/05/2007  Angel Feng   Initial for 07SSP-00107 field "S-2"
*/
BEGIN 
  DECLARE
	@TEM	  NVARCHAR(4000),
	@VSTR NVARCHAR(4000),
	@VTEM NVARCHAR(4000),
	@LASTSTRING NVARCHAR(4000),
	@STARTPOS INT,
	@ENDPOS INT,
	@TMPPOS INT;
	set  @TEM=N'';
	SET @STARTPOS = 1;
	SET @TMPPOS = 1;
	SET @VSTR = N'';
  WHILE (@TMPPOS<=LEN(@FEEITEM))
    BEGIN
      IF (SUBSTRING(@FEEITEM,@TMPPOS,1) = N',')
        BEGIN
	  SET @VTEM = LTRIM(RTRIM(SUBSTRING(@FEEITEM,@STARTPOS,@TMPPOS-@STARTPOS)))                
	  IF (@VTEM != N'')
            BEGIN
	      IF (@VSTR != N'')
		SET @VSTR=@VSTR+N','''+@VTEM+N''''
	      ELSE
               	SET @VSTR=N''''+@VTEM+N''''
            END
          SET @TMPPOS = @TMPPOS +1
          SET @STARTPOS = @TMPPOS
        END
      ELSE
        SET @TMPPOS = @TMPPOS +1			
    END
    SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@FEEITEM,@STARTPOS,@TMPPOS-@STARTPOS)))
    IF (@LASTSTRING != N'')
      BEGIN
        IF (@VSTR=N'')
	  SET @VSTR =@VSTR + N''''+ @LASTSTRING+N''''
        ELSE
	  SET @VSTR =@VSTR + N','''+@LASTSTRING+N''''
      END
 BEGIN
  DECLARE @RESULT FLOAT;
  SELECT
    	@RESULT = SUM(F.GF_UNIT)
  FROM
    	F4FEEITEM F
  WHERE
    	F.SERV_PROV_CODE = @CLIENT	AND 
    	F.B1_PER_ID1 = @PID1 		AND 
    	F.B1_PER_ID2 = @PID2 		AND 
	F.B1_PER_ID3 = @PID3 		AND 
	F.REC_STATUS=N'A' 		AND
	(UPPER(F.GF_ITEM_STATUS_FLAG) = UPPER(@ITEMSTAT) OR (@ITEMSTAT = N'' AND F.GF_ITEM_STATUS_FLAG=N'INVOICED')) AND
	( (ISNULL(@FEEITEM,N'') <> N'' and CHARINDEX(UPPER(F.GF_COD),UPPER(@VSTR))>0) OR ISNULL(@FEEITEM,N'') = N'')
 END
  RETURN ISNULL(@RESULT,0)
END
GO


ALTER FUNCTION [dbo].[FN_GET_INVOICED_FEE_TOTAL] (@CLIENT NVARCHAR(50),
					    @PID1 NVARCHAR(50),
					    @PID2 NVARCHAR(50),
					    @PID3 NVARCHAR(50),
					    @ITEMSTAT NVARCHAR(30),
					    @FEEITEM  NVARCHAR(100)
					    )RETURNS FLOAT
/*  Author           :   Glory Wang
    Create Date      :   12/01/2004
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Sum of fees for application whose status is {FeeItemStatusFlag} and whose description is {FeeItemDescription}.  If {FeeItemStatusFlag} is '', sums all invoiced fees; if {FeeItemDescription} is '', sums all fees regardless of description.
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, FeeItemStatusFlag (optional, default is 'INVOICED'), FeeItemDescription (optional, default is all).
  Revision History :     12/01/2004  Glory Wang    Initial
                         ?           Larry Cooper  Add code to drop function if it exists
                         09/22/2005  Lydia Lim     Modify report so to standardize logic for other agencies
                         06/13/2007  Lydia Lim     Add COALESCE() so that NULL can be used instead of ''
*/
BEGIN
	DECLARE @RESULT FLOAT;
IF @CLIENT<>N'PINAL' 
  /* Standard Logic */
  SELECT
    	@RESULT = SUM(F.GF_FEE)
  FROM
    	F4FEEITEM F
  WHERE
    	F.SERV_PROV_CODE = @CLIENT	AND 
    	F.B1_PER_ID1 = @PID1 		AND 
    	F.B1_PER_ID2 = @PID2 		AND 
		F.B1_PER_ID3 = @PID3 		AND 
		F.REC_STATUS=N'A' 		AND
		(UPPER(F.GF_ITEM_STATUS_FLAG) = UPPER(@ITEMSTAT) 
		 OR 
		 (COALESCE(@ITEMSTAT,N'') = N'' AND F.GF_ITEM_STATUS_FLAG=N'INVOICED')) AND
	    (UPPER(F.GF_DES) = UPPER(@FEEITEM) OR COALESCE(@FEEITEM,N'') = N'' );
ELSE
  /* PINAL Logic */
  IF @FEEITEM!=N'OTHER'
	SELECT 
		@RESULT=SUM(F.GF_FEE)
	FROM 
		F4FEEITEM F, 
		RPAYMENT_PERIOD R
	WHERE 
		F.SERV_PROV_CODE = @CLIENT	AND 
		F.B1_PER_ID1 = @PID1 	        AND 
		F.B1_PER_ID2 = @PID2 		AND 
		F.B1_PER_ID3 = @PID3 		AND 
		F.REC_STATUS=N'A' 		AND
		(UPPER(F.GF_ITEM_STATUS_FLAG) = UPPER(@ITEMSTAT) OR @ITEMSTAT = N'N/A' )AND
		(LEFT(UPPER(F.GF_DES),15) = UPPER(@FEEITEM) OR @FEEITEM = N'N/A' ) AND
		R.SERV_PROV_CODE = F.SERV_PROV_CODE AND 
		F.GF_FEE_PERIOD = R.GF_FEE_PERIOD;
  ELSE
	SELECT 
		@RESULT=SUM(F.GF_FEE)
	FROM 
		F4FEEITEM F, 
		RPAYMENT_PERIOD R
	WHERE 
		F.SERV_PROV_CODE = @CLIENT	AND 
		F.B1_PER_ID1 = @PID1 		AND 
		F.B1_PER_ID2 = @PID2 		AND 
		F.B1_PER_ID3 = @PID3  		AND 
		UPPER(F.GF_DES) NOT IN(N'BUILDING PERMIT FEE VALUATION (ENTER ACTUAL VALUATION)',N'PLAN CHECK FEE (ENTER 1 TO ACTIVATE)',N'BUILDING PERMIT FEE VALUATION 75,000 OR LESS (ENTER ACTUAL VALUATION)') AND
		F.REC_STATUS=N'A' AND 
		R.SERV_PROV_CODE = F.SERV_PROV_CODE AND 
		F.GF_FEE_PERIOD = R.GF_FEE_PERIOD;
  RETURN ISNULL(@RESULT,0);
END
GO


ALTER FUNCTION [dbo].[FN_GET_JOB_VALUE_CALC] (@CLIENTID  NVARCHAR(15),
 				      	@PID1      NVARCHAR(5),
                                      	@PID2      NVARCHAR(5),
                                      	@PID3      NVARCHAR(5)
                                      	) RETURNS FLOAT  AS
/*  Author           :   Glory Wang
    Create Date      :   12/01/2004
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Total Job Value from the Valuation Calculator, regardless of whether the Calculated Valuation is the default job value for the application.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ChecklistDescription.
  Revision History :	12/01/2004  Glory Wang	Initial
			09/28/2005  Lydia Lim	Edit comments
*/
BEGIN 
DECLARE 
  @V_JOBVALUE FLOAT
  SELECT 
	@V_JOBVALUE = SUM(B1_VALUE_TTL)
  FROM 
	BCALC_VALUATN
  WHERE 
	SERV_PROV_CODE  =@CLIENTID
  AND   B1_PER_ID1 = @PID1
  AND   B1_PER_ID2 = @PID2
  AND   B1_PER_ID3 = @PID3
  AND	REC_STATUS = N'A'
RETURN @V_JOBVALUE
END
GO


ALTER FUNCTION [dbo].[FN_GET_JOB_VALUE_CONT] (@CLIENTID  NVARCHAR(50),
                                           @PID1    NVARCHAR(50),
                                           @PID2    NVARCHAR(50),
                                           @PID3   NVARCHAR(50)
                                           ) RETURNS FLOAT AS
/*  Author           :  Arthur Miao
    Create Date      :  08/25/2005
    Version          :  AA6.1 MSSQL
    Detail           :  RETURN: Contractor job value, if Contractor Value is set as the default value for the app; If the Contractor Value is not the default job value, returns 0.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History   :  08/25/2005  Arthur Miao 	Inital design
			09/28/2005  Lydia Lim		Edit comments
                        02/06/2006  Lydia Lim           Drop function before creating it.
*/  				      	   
begin
	DECLARE			      	    
	@Flag NVARCHAR(10),
	@Job_Value1 FLOAT,
	@Result float set @Result=0;
			SELECT	TOP 1
			        @Job_Value1= isnull(G3_VALUE_TTL,0),
			        @Flag=G3_FEE_FACTOR_FLG
			FROM    BVALUATN 
			WHERE  SERV_PROV_CODE = @CLIENTID AND
			       B1_PER_ID1 = @PID1 AND		
			       B1_PER_ID2 = @PID2 AND		
			       B1_PER_ID3 = @PID3 AND
	                       UPPER(REC_STATUS) = N'A';
			if UPPER(@Flag)=N'CONT' OR @Flag IS NULL 
	          		set @Result=@Job_Value1;
	    return @Result;
END
GO


ALTER FUNCTION [dbo].[FN_GET_JOBVALUE_TTL] (@CLIENTID  NVARCHAR(50),
 				      	    @PID1    NVARCHAR(50),
 				      	    @PID2    NVARCHAR(50),
 				      	    @PID3   NVARCHAR(50)
 				      	     ) RETURNS FLOAT AS
/*  Author           :  Lucky Song
    Create Date      :  12/30/2004
    Version          :  AA6.0
    Version          :  AA6.0 MSSQL
    Detail           :  RETURN: Get 1st Job Value G3_VALUE_TTL from the Valuation, if Flag = 'CONT' or doesn't exist in table BVALUATN, else get total Job Value SUM(B1_VALUE_TTL) from the Valuation Calculator BCALC_VALUATN.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History   :  Sandy Yin optimize the function 04/13/2005
*/  				      	   
begin
	DECLARE			      	    
	@Flag NVARCHAR(10),
	@Job_Value1 FLOAT,
	@Result float set @Result=0;
			SELECT	TOP 1
			        @Job_Value1= isnull(G3_VALUE_TTL,0),
			        @Flag=G3_FEE_FACTOR_FLG
			FROM    BVALUATN 
			WHERE  SERV_PROV_CODE = @CLIENTID AND
			       UPPER(REC_STATUS) = N'A' AND
			       B1_PER_ID1 = @PID1 AND		
			       B1_PER_ID2 = @PID2 AND		
			       B1_PER_ID3 = @PID3 AND
	                       UPPER(REC_STATUS) = N'A';
			if UPPER(@Flag)=N'CONT' OR @Flag IS NULL 
	          		set @Result=@Job_Value1;
	     		 else 
	         		set @Result = dbo.FN_GET_JOB_VALUE_CALC(@CLIENTID, @PID1, @PID2, @PID3);  
	    return @Result;
end
GO


ALTER FUNCTION [dbo].[FN_GET_LICPROF_ATTRI](
                                            @CLIENTID NVARCHAR(15),
                                            @PID1  NVARCHAR(5),
                                            @PID2  NVARCHAR(5),
                                            @PID3  NVARCHAR(5),
					    @CONTACTTYPE NVARCHAR(30),
                                            @LICENSE_NBR NVARCHAR(30),
                                            @ATTRIBUTE_NAME NVARCHAR(70)
                                            ) RETURNS NVARCHAR(200) AS
/*  
            Author             :   Arthur Miao
            Create Date        :   01/18/2006
            Version            :   AA6.1.2 MS SQL
            Detail             :   RETURNS: Value of the custom Licensed Professional attribute named {AttributeName} for the Licensed Professional whose license number is {LicenseNumber} and whose license type is {LicenseType}. The attribute value is taken from data for the Licensed Professional stored with the application. Note that {AttributeName} is the attribute name, not the attribute label.
                                   ARGUMENTS: clientID, 
                                              PrimaryTrackingID1, 
                                              PrimaryTrackingID2, 
                                              PrimaryTrackingID3, 
                                              LicenseType(optional), 
                                              LicenseNumber, 
                                              AttributeName
            Revision History   :   01/18/2006 Arthur Miao 
                                   01/29/2007 Lydia Lim     Edit comments
*/
BEGIN
        DECLARE @result NVARCHAR(200);
        SELECT
                TOP 1
                @result = B1_ATTRIBUTE_VALUE
        FROM    
                B3CONTACT_ATTRIBUTE
        WHERE   
                SERV_PROV_CODE = @CLIENTID AND
		REC_STATUS=N'A' AND
		B1_PER_ID1 = @PID1 AND
  		B1_PER_ID2 = @PID2 AND
  		B1_PER_ID3 = @PID3 AND
                (UPPER(B1_CONTACT_TYPE)=UPPER(@CONTACTTYPE) or isnull(@CONTACTTYPE,N'')=N'') AND
                UPPER(B1_CONTACT_NBR) = UPPER(@LICENSE_NBR)   AND
                UPPER(B1_ATTRIBUTE_NAME) =UPPER(@ATTRIBUTE_NAME) 
        RETURN @result;
END
GO


ALTER FUNCTION [dbo].[FN_GET_LICPROF_INFO] (@CLIENTID  NVARCHAR(15),
                                            @PID1    NVARCHAR(5),
                                            @PID2    NVARCHAR(5),
                                            @PID3   NVARCHAR(5), 
                                            @Get_Field NVARCHAR(100),
                                            @NameFormat NVARCHAR(3),
                                            @Case NVARCHAR(1),
	      				    @LicenseType NVARCHAR(200)
                               	             ) RETURNS NVARCHAR (200)  AS
/*
	Author		: Jim Gao	
	create date	: 06/09/2005
	version		: AA6.0 MS SQL
	detail		: RETURNS: Licensed Professional Info, as follows: If {LicenseType} is specified, returns the first Licensed Professional whose License Type is {LicenseType},else returns the primary Licensed Professional. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}; if {Get_Field} is 'FullAddr_Block', returns full address in block format.
		          ARGUMENTS: ClientID, 
                                     PrimaryTrackingID1, 
                                     PrimaryTrackingID2, 
                                     PrimaryTrackingID3,
                                     Get_Field (options: 'FullName', 'BusinessName', 'LicenseType', 'LicenseNumber', 'FullAddr_Block', 'FullAddr_Line','Phone1'), 
                                     NameFormat (options: '' or 'FML' for [First Middle Last], 'LFM' for [Last, First Middle]), 
                                     Case ('U' for uppercase, 'I' for initial caps, '' for original case), 
                                     LicenseType (optional).
		   Revision History: 06/09/2005 Jim Gao Initial Design
		                     06/24/2005  Sunny Chen  Revised field value as specified by {Get_Field}. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {Case} is 'U', return value is in UPPERCASE if {Case} is 'I', return value is in Initial Capitals.
                                     07/22/2005  Sandy Yin   Revised logic for "((@LicenseType<> '' AND UPPER(B1_LICENSE_TYPE) LIKE UPPER(@LicenseType)) OR (@LicenseType= '' AND  UPPER(B1_PRINT_FLAG)='Y' ) ) "
				     08/17/2005  Arthur Miao Revised logic added one order by field b1_print_flag, so it can get primary contents first
								added get field b1_license_nbr & b1_license_type
				     11/08/2005  Arthur Miao Added 'IF UPPER(@Get_Field)='FULLADDR_BLOCK_2'( Get All Address, Exclude Address3).
				     12/13/2005  Lydia Lim   Restore changes made on 10/11/2005 (CVS rev. 1.3) lost in 11/08/2005 revision (CVS Rev. 1.4) for Get_Field values LICENSENUMBER, LICENSETYPE, BUSINESSNAME and related comments
				     06/27/2006  Ava Wu Added 'IF UPPER(@Get_Field)='TRUNADDR_BLOCK_2'( Get All Address, Exclude Address3, and truncate the extra length of each line).
                                09/13/2006  Cece Wang Added IF UPPER(@Get_Field)='NAME_ADDR123_PHONE'(Get all information of business name & fullname & fulladdress & phone1)
                               03/06/2007  Sandy Yin Added  IF UPPER(@Get_Field)='BUS_NAME_ADR_PHONE_EML''(Busniss name, address, phone1, EMAIL 06SSP-000209.R70305) revised    @Get_Field VARCHAR(100),
                               03/27/2007  Sandy Yin  revised the  @LicenseType VARCHAR(200). since 06SSP-000209.B70326 
                     05/28/2007 Rainy Yu Add IF UPPER(@Get_Field)='BUS_NAME_ADR'(Busniss name, address 06SSP-000209.C70525)
*/ 
BEGIN 
DECLARE 
	@B1_COUNTRY NVARCHAR(30), 
	@B1_SUFFIX_NAME NVARCHAR(3), 
	@B1_BUS_LIC NVARCHAR(15), 
	@B1_LIC_ORIG_ISS_DD datetime , 
	@B1_LIC_EXPIR_DD datetime, 
	@B1_LAST_UPDATE_DD datetime, 
	@B1_LAST_RENEWAL_DD datetime, 
	@VSTR NVARCHAR(200),
	@C_Bname NVARCHAR(65),
	@C_FullName NVARCHAR(80),
	@C_fname NVARCHAR(15),
	@C_mname NVARCHAR(15),
	@C_lname NVARCHAR(35),
	@C_addr1 NVARCHAR(40),
	@C_addr2 NVARCHAR(40),
	@C_addr3 NVARCHAR(40),
	@C_city NVARCHAR(30),
	@C_state NVARCHAR(2),
	@C_zip NVARCHAR(10),
	@B1_PHONE1 NVARCHAR(40), 
	@B1_PHONE2 NVARCHAR(40), 
	@B1_FAX NVARCHAR(15),
	@B1_EMAIL NVARCHAR(70),
	@B1_SER_DES NVARCHAR(15),
	@LICENSE_NBR NVARCHAR(30),  
	@B1_LICENSE_NBR NVARCHAR(30),	
	@CSZ NVARCHAR(50),
	@B1_LICENSE_TYPE NVARCHAR(16)  
    BEGIN
      SELECT TOP 1 
	@B1_BUS_LIC=B1_BUS_LIC, 
	@B1_LIC_ORIG_ISS_DD=B1_LIC_ORIG_ISS_DD,
	@B1_LIC_EXPIR_DD=B1_LIC_EXPIR_DD, 
	@B1_LAST_UPDATE_DD=B1_LAST_UPDATE_DD,
	@B1_LAST_RENEWAL_DD=B1_LAST_RENEWAL_DD, 
	@B1_SUFFIX_NAME=B1_SUFFIX_NAME,      
        @C_fname = B1_CAE_FNAME,
        @C_mname = B1_CAE_MNAME,
        @C_lname = B1_CAE_LNAME,
        @C_Bname = B1_BUS_NAME,
        @C_addr1 = B1_ADDRESS1,
        @C_addr2 = B1_ADDRESS2,
        @C_addr3 = B1_ADDRESS3,
        @C_city = B1_CITY,
        @C_state = B1_STATE,
        @C_zip = B1_ZIP,
	@B1_COUNTRY=B1_COUNTRY, 
	@B1_PHONE1=B1_PHONE1, 
	@B1_PHONE2=B1_PHONE2, 
	@B1_FAX=B1_FAX, 
	@B1_EMAIL=B1_EMAIL,
	@B1_SER_DES=B1_SER_DES,
	@B1_LICENSE_NBR=B1_LICENSE_NBR,  
	@B1_LICENSE_TYPE=B1_LICENSE_TYPE			      
      FROM  
        B3CONTRA
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 AND
    	((@LicenseType <>N'' AND CHARINDEX(UPPER(B1_LICENSE_TYPE)+N',',UPPER(@LicenseType+N','))>0 )
        OR @LicenseType =N'')   
     ORDER BY B1_PRINT_FLAG DESC , B1_LICENSE_NBR
    END
/* Begin Busniss name, address 06SSP-000209.C70525*/
IF UPPER(@Get_Field)=N'BUS_NAME_ADR'
    BEGIN
		 IF @C_Bname <> N''
                     SET @VSTR = @C_Bname
	    IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END            
            IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
	            IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR  
            IF @C_city <> N'' 
              SET @CSZ = @C_city    
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ                 
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @C_zip
		      ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END   
/* Begin Busniss name, address, phone1, EMAIL 06SSP-000209.R70305*/
ELSE IF UPPER(@Get_Field)=N'BUS_NAME_ADR_PHONE_EML'
    BEGIN
		 IF @C_Bname <> N''
                     SET @VSTR = @C_Bname
	    IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END            
            IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
	            IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR  
            IF @C_city <> N'' 
              SET @CSZ = @C_city    
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ                 
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @C_zip
		      ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
       IF @B1_PHONE1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @B1_PHONE1
                      ELSE
                        SET @VSTR = @B1_PHONE1
               END
      IF @B1_EMAIL<>N'' 
	   BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @B1_EMAIL 
                      ELSE
                        SET @VSTR = @B1_EMAIL 
               END
    END 
/* Begin Busniss name, address, phone1, EMAIL for 06SSP-000209.R70305*/
  /* Get Address  */
ELSE  IF UPPER(@Get_Field)=N'ADDRESS1' 
    BEGIN
    BEGIN
    	IF @C_addr1 <> N''
    	  SET @VSTR = @C_addr1
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
    BEGIN
	    BEGIN
	    	IF @C_addr2 <> N''
	    	  SET @VSTR = @C_addr2
	    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3' 
    BEGIN
	    BEGIN
	    	IF @C_addr3 <> N''
	    	  SET @VSTR = @C_addr3
	    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
    BEGIN
	    BEGIN
	    	IF @C_city <> N''
	    	  SET @VSTR = @C_city
	    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'STATE' 
    BEGIN
    	IF @C_state <> N''
    	  SET @VSTR = @C_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP' 
    BEGIN
    	IF @C_zip <> N''
    	  SET @VSTR = @C_zip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
	            IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
									SET @CSZ = @CSZ + N', ' + @C_zip
		      			ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK_2' 
  --exclude Address3
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
                    IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
									SET @CSZ = @CSZ + N', ' + @C_zip
		      			ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
  ELSE IF UPPER(@Get_Field)=N'TRUNADDR_BLOCK_2' 
  --exclude Address3 and truncate the extra length
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = substring(@C_addr1, 1, 26)
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + substring(@C_addr2, 1, 26)
                      ELSE
                        SET @VSTR = substring(@C_addr2, 1, 26)
              END   
                    IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
									SET @CSZ = @CSZ + N', ' + @C_zip
		      			ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + substring(@CSZ, 1, 26)
                      ELSE
                        SET @VSTR = substring(@CSZ, 1, 26)
              END
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR            
            IF @C_state <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N'' AND isnull(@C_state,N'')<> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE IF @VSTR <> N'' AND isnull(@C_state,N'') = N'' 
			SET @VSTR = @VSTR + N', ' + @C_zip
		      ELSE
	                SET @VSTR = @C_zip
              END
    END
  /* Get City, State and Zip */
  ELSE IF UPPER(@Get_Field)=N'CSZ' 
    BEGIN                                          
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @VSTR = @CSZ
            IF @C_state <> N''
             BEGIN
	              IF @VSTR  <> N'' 
	                   SET @VSTR = @VSTR  + N', ' + @C_state
	              ELSE
	                   SET @VSTR = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N'' AND isnull(@C_state,N'')<> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE IF @VSTR <> N'' AND isnull(@C_state,N'') = N'' 
			SET @VSTR = @VSTR + N', ' + @C_zip
		      ELSE
	                SET @VSTR = @C_zip
              END                        
    END
  /*Get all information of business name & fullname & fulladdress */
  ELSE IF UPPER(@Get_Field)=N'FULL_INFO' 
    BEGIN
					 IF @C_Bname <> N''
            SET @VSTR = @C_Bname
					 IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END            
            IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
	            IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR  
            IF @C_city <> N'' 
              SET @CSZ = @C_city    
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ                 
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @C_zip
		      ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END 
/*Get all information of business name & fullname & fulladdress & phone1 */
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR123_PHONE' 
    BEGIN
					 IF @C_Bname <> N''
            SET @VSTR = @C_Bname
					 IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END            
            IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
	            IF UPPER(@Case) = N'U' 
	              SET @VSTR = UPPER(@VSTR)
	            ELSE IF UPPER(@Case) = N'I' 
	              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
	            ELSE 
	              SET @VSTR = @VSTR  
            IF @C_city <> N'' 
              SET @CSZ = @C_city    
	            IF UPPER(@Case) = N'U' 
	                SET @CSZ = UPPER(@CSZ)
	            ELSE IF UPPER(@Case) = N'I' 
	                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
	            ELSE 
	                SET @CSZ = @CSZ                 
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N'' AND isnull(@C_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE IF @CSZ <> N'' AND isnull(@C_state,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @C_zip
		      ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
            IF @B1_PHONE1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @B1_PHONE1
                      ELSE
                        SET @VSTR = @B1_PHONE1
               END
    END   
  /* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FIRSTNAME' 
    BEGIN
    	IF @C_fname <> N''
    	  SET @VSTR = @C_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LASTNAME' 
    BEGIN
    	IF @C_lname <> N''
    	  SET @VSTR = @C_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MIDDLENAME' 
    BEGIN
    	IF @C_mname <> N''
    	  SET @VSTR = @C_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END           
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR       
         END                           
    END
  /* Get COUNTRY  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @B1_COUNTRY <> N''
              SET @VSTR = @B1_COUNTRY
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get PHONE1  */
  ELSE IF UPPER(@Get_Field)=N'PHONE1' 
        BEGIN
            IF @B1_PHONE1 <> N''
              SET @VSTR = @B1_PHONE1
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get PHONE2  */
  ELSE IF UPPER(@Get_Field)=N'PHONE2' 
        BEGIN
            IF @B1_PHONE2 <> N''
              SET @VSTR = @B1_PHONE1
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get FAX  */
  ELSE IF UPPER(@Get_Field)=N'FAX' 
        BEGIN
            IF @B1_FAX <> N''
              SET @VSTR = @B1_FAX
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END        
  /* Get EMAIL  */
  ELSE IF UPPER(@Get_Field)=N'EMAIL' 
        BEGIN
            IF @B1_EMAIL <> N''
              SET @VSTR = @B1_EMAIL
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END 
  /* Get B1_SER_DES  */
  ELSE IF UPPER(@Get_Field)=N'SER_DES' 
        BEGIN
            IF @B1_SER_DES <> N''
              SET @VSTR = @B1_SER_DES
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END         
 /* Get B1_LICENSE_NBR  */
  ELSE IF UPPER(@Get_Field)=N'LICENSE_NBR' OR UPPER(@Get_Field)=N'LICENSENUMBER' 
        BEGIN
            IF @B1_LICENSE_NBR <> N''
              SET @VSTR = @B1_LICENSE_NBR
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END  
/* Get B1_LICENSE_TYPE  */
  ELSE IF UPPER(@Get_Field)=N'LICENSE_TYPE' OR UPPER(@Get_Field)=N'LICENSETYPE' 
        BEGIN
            IF @B1_LICENSE_TYPE <> N''
              SET @VSTR = @B1_LICENSE_TYPE
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END                          
  /* Get Business Name  */
  ELSE IF UPPER(@Get_Field)=N'BUSNAME' OR UPPER(@Get_Field)=N'BUSINESSNAME' 
        BEGIN
          IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
 ELSE
  /* Get Name as @Get_Field not one of the correct options  */
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
        BEGIN
	   IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FML' 
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END     
      ELSE IF UPPER(@NameFormat) = N'LF' 
        BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FL' 
        BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
       END
  END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_LICPROF_REF_ATTR](
                                            @CLIENTID NVARCHAR(15),
                                            @LICENSE_NBR NVARCHAR(30),
                                            @ATTRIBUTE_NAME NVARCHAR(70)
                                            ) RETURNS NVARCHAR(200) AS
/*  
            Author             :   Martin Ma
            Create Date        :   05/18/2005
            Version            :   AA6.0 MS SQL
            Detail             :   RETURNS: Value of the {AttributeName} custom Licensed Professional attribute for the Licensed Professional whose license number is {LicenseNumber}. The attribute value is taken from reference data for the Licensed Professional.
                                   ARGUMENTS: clientID, LicenseNumber, AttributeName
            Revision History   :   04/12/2005 Martin Ma  Initial Design
*/
BEGIN
        DECLARE @result NVARCHAR(200);
        SELECT
                TOP 1
                @result = G.G1_ATTRIBUTE_VALUE
        FROM    
                RSTATE_LIC  R, G3CONTACT_ATTRIBUTE G
        WHERE   
                R.SERV_PROV_CODE = @CLIENTID AND
                R.SERV_PROV_CODE = G.SERV_PROV_CODE AND
                CONVERT(NVARCHAR(30),R.LIC_SEQ_NBR) = G.G1_CONTACT_NBR AND
                R.LIC_TYPE = G.G1_CONTACT_TYPE AND
                R.LIC_NBR = @LICENSE_NBR   AND
                G.G1_ATTRIBUTE_NAME = @ATTRIBUTE_NAME 
        RETURN @result;
END
GO


ALTER FUNCTION [dbo].[FN_GET_LICPROF_TRUST_BALANCE] (@CLIENTID  NVARCHAR(15),
 				                    @LICENSENUM NVARCHAR(30),
                                                    @LICENSETYPE NVARCHAR(20)
                                      	           ) RETURNS FLOAT  AS
/*  Author           :   Cece Wang
    Create Date      :   03/23/2006
    Version          :   AA6.1.3 MS SQL
    RETURNS          :   Total balance for all active Trust Accounts belonging to the licensed professional whose license number is {LicenseNum} and license type is {LicenseType}.
    ARGUMENTS        :   ClientID, LicenseNum, LicenseType.
  Revision History   :   03/23/2006 Cece Wang initial design 
*/
BEGIN 
DECLARE 
  @V_TRUSTACC_BALANCE FLOAT
  SELECT 
    @V_TRUSTACC_BALANCE = SUM(R.ACCT_BALANCE)
  FROM
    RSTATE_LIC L,
    XACCT_PEOPLE X,
    RACCOUNT R   
  WHERE 
    L.SERV_PROV_CODE = @CLIENTID  AND
    upper(L.LIC_NBR) = upper(@LICENSENUM) AND
    upper(L.LIC_TYPE)= upper(@LICENSETYPE) AND
    L.REC_STATUS     = N'A' AND
    L.SERV_PROV_CODE = X.SERV_PROV_CODE AND
    L.LIC_SEQ_NBR    = X.PEOPLE_SEQ_NBR AND 
    X.PEOPLE_TYPE    = N'Licensed People' AND
    X.REC_STATUS     = N'A' AND
    X.SERV_PROV_CODE = R.SERV_PROV_CODE AND
    X.ACCT_SEQ_NBR   = R.ACCT_SEQ_NBR AND
    R.ACCT_STATUS    = N'Active' AND
    R.REC_STATUS     = N'A'
RETURN @V_TRUSTACC_BALANCE
END
GO


ALTER FUNCTION [dbo].[FN_GET_OWNER_INFO](@CLIENTID NVARCHAR(15),
                                        @PID1 NVARCHAR(5),
                                        @PID2 NVARCHAR(5),
                                        @PID3 NVARCHAR(5),
                                        @PrimaryContactFlag NVARCHAR(2),
                                        @Get_Field NVARCHAR(30),
                                        @NameFormat NVARCHAR(3),
                                        @Case NVARCHAR(1)
                                        ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   04/19/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Owner information, as follows: If {PrimaryContactFlag} is 'Y', returns primary owner; if {PrimaryContactFlag} is 'N', returns the first non-primary owner; else returns the primary owner if available or the first owner.   Returns field value as specified by {Get_Field}. If {Case} is 'U', return value is in UPPERCASE; if {Case} is 'I', return value is in Initial Capitals.
                         ARGUMENTS: CLIENTID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    PrimaryOwnerFlag ('Y', 'N', ''), 
                                    Get_Field (Options:'Name' (default), 'MAddress1', 'MAddress2', 'MAddress3', 'MFullAddr_Block', 'MFullAddr_Line', 'MCity', 'MState', 'MZip', 'MCountry', 'Phone', 'Fax'),  
                                    NameFormat (Not applicable, enter ''), 
                                    Case ('U' for uppercase, 'I' for initial-caps, '' for original case).
    Revision History :   04/19/2005  David Zheng Initial Design
    			 06/30/2005  David Zheng Revised the all values of address
			 08/17/2005  Arthur Miao Revised @owner_MCity as @get_Field='MCITY'
			 09/23/2005  Arthur Miao Added "ORDER BY B1_PRIMARY_OWNER DESC" for the 2nd query
			 09/27/2005  Lydia Lim   Edit comments to remove unused fields.
                         11/08/2005  Cece  Wang  Added 'IF UPPER(@Get_Field)='MFULLADDR_BLOCK_2''( Get All Mail_Address, Exclude Mail_Address3).
			 03/30/2006  Ava Wu Added "ELSE IF UPPER(@Get_Field)='MADDR123_BLOCK'" ( Get Mail_Address1, Mail_Address2, Mail_Address3 in Block) and "ELSE IF UPPER(@Get_Field)='MCSZ'"( Get Mail_City, Mail_State, Mail_Zip in Line)
                         08/24/2006  Sandy Yin Revised "MFULLADDR_LINE" Mzip logic.
                         09/13/2006  Cece Wang Added 'IF UPPER(@Get_Field)='MNAME_ADDR123_PHONE''(Get all information of owner name &Full Mail address & phone1)
                         10/17/2006  Sandy Yin add ELSE IF @PrimaryContactFlag = 'NO"
                         12/15/2006  Sandy Yin add ELSE IF UPPER(@Get_Field)='MNAME_ADDRS'(oracle version Getfield=OWNERNAME_MADDR  for SAN 06SSP-00124.R61214 for field P
                         02/09/2007  Sandy Yin Add Get_Field  OWNER_MADDR , owner name, Maddress(addr1, addr2,addr3 use line),Mcsz(zip with format NNNNN-NNNN)) use block;
                         02/09/2007  Sandy Yin Add Get_Field  OWNER_MADDR123_PHONE , owner name, Maddress(addr1, addr2,addr3 use line),Mcsz(zip with format NNNNN-NNNN)) use block;
			 02/09/2007  Sandy Yin Add Get_Field='MADDR12_CSZ_SPACE'[GET ADDR1,ADDR2,CSZ (insert ten space between state and zip)]
			 02/09/2007  Sandy Yin Add Get_Field='OWNERNAME_MADDR12_BLK' for 07SSP-00017 fields B8~B9,C0
			 05/10/2007  Lucky Song Correct parameter character lengths  
                         05/28/2007  Rainy Yu Added IF UPPER(@Get_Field)='MNAME_ADDR123'(Get all information of owner name &Full Mail address)
                         06/01/2007  Lydia Lim  Mark extraneous code; Add 'N' option for PrimaryOwnerFlag
*/ 
BEGIN 
DECLARE 
        @owner_name NVARCHAR(200),
        @owner_title NVARCHAR(200),
        @owner_fname NVARCHAR(200), 
        --do not use: AA does not populate this field
        @owner_mname NVARCHAR(200), 
        --do not use
        @owner_lname NVARCHAR(200), 
        --do not use
        @owner_addr1 NVARCHAR(200), 
        --do not use
        @owner_addr2 NVARCHAR(200), 
        --do not use
        @owner_addr3 NVARCHAR(200), 
        --do not use
        @owner_city NVARCHAR(200), 
        --do not use
        @owner_state NVARCHAR(200), 
        --do not use
        @owner_zip NVARCHAR(200), 
        --do not use
        @owner_country NVARCHAR(200), 
        --do not use
        @owner_phone NVARCHAR(200),
        @owner_fax NVARCHAR(200),
        @owner_MAddr1 NVARCHAR(200),
        @owner_MAddr2 NVARCHAR(200),
        @owner_MAddr3 NVARCHAR(200),
        @owner_MCity NVARCHAR(200),
        @@owner_Mstate NVARCHAR(200),
        @owner_MZip NVARCHAR(200),
        @owner_MCountry NVARCHAR(200),
        @VSTR NVARCHAR(4000),
        @CSZ NVARCHAR(50),
        @MNAME_ADDRS NVARCHAR(4000),
        @OWNER_MADDR NVARCHAR(4000),
        @owner_Mstate NVARCHAR(400)
        IF @PrimaryContactFlag = N'Y' 
            BEGIN
              SELECT  TOP 1
               @owner_name = B1_OWNER_FULL_NAME,
               @owner_title = B1_owner_title,
               @owner_fname = B1_owner_fname,
               @owner_mname = B1_owner_mname,
               @owner_lname = B1_owner_lname,
               @owner_addr1 = B1_ADDRESS1,
               @owner_addr2 = B1_ADDRESS2,
               @owner_addr3 = B1_ADDRESS3,
               @owner_city = B1_CITY,
               @owner_state = B1_STATE,
               @owner_zip = B1_ZIP,
               @owner_country = B1_COUNTRY,
               @owner_phone = B1_PHONE,
               @owner_fax = B1_FAX,
               @owner_MAddr1 = B1_MAIL_ADDRESS1,
               @owner_MAddr2 = B1_MAIL_ADDRESS2,
               @owner_MAddr3 = B1_MAIL_ADDRESS3,
               @owner_MCity = B1_MAIL_CITY,
               @@owner_Mstate = B1_MAIL_STATE,
               @owner_MZip = B1_MAIL_ZIP,
               @owner_MCountry = B1_MAIL_COUNTRY 
              FROM  
                B3OWNERS
              WHERE 
                SERV_PROV_CODE = @CLIENTID AND
                B1_PER_ID1 = @PID1 AND
                B1_PER_ID2 = @PID2 AND
                B1_PER_ID3 = @PID3 AND
                REC_STATUS = N'A' AND
                UPPER (B1_PRIMARY_OWNER) = N'Y'
            END
   ELSE IF UPPER(@PrimaryContactFlag) IN (N'NO',N'N')
             BEGIN
              SELECT  TOP 1 
                @owner_name = B1_OWNER_FULL_NAME,
                @owner_title = B1_owner_title,
                @owner_fname = B1_owner_fname,
                @owner_mname = B1_owner_mname,
                @owner_lname = B1_owner_lname,
                @owner_addr1 = B1_ADDRESS1,
                @owner_addr2 = B1_ADDRESS2,
                @owner_addr3 = B1_ADDRESS3,
                @owner_city = B1_CITY,
                @owner_state = B1_STATE,
                @owner_zip = B1_ZIP,
                @owner_country = B1_COUNTRY,
                @owner_phone = B1_PHONE,
                @owner_fax = B1_FAX,
               @owner_MAddr1 = B1_MAIL_ADDRESS1,
                @owner_MAddr2 = B1_MAIL_ADDRESS2,
                @owner_MAddr3 = B1_MAIL_ADDRESS3,
                @owner_MCity = B1_MAIL_CITY,
                @@owner_Mstate = B1_MAIL_STATE,
                @owner_MZip = B1_MAIL_ZIP,
                @owner_MCountry = B1_MAIL_COUNTRY 
              FROM  
                B3OWNERS
              WHERE 
                SERV_PROV_CODE = @CLIENTID AND
                B1_PER_ID1 = @PID1 AND
                B1_PER_ID2 = @PID2 AND
                B1_PER_ID3 = @PID3 AND
                REC_STATUS = N'A' AND
              UPPER (B1_PRIMARY_OWNER) <> N'Y'
      END
        ELSE 
            BEGIN
              SELECT  TOP 1 
                @owner_name = B1_OWNER_FULL_NAME,
                @owner_title = B1_owner_title,
                @owner_fname = B1_owner_fname,
                @owner_mname = B1_owner_mname,
                @owner_lname = B1_owner_lname,
                @owner_addr1 = B1_ADDRESS1,
                @owner_addr2 = B1_ADDRESS2,
                @owner_addr3 = B1_ADDRESS3,
                @owner_city = B1_CITY,
                @owner_state = B1_STATE,
                @owner_zip = B1_ZIP,
                @owner_country = B1_COUNTRY,
                @owner_phone = B1_PHONE,
                @owner_fax = B1_FAX,
               @owner_MAddr1 = B1_MAIL_ADDRESS1,
                @owner_MAddr2 = B1_MAIL_ADDRESS2,
                @owner_MAddr3 = B1_MAIL_ADDRESS3,
                @owner_MCity = B1_MAIL_CITY,
                @@owner_Mstate = B1_MAIL_STATE,
                @owner_MZip = B1_MAIL_ZIP,
                @owner_MCountry = B1_MAIL_COUNTRY 
              FROM  
                B3OWNERS
              WHERE 
                SERV_PROV_CODE = @CLIENTID AND
                B1_PER_ID1 = @PID1 AND
                B1_PER_ID2 = @PID2 AND
                B1_PER_ID3 = @PID3 AND
                REC_STATUS = N'A'
	      ORDER BY B1_PRIMARY_OWNER DESC
            END
  /* Get Address  */
  IF UPPER(@Get_Field)=N'ADDRESS1'  
  --do not use
    BEGIN
      IF @owner_addr1 <> N''
        SET @VSTR = @owner_addr1
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
  --do not use 
    BEGIN
      IF @owner_addr2 <> N''
        SET @VSTR = @owner_addr2
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3'  
  --do not use
    BEGIN
      IF @owner_addr3 <> N''
        SET @VSTR = @owner_addr3
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
  --do not use 
    BEGIN
      IF @owner_city <> N''
        SET @VSTR = @owner_city
    END
  ELSE IF UPPER(@Get_Field)=N'STATE'  
  --do not use
    BEGIN
      IF @owner_state <> N''
        SET @VSTR = @owner_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP'  
  --do not use
    BEGIN
      IF @owner_zip <> N''
        SET @VSTR = @owner_zip
    END
  ELSE IF UPPER(@Get_Field)=N'MADDRESS1' 
    BEGIN
      IF @owner_MAddr1 <> N''
        SET @VSTR =@owner_MAddr1
    END
  ELSE IF UPPER(@Get_Field)=N'MADDRESS2' 
    BEGIN
      IF @owner_MAddr2 <> N''
        SET @VSTR = @owner_MAddr2
    END
  ELSE IF UPPER(@Get_Field)=N'MADDRESS3' 
    BEGIN
      IF @owner_MAddr3 <> N''
        SET @VSTR = @owner_MAddr3
    END
  ELSE IF UPPER(@Get_Field)=N'MCITY' 
    BEGIN
      IF @owner_MCity <> N''
        SET @VSTR = @owner_MCity
    END
  ELSE IF UPPER(@Get_Field)=N'MSTATE' 
    BEGIN
      IF @@owner_Mstate <> N''
        SET @VSTR = @@owner_Mstate
    END
  ELSE IF UPPER(@Get_Field)=N'MZIP' 
    BEGIN
      IF @owner_MZip <> N''
        SET @VSTR = @owner_MZip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK'   
    BEGIN
            IF @owner_addr1 <> N'' 
              SET @VSTR = @owner_addr1
            IF @owner_addr2 <> N'' 
                BEGIN
                      IF  @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @owner_addr2
                      ELSE
                        SET @VSTR = @owner_addr2
                END         
            IF @owner_addr3 <> N'' 
                BEGIN
                      IF  @VSTR <> N'' 
                        SET @VSTR =  @VSTR + CHAR(10) + @owner_addr3
                      ELSE
                        SET @VSTR = @owner_addr3
                END         
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR  
            IF @owner_city <> N'' 
              SET @CSZ =  @owner_city        
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @owner_state <> N'' 
                BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @owner_state
                      ELSE
                           SET @CSZ = @owner_state
                END         
            IF @owner_zip <> N'' 
              BEGIN
                IF @CSZ <> N'' AND isnull(@owner_state,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @owner_zip
	        ELSE IF @CSZ <> N'' AND isnull(@owner_state,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @owner_zip
		     ELSE
	                SET @CSZ = @owner_zip
              END
            IF @CSZ <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
                END               
    END
  ELSE IF UPPER(@Get_Field)=N'MFULLADDR_BLOCK' 
    BEGIN
            IF @owner_MAddr1 <> N'' 
              SET @VSTR =@owner_MAddr1       
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr2
                      ELSE
                        SET @VSTR = @owner_MAddr2
                END
            IF @owner_MAddr3 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr3
                      ELSE
                        SET @VSTR = @owner_MAddr3
                END
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR 
            IF @owner_MCity <> N'' 
              SET @CSZ =  @owner_MCity        
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF @CSZ <> N'' 
                        SET @CSZ =  @CSZ + N', ' + @@owner_Mstate
                      ELSE
                        SET @CSZ =  @@owner_Mstate
                END
            IF @owner_MZip <> N'' 
              BEGIN          		              		
              	IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @owner_MZip
	        ELSE IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @owner_MZip
		     ELSE
	                SET @CSZ = @owner_MZip
              END
            IF @CSZ <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ           
                END                        
    END
/*(Get all information of owner name &Full Mail address & phone1)*/
ELSE IF UPPER(@Get_Field)=N'MNAME_ADDR123_PHONE' 
    BEGIN
        IF @owner_name <> N''
              SET @VSTR = @owner_name
            IF UPPER(@Case)= N'U' 
               SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
               SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =   @VSTR
            IF @owner_MAddr1 <> N'' 
              BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) +@owner_MAddr1
                      ELSE
                        SET @VSTR =@owner_MAddr1
                END       
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr2
                      ELSE
                        SET @VSTR = @owner_MAddr2
                END
            IF @owner_MAddr3 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr3
                      ELSE
                        SET @VSTR = @owner_MAddr3
                END
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR 
            IF @owner_MCity <> N'' 
              SET @CSZ =  @owner_MCity        
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF @CSZ <> N'' 
                        SET @CSZ =  @CSZ + N', ' + @@owner_Mstate
                      ELSE
                        SET @CSZ =  @@owner_Mstate
                END
            IF @owner_MZip <> N'' 
              BEGIN          		              		
              	IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @owner_MZip
	        ELSE IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @owner_MZip
		     ELSE
	                SET @CSZ = @owner_MZip
              END
            IF @CSZ <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ           
                END  
            IF @owner_phone <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_phone
                      ELSE
                        SET @VSTR = @owner_phone          
                END  
    END
/*(Get all information of owner name &Full Mail address )*/
ELSE IF UPPER(@Get_Field)=N'MNAME_ADDR123' 
    BEGIN
        IF @owner_name <> N''
              SET @VSTR = @owner_name
            IF UPPER(@Case)= N'U' 
               SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
               SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =   @VSTR
            IF @owner_MAddr1 <> N'' 
              BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) +@owner_MAddr1
                      ELSE
                        SET @VSTR =@owner_MAddr1
                END       
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr2
                      ELSE
                        SET @VSTR = @owner_MAddr2
                END
            IF @owner_MAddr3 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr3
                      ELSE
                        SET @VSTR = @owner_MAddr3
                END
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR 
            IF @owner_MCity <> N'' 
              SET @CSZ =  @owner_MCity        
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF @CSZ <> N'' 
                        SET @CSZ =  @CSZ + N', ' + @@owner_Mstate
                      ELSE
                        SET @CSZ =  @@owner_Mstate
                END
            IF @owner_MZip <> N'' 
              BEGIN          		              		
              	IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @owner_MZip
	        ELSE IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @owner_MZip
		     ELSE
	                SET @CSZ = @owner_MZip
              END
            IF @CSZ <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ           
                END  
    END
/* Get Mail_Address1, Mail_Address2, Mail_Address3 in Block*/
  ELSE IF UPPER(@Get_Field)=N'MADDR123_BLOCK' 
    BEGIN
             IF @owner_MAddr1 <> N'' 
              SET @VSTR =@owner_MAddr1       
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr2
                      ELSE
                        SET @VSTR = @owner_MAddr2
                END
            IF @owner_MAddr3 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr3
                      ELSE
                        SET @VSTR = @owner_MAddr3
                END
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR 
     END
/* Get Mail_City, Mail_State, Mail_Zip in Line*/
  ELSE IF UPPER(@Get_Field)=N'MCSZ' 
    BEGIN
            IF @owner_MCity <> N'' 
              SET @VSTR =  @owner_MCity        
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE 
                SET @VSTR =   @VSTR
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =    @VSTR + N', ' + @@owner_Mstate
                      ELSE
                        SET @VSTR =  @@owner_Mstate
                END
            IF @owner_MZip <> N'' 
              BEGIN          		              		
              	IF   @VSTR <> N'' AND isnull(@@owner_Mstate,N'')<> N''
	                SET @VSTR =   @VSTR + N' ' + @owner_MZip
	        ELSE IF   @VSTR <> N'' AND isnull(@@owner_Mstate,N'') = N'' 
			SET @VSTR =   @VSTR + N', ' + @owner_MZip
		     ELSE
	                SET @VSTR = @owner_MZip
              END
      END 
/* Get All Mail_Address, Exclude Mail_Address3 */
 ELSE IF UPPER(@Get_Field)=N'MFULLADDR_BLOCK_2' 
    BEGIN
             IF @owner_MAddr1 <> N'' 
              SET @VSTR =@owner_MAddr1       
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @owner_MAddr2
                      ELSE
                        SET @VSTR = @owner_MAddr2
                END
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR 
            IF @owner_MCity <> N'' 
              SET @CSZ =  @owner_MCity        
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF @CSZ <> N'' 
                        SET @CSZ =  @CSZ + N', ' + @@owner_Mstate
                      ELSE
                        SET @CSZ =  @@owner_Mstate
                END
            IF @owner_MZip <> N'' 
              BEGIN          		              		
              	IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @owner_MZip
	        ELSE IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @owner_MZip
		     ELSE
	                SET @CSZ = @owner_MZip
              END
            IF @CSZ <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ           
                END                        
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @owner_addr1 <> N'' 
              SET @VSTR = @owner_addr1
            IF @owner_addr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + N', ' + @owner_addr2
                      ELSE
                        SET @VSTR = @owner_addr2
                END
            IF @owner_addr3 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + N', ' + @owner_addr3
                      ELSE
                        SET @VSTR = @owner_addr3
                END                      
            IF @owner_city <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + N', ' + @owner_city
                      ELSE
                        SET @VSTR = @owner_city
                END         
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR
            IF @owner_state <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + N', ' + @owner_state
                      ELSE
                        SET @VSTR = @owner_state
                END      
               IF @owner_zip  <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + N', ' + @owner_zip 
                      ELSE
                        SET @VSTR = @owner_zip 
                END      
            /*IF @owner_zip <> '' 
              BEGIN
                IF @CSZ <> '' AND isnull(@owner_state,'')<> ''
	                SET @CSZ = @CSZ + ' ' + @owner_zip
	        ELSE IF @CSZ <> '' AND isnull(@owner_state,'') = '' 
			SET @CSZ = @CSZ + ', ' + @owner_zip
		     ELSE
	                SET @CSZ = @owner_zip
              END          */
    END
  ELSE IF UPPER(@Get_Field)=N'MFULLADDR_LINE' 
    BEGIN
             IF @owner_MAddr1 <> N'' 
              SET @VSTR =@owner_MAddr1     
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + N', ' + @owner_MAddr2
                      ELSE
                        SET @VSTR = @owner_MAddr2
                END      
            IF @owner_MAddr3 <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                            SET @VSTR =   @VSTR + N', ' + @owner_MAddr3
                      ELSE
                            SET @VSTR = @owner_MAddr3
                END             
            IF @owner_MCity <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                            SET @VSTR =   @VSTR + N', ' + @owner_MCity
                      ELSE
                            SET @VSTR = @owner_MCity
                END            
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
              SET @VSTR =   @VSTR 
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                           SET @VSTR =   @VSTR + N', ' + @@owner_Mstate
                      ELSE
                           SET @VSTR = @@owner_Mstate                
                END
              IF @owner_MZip <> N'' 
                        IF   @VSTR <> N'' 
                           SET @VSTR =   @VSTR + N' ' + @owner_MZip
                      ELSE
                           SET @VSTR = @owner_MZip 
           /* IF @owner_MZip <> '' 
              BEGIN
                IF @CSZ <> '' AND isnull(@@owner_Mstate,'')<> ''
	                SET @CSZ = @CSZ + ' ' + @owner_MZip
	        ELSE IF @CSZ <> '' AND isnull(@@owner_Mstate,'') = '' 
			SET @CSZ = @CSZ + ', ' + @owner_MZip
		     ELSE
	                SET @CSZ = @owner_MZip
              END*/                   
    END
/*   12/15/2006   Sandy Yin add ELSE IF UPPER(@Get_Field)='MNAME_ADDRS'  for SAN 06SSP-00124.R61214  begin  */   
ELSE IF UPPER(@Get_Field)=N'MNAME_ADDRS'  
    BEGIN
        IF @owner_name <> N''
              SET @VSTR = @owner_name
            IF UPPER(@Case)= N'U' 
               SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
               SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =   @VSTR
             IF @owner_MAddr1 <> N'' 
                   SET @MNAME_ADDRS =@owner_MAddr1
            IF @owner_MAddr2 <> N'' 
                BEGIN
                      IF @MNAME_ADDRS <> N'' 
                        SET @MNAME_ADDRS = @MNAME_ADDRS +CHAR(10)+ @owner_MAddr2
                      ELSE
                        SET @MNAME_ADDRS = @owner_MAddr2
                END
            IF @owner_MAddr3 <> N'' 
                BEGIN
                      IF @MNAME_ADDRS <> N'' 
                        SET @MNAME_ADDRS = @MNAME_ADDRS +CHAR(10) + @owner_MAddr3
                      ELSE
                        SET @MNAME_ADDRS = @owner_MAddr3
                END
            IF UPPER(@Case)= N'U' 
              SET @MNAME_ADDRS = UPPER(@MNAME_ADDRS)
            ELSE IF UPPER(@Case)= N'I' 
              SET @MNAME_ADDRS = DBO.FN_GET_INITCAP(N'',@MNAME_ADDRS)
            ELSE
              SET @MNAME_ADDRS = @MNAME_ADDRS 
             IF  @MNAME_ADDRS<>N''
             BEGIN
             IF   @VSTR<> N'' 
              SET @VSTR=  @VSTR+CHAR(10)+  @MNAME_ADDRS
              ELSE 
              SET @VSTR=@MNAME_ADDRS
             END
            IF @owner_MCity <> N'' 
              SET @CSZ =  @owner_MCity        
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @@owner_Mstate <> N'' 
                BEGIN
                      IF @CSZ <> N'' 
                        SET @CSZ =  @CSZ + N', ' + @@owner_Mstate
                      ELSE
                        SET @CSZ =  @@owner_Mstate
                END
            IF @owner_MZip <> N'' 
              BEGIN          		              		
              	IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'')<> N''
	                SET @CSZ = @CSZ + N' ' + @owner_MZip
	        ELSE IF @CSZ <> N'' AND isnull(@@owner_Mstate,N'') = N'' 
			SET @CSZ = @CSZ + N', ' + @owner_MZip
		     ELSE
	                SET @CSZ = @owner_MZip
              END
            IF @CSZ <> N'' 
                BEGIN
                      IF   @VSTR <> N'' 
                        SET @VSTR =   @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ           
                END  
    END
/*   12/15/2006   Sandy Yin add ELSE IF UPPER(@Get_Field)='MNAME_ADDRS'  for SAN 06SSP-00124.R61214  end  */   
/* Extraneous Code DO NOT USE: Start */
  /* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FNAME' 
  --do not use
    BEGIN
      IF @owner_fname <> N''
        SET @VSTR = @owner_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LNAME'  
  --do not use
    BEGIN
      IF @owner_lname <> N''
        SET @VSTR = @owner_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MNAME'  
  --do not use
    BEGIN
      IF @owner_mname <> N''
        SET @VSTR = @owner_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
  --do not use
    BEGIN
      IF UPPER(@NameFormat)= N'LFM' 
        BEGIN
                IF @owner_lname <> N''
                  SET @VSTR = @owner_lname
                IF @owner_fname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N', ' + @owner_fname
                    ELSE
                    	SET @VSTR = @owner_fname
                  END
                IF @owner_mname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_mname
                    ELSE
                    	SET @VSTR = @owner_mname
                  END
                IF UPPER(@Case)= N'U' 
                  SET @VSTR = UPPER(  @VSTR)  
                ELSE IF UPPER(@Case)= N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR) 
                ELSE
                  SET @VSTR =   @VSTR
        END
      ELSE IF UPPER(@NameFormat)= N'FLM'  
      --do not use
        BEGIN
                IF @owner_fname <> N''
                  SET @VSTR = @owner_fname
                IF @owner_lname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_lname
                    ELSE
                    	SET @VSTR = @owner_lname
                  END
                IF @owner_mname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_mname
                    ELSE
                    	SET @VSTR = @owner_mname
                  END
                IF UPPER(@Case)= N'U' 
                  SET @VSTR = UPPER(  @VSTR)  
                ELSE IF UPPER(@Case)= N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR) 
                ELSE
                  SET @VSTR =   @VSTR
        END
      ELSE IF UPPER(@NameFormat)= N'FML'  
      --do not use
        BEGIN
                IF @owner_fname <> N''
                  SET @VSTR = @owner_fname
                IF @owner_mname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_mname
                    ELSE
                    	SET @VSTR = @owner_mname
                  END
                IF @owner_lname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_lname
                    ELSE
                    	SET @VSTR = @owner_lname
                  END
                IF UPPER(@Case)= N'U' 
                  SET @VSTR = UPPER(  @VSTR)  
                ELSE IF UPPER(@Case)= N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR) 
                ELSE
                  SET @VSTR =   @VSTR
        END
      ELSE IF UPPER(@NameFormat)= N'LF'  
      --do not use
        BEGIN
                IF @owner_lname <> N''
                  SET @VSTR = @owner_lname
                IF @owner_fname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_fname
                    ELSE
                    	SET @VSTR = @owner_fname
                  END
                IF UPPER(@Case)= N'U' 
                  SET @VSTR = UPPER(  @VSTR)  
                ELSE IF UPPER(@Case)= N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR) 
                ELSE
                  SET @VSTR =   @VSTR
        END
      ELSE IF UPPER(@NameFormat)= N'FL'  
      --do not use
        BEGIN
                IF @owner_fname <> N''
                  SET @VSTR = @owner_fname
                IF @owner_lname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_lname
                    ELSE
                    	SET @VSTR = @owner_lname
                  END
                IF UPPER(@Case)= N'U' 
                  SET @VSTR = UPPER(  @VSTR)  
                ELSE IF UPPER(@Case)= N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR) 
                ELSE
                  SET @VSTR =   @VSTR
        END
      ELSE
        BEGIN
                IF @owner_fname <> N''
                  SET @VSTR = @owner_fname
                IF @owner_mname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_mname
                    ELSE
                    	SET @VSTR = @owner_mname
                  END
                IF @owner_lname <> N''
                  BEGIN
                    IF   @VSTR <> N''
                    	SET @VSTR =   @VSTR + N' ' + @owner_lname
                    ELSE
                    	SET @VSTR = @owner_lname
                  END
                IF UPPER(@Case)= N'U' 
                  SET @VSTR = UPPER(  @VSTR)  
                ELSE IF UPPER(@Case)= N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR) 
                ELSE
                  SET @VSTR =   @VSTR
        END
    END
/* Extraneous Code DO NOT USE: End */
  /* Get Title  */
  ELSE IF UPPER(@Get_Field)=N'TITLE' 
        BEGIN
            IF @owner_title <> N''
              SET @VSTR = @owner_title
            IF UPPER(@Case)= N'U' 
               SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
               SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =   @VSTR
       END
  /* Get Phone  */
  ELSE IF UPPER(@Get_Field)=N'PHONE' 
    BEGIN
      IF @owner_phone <> N''
        SET @VSTR = @owner_phone
    END
  /* Get Fax  */
  ELSE IF UPPER(@Get_Field)=N'FAX' 
    BEGIN
      IF @owner_fax <> N''
        SET @VSTR = @owner_fax
    END
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @owner_country <> N''
              SET @VSTR = @owner_country
            IF UPPER(@Case)= N'U' 
              SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =   @VSTR
        END
ELSE IF UPPER(@Get_Field)=N'OWNER_MADDR' 
       BEGIN
             IF @owner_MAddr1 <>N''
               SET @VSTR = @owner_MAddr1;
            ELSE
              SET @VSTR = N'';
            IF @owner_MAddr2 <>N''
             BEGIN 
              IF   @VSTR <>N''
                  SET @VSTR =   @VSTR + N', ' +@owner_MAddr2;
              ELSE
                 SET @VSTR =@owner_MAddr2;
              END
	       IF @owner_MAddr3 <>N''  
	             BEGIN 
		              IF  @VSTR <>N''  
		                  SET @VSTR =   @VSTR + N', ' + @owner_MAddr3 ;
		              ELSE
		                 SET @VSTR =  @owner_MAddr3 ;
	              END 
            IF @owner_Mcity <>N''  
             SET @CSZ = ltrim(@owner_Mcity);
            ELSE
             SET @CSZ = N'';
            IF @@owner_Mstate <>N''  
	           BEGIN 
	             IF @CSZ <>N''  
	              SET  @CSZ = ltrim(@CSZ) + N', ' + ltrim(@@owner_Mstate);
	              ELSE
	               SET  @CSZ = ltrim(@@owner_Mstate);
	              END 
             IF @owner_Mzip <>N'' 
               BEGIN 
              IF LEN(rtrim(REPLACE(@owner_Mzip,N'-',N'')))>5   
                SET @CSZ = ltrim(@CSZ) + N'  ' + SUBSTRING(REPLACE(@owner_Mzip,N'-',N''),1,5)+N'-'+ SUBSTRING(REPLACE(@owner_Mzip,N'-',N''),6,20);
              ELSE
                SET @CSZ = ltrim(@CSZ) + N'  ' + @owner_Mzip;
              END 
            IF @CSZ <>N''  
              BEGIN
              IF   @VSTR <>N''  
                 SET @VSTR =   @VSTR + CHAR(10) + ltrim(@CSZ);
              ELSE
                 SET @VSTR = ltrim(@CSZ);
              END 
            IF @owner_name <>N''  
             BEGIN
		 IF   @VSTR <>N''  
               SET @VSTR=@owner_name+CHAR(10)+  @VSTR;
              ELSE
               SET @VSTR=@owner_name;
              END 
            IF UPPER(@Case)= N'U'   
               SET @VSTR = UPPER( @VSTR);
            ELSE IF UPPER(@Case)= N'I'   
               SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =   @VSTR;
  END 
ELSE IF UPPER(@Get_Field)=N'OWNER_MADDR123_PHONE'
      BEGIN
            IF @owner_MAddr1 <>N''  
             SET  @VSTR = @owner_MAddr1;
            ELSE
             SET  @VSTR = N'';
            IF @owner_MAddr2 <>N''  
           BEGIN  
 	    IF @VSTR <>N''  
               SET  @VSTR = @VSTR+ N', '+ @owner_MAddr2;
              ELSE
               SET  @VSTR = @owner_MAddr2;
            END
            IF @owner_MAddr3 <>N''  
              BEGIN
	        IF @VSTR <>N''  
               SET  @VSTR = @VSTR+ N', '+ @owner_MAddr3;
              ELSE
               SET  @VSTR = @owner_MAddr3;
              END 
            IF @owner_Mcity <>N''  
              SET @CSZ= ltrim(@owner_Mcity);
            ELSE
              SET @CSZ= N'';
            IF @owner_Mstate <>N''  
             BEGIN
 		IF @CSZ <>N''  
                SET @CSZ= ltrim(@CSZ)+ N', '+ ltrim(@owner_Mstate);
              ELSE
                SET @CSZ= ltrim(@owner_Mstate);
            END 
            IF @owner_Mzip <>N''  
                 SET @CSZ= ltrim(@CSZ)+ N'  '+ @owner_Mzip;
            IF @CSZ <>N'' 
               BEGIN  
              IF @VSTR <>N''  
               SET  @VSTR = @VSTR+ CHAR(10)+ ltrim(@CSZ);
              ELSE
               SET  @VSTR = ltrim(@CSZ);
             END 
           IF  @owner_phone <>N''  
			BEGIN    
			IF @VSTR <>N'' 
                           BEGIN  
			     IF LEN(rtrim(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''))) >6  
			      SET  @VSTR=@VSTR+CHAR(10)+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),1,3)+N'-'+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),4,3)+N'-'+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),7,4) ;
				ELSE IF LEN(rtrim(rtrim(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N'')))) >3  
				  SET  @VSTR=@VSTR+CHAR(10)+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),1,3)+N'-'+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),4,3) ;
				 ELSE
				  SET  @VSTR=@VSTR+CHAR(10)+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),1,3);
				 END 
    			END
    		     ELSE
			    BEGIN 
                               IF LEN(rtrim(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''))) >6  
			        SET  @VSTR=SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),1,3)+N'-'+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),4,3)+N'-'+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),7,4) ;
				 ELSE IF LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N'')) >3  
				  SET  @VSTR=SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),1,3)+N'-'+SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),4,3) ;
				 ELSE
				  SET  @VSTR=SUBSTRING(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@owner_phone,N'-',N''),N'_',N''),N'(',N''),N')',N''),N'',N''),1,3);
				END 	
            IF @owner_name <>N''  
             IF @VSTR <>N''  
             SET  @VSTR=@owner_name+CHAR(10)+@VSTR;
              ELSE
             SET  @VSTR=@owner_name;
            IF UPPER(@Case)= N'U'  
             SET  @VSTR = UPPER(@VSTR);
            ELSE IF UPPER(@Case)= N'I'  
             SET  @VSTR =  DBO.FN_GET_INITCAP(N'',  @VSTR);
            ELSE
             SET  @VSTR = @VSTR;
  END 
 ELSE IF  UPPER(@Get_Field)= N'MADDR12_CSZ_SPACE' 
    BEGIN
            IF @owner_Maddr1 <>N''
              SET  @VSTR = @owner_Maddr1;
            ELSE
              SET  @VSTR = N'';
            IF @owner_Maddr2 <>N''
             	BEGIN
              IF @VSTR <>N''
                SET  @VSTR = @VSTR + CHAR(10) + @owner_Maddr2;
              ELSE
                SET  @VSTR = @owner_Maddr2;
            END 
            IF @owner_Mcity <>N''
             SET  @CSZ = @owner_Mcity;
            ELSE
             SET  @CSZ = N'';
            IF @owner_Mstate <>N''
             BEGIN
              IF @CSZ <>N''
               SET  @CSZ = @CSZ + N', ' + @owner_Mstate;
              ELSE
               SET  @CSZ = @owner_Mstate;
              END 
            IF @owner_Mzip <>N''
             SET  @CSZ = @CSZ + N'          ' + @owner_Mzip;
            IF @CSZ <>N''
             BEGIN
              IF @VSTR <>N''
                SET  @VSTR = @VSTR + CHAR(10) + ltrim(@CSZ);
              ELSE
                SET  @VSTR = ltrim(@CSZ);
              END
            IF UPPER(@Case)= N'U' 
              SET  @VSTR = UPPER(@VSTR);
             ELSE IF  UPPER(@Case)= N'I' 
              SET  @VSTR =  DBO.FN_GET_INITCAP(N'',  @VSTR);
            ELSE
              SET  @VSTR = @VSTR;
    END;
  /* Begin GET Owner Name,MAddress 1,MAddress 2,in block format */
ELSE IF UPPER(@Get_Field)=N'OWNERNAME_MADDR12_BLK' 
  BEGIN
	IF @owner_name <>N''
	  SET  @VSTR =@owner_name;
	ELSE
	  SET  @VSTR = N'';
    IF @owner_Maddr1 <>N''
   BEGIN
      IF @VSTR <>N''
        SET @VSTR=@VSTR+CHAR(10)+ @owner_Maddr1;
      ELSE
        SET @VSTR=@owner_Maddr1;
      END 
    IF @owner_Maddr2 <>N''
      BEGIN 
	IF @VSTR <>N''
       SET  @VSTR=@VSTR+CHAR(10)+ @owner_Maddr2;
       ELSE
       SET  @VSTR=@owner_Maddr2;
      END 
    IF UPPER(@Case)= N'U' 
        SET  @VSTR = UPPER(@VSTR);
    ELSE IF  UPPER(@Case)= N'I' 
        SET  @VSTR =  DBO.FN_GET_INITCAP(N'',  @VSTR);
    ELSE
        SET  @VSTR = @VSTR;
  END ;
  /* Get Owner Full Name (Default) */
  ELSE
        BEGIN
            IF @owner_name <> N''
              SET @VSTR = @owner_name
            IF UPPER(@Case)= N'U' 
               SET @VSTR = UPPER(  @VSTR)
            ELSE IF UPPER(@Case)= N'I' 
               SET @VSTR = DBO.FN_GET_INITCAP(N'',  @VSTR)
            ELSE
               SET @VSTR =@VSTR
       END
  RETURN   @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_OWNER_NAME](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5)
                                      ) RETURNS NVARCHAR (100)  AS
/*  Author           :   Sandy Yin
    Create Date      :   11/29/2004
    Version          :   AA5.3 MSSQL
    Detail           :   RETURNS: Primary owner's full name; if there is no primary owner, selects the first owner on the application.
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ChecklistDescription.
    Revision History :
*/
BEGIN 
	DECLARE @RESULT NVARCHAR(100),
                @TEMP  NVARCHAR(100) SET @TEMP=N'';
	SELECT	
		TOP 1 @RESULT=B1_OWNER_FULL_NAME
	FROM	
		B3OWNERS 
	WHERE	
		SERV_PROV_CODE = @CLIENTID AND    
		B1_PER_ID1 = @PID1 AND    
		B1_PER_ID2 = @PID2 AND    
		B1_PER_ID3 = @PID3  AND	
		REC_STATUS = N'A' AND 
		B1_PRIMARY_OWNER = N'Y';
                IF  @RESULT IS  NOT NULL
                 	RETURN @RESULT
               ELSE
  		 SELECT	
			TOP 1 @TEMP=B1_OWNER_FULL_NAME
		FROM	
			B3OWNERS 
		WHERE	
			SERV_PROV_CODE = @CLIENTID AND    
			B1_PER_ID1 = @PID1 AND    
			B1_PER_ID2 = @PID2 AND    
			B1_PER_ID3 = @PID3  AND	
			REC_STATUS = N'A' ;
                      RETURN  @TEMP ;
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARAMETER_FISCAL_YEAR] (@P_ROW INT,
				    		  @P_DATE DATETIME)
				    		  RETURNS NVARCHAR(10) AS
/*  Author           :   Glory Wang
    Create Date      :   12/29/2004
    Version          :   AA6.0
    Detail           :   RETURNS: Get Parameter Fiscal Year(Format:yy/yy)
    ARGUMENTS        :   row number(int) ,begin date(current date)
  Revision History :
*/
BEGIN
DECLARE 
  @V_FIS_YEAR INT,
  @V_MONTH NVARCHAR(2),
  @V_DAY NVARCHAR(2)
  SET @V_FIS_YEAR = CONVERT(INT,DATEPART(YEAR,@P_DATE))-@P_ROW
  SET @V_MONTH = DATEPART(MONTH,@P_DATE)
  SET @V_DAY = DATEPART(DAY,@P_DATE)
  IF CONVERT(INT,@V_MONTH+@V_DAY) > 630
    SET @V_FIS_YEAR = @V_FIS_YEAR + 1
RETURN (SUBSTRING(CONVERT(CHAR,@V_FIS_YEAR-1),3,2)+N'/'+SUBSTRING(CONVERT(CHAR,@V_FIS_YEAR),3,2))
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARCEL_DIST]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5)
	 )
RETURNS NVARCHAR(1000) AS 
/*  Author           :   	Arthur Miao
    Create Date      :   	12/07/2004
    Version          :  	AA6.0 MSSQL
    Detail           :   	RETURNS: Supervisor District for the first parcel on the application.
                        	ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
    Revision History :     	12/07/2004  Arthur Miao    Initial Design
				?	    Larry Cooper   Add code to delete function if it already exists
				09/22/2005  Lydia Lim      Edit comment.
*/
BEGIN 
	DECLARE @SNAMEVALUE NVARCHAR(200)
	SELECT	
		TOP 1 
		@SNAMEVALUE=B.L1_SUPERVISOR_DISTRICT
	FROM	
		B3PARCEL A, L3PARCEL B
	WHERE 
		A.B1_PARCEL_NBR=B.L1_PARCEL_NBR AND
		A.SERV_PROV_CODE =@CLIENTID  AND
		A.REC_STATUS = N'A' AND
		A.B1_PER_ID1=@PID1  AND
		A.B1_PER_ID2=@PID2  AND
		A.B1_PER_ID3=@PID3  
	RETURN isnull(@SNAMEVALUE,N'')
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARCEL_INFO](@CLIENTID NVARCHAR(15),
                                        @PID1 NVARCHAR(5),
                                        @PID2 NVARCHAR(5),
                                        @PID3 NVARCHAR(5),
                                        @Get_Field NVARCHAR(20)
                                        ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Arthur Miao
    Create Date      :   08/17/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNs: Information about the first parcel for the application.  Returns field value as specified by {Get_Field}. If {Get_Field} is 'PARCEL NBR', returns parcel number.
                         ARGUMENTS: CLIENTID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    Get_Field (Options:'PARCEL NBR'(default),'BOOK','PAGE','PARCEL','LOT','BLOCK','TRACT','PARCEL AREA','LEGAL DESCRIPTION','CENSUS TRACT','MAP NBR', 'COUNCIL DIST').
    Revision History :   08/17/2005  Arthur Miao initial design
			 10/18/2005  Arthur Miao Modified for field B1_PARCEL_AREA
			 11/21/2005  Sandy Yin   Added IF UPPER(@Get_Field)='CENSUS_TRACT', get CENSUS TRACT from L3PARCEL table.
			 11/29/2005  Lydia Lim   Changed parameter option from CENSUS_TRACT to CENSUs TRACT				
                         12/06/2006  Sandy Yin   Revised the 'PARCEL AREA'  field , remove the function str(06SSP-00140.B61205)
                         02/08/2006  Lydia Lim   Added 'MAP NBR' to @Get_Field options
                         02/09/2007  Sandy Yin   Added 'INSPECTION DIST','COUNCIL_DIST' ,'PARCEL NBR FORMAT'(FORMAT" (NNN-NNNN-NNN-NNNN)to @Get_Field options
                         05/10/2007  Rainy Yu change @LEGAL_DESC VARCHAR(2000) and RETURNS VARCHAR (4000)
                         06/14/2007  Lydia Lim  Edit comments, add COUNCIL DIST option
*/
BEGIN 
DECLARE 
	@VSTR NVARCHAR(4000),
        @PARCEL_NBR NVARCHAR(24),
        @BOOK NVARCHAR(8),
        @PAGE NVARCHAR(8),
        @PARCEL NVARCHAR(9),
        @MAP_REF NVARCHAR(30),
        @MAP_NBR NVARCHAR(10),
        @LOT NVARCHAR(40),
        @BLOCK NVARCHAR(15),
        @TRACT NVARCHAR(80),
        @LEGAL_DESC NVARCHAR(2000),
        @PARCEL_AREA NUMERIC(15,2),
        @L1_PARCEL_NBR NVARCHAR(24),
        @SOURCE_NBR    BIGINT
    SELECT  TOP 1
        @PARCEL_NBR=B1_PARCEL_NBR,
        @BOOK=B1_BOOK,
        @PAGE =B1_PAGE,
        @PARCEL=B1_PARCEL,
        @MAP_REF=B1_MAP_REF,
        @MAP_NBR=B1_MAP_NBR,
        @LOT=B1_LOT,
        @BLOCK =B1_BLOCK,
        @TRACT=B1_TRACT,
        @LEGAL_DESC=B1_LEGAL_DESC,
        @PARCEL_AREA=B1_PARCEL_AREA,
        @L1_PARCEL_NBR=L1_PARCEL_NBR
      FROM  
                B3PARCEL
      WHERE 
                SERV_PROV_CODE = @CLIENTID AND
                B1_PER_ID1 = @PID1 AND
                B1_PER_ID2 = @PID2 AND
                B1_PER_ID3 = @PID3 AND
                REC_STATUS = N'A' 
  /* Get PARCEL INFO  */
  IF UPPER(@Get_Field)=N'PARCEL NBR' 
    BEGIN
      IF @PARCEL_NBR <> N''
        SET @VSTR = @PARCEL_NBR
    END
  ELSE IF UPPER(@Get_Field)=N'BOOK' 
    BEGIN
      IF @BOOK <> N''
        SET @VSTR = @BOOK
    END
  ELSE IF UPPER(@Get_Field)=N'PAGE' 
    BEGIN
      IF @PAGE <> N''
        SET @VSTR = @PAGE
    END
  ELSE IF UPPER(@Get_Field)=N'LOT' 
    BEGIN
      IF @LOT <> N''
        SET @VSTR = @LOT
    END
  ELSE IF UPPER(@Get_Field)=N'BLOCK' 
    BEGIN
      IF @BLOCK <> N''
        SET @VSTR = @BLOCK
    END
  ELSE IF UPPER(@Get_Field)=N'PARCEL AREA' 
    BEGIN
      IF @PARCEL_AREA IS NOT NULL
        SET @VSTR = @PARCEL_AREA
    END
  ELSE IF UPPER(@Get_Field)=N'PARCEL' 
    BEGIN
      IF @PARCEL<>N''
        SET @VSTR = @PARCEL
    END
  ELSE IF UPPER(@Get_Field)=N'TRACT' 
    BEGIN
      IF @TRACT <> N''
        SET @VSTR = @TRACT
    END
  ELSE IF UPPER(@Get_Field)=N'LEGAL DESCRIPTION' 
    BEGIN
      IF @LEGAL_DESC <> N''
        SET @VSTR = @LEGAL_DESC
    END
  ELSE IF UPPER(@Get_Field)=N'MAP NBR'
    BEGIN
      IF @MAP_NBR<>N''
        SET @VSTR = @MAP_NBR
    END
  ELSE IF UPPER(@Get_Field)=N'CENSUS TRACT' or 
           UPPER(@Get_Field)=N'INSPECTION DIST' OR
           UPPER(@Get_Field)=N'MAP_NUM' OR
           UPPER(@Get_Field) IN (N'COUNCIL_DIST',N'COUNCIL DIST') 
    BEGIN
    	SELECT  
		@SOURCE_NBR=APO_SRC_SEQ_NBR
	FROM RSERV_PROV
	WHERE SERV_PROV_CODE=@CLIENTID
	SELECT	TOP 1
		@VSTR= case when UPPER(@Get_Field)= N'CENSUS TRACT' then  B.L1_CENSUS_TRACT
		             when UPPER(@Get_Field)=N'INSPECTION DIST' then B.L1_INSPECTION_DISTRICT
		             when UPPER(@Get_Field)IN (N'COUNCIL_DIST',N'COUNCIL DIST') then B.l1_council_district
		             else N'' end 
		FROM	
			B3PARCEL A, L3PARCEL B
		WHERE 
			A.B1_PARCEL_NBR=B.L1_PARCEL_NBR AND
			B.L1_PARCEL_STATUS=N'A' AND
			A.SERV_PROV_CODE =@CLIENTID  AND
			A.REC_STATUS = N'A'  AND
			A.B1_PER_ID1=@PID1  AND
			A.B1_PER_ID2=@PID2  AND
			A.B1_PER_ID3=@PID3  AND 
			B.SOURCE_SEQ_NBR=@SOURCE_NBR
     END
  ELSE IF UPPER(@Get_Field)=N'PARCEL NBR FORMAT' 
	  BEGIN
	   IF len(@PARCEL_NBR)>=14 
	   SET  @VSTR =SUBSTRING(@PARCEL_NBR,1,3)+N'-'+ SUBSTRING(@PARCEL_NBR,4,4)+N'-' +SUBSTRING(@PARCEL_NBR,8,3)+N'-'+ SUBSTRING(@PARCEL_NBR,11,4);
	  ELSE IF   LEN(REPLACE(@PARCEL_NBR,N'-',N''))>=12 
	   SET  @VSTR =SUBSTRING(@PARCEL_NBR,1,3)+N'-'+ SUBSTRING(@PARCEL_NBR,4,4)+N'-' +SUBSTRING(@PARCEL_NBR,8,3);
	  ELSE
	   SET @VSTR =@PARCEL_NBR;
		END     
  ELSE
  --DEFAULT IS B1_PARCEL_NBR
    BEGIN
      IF @PARCEL_NBR<> N''
        SET @VSTR = @PARCEL_NBR
    END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARCEL_NBR]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5)
	 )
RETURNS NVARCHAR(50) AS 
/*  Author           :   	Lucky Song
    Create Date      :   	12/30/2004
    Version          :  	AA6.0
    Detail           :   	RETURNS: one parcel number
                        		ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History :
*/
BEGIN 
	DECLARE @PARCELNOVALUE NVARCHAR(50)
	SELECT	
		TOP 1 
		@PARCELNOVALUE=B1_PARCEL_NBR
	FROM	
		B3PARCEL 
	WHERE 		
		SERV_PROV_CODE =@CLIENTID  AND
		REC_STATUS = N'A' AND
		B1_PER_ID1=@PID1  AND
		B1_PER_ID2=@PID2  AND
		B1_PER_ID3=@PID3  
	RETURN isnull(@PARCELNOVALUE,N'')
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARCEL_NBR_ALL]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5),
	 @Delimiter NVARCHAR(500)
	 )
RETURNS NVARCHAR(4000) AS
/*  Author           :   Arthur Miao
    Create Date      :   08/24/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: Get all parcel numbers for application,  Values will be separated by {Delimiter} or line breaks if {Delimiter} is not specified ; 
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3,Delimiter (default is single line break).
  Revision History :	 08/24/2005  Arthur Miao initial design 
                         02/06/2006  Lydia Lim   Drop function before creating it.
*/
BEGIN 
DECLARE
	@VSTR	              NVARCHAR(4000),
	@Result	  	      NVARCHAR(4000);
	set  @VSTR=N'';
	DECLARE CURSOR_1 CURSOR FOR
	SELECT	
   		ISNULL(B1_PARCEL_NBR,N'')
  	FROM 
    		B3PARCEL
 	WHERE
    		REC_STATUS = N'A' AND  
    		SERV_PROV_CODE  = @CLIENTID AND
    		B1_PER_ID1 = @PID1 AND
    		B1_PER_ID2 = @PID2 AND
    		B1_PER_ID3 = @PID3
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	WHILE @@FETCH_STATUS = 0
	BEGIN
	  SET @VSTR=LTRIM(RTRIM(@VSTR))
	if (@VSTR <> N'')
		if (ISNULL(@Result,N'') = N'')
			SET @Result = @VSTR
		else
		     if @Delimiter <> N''
			SET @Result = @Result + @Delimiter+ @VSTR
		     ELSE 
			SET @Result = @Result + CHAR(10) + @VSTR
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARENT_APP](@CLIENTID  NVARCHAR(15),
         					@PID1  NVARCHAR(5),
                                            	@PID2  NVARCHAR(5),
                                            	@PID3  NVARCHAR(5) ) 
                                            RETURNS NVARCHAR(200) as
/*  Author           :   Sandy Yin
    Create Date      :   02/08/2007
    Version          :   AA6.4 MS SQL
    Detail           :   RETURNS:   The application's parent application.  If it has more than one parent, the first will be selected.
                         ARGUMENTS: ClientID,
                                    PrimaryTrackingID1,
                                    PrimaryTrackingID2,
                                    PrimaryTrackingID3
    Revision History :   02/08/2007  Sandy Yin  Created by modifying Oracle version of function (07SSP-00068)
                         05/10/2007 Rainy Yu change CLIENTID VARCHAR(10) into VARCHAR(15)
*/
begin
DECLARE
@TEM NVARCHAR(200)
set @TEM=N'';
SELECT 
 TOP 1   @TEM=B.B1_ALT_ID   
FROM 
      B1PERMIT B,
      XAPP2REF X
WHERE 
    B.SERV_PROV_CODE = @CLIENTID AND       
    B.REC_STATUS = N'A' AND
    B.B1_PER_ID1 = X.B1_MASTER_ID1 AND
    B.B1_PER_ID2 = X.B1_MASTER_ID2 AND
    B.B1_PER_ID3 = X.B1_MASTER_ID3 AND
    B.SERV_PROV_CODE = X.SERV_PROV_CODE AND
    X.SERV_PROV_CODE = @CLIENTID    AND
    X.B1_PER_ID1 = @PID1  AND
    X.B1_PER_ID2 = @PID2  AND
    X.B1_PER_ID3 = @PID3  AND
    X.REC_STATUS = N'A'   AND 
    (B.B1_APPL_STATUS<>N'Void' OR B.B1_APPL_STATUS is null) 
    return(@TEM);
 END
GO


ALTER FUNCTION [dbo].[FN_GET_PAYMENT_APPLIED_TOTAL]
		    (@CLIENTID NVARCHAR(15),
		     @PID1     NVARCHAR(5),
                     @PID2     NVARCHAR(5),
                     @PID3     NVARCHAR(5),
                     @TYPE     NVARCHAR(2))RETURNS FLOAT AS   
/*  Author           :   Cece Wang
    Create Date      :   08/22/2005
    Version          :   AA6.0 MSSQL
    Detail           :   Returns: If {Applied} is 'Y' or '', returns total amount of applied payments; if {Applied} is 'N', returns total amount of non-applied payments.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, Applied ('Y' or 'N', optional)
    Revision History :	 08/22/2005, Cece Wang   	initial design.
                         09/28/2005  Lydia Lim		Correct code for "Applied" payments
*/
begin
DECLARE	
@apply FLOAT,
@napply FLOAT,
@VSTR FLOAT
SELECT TOP 1
        @apply=SUM (PAYMENT_AMOUNT) ,	
        @napply=SUM(AMOUNT_NOTALLOCATED)
FROM 	F4PAYMENT
WHERE	
	SERV_PROV_CODE = @CLIENTID
    AND	UPPER (REC_STATUS) = N'A'
    AND	B1_PER_ID1 = @PID1
    AND	B1_PER_ID2 = @PID2
    AND	B1_PER_ID3 = @PID3
    AND (PAYMENT_STATUS <> N'VOIDED'  OR PAYMENT_STATUS IS NULL);
if UPPER(@type)=N'N'
     SET @VSTR = (isnull(@napply,0))
else 
     SET @VSTR = (isnull(@apply,0) - isnull(@napply,0))
return(@VSTR)
END
GO


ALTER FUNCTION [dbo].[FN_GET_PAYMENT_LATEST] (@CLIENTID NVARCHAR(15),
					    @PID1 NVARCHAR(5),
				            @PID2 NVARCHAR(5),
			 		    @PID3 NVARCHAR(5),
					    @FIELD  NVARCHAR(20) 
					   )RETURNS NVARCHAR(100) AS
/*  Author         :   Lydia Lim
     Create Date   :   04/05/2006
     Version       :   AA6.1 MS SQL
     Detail        :   RETURNS: Info about last payment received. If {Field} is 'DATE', returns payment date in MM/DD/YYYY format; if {Field} is 'AMOUNT', returns payment amount; if {Field} is 'DOLLAR AMT DATE', returns payment amount in dollar format and date in MM/DD/YYYY format'.  Returns NULL if no payment has been made.
                       ARGUMENTS: ClientID, 
                                  PrimaryTrackingID1, 
                                  PrimaryTrackingID2, 
                                  PrimaryTrackingID3, 
                                  Field (options: 'DATE'(default),'AMOUNT','DOLLAR AMT DATE')
    Revision History : 04/05/2006  Lydia Lim  Initial Design
*/
BEGIN
declare @V_RET NVARCHAR(100) 
  BEGIN 
     SELECT TOP 1 
                    @V_RET = 
                     CASE UPPER(@FIELD)  
                     WHEN N'DATE'            THEN CONVERT(NVARCHAR,PAYMENT_DATE,101)  
                     WHEN N'AMOUNT'          THEN CAST(PAYMENT_AMOUNT AS NVARCHAR)
                     WHEN N'DOLLAR AMT DATE' THEN N'$'+CONVERT(NVARCHAR,CAST(PAYMENT_AMOUNT AS SMALLMONEY),1)+N' '+CONVERT(NVARCHAR,PAYMENT_DATE,101)                          
                     ELSE               CONVERT(NVARCHAR,PAYMENT_DATE,101)        
                     END
      FROM		
                    F4PAYMENT 
      WHERE 	
	                REC_STATUS = N'A'  
                    AND SERV_PROV_CODE = @CLIENTID  
                    AND B1_PER_ID1 = @PID1 
                    AND B1_PER_ID2=@PID2
                    AND B1_PER_ID3=@PID3  
                    AND PAYMENT_STATUS <> N'VOIDED'
      ORDER BY PAYMENT_DATE DESC
  END
  RETURN @V_RET 
END
GO


ALTER FUNCTION [dbo].[FN_GET_PRI_ADDRESS_FULL] (
	@CLIENTID NVARCHAR(15),
	@PID1 NVARCHAR(5),
	@PID2 NVARCHAR(5),
	@PID3 NVARCHAR(5)
	)  
RETURNS NVARCHAR(500) AS  
/*  Author           :   	Lucky Song
    Create Date      :   	12/29/2004
    Version          :  	AA6.0
    Detail           :   	RETURNS: Primary address. In Block Format
   ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History :
*/
BEGIN 
DECLARE  
		@VSTR NVARCHAR(200),
		@VSTR1 NVARCHAR(200),
		@VSTR2 NVARCHAR(200),
		@B1_HSE_NBR_START NVARCHAR(9),
	             @B1_HSE_NBR_END NVARCHAR(9),
		@B1_HSE_FRAC_NBR_START NVARCHAR(4),
		@B1_HSE_FRAC_NBR_END NVARCHAR(3),
		@B1_STR_DIR NVARCHAR(2),
		@B1_STR_NAME NVARCHAR(40),
		@B1_STR_SUFFIX NVARCHAR(6),
                @B1_STR_SUFFIX_DIR NVARCHAR(30),
		@B1_UNIT_TYPE NVARCHAR(6),
		@B1_UNIT_START NVARCHAR(10),
		@B1_UNIT_END NVARCHAR(10),
		@B1_SITUS_CITY NVARCHAR(40),
		@B1_SITUS_STATE NVARCHAR(2),
		@B1_SITUS_ZIP NVARCHAR(10)
	SET @VSTR = N'';
             SET @VSTR1=N'' ;
	SET @VSTR2=N'';
	SELECT 
		@B1_HSE_NBR_START=B1_HSE_NBR_START,    
		@B1_HSE_NBR_END=B1_HSE_NBR_END,
		@B1_HSE_FRAC_NBR_START=B1_HSE_FRAC_NBR_START,
		@B1_HSE_FRAC_NBR_END= B1_HSE_FRAC_NBR_END, 
		@B1_STR_DIR = B1_STR_DIR,    
		@B1_STR_NAME =B1_STR_NAME ,
		@B1_STR_SUFFIX=B1_STR_SUFFIX,
                @B1_STR_SUFFIX_DIR=B1_STR_SUFFIX_DIR,
		@B1_UNIT_TYPE = B1_UNIT_TYPE, 
		@B1_UNIT_START = B1_UNIT_START,  
		@B1_UNIT_END=B1_UNIT_END,
		@B1_SITUS_CITY=B1_SITUS_CITY, 
		@B1_SITUS_STATE=B1_SITUS_STATE, 
		@B1_SITUS_ZIP= B1_SITUS_ZIP
	FROM   
		B3ADDRES
	WHERE 
		REC_STATUS = N'A'
		AND UPPER(B1_ADDR_SOURCE_FLG)=N'ADR'
		AND SERV_PROV_CODE  =@CLIENTID
		AND B1_PER_ID1 = @PID1
		AND B1_PER_ID2 = @PID2
		AND B1_PER_ID3 = @PID3
		AND B1_PRIMARY_ADDR_FLG=N'Y' 
  IF @B1_HSE_NBR_START!=N''  SET @VSTR=@B1_HSE_NBR_START;
  IF @B1_HSE_FRAC_NBR_START!=N''  SET @VSTR=@VSTR+N' '+@B1_HSE_FRAC_NBR_START;
  IF (@B1_HSE_NBR_START!=N'' OR @B1_HSE_FRAC_NBR_START!=N'')	AND 
  	 (@B1_HSE_NBR_END!=N'' OR @B1_HSE_FRAC_NBR_END!=N'') 
	  SET @VSTR=@VSTR+N' -';  
  IF @B1_HSE_NBR_END!=N'' SET @VSTR=@VSTR+N' '+@B1_HSE_NBR_END;
  IF @B1_HSE_FRAC_NBR_END!=N'' SET @VSTR=@VSTR+N' '+@B1_HSE_FRAC_NBR_END;
  IF @B1_STR_DIR!=N'' SET @VSTR=@VSTR+N' '+@B1_STR_DIR;
  IF @B1_STR_NAME!=N'' SET @VSTR=@VSTR+N' '+@B1_STR_NAME;
  IF @B1_STR_SUFFIX!=N''  SET @VSTR=@VSTR+N' '+@B1_STR_SUFFIX;
  IF @B1_STR_SUFFIX_DIR!=N''  SET @VSTR=@VSTR+N' '+@B1_STR_SUFFIX_DIR;
  IF @B1_UNIT_TYPE!=N''  
  BEGIN 
	  IF @VSTR!=N''  
		  SET @VSTR=@VSTR+N', '+@B1_UNIT_TYPE+N'#';
	  ELSE 
		  SET @VSTR=@B1_UNIT_TYPE+N'#';
    END 
  IF @B1_UNIT_START!=N'' SET @VSTR=@VSTR+N' '+@B1_UNIT_START;
  IF @B1_UNIT_START!=N''  AND @B1_UNIT_END!=N''  
     SET  @VSTR=@VSTR+N' -';
  IF @B1_UNIT_END!=N''  
	  SET @VSTR=@VSTR+N' '+@B1_UNIT_END;  
  IF @B1_SITUS_CITY != N'' 
		 SET @VSTR1=@B1_SITUS_CITY;	 
  IF @B1_SITUS_STATE!=N''
  BEGIN 
	  IF @VSTR1 !=N'' 
		SET	@VSTR1=@VSTR1+N', '+@B1_SITUS_STATE;
    	  ELSE 
		SET @VSTR1=@B1_SITUS_STATE;
  END;
  IF @B1_SITUS_ZIP!=N'' 
	  SET @VSTR1=@VSTR1+N' '+@B1_SITUS_ZIP;
  IF LTRIM( RTRIM(@VSTR))!=N'' 
	BEGIN 
 		if LTRIM(RTRIM( @VSTR1))!=N''
 			SET @VSTR2=@VSTR+CHAR(10)+@VSTR1 ;
 		else
 			SET @VSTR2=@VSTR;
	END 
  ELSE
            SET @VSTR2 =@VSTR1;
	RETURN @VSTR2
END
GO


ALTER FUNCTION [dbo].[FN_GET_PRI_ADDRESS_PARTIAL](
	   	  		      @CLIENTID  NVARCHAR(15),
	   	  		      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5)) returns  NVARCHAR(1000) AS
/*  Author           :   Sandy Yin
    Create Date      :   02/09/2007
    Version          :   AA6.3 MS SQL
    Detail           :   RETURNS: Primary address without city, state and zip, or first address found if no primary address exists; Null if no addresses are found.
			 ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3.
    Revision History :   02/09/2007  Sandy Yin  Create function by modifying Oracle version of function (07SSP-00068)
                         05/10/2007  Rainy Yu   Change returns varchar into 1000 and change CLIENTID into 15.
                         06/13/2007  Lydia Lim  Edit comments.
                         12/18/2007  Lydia Lim  Add handling of null values, not just '' values
*/
BEGIN
DECLARE @VSTR NVARCHAR(1000)
  SET  @VSTR=N''
  SELECT 
       top 1 @VSTR = RTRIM(CAST(B1_HSE_NBR_START AS CHAR)) +
         case when ISNULL(B1_HSE_FRAC_NBR_START,N'')=N'' then N'' else  N' '+B1_HSE_FRAC_NBR_START end +
         case when ISNULL(B1_STR_DIR,N'')=N''then  N'' else N' '+B1_STR_DIR end +
         N' '+ISNULL(B1_STR_NAME,N'') +
         case when ISNULL(B1_STR_SUFFIX,N'')=N'' then  N'' else  N' '+B1_STR_SUFFIX end  +
         case when ISNULL(B1_STR_SUFFIX_DIR, N'') = N'' then N'' else N' ' + B1_STR_SUFFIX_DIR end +
         case when ISNULL(B1_UNIT_TYPE,N'')=N'' then  N'' else  N', '+B1_UNIT_TYPE  end +
         case when ISNULL(B1_UNIT_START,N'')=N'' then  N'' else  N' '+B1_UNIT_START end 
  	FROM B3ADDRES 
       WHERE REC_STATUS = N'A'
         AND B1_ADDR_SOURCE_FLG = N'Adr'
         AND SERV_PROV_CODE = @CLIENTID
         AND B1_PER_ID1 = @PID1
         AND B1_PER_ID2 = @PID2
         AND B1_PER_ID3 = @PID3
    ORDER BY B1_PRIMARY_ADDR_FLG desc 
   RETURN(@VSTR);
END
GO


ALTER FUNCTION [dbo].[FN_GET_PRI_OWNER_FULL] ( @servcode NVARCHAR(50), @id1 NVARCHAR(50), @id2 NVARCHAR(50), @id3 NVARCHAR(50))
RETURNS NVARCHAR(500) 
AS
/*  Author         :   Lucky Song
     Create Date   :   12/30/2004
     Version       :   AA6.0
     Detail        :   RETURNS:Get primary owner informaton:name+address1+city+state+zip. In block format.   
   ARGUMENTS       : ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History :
*/
BEGIN
         DECLARE  @Result NVARCHAR(300);
        SELECT TOP 1 @Result=
 	   case B1_OWNER_FULL_NAME when N'' then N'' else B1_OWNER_FULL_NAME end +
	   case B1_MAIL_ADDRESS1 when N'' then N'' else case B1_OWNER_FULL_NAME when N'' then B1_MAIL_ADDRESS1 else char(10)+B1_MAIL_ADDRESS1 end end+
	   case B1_MAIL_CITY+B1_MAIL_STATE+B1_MAIL_ZIP when N'' then N'' else
	   case B1_OWNER_FULL_NAME+B1_MAIL_ADDRESS1 when N'' then 
	   case B1_MAIL_CITY when N'' then N'' else case B1_MAIL_STATE+B1_MAIL_ZIP when N'' then B1_MAIL_CITY else B1_MAIL_CITY+N',' end end + case B1_MAIL_STATE when N'' then N'' else B1_MAIL_STATE+N' ' end +B1_MAIL_ZIP else 
	   char(10)+case B1_MAIL_CITY when N'' then N'' else case B1_MAIL_STATE+B1_MAIL_ZIP when N'' then B1_MAIL_CITY else B1_MAIL_CITY+N', ' end end + case B1_MAIL_STATE when N'' then N'' else B1_MAIL_STATE+N' ' end+B1_MAIL_ZIP end end 
         FROM	
	  B3OWNERS 
         WHERE	
	    serv_prov_code =@servcode 
                 AND B1_PER_ID1=@id1
                 AND B1_PER_ID2=@id2
                 AND B1_PER_ID3=@id3
                 AND REC_STATUS=N'A' 
 	    AND B1_PRIMARY_OWNER = N'Y';
Return (ISNULL(@Result,N'')) ;
END
GO


ALTER FUNCTION [dbo].[FN_GET_PRIMARYADDRESS] (
					@CLIENTID NVARCHAR(15),
					@PID1 NVARCHAR(5),
					@PID2 NVARCHAR(5),
					@PID3 NVARCHAR(5)
					)  
RETURNS NVARCHAR(200) AS  
/*  Author           :   	Arthur Miao
    Create Date      :   	12/29/2004
    Version          :  	AA6.0 MSSQL
    Detail           :   	RETURNS: Primary address 
                        	ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3
  Revision History :
*/
BEGIN 
DECLARE @VSTR NVARCHAR(200),
		@B1_HSE_NBR_START NVARCHAR(4),
	             @B1_HSE_NBR_END NVARCHAR(4),
		@B1_HSE_FRAC_NBR_START NVARCHAR(4),
		@B1_HSE_FRAC_NBR_END NVARCHAR(3),
		@B1_STR_DIR NVARCHAR(2),
		@B1_STR_NAME NVARCHAR(40),
		@B1_STR_SUFFIX NVARCHAR(6),
		@B1_UNIT_TYPE NVARCHAR(6),
		@B1_UNIT_START NVARCHAR(10),
		@B1_UNIT_END NVARCHAR(10),
		@B1_SITUS_CITY NVARCHAR(40),
		@B1_SITUS_STATE NVARCHAR(2),
		@B1_SITUS_ZIP NVARCHAR(10)
	SET @VSTR = N''
	SELECT 
		@B1_HSE_NBR_START=B1_HSE_NBR_START,    
		@B1_HSE_NBR_END=B1_HSE_NBR_END,
		@B1_HSE_FRAC_NBR_START=B1_HSE_FRAC_NBR_START,
		@B1_HSE_FRAC_NBR_END= B1_HSE_FRAC_NBR_END, 
		@B1_STR_DIR = B1_STR_DIR,    
		@B1_STR_NAME =B1_STR_NAME ,
		@B1_STR_SUFFIX=B1_STR_SUFFIX,
		@B1_UNIT_TYPE = B1_UNIT_TYPE, 
		@B1_UNIT_START = B1_UNIT_START,  
		@B1_UNIT_END=B1_UNIT_END,
		@B1_SITUS_CITY=B1_SITUS_CITY, 
		@B1_SITUS_STATE=B1_SITUS_STATE, 
		@B1_SITUS_ZIP= B1_SITUS_ZIP
	FROM   
		B3ADDRES
	WHERE 
		REC_STATUS = N'A'
		AND UPPER(B1_ADDR_SOURCE_FLG)=N'ADR'
		AND SERV_PROV_CODE  =@CLIENTID
		AND B1_PER_ID1 = @PID1
		AND B1_PER_ID2 = @PID2
		AND B1_PER_ID3 = @PID3
		AND B1_PRIMARY_ADDR_FLG=N'Y' 
	IF @B1_HSE_NBR_START IS NOT NULL  SET @VSTR = @B1_HSE_NBR_START 
	IF @B1_HSE_FRAC_NBR_START IS NOT NULL SET @VSTR=@VSTR+N' '+@B1_HSE_FRAC_NBR_START;
	IF (@B1_HSE_NBR_START IS NOT NULL OR @B1_HSE_FRAC_NBR_START IS NOT NULL) AND
   	 (@B1_HSE_NBR_END IS NOT NULL OR @B1_HSE_FRAC_NBR_END IS NOT NULL) SET @VSTR=@VSTR+N' -';
	IF @B1_HSE_NBR_END IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_HSE_NBR_END
	IF @B1_HSE_FRAC_NBR_END IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_HSE_FRAC_NBR_END
	IF @B1_STR_DIR IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_STR_DIR
	IF @B1_STR_NAME IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_STR_NAME
	IF @B1_STR_SUFFIX IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_STR_SUFFIX
	IF @B1_UNIT_TYPE IS NOT NULL 
	BEGIN
		IF @VSTR IS NOT NULL SET @VSTR=@VSTR +N', '+@B1_UNIT_TYPE+N'#'
		ELSE SET @VSTR=@B1_UNIT_TYPE+N'#'
	END
	IF @B1_UNIT_START IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_UNIT_START
	IF @B1_UNIT_START IS NOT NULL AND  @B1_UNIT_END IS NOT NULL SET @VSTR=@VSTR +N' -'
	IF @B1_UNIT_END IS NOT NULL SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
	IF @B1_SITUS_CITY IS NOT NULL 
	BEGIN
		IF @VSTR IS NOT NULL SET @VSTR = @VSTR + N', '+@B1_SITUS_CITY
		ELSE	SET @VSTR = @B1_SITUS_CITY
	END
	IF @B1_SITUS_STATE IS NOT NULL 
	BEGIN
		IF @VSTR IS NOT NULL SET @VSTR = @VSTR + N', '+@B1_SITUS_STATE
		ELSE	SET @VSTR = @B1_SITUS_STATE
	END
	IF @B1_SITUS_ZIP IS NOT NULL SET  @VSTR=@VSTR +N' '+ @B1_SITUS_ZIP
	RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_PUBLICUSER_INFO]
	(@CLIENTID NVARCHAR(15),
	 @USERID NVARCHAR(100), 
	 @USERSEQNUM NVARCHAR(20), 
	 @GET_FIELD NVARCHAR(100) 	 
	 )
RETURNS NVARCHAR(4000) AS
/*  Author           :   Lucky Song
    Create Date   :   06/07/2007
    Version         :   AA6.3.1 MS SQL
    Detail           :   RETURNS:  Information about the public user whose user ID is {UserId} or whose user sequence number is {UserSeqNum}.  The Get_Field argument determines what information is returned.
                           ARGUMENTS: ClientID, 
                                                 UserId (Required if UserSeqNum argument is not used),
                                                 UserSeqNum (Required if UserId argument is not used), 
                                                 Get_Field (Options: 'USER_SEQ_NBR', 'NAME', 'DISPLAY NAME', 'EMAIL', 'ADDRESS', 'WORK PHONE') 
  Revision History :	 06/07/2007 Lucky Song Initial Design, convert from Oracle Version                          
*/
BEGIN 
DECLARE 
@V_TEMP      NVARCHAR(4000),  
@DISPLAY_NAME   NVARCHAR(100), 
@USER_SEQ_NBR NVARCHAR(20),  
@EMAIL_ID NVARCHAR(100), 
@ADDRESS1 NVARCHAR(100), 
@CITY NVARCHAR(30), 
@STATE NVARCHAR(2), 
@ZIP NVARCHAR(10), 
@PHONE_WORK NVARCHAR(25), 
@FNAME NVARCHAR(30), 
@LNAME NVARCHAR(60),
@TPHONE NVARCHAR(50); 
BEGIN
   SET @V_TEMP = N'';
   SELECT  TOP 1 			
                @DISPLAY_NAME = isnull(PU.DISPLAY_NAME,NULL),    
                @USER_SEQ_NBR = isnull(PU.USER_SEQ_NBR,NULL),
                @EMAIL_ID = isnull(PU.EMAIL_ID,N''),
                @ADDRESS1 = isnull(PU.ADDRESS1,N'') ,
                @CITY = isnull(PU.CITY,N'') ,   
                @STATE = isnull(PU.STATE ,N''),
                @ZIP = isnull(PU.ZIP,N''),
                @PHONE_WORK = isnull(PU.PHONE_WORK,N''), 
                @FNAME = isnull(PU.FNAME,N''),  
                @LNAME = isnull(PU.LNAME,N'')                              
        FROM   
                PUBLICUSER PU, 
                XPUBLICUSER_SERVPROV XU 
        WHERE             
                PU.USER_SEQ_NBR = XU.USER_SEQ_NBR 
                AND XU.SERV_PROV_CODE = @CLIENTID  
                AND XU.REC_STATUS = N'A' 
	            AND (@USERSEQNUM <>N'' AND PU.USER_SEQ_NBR =@USERSEQNUM
                     OR
                     @USERSEQNUM=N'') 
                AND (@USERID <>N'' AND PU.USER_ID = @USERID
                     OR
                     @USERID =N'') 
		        AND PU.REC_STATUS = N'A'    	  
END
IF UPPER(@Get_Field) = N'DISPLAY NAME'
   SET @V_TEMP = @DISPLAY_NAME;    
IF UPPER(@Get_Field) = N'USER_SEQ_NBR'
  SET @V_TEMP = @USER_SEQ_NBR; 
IF UPPER(@Get_Field) = N'EMAIL'
  SET @V_TEMP = @EMAIL_ID;   
IF UPPER(@Get_Field) = N'ADDRESS'
  BEGIN  
          IF @ADDRESS1 <> N''
                SET @V_TEMP = @ADDRESS1;          
          IF @CITY+@STATE+@ZIP <> N'' 
              BEGIN 
                 IF @V_TEMP<>N'' 
                    SET @V_TEMP = @V_TEMP+N', '+LTRIM(RTRIM(RTRIM(@CITY+N', '+@STATE)+N' '+@ZIP))  
                 ELSE 
                    SET @V_TEMP = LTRIM(RTRIM(RTRIM(@CITY+N', '+@STATE)+N' '+@ZIP));             
              END
  END 
IF  UPPER(@Get_Field)=N'WORK PHONE'  
BEGIN    
         SET @TPHONE = REPLACE(REPLACE(@PHONE_WORK,N'(',N''), N')', N'');            
         IF LEN(@TPHONE) = 10            
           SET @V_TEMP = N'('+SUBSTRING(@TPHONE,1,3)+N')'+SUBSTRING(@TPHONE,4,3)+N'-'+SUBSTRING(@TPHONE,7,LEN(@TPHONE)); 
         ELSE          
           SET @V_TEMP = @PHONE_WORK;  		      		      		            
END    
IF( @Get_Field = N'NAME'  or @Get_Field = N'' ) 
    SET @V_TEMP =@FNAME+N' '+@LNAME;   
  RETURN( @V_TEMP)
END
GO


ALTER FUNCTION [dbo].[FN_GET_RECEIPT_NUM_FIRST_LAST] (@CLIENT NVARCHAR(50),
					            @PID1 NVARCHAR(50),
					            @PID2 NVARCHAR(50),
					            @PID3 NVARCHAR(50),
					            @FIRST_LAST NVARCHAR(10)
					            )RETURNS FLOAT
/*  Author           :   Roy Zhou
    Create Date      :   3/21/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: The first receipt number on the application if {First_Last} is 'FIRST', or the last receipt number if {First_Last} is 'LAST'.  Ignores voided payments.
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, First_Last('FIRST','LAST'(default))
    Revision History :   3/21/2005  Roy Zhou    Initial
*/
BEGIN
	DECLARE @MAX_RESULT FLOAT,
                @MIN_RESULT FLOAT,
                @RESULT FLOAT;
	SELECT 
		 @MAX_RESULT=MAX(F.RECEIPT_NBR),@MIN_RESULT=MIN(F.RECEIPT_NBR)
	FROM 
		F4PAYMENT F
	WHERE 
		F.SERV_PROV_CODE = @CLIENT	AND 
		F.B1_PER_ID1 = @PID1 	        AND 
		F.B1_PER_ID2 = @PID2 		AND 
		F.B1_PER_ID3 = @PID3 		AND 
                F.PAYMENT_STATUS <> N'VOIDED'    AND
		F.REC_STATUS=N'A';
       IF UPPER(@FIRST_LAST)=N'FIRST' 
    	 SET @RESULT = @MIN_RESULT
       ELSE
         SET @RESULT = @MAX_RESULT
    RETURN @RESULT;
END
GO


ALTER FUNCTION [dbo].[FN_GET_RECEIPT_NUMBER] (@CLIENT NVARCHAR(50),
					    @PID1 NVARCHAR(50),
					    @PID2 NVARCHAR(50),
					    @PID3 NVARCHAR(50)					   
					    )RETURNS FLOAT
/*  Author           :   LARRY COOPER
    Create Date      :   1/13/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: The first receipt number on the application.
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3.
    Revision History :   01/13/2005  Larry Cooper    Initial
			 09/22/2005  Lydia Lim       Get first receipt number
*/
BEGIN
	DECLARE @RESULT FLOAT;
	SELECT 
		TOP 1 @RESULT=F.RECEIPT_NBR
	FROM 
		F4PAYMENT F
	WHERE 
		F.SERV_PROV_CODE = @CLIENT	AND 
		F.B1_PER_ID1 = @PID1 	        AND 
		F.B1_PER_ID2 = @PID2 		AND 
		F.B1_PER_ID3 = @PID3 		AND 
		F.REC_STATUS=N'A';
	RETURN @RESULT;
END
GO


ALTER FUNCTION [dbo].[FN_GET_RECEIPT_NUMBER_ALL] (@CLIENT NVARCHAR(50),
					        @PID1 NVARCHAR(50),
					        @PID2 NVARCHAR(50),
				     	        @PID3 NVARCHAR(50),
					        @Separator NVARCHAR(10)					   
					       )RETURNS NVARCHAR(3000)
/*  Author           :   David Zheng
    Create Date      :   04/05/2006
    Version          :   AA6.1.3 MS SQL
    Detail           :   RETURNS: All receipt numbers for the application, separated by {Separator}.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    Separator (eg.', ' 'CHR(10)')
    Revision History :   04/05/2006  David Zheng    Initial Design
*/
BEGIN 
DECLARE
	@VSTR	              NVARCHAR(3000),
	@Result	  	      NVARCHAR(3000);
	set  @VSTR=N'';
	DECLARE CURSOR_1 CURSOR FOR
    	SELECT 
		DISTINCT ISNULL(CAST(F.RECEIPT_NBR AS NVARCHAR),N'')
	FROM 
		F4PAYMENT F
	WHERE 
		F.SERV_PROV_CODE = @CLIENT	AND 
		F.B1_PER_ID1 = @PID1 	        AND 
		F.B1_PER_ID2 = @PID2 		AND 
		F.B1_PER_ID3 = @PID3 		AND 
		F.REC_STATUS=N'A';
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @VSTR=LTRIM(RTRIM(@VSTR))
			if (@VSTR <> N'')
			if (ISNULL(@Result,N'') = N'')
				SET @Result = @VSTR
			else
				SET @Result = @Result + @Separator + @VSTR
			FETCH NEXT FROM CURSOR_1 INTO @VSTR
		END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
RETURN  @Result;
END
GO


ALTER FUNCTION [dbo].[FN_GET_RENEWAL_INFO](
						@CLIENTID NVARCHAR(15),         
						@PID1 NVARCHAR(5),
						@PID2 NVARCHAR(5),
						@PID3 NVARCHAR(5),
						@Get_Field NVARCHAR(20),
					 	@Date_Fmt NVARCHAR(15)
						) returns NVARCHAR(30) AS
/*
	Author		: David Zheng
	create date	: 08/18/2006
	version		: AA6.2 MS SQL
	detail		: RETURNs: Renewal info specified by {Get_Field}. If {Get_Field} is 'EXP STATUS', returns Expiration Status; if {Get_Field} is 'EXP DATE', return the expiration date in the format specified by {Date_Fmt}.
			  ARGUMENTS: ClientID, 
                                     PrimaryTrackingID1, 
                                     PrimaryTrackingID2, 
                                     PrimaryTrackingID3, 
                                     Get_Field ('EXP STATUS','EXP DATE')
                                     Date_Fmt ('MM/DD/YYYY'(default),'DD','MONTH','YYYY','DD MON YYYY')
	Revision History: 08/18/2006 David Zheng Initial Design for 06SSP-00142
*/     
BEGIN
  DECLARE @expDate DATETIME;
  DECLARE @expStatus NVARCHAR(30);
  DECLARE @Result NVARCHAR(30);	
  SELECT TOP 1
	@expDate = EXPIRATION_DATE,
	@expStatus = EXPIRATION_STATUS
  FROM 
	B1_EXPIRATION 
  WHERE  
	SERV_PROV_CODE = @CLIENTID AND    
	B1_PER_ID1 = @PID1 AND    
	B1_PER_ID2 = @PID2 AND    
	B1_PER_ID3 = @PID3 AND	
	REC_STATUS = N'A';
  IF UPPER(@Get_Field) = N'EXP STATUS'
  	set @RESULT = @expStatus
  ELSE IF UPPER(@Get_Field) = N'EXP DATE'
	  BEGIN
		  IF UPPER(@Date_Fmt) = N'YYYY' 
		  --Get Year
		  	set @RESULT = substring(rtrim(ltrim(convert(NVARCHAR(12),@expDate,13))),8,4)
		  ELSE IF UPPER(@Date_Fmt) = N'MONTH' 
		  --Get Month
			set @RESULT = CASE substring(rtrim(ltrim(convert(NVARCHAR(12),@expDate,13))),4,3)
				      when N'JAN' then N'JANUARY'
		                      when N'FEB' then N'FEBRUARY'
				      when N'MAR' then N'MARCH'
				      when N'APR' then N'APRIL'
				      when N'MAY' then N'MAY'
				      when N'JUN' then N'JUNE'
				      when N'JUL' then N'JULY'	
				      when N'AUG' then N'AUGUST'
				      when N'SEP' then N'SEPTEMBER'
				      when N'OCT' then N'OCTOBER'
				      when N'NOV' then N'NOVEMBER'
				      when N'DEC' then N'DECEMBER' 
				      end
		  ELSE IF UPPER(@Date_Fmt) = N'DD' 
		  --Get Day
			set @RESULT = substring(rtrim(ltrim(convert(NVARCHAR(12),@expDate,13))),1,2)
		  ELSE IF UPPER(@Date_Fmt) = N'DD MON YYYY' 
		  --Get full date in {dd mon yyyy}
			set @RESULT = convert(NVARCHAR(12),@expDate,13)
                  ELSE
                        set @RESULT = convert(NVARCHAR(12),@expDate,101)
	  END
  RETURN @RESULT 
END
GO


ALTER FUNCTION [dbo].[FN_GET_STAFF_DEPT] (@ClientID     NVARCHAR(15),
 				        @FirstName    NVARCHAR(50),
 				        @MiddleName   NVARCHAR(50),
 				        @LastName     NVARCHAR(50)
                                        ) RETURNS NVARCHAR (400) AS
/*  Author           :   Ava Wu
    Create Date      :   10/11/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Department department of staff whose full name is {FirstName} {MiddleName} {LastName}.
                         ARGUMENTS: ClientID, FirstName, MiddleName, LastName.
    Revision History :   10/11/2005  Ava Wu Initial Design
*/
BEGIN
	DECLARE
           @DEPT NVARCHAR(400),
           @AGENCY NVARCHAR(50),
           @BUREAU NVARCHAR(50),
           @DIVISION NVARCHAR(50),
           @SECTION NVARCHAR(50),
           @GROUP NVARCHAR(50),
           @OFFICE NVARCHAR(50),
           @VSTR NVARCHAR(400)				    
	BEGIN
               SELECT 
			@DEPT = D.R3_DEPTNAME,
			@AGENCY = S.GA_AGENCY_CODE,
			@BUREAU = S.GA_BUREAU_CODE,
			@DIVISION = S.GA_DIVISION_CODE,
			@SECTION = S.GA_SECTION_CODE,
			@GROUP = S.GA_GROUP_CODE,
			@OFFICE = S.GA_OFFICE_CODE
		FROM 
			  G3DPTTYP D, G3STAFFS S
		WHERE 
			ISNULL(S.GA_FNAME,N'') = ISNULL(@FirstName,N'') AND
			ISNULL(S.GA_LNAME,N'') = ISNULL(@LastName,N'') AND
			ISNULL(S.GA_MNAME,N'') = ISNULL(@MiddleName,N'') AND
			S.SERV_PROV_CODE = @ClientID AND
			D.SERV_PROV_CODE = S.SERV_PROV_CODE AND
			D.R3_AGENCY_CODE = S.GA_AGENCY_CODE AND
			D.R3_BUREAU_CODE = S.GA_BUREAU_CODE AND
			D.R3_DIVISION_CODE = S.GA_DIVISION_CODE AND
			D.R3_SECTION_CODE = S.GA_SECTION_CODE AND 
			D.R3_GROUP_CODE = S.GA_GROUP_CODE AND 
			D.R3_OFFICE_CODE = S.GA_OFFICE_CODE
	END
	IF @AGENCY IS NULL 
		BEGIN
			SELECT 
				@AGENCY = S.GA_AGENCY_CODE,
				@BUREAU = S.GA_BUREAU_CODE,
				@DIVISION = S.GA_DIVISION_CODE,
				@SECTION = S.GA_SECTION_CODE,
				@GROUP = S.GA_GROUP_CODE,
				@OFFICE = S.GA_OFFICE_CODE
			FROM 
				  G3STAFFS S
			WHERE 
				ISNULL(S.GA_FNAME,N'') = ISNULL(@FirstName,N'') AND
				ISNULL(S.GA_LNAME,N'') = ISNULL(@LastName,N'') AND
				ISNULL(S.GA_MNAME,N'') = ISNULL(@MiddleName,N'') AND
				S.SERV_PROV_CODE = @ClientID 
		END
	  IF ISNULL(@DEPT,N'') = N''
		SET @VSTR = UPPER(@ClientID +N'/'+ @AGENCY +N'/'+ @BUREAU +N'/'+ @DIVISION +N'/'+ @SECTION +N'/'+ @GROUP +N'/'+ @OFFICE )
	  ELSE
		SET @VSTR = UPPER(@DEPT)
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_STAFF_FULLNAME]( @CLIENTID NVARCHAR(15),
                                      @Puserid  NVARCHAR(50),
                                      @NameFormat NVARCHAR(5),
                                      @PCASE NVARCHAR(10)
                                      ) returns NVARCHAR(60) as
/*  Author           :   Sandy Yin
    Create Date      :   07/27/2006
    Version          :   AA6.2.0 MS SQL
    Detail           :   RETURNS: Full name of user whose user ID is {UserName}, in the format specified by {NameFormat}, in the case specified by {Case}.
			 ARGUMENTS: ClientID,
                                    UserName,
                                    NameFormat ('FML' for First Middle Last (default) 'LFM' for Last, First Middle 'FMIL' for First Middle Initial Last),
                                    PCase ('U' for uppercase, 'I' for initial capitalization, '' for original case) 
    Revision History : 	Sandy Yin Initial Design
                                 12/06/2006 Sandy revised user_id as user_name. (06SSP-00140.B61205)
                                 05/14/2007 Lucky Song Correct parameter character lengths   
*/
BEGIN
declare 
	@VSTR NVARCHAR(60),
	@C_fname NVARCHAR(15),
	@C_mname NVARCHAR(15),
	@C_lname NVARCHAR(25)
  	SELECT TOP 1
  		@C_fname=GA_FNAME,  
	      	@C_lname=GA_LNAME, 
	      	@C_mname=GA_MNAME
  	FROM
  		G3STAFFS
  	WHERE
  		SERV_PROV_CODE =@CLIENTID AND
  	   USER_NAME=UPPER( @Puserid)
BEGIN
IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END         
            IF UPPER(@PCase) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@PCase) = N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
      END
   ELSE  IF UPPER(@NameFormat)=N'FMIL'
       BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + SUBSTRING(@C_mname,1,1)
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
     IF UPPER(@PCase) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@PCase) = N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR       
   END
    ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@PCase) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@PCase) = N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
          IF UPPER(@PCase) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@PCase) = N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
         END           
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
           IF UPPER(@PCase) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@PCase) = N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END 
            IF UPPER(@PCase) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@PCase) = N'I' 
                  SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
         END   
 END 
 RETURN (@VSTR)
END
GO


ALTER FUNCTION [dbo].[FN_GET_STAFF_INFO] (@ClientID     NVARCHAR(15),
                                        @FirstName    NVARCHAR(50),
                                        @MiddleName   NVARCHAR(50),
                                        @LastName     NVARCHAR(50),
                                        @GetField     NVARCHAR(100)
                                        ) RETURNS NVARCHAR (400) AS
/*  Author           :   Angel Feng
    Create Date      :   12/28/2006
    Version          :   AA6.2 MSSQL
    Detail           :   RETURNS: Department of staff whose full name is {FirstName} {MiddleName} {LastName}. Returns field value as specified by {GetField}, If {GetField} is null return to EMPLOYEE ID.
                         ARGUMENTS: ClientID, 
                                    FirstName, 
                                    MiddleName (optional), 
                                    LastName.
                                    GetField (OPTIONS: 'USERNAME' or 'USER ID','FNAME','MNAME','LNAME','TITLE','EMPLOYEE ID', 'CASHIER ID', 'FULL NAME')
    Revision History :   12/28/2006  Angel Feng Convert from Oracle version and update for some new fields (e.g. Title) for 06SSP-00269 field L
                         02/09/2007  Lydia Lim  Update code for 'EMPLOYEE ID' and add 'CASHIER ID' Get_Field option; make parameters case insensitive
*/
BEGIN
        DECLARE
           @DEPT NVARCHAR(400),
           @AGENCY NVARCHAR(50),
           @BUREAU NVARCHAR(50),
           @DIVISION NVARCHAR(50),
           @SECTION NVARCHAR(50),
           @GROUP NVARCHAR(50),
           @OFFICE NVARCHAR(50),
           @V_TITLE NVARCHAR(50),
           @USERID NVARCHAR(50),
           @USERNAME NVARCHAR(50),
           @V_FNAME  NVARCHAR(100),
           @V_MNAME  NVARCHAR(100),
           @V_LNAME  NVARCHAR(100),
           @EMPLOYEEID NVARCHAR(50),
           @CASHIERID NVARCHAR(10),
           @VSTR NVARCHAR(400)     
        BEGIN
               SELECT   TOP 1
                        @DEPT = D.R3_DEPTNAME,
                        @AGENCY = S.GA_AGENCY_CODE,
                        @BUREAU = S.GA_BUREAU_CODE,
                        @DIVISION = S.GA_DIVISION_CODE,
                        @SECTION = S.GA_SECTION_CODE,
                        @GROUP = S.GA_GROUP_CODE,
                        @OFFICE = S.GA_OFFICE_CODE,
                        @USERID = S.GA_USER_ID,
                        @USERNAME = S.USER_NAME,
                        @V_FNAME = S.GA_FNAME,
                        @V_MNAME = S.GA_MNAME,
                        @V_LNAME = S.GA_LNAME,
                        @V_TITLE = S.GA_TITLE
                FROM 
                        G3DPTTYP D, G3STAFFS S
                WHERE 
                        UPPER(ISNULL(S.GA_FNAME,N'')) = UPPER(ISNULL(@FirstName,N'')) AND
                        UPPER(ISNULL(S.GA_LNAME,N'')) = UPPER(ISNULL(@LastName,N'')) AND
                        UPPER(ISNULL(S.GA_MNAME,N'')) = UPPER(ISNULL(@MiddleName,N'')) AND
                        S.SERV_PROV_CODE = @ClientID AND
                        D.SERV_PROV_CODE = S.SERV_PROV_CODE AND
                        D.R3_AGENCY_CODE = S.GA_AGENCY_CODE AND
                        D.R3_BUREAU_CODE = S.GA_BUREAU_CODE AND
                        D.R3_DIVISION_CODE = S.GA_DIVISION_CODE AND
                        D.R3_SECTION_CODE = S.GA_SECTION_CODE AND 
                        D.R3_GROUP_CODE = S.GA_GROUP_CODE AND 
                        D.R3_OFFICE_CODE = S.GA_OFFICE_CODE
        END
        IF @AGENCY IS NULL 
                BEGIN   
                        SELECT  TOP 1
                                @AGENCY = S.GA_AGENCY_CODE,
                                @BUREAU = S.GA_BUREAU_CODE,
                                @DIVISION = S.GA_DIVISION_CODE,
                                @SECTION = S.GA_SECTION_CODE,
                                @GROUP = S.GA_GROUP_CODE,
                                @OFFICE = S.GA_OFFICE_CODE,
                                @USERID = S.GA_USER_ID,
                                @USERNAME = S.USER_NAME,
                                @V_FNAME = S.GA_FNAME,
                                @V_MNAME = S.GA_MNAME,
                                @V_LNAME = S.GA_LNAME,
                                @V_TITLE = S.GA_TITLE
                        FROM 
                                G3STAFFS S
                        WHERE 
                                UPPER(ISNULL(S.GA_FNAME,N'')) = UPPER(ISNULL(@FirstName,N'')) AND
                        	UPPER(ISNULL(S.GA_LNAME,N'')) = UPPER(ISNULL(@LastName,N'')) AND
                        	UPPER(ISNULL(S.GA_MNAME,N'')) = UPPER(ISNULL(@MiddleName,N'')) AND
                                S.SERV_PROV_CODE = @ClientID 
                END
        IF UPPER(@GetField) IN (N'EMPLOYEE ID',N'CASHIER ID')
		BEGIN
			SELECT TOP 1
				@EMPLOYEEID = P.EMPLOYEE_ID,
				@CASHIERID = P.CASHIER_ID
			FROM
				PUSER P
			WHERE
				P.SERV_PROV_CODE=@ClientID AND
UPPER(ISNULL(P.FNAME,N'')) = UPPER(ISNULL(@FirstName,N'')) AND
                                UPPER(ISNULL(P.LNAME,N'')) = UPPER(ISNULL(@LastName,N'')) AND
                                UPPER(ISNULL(P.MNAME,N'')) = UPPER(ISNULL(@MiddleName,N'')) 
		END
        IF UPPER(@GetField) =N'DEPT' 
            IF ISNULL(@DEPT,N'') = N''
                   SET @VSTR = @ClientID +N'/'+ @AGENCY +N'/'+ @BUREAU +N'/'+ @DIVISION +N'/'+ @SECTION +N'/'+ @GROUP +N'/'+ @OFFICE 
            ELSE
                   SET @VSTR = @DEPT
        ELSE IF UPPER(@GetField) = N'USER ID' OR UPPER(@GetField) = N'USERNAME'
          SET @VSTR = @USERNAME
        ELSE IF UPPER(@GetField) = N'FNAME' 
          SET @VSTR = @V_FNAME
        ELSE IF UPPER(@GetField) =N'MNAME' 
          SET @VSTR = @V_MNAME
        ELSE IF UPPER(@GetField) =N'LNAME' 
          SET @VSTR = @V_LNAME
        ELSE IF UPPER(@GetField) =N'TITLE' 
          SET @VSTR = @V_TITLE
        ELSE IF UPPER(@GetField) = N'EMPLOYEE ID' 
          SET @VSTR = @EMPLOYEEID
        ELSE IF UPPER(@GetField) = N'CASHIER ID' 
          SET @VSTR = @CASHIERID
        ELSE IF UPPER(@GetField) = N'FULL NAME'
	  begin
	    IF @V_FNAME <> N''
         	    SET @VSTR = @V_FNAME
        	IF @V_MNAME <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @V_MNAME
               		 ELSE
                         	SET @VSTR = @V_MNAME
             		END
           	IF @V_LNAME <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @V_LNAME
              		  ELSE
                        	SET @VSTR = @V_LNAME
             		END
          end
        ELSE
          SET @VSTR = @USERID
        RETURN @VSTR            
END
GO


ALTER FUNCTION [dbo].[FN_GET_STATUS_TYPE](@SERVCODE  NVARCHAR(15),
                                       @STGRP     NVARCHAR(30),
                                       @ST        NVARCHAR(30)
                                      )RETURNS NVARCHAR (500) AS
BEGIN
DECLARE @STATUSTYPE NVARCHAR(250)
 SELECT 
  @STATUSTYPE=STATUS_TYPE
 FROM APP_STATUS_GROUP
 WHERE SERV_PROV_CODE = @SERVCODE
  AND APP_STATUS_GROUP_CODE = @STGRP     
	AND STATUS = @ST
	AND REC_STATUS = N'A';
 RETURN (@STATUSTYPE)
END
GO


ALTER  FUNCTION  [FN_GET_STDCHOICE_VALUEDESC]( @ClientID  NVARCHAR(15),
                                                 @StandardChoicesItemName  NVARCHAR(250),
                                                 @StandardChoicesValue     NVARCHAR(250)
                                                 )
                                                RETURNS NVARCHAR(1024) AS
    /*  Author           :   Cece Wang
        Create Date      :   07/11/2005
        Version          :   AA6.0 MSSQL
        Detail           :   RETURNS: Value Description of Standard Choices Value called {StandardChoicesValue}, belonging to Standard Choices Item called {StandardChoicesItemName}; Null if the field is not found.
                             ARGUMENTS: ClientID, 
                                        StandardChoicesItemName,
                                        StandardChoicesValue. 
        Revision History :   07/11/2005  Cece Wang  Initial Design
                             07/21/2006  Rainy Yu   update @retDesc for AA6.2
                             07/21/2006  Lydia Lim  Added code to drop function before creating it
                             05/14/2007   Lucky Song Correct parameter character lengths  
    */
BEGIN
	DECLARE @retDesc  NVARCHAR(1024) 
	SELECT  
	        TOP 1 
	        @retDesc=VALUE_DESC  
	FROM  
	        RBIZDOMAIN_VALUE 
	WHERE 
	       SERV_PROV_CODE= @ClientID AND 
	       UPPER(BIZDOMAIN)= UPPER(@StandardChoicesItemName)  AND 
	       UPPER(BIZDOMAIN_VALUE)= UPPER(@StandardChoicesValue) 
               RETURN isnull(@retDesc,N'')
END
GO


ALTER FUNCTION [dbo].[FN_GET_STRUC_ATTR_VALUE] (@CLIENTID  NVARCHAR(15),
 				      	    @PID1    NVARCHAR(5),
 				      	    @PID2    NVARCHAR(5),
 				      	    @PID3   NVARCHAR(5),
 				      	    @STRUCTURE_NBR bigint,
 				      	    @COMPONENT_GROUP NVARCHAR(30),
					    @ATTRIBUTE_NAME NVARCHAR(70)
 				      	    ) RETURNS NVARCHAR (500)  AS
/*  Author           :   David Zheng
    Create Date      :   04/12/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Attribute value that belongs to the specified {StructureNbr},{ComponentGroup}, {AttributeName}, {AttributeLabel}.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, 
			 StructureNbr, ComponentGroup, AttributeName, AttributeLabel (optional).
  Revision History   :    04/12/2005    David Zheng Inital Design
                                  05/14/2007   Lucky Song Correct parameter @ATTRIBUTE_NAME character lengths, and add codes to drop function before creating it   
*/
BEGIN 
DECLARE 	
  @VSTR NVARCHAR(500)
  SET @VSTR = N''
  SELECT TOP 1 
	@VSTR = B1_ATTRIBUTE_VALUE	
  FROM
	  BSTRUCTURE_ATTRIBUTE
  WHERE
	  SERV_PROV_CODE = @CLIENTID AND
	  B1_PER_ID1 = @PID1 AND
	  B1_PER_ID2 = @PID2 AND
	  B1_PER_ID3 = @PID3 AND
	  B1_STRUCTURE_NBR = @STRUCTURE_NBR AND
	  REC_STATUS = N'A' AND
	  UPPER(B1_COMPONENT_GROUP) = UPPER(@COMPONENT_GROUP) AND
	  ((B1_ATTRIBUTE_LABEL IS NULL AND UPPER(B1_ATTRIBUTE_NAME) = UPPER(@ATTRIBUTE_NAME)) OR	
	  UPPER(B1_ATTRIBUTE_LABEL) = UPPER(@ATTRIBUTE_NAME))
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_SWITCH_FISCAL_YEAR] (@CLIENTID NVARCHAR(15),
				    	       @P_YY     NVARCHAR(10),
					       @P_CURRDATE DATETIME)
 	   				       RETURNS NVARCHAR(10) AS
/*  Author           :   Glory Wang
    Create Date      :   12/29/2004
    Version          :   AA6.0
    Detail           :   RETURNS: Parameter Fiscal Year format yy/mm to yyyy
    ARGUMENTS        :   ClientID ,User selected year (yy/yy),Current Date
  Revision History :
*/
BEGIN
DECLARE 
  @V_YEAR NVARCHAR(10),
  @V_CURRYEAR NVARCHAR(10)
  SET @V_YEAR = SUBSTRING(@P_YY,4,2)
  SET @V_CURRYEAR = DATEPART(YEAR,@P_CURRDATE)
  IF CONVERT(INT,SUBSTRING(@V_CURRYEAR,1,2)+@V_YEAR) - CONVERT(INT,@V_CURRYEAR) > 10
    SET @V_YEAR =  CONVERT(NVARCHAR(10),CONVERT(INT,SUBSTRING(@V_CURRYEAR,1,2))-1)+@V_YEAR
  ELSE
    SET @V_YEAR = SUBSTRING(@V_CURRYEAR,1,2)+@V_YEAR
RETURN (@V_YEAR)
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_ACTIVE_ALL] 
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5) 	
	 )
RETURNS NVARCHAR(4000) AS
/*  Author         :   Lucky  Song
     Create Date   :   08/30/2005
     Version       :   AA6.1 MS SQL
     Detail        :    RETURNS: All active tasks for this application; if there are more than one, then each task begins on a new line. 
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3 
     Revision History :  Lucky Song initial design 08/30/2005
*/
BEGIN 
DECLARE
	@VSTR	              NVARCHAR(4000),
	@Result	  	      NVARCHAR(4000);
	set  @VSTR=N'';
          DECLARE CURSOR_1 CURSOR FOR
          SELECT          
                       ISNULL(SD_PRO_DES,N'')  
          FROM
                       GPROCESS
          WHERE
                      REC_STATUS=N'A' AND
                      SD_CHK_LV1=N'Y' AND
                      SERV_PROV_CODE=@CLIENTID AND
                      B1_PER_ID1=@PID1 AND
                      B1_PER_ID2=@PID2 AND
                     B1_PER_ID3=@PID3 
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	WHILE @@FETCH_STATUS = 0
	BEGIN
	  SET @VSTR=LTRIM(RTRIM(@VSTR))
	if (@VSTR <> N'')
		if (ISNULL(@Result,N'') = N'')
			SET @Result = @VSTR 
		else		 
			SET @Result = @Result + CHAR(10) + @VSTR
	FETCH NEXT FROM CURSOR_1 INTO @VSTR
	END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_CURRENT_INFO] (@CLIENT NVARCHAR(15),
					         @PID1 NVARCHAR(5),
					         @PID2 NVARCHAR(5),
					         @PID3 NVARCHAR(5),
					         @PRO_DES NVARCHAR(80),
                                                 @APP_DES NVARCHAR(50),
                                                 @GETFIELD NVARCHAR(50)	
					        )RETURNS NVARCHAR(100)
/*  Author           :   Roy Zhou
    Create Date      :   3/21/2006
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: CURRENT INFO FOR THE TASK {CURRENTTASKDESCRIPTION} WHOSE CURRENT STATUS IS LIKE {CURRENTTASKSTATUS}; IF {CURRENTTASKSTATUS} IS NOT SPECIFIED IN ARGUMENTS, RETURNS CURRENT INFO FOR THE TASK {CURRENTTASKDESCRIPTION}, REGARDLESS OF TASK STATUS.  RETURNS FIELD VALUE AS SPECIFIED BY {GET_FIELD}.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    CurrentTaskDescription (% WILDCARD MAY BE USED), 
                                    CurrentTaskStatus (OPTIONAL, % WILDCARD MAY BE USED), 
                                    GetField (OPTIONS: 'ACTION_BY', 'FNAME', 'MNAME', 'LNAME','ASGNFNAME','ASGNMNAME','ASGNLNAME','ASGN_FULLNAME','DUEDATE')
    Revision History :   3/21/2005  Roy Zhou    Initial
			 12/28/2006 Angel Feng  Update to get Current First, Middle and Last Name for 06SSP-00269 fields L&M.
			 01/02/2007 Angel Feng  Update to get "Assigned To" First Middle Last Name for 06SSP-00267.
			 01/04/2007 Angel Feng  Update to get Workflow task 'Due Date' in format 'fmMonth dd, yyyy' for 06SSP-00271 field N.
			 05/10/2007   Lucky Song Correct parameter @PRO_DES character lengths 
                         05/14/2007 Rainy Yu update parameter length
*/
BEGIN
	DECLARE @VSTR NVARCHAR(100),
		@V_FNAME  NVARCHAR(15),
		@V_MNAME  NVARCHAR(15),
		@V_LNAME  NVARCHAR(25),
		@V_ASGNFNAME  NVARCHAR(15),
		@V_ASGNMNAME  NVARCHAR(15),
		@V_ASGNLNAME  NVARCHAR(25),
		@V_DUEDATE  NVARCHAR(30),
                @V_ACTION_BY  NVARCHAR(100) 
        SET @V_ACTION_BY=N'';
	SELECT TOP 1
	    @V_FNAME = GA_FNAME,
	    @V_MNAME = GA_MNAME,
	    @V_LNAME = GA_LNAME,
	    @V_ASGNFNAME = ASGN_FNAME,
	    @V_ASGNMNAME = ASGN_MNAME,
	    @V_ASGNLNAME = ASGN_LNAME,
	    @V_DUEDATE = case when isnull(B1_DUE_DD,N'')<>N'' then datename(month,B1_DUE_DD)+N' '+datename(day,B1_DUE_DD)+ N', '+datename(year,B1_DUE_DD) else N'' end,
	    @V_ACTION_BY = (CASE WHEN ISNULL(GA_FNAME,N'')=N'' THEN N'' ELSE (CASE WHEN ISNULL(ISNULL(GA_MNAME,N'')+ISNULL(GA_LNAME,N''),N'')=N''  THEN GA_FNAME ELSE GA_FNAME+N' ' END)END)+
                               (CASE WHEN ISNULL(GA_MNAME,N'')=N'' THEN N'' ELSE (CASE WHEN ISNULL(GA_LNAME,N'')=N'' THEN ISNULL(GA_MNAME,N'') ELSE ISNULL(GA_MNAME,N'')+N' ' END) END)+ ISNULL(GA_LNAME,N'')
	FROM
	    GPROCESS
	WHERE
	    SERV_PROV_CODE = @CLIENT AND
	    B1_PER_ID1 = @PID1       AND
	    B1_PER_ID2 = @PID2       AND
	    B1_PER_ID3 = @PID3       AND
	    REC_STATUS=N'A' 	     AND
	    UPPER(SD_PRO_DES) LIKE UPPER(@PRO_DES) AND
	    ((UPPER(SD_APP_DES) LIKE  UPPER(@APP_DES)) OR ISNULL(@APP_DES,N'')=N'' )	
      IF upper(@GETFIELD) =N'ACTION_BY' 
          SET @VSTR=@V_ACTION_BY
      ELSE IF upper(@GETFIELD) =N'FNAME' 
          SET @VSTR=@V_FNAME
      ELSE IF upper(@GETFIELD) =N'MNAME' 
          SET @VSTR=@V_MNAME
      ELSE IF upper(@GETFIELD) =N'LNAME' 
          SET @VSTR=@V_LNAME
      ELSE IF upper(@GETFIELD) =N'ASGNFNAME' 
          SET @VSTR=@V_ASGNFNAME
      ELSE IF upper(@GETFIELD) =N'ASGNMNAME' 
          SET @VSTR=@V_ASGNMNAME
      ELSE IF upper(@GETFIELD) =N'ASGNLNAME' 
          SET @VSTR=@V_ASGNLNAME
      ELSE IF upper(@GETFIELD) =N'ASGN_FULLNAME' 
	BEGIN
		IF @V_ASGNFNAME <> N''
		    SET @VSTR = @V_ASGNFNAME
		IF @V_ASGNMNAME <> N''
		  	BEGIN
			 IF @VSTR <>N''                            
		       		SET @VSTR = @VSTR + N' ' + @V_ASGNMNAME
			 ELSE
		         	SET @VSTR = @V_ASGNMNAME
			END
		IF @V_ASGNLNAME <> N''
			BEGIN
			  IF @VSTR <>N''                            
		       		SET @VSTR = @VSTR + N' ' + @V_ASGNLNAME
			  ELSE
		        	SET @VSTR = @V_ASGNLNAME
			END
	END
      ELSE IF upper(@GETFIELD) =N'DUEDATE' 
          SET @VSTR=@V_DUEDATE
      ELSE
      	SET @VSTR=@V_ACTION_BY
     RETURN @VSTR;         
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_EARLIEST] (@CLIENTID NVARCHAR(15),
					 @PID1 NVARCHAR(5),
					 @PID2 NVARCHAR(5),
					 @PID3 NVARCHAR(5),
                                         @INFOTYPE NVARCHAR(10),
					 @PTASK NVARCHAR(100),
					 @PSTAT NVARCHAR(100)
					 )RETURNS NVARCHAR(100) AS
/*  Author           :   Arthur Miao
    Create Date      :   05/19/2004
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Info about the workflow history task with the earliest status date; if {TaskDescription} or {TaskDisposationDesc} is specified, returns info about the earliest workflow history task for the specified task or status; if there is more than one workflow task with the earliest status date, uses the one updated first. If {InfoType} = 'TASK', returns task name; if {InfoType} = 'STATUS', returns status; if {InfoType} = 'DATE', returns status date in format MM/DD/YYYY; if {InfoType} = 'STAFF', returns the "Action By" staff name, in format [First Initial] [Last Name]; default is 'TASK'.
    			 ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3,                                     
                                    InfoType ('TASK','STATUS','DATE','STAFF'), 
                                    TaskDescription (optional), 
                                    TaskDisposationDesc (optional).
  Revision History   :	 05/19/2004  Arthur Miao  Initial Design
                         03/31/2006  Lydia Lim    Correct and simplify query. Add code to drop function first.
                         10/03/2006  Lydia Lim    Correct ORDER BY clause from Desc to Asc
                         06/14/2007  Lydia Lim    Add Coalesce() to allow NULL parameter value
*/
BEGIN
DECLARE
  @RET NVARCHAR(100)
  SELECT TOP 1 
    @RET = CASE UPPER(@INFOTYPE)
             WHEN N'TASK'   THEN SD_PRO_DES
             WHEN N'STATUS' THEN SD_APP_DES
             WHEN N'DATE'   THEN CONVERT(CHAR,SD_APP_DD,101)
             WHEN N'STAFF'  THEN SUBSTRING(G6_ISS_FNAME,1,1)+N' '+G6_ISS_LNAME
             ELSE               SD_PRO_DES
           END
  FROM 
	GPROCESS_HISTORY A
  WHERE A.SERV_PROV_CODE = @CLIENTID
  AND	A.B1_PER_ID1 = @PID1
  AND	A.B1_PER_ID2 = @PID2
  AND	A.B1_PER_ID3 = @PID3
  AND	(UPPER(A.SD_PRO_DES) LIKE UPPER(@PTASK) OR COALESCE(@PTASK,N'')=N'')
  AND   (UPPER(A.SD_APP_DES) LIKE UPPER(@PSTAT) OR COALESCE(@PSTAT,N'')=N'')
  AND   A.REC_STATUS = N'A'
  ORDER BY
        SD_APP_DD ASC, REC_DATE ASC
RETURN @RET
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_LAST_BYTASK_STAT](@CLIENTID NVARCHAR(15),
					 @PID1 NVARCHAR(5),
					 @PID2 NVARCHAR(5),
					 @PID3 NVARCHAR(5),
					 @TASK  NVARCHAR(80),
                                         @STATUS NVARCHAR(30),
                                         @INFOTYPE  NVARCHAR(100)
					 )RETURNS NVARCHAR(4000) AS
/*  Author         :   Cece Wang
     Create Date   :   08/29/2006 
     Version       :   AA6.2
     Detail        :   RETURNS:   Get the latest info for input work flow task and task status
                       ARGUMENTS: ClientID, 
                                  PrimaryTrackingID1, 
                                  PrimaryTrackingID2, 
                                  PrimaryTrackingID3, 
                                  TaskDescription(optional), 
                                  TaskDisposationDesc(optional),
                                  Info_Type(options: TASK(default), STATUS, DATE, RECDATE, STAFF, TASK-STATUS DATE)
    Revision History : 08/24/2006  Cece Wang  Initial Design
*/
BEGIN
declare @V_RET NVARCHAR(4000)
BEGIN 
     SELECT TOP 1 
                    @V_RET = 
                     CASE UPPER(@INFOTYPE)  
                     WHEN N'TASK'             THEN SD_PRO_DES  
                     WHEN N'STATUS'           THEN SD_APP_DES  
                     WHEN N'DATE'             THEN CONVERT(CHAR,SD_APP_DD,101)                       
                     WHEN N'RECDATE'          THEN CONVERT(CHAR,REC_DATE,20) 
                     WHEN N'STAFF'            THEN SUBSTRING(G6_ISS_FNAME,1,1)+N' '+G6_ISS_LNAME  
                     WHEN N'TASK-STATUS DATE' THEN SD_PRO_DES+N' - '+SD_APP_DES+N' '+CONVERT(CHAR,SD_APP_DD,101)     
                     ELSE                         SD_PRO_DES         
                     END                      
      FROM		
                     GPROCESS_HISTORY 
      WHERE 	
	            REC_STATUS = N'A'  AND
                    SERV_PROV_CODE = @CLIENTID  
                    AND B1_PER_ID1 = @PID1 
                    AND B1_PER_ID2=@PID2
                    AND B1_PER_ID3=@PID3
                    AND((@TASK <>N'' AND UPPER(SD_PRO_DES) LIKE UPPER(@TASK)) OR @TASK=N'')
                    AND((@STATUS <>N'' AND UPPER(SD_APP_DES) LIKE UPPER(@STATUS)) OR @STATUS=N'')
                    ORDER BY SD_APP_DD DESC, REC_DATE DESC
 END
    RETURN @V_RET
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_LATEST] (@CLIENTID NVARCHAR(15),
					 @PID1 NVARCHAR(5),
					 @PID2 NVARCHAR(5),
					 @PID3 NVARCHAR(5),
					 @INFOTYPE  NVARCHAR(100) 
					 )RETURNS NVARCHAR(4000) AS
/*  Author         :   Lucky Song
     Create Date   :   08/30/2005 
     Version       :   AA6.1
     Detail        :   RETURNS: Info about the workflow task with the latest status date; if there is more than one such workflow task, uses the one updated last.  If {Info_Type} = 'TASK', returns task name; if {Info_Type} = 'STATUS', returns status; if {Info_Type} = 'DATE', returns status date in format MM/DD/YYYY; if {Info_Type} = 'RECDATE', returns record date in format yyyy-mm-dd hh:mi:ss(24h);if {Info_Type} = 'STAFF', returns the "Action By" staff name, in format [First Initial] [Last Name], if {Info_TYpe} is 'TASK-STATUS DATE', returns Task - Status Status Date. Returns NULL if no workflow history task found.
                       ARGUMENTS: ClientID, 
                                  PrimaryTrackingID1, 
                                  PrimaryTrackingID2, 
                                  PrimaryTrackingID3, 
                                  Info_Type (options: TASK(default), STATUS, DATE, RECDATE, STAFF, TASK-STATUS DATE)
    Revision History : 08/30/2005  Lucky Song  Initial Design
		       11/21/2005  Arthur Miao add 'DESC' to Order By clause
                       04/05/2006  Lydia Lim   Add option 'TASK-STATUS DATE', add STATUS DATE to Order By clause, RETURN NULL if no record found.
*/
BEGIN
declare @V_RET NVARCHAR(4000) 
BEGIN 
     SELECT TOP 1 
                    @V_RET = 
                     CASE UPPER(@INFOTYPE)  
                     WHEN N'TASK'             THEN SD_PRO_DES  
                     WHEN N'STATUS'           THEN SD_APP_DES  
                     WHEN N'DATE'             THEN CONVERT(CHAR,SD_APP_DD,101)                       
                     WHEN N'RECDATE'          THEN CONVERT(CHAR,REC_DATE,20) 
                     WHEN N'STAFF'            THEN SUBSTRING(G6_ISS_FNAME,1,1)+N' '+G6_ISS_LNAME  
                     WHEN N'TASK-STATUS DATE' THEN SD_PRO_DES+N' - '+SD_APP_DES+N' '+CONVERT(CHAR,SD_APP_DD,101)     
                     ELSE                         SD_PRO_DES         
                     END
      FROM		
                     GPROCESS_HISTORY 
      WHERE 	
	       REC_STATUS = N'A'  AND
                    SERV_PROV_CODE = @CLIENTID  
                    AND B1_PER_ID1 = @PID1 
                    AND B1_PER_ID2=@PID2
                    AND B1_PER_ID3=@PID3  
      ORDER BY SD_APP_DD DESC, REC_DATE DESC
 END
   RETURN @V_RET 
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_LATEST_REC_DATE]
                 (@CLIENTID  NVARCHAR(15),
                  @PID1      NVARCHAR(5),
                  @PID2      NVARCHAR(5),
                  @PID3      NVARCHAR(5)
                 )RETURNS DATETIME AS
/*  Author           :   Glory Wang
    Create Date      :   04/27/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: WorkFlow history latest Record Date
                         ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3.
  Revision History   :   Glory Wang Initial Design
*/
BEGIN
  DECLARE
    @V_DATE DATETIME
  SELECT @V_DATE = MAX(REC_DATE)
  FROM   GPROCESS_HISTORY
  WHERE  SERV_PROV_CODE = @CLIENTID
  AND    B1_PER_ID1 = @PID1
  AND    B1_PER_ID2 = @PID2
  AND    B1_PER_ID3 = @PID3
  AND    REC_STATUS = N'A'
  RETURN @V_DATE
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_SPEC_INFO](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5),
                                      @CURRENTTASKDESCRIPTION NVARCHAR(80),
                                      @FIELDLABEL  NVARCHAR(250)
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author           :   David Zheng
    Create Date      :   11/07/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: Value of Task Specific Info field whose label is {FieldLabel} and whose task name is {CurrentTaskDescription}; If the {CurrentTaskDescription} argument is blank, returns the value of the first Task Specific Info field whose label is {FieldLabel}; Null if no Task Specific Info called {FieldLabel} is found.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3,
                                    CurrentTaskDescription (optional), 
                                    FieldLabel.    
    Revision History :   11/07/2005  David Zheng Initial Design
                         07/21/2006  Rainy Yu update @SEQ_ID for AA6.2
*/
BEGIN 
	DECLARE @SD_NUM     int;
	DECLARE @SEQ_ID     int;
	DECLARE @INFO_VALUE  NVARCHAR(240);
	set  @SD_NUM=0;
	set  @SEQ_ID=0;
	set  @INFO_VALUE = N'';
	IF @FIELDLABEL IS NULL 
	 RETURN NULL
    IF @CURRENTTASKDESCRIPTION IS NOT NULL 
    	BEGIN
	        SELECT TOP 1
	               @SD_NUM = SD_STP_NUM, 
	               @SEQ_ID = RELATION_SEQ_ID
	          FROM GPROCESS
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND UPPER(SD_PRO_DES) = UPPER(@CURRENTTASKDESCRIPTION)
	        SELECT TOP 1 
	               @INFO_VALUE = B1_CHECKLIST_COMMENT
	          FROM GPROCESS_SPEC_INFO
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND RELATION_SEQ_ID = @SEQ_ID
	           AND SD_STP_NUM = @SD_NUM
	           AND REC_STATUS = N'A'
	           AND UPPER(B1_CHECKBOX_DESC) = UPPER(@FIELDLABEL)
	END
    ELSE
    	BEGIN
	        SELECT TOP 1
	               @INFO_VALUE = B1_CHECKLIST_COMMENT
	          FROM GPROCESS_SPEC_INFO	
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND REC_STATUS = N'A'
	           AND UPPER(B1_CHECKBOX_DESC) = UPPER(@FIELDLABEL)
       END
 RETURN(@INFO_VALUE);
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_SPEC_INFO_BYGROUP](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5),
                                      @CURRENTTASKDESCRIPTION NVARCHAR(80),
                                      @TYP NVARCHAR(250),
                                      @FIELDLABEL  NVARCHAR(250)
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author           :   David Zheng
    Create Date      :   11/07/2005
    Version          :   AA6.1 MS SQL
    Detail           :   RETURNS: Value of Task Specific Info field whose label is {FieldLabel} and whose task name is 
{CurrentTaskDescription}; If the {CurrentTaskDescription} argument is blank, returns the value of the first Task Specific 
Info field whose label is {FieldLabel}; Null if no Task Specific Info called {FieldLabel} is found.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3,
                                    CurrentTaskDescription (optional), 
                                    FieldLabel.    
    Revision History :   08/05/2005  Sandy Yin convert Oracle  
                                   12/29/2006  Sandy Yin  revised the function bug.   use '' instead of null.
*/
BEGIN 
	DECLARE @SD_NUM     int;
	DECLARE @SEQ_ID     int;
	DECLARE @INFO_VALUE  NVARCHAR(240);
	set  @SD_NUM=0;
	set  @SEQ_ID=0;
	set  @INFO_VALUE = N'';
	IF @FIELDLABEL =N'' 
	 RETURN N''
    IF @CURRENTTASKDESCRIPTION <>N''
    	BEGIN
	        SELECT TOP 1
	               @SD_NUM = SD_STP_NUM, 
	               @SEQ_ID = RELATION_SEQ_ID
	          FROM GPROCESS
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND UPPER(SD_PRO_DES) = UPPER(@CURRENTTASKDESCRIPTION)
	        SELECT TOP 1 
	               @INFO_VALUE = B1_CHECKLIST_COMMENT
	          FROM GPROCESS_SPEC_INFO
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND RELATION_SEQ_ID = @SEQ_ID
	           AND SD_STP_NUM = @SD_NUM
	           AND REC_STATUS = N'A'
                   AND UPPER(B1_CHECKBOX_TYPE) LIKE UPPER(@TYP)
	           AND UPPER(B1_CHECKBOX_DESC) = UPPER(@FIELDLABEL)
	END
    ELSE
    	BEGIN
	        SELECT TOP 1
	               @INFO_VALUE = B1_CHECKLIST_COMMENT
	          FROM GPROCESS_SPEC_INFO	
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND REC_STATUS = N'A'
                   AND UPPER(B1_CHECKBOX_TYPE) LIKE UPPER(@TYP)
	           AND UPPER(B1_CHECKBOX_DESC) = UPPER(@FIELDLABEL)
       END
 RETURN(@INFO_VALUE);
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_SPEC_INFO_BYGROUP_CODE](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5),
                                      @CURRENTTASKDESCRIPTION NVARCHAR(80),
                                      @P_CODE NVARCHAR(250),
                                      @TYP NVARCHAR(250),
                                      @FIELDLABEL  NVARCHAR(250)
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author           :   Sandy Yin
    Create Date      :   12/29/2006
    Version          :   AA6.2 MS SQL
    Detail           :   RETURNS: Value of Task Specific Info field whose label is {FieldLabel} and whose task name is {CurrentTaskDescription}; If the {CurrentTaskDescription} argument is blank, returns the first task specific info field TaskSpecGroupCode is {@P_CODE} and TaskSpecSubgroup is {@typ} whose label is {Fieldlabel}; Null if no Task Specific Info called {FieldLabel} is found.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3,
                                    CurrentTaskDescription (optional), 
                                    TaskSpecGroupCode(optonal)
                                    TaskSpecSubgroup(optonal)
                                    FieldLabel.    
    Revision History :   08/05/2005  Sandy Yin Initial Create
*/
BEGIN 
	DECLARE @SD_NUM     int;
	DECLARE @SEQ_ID     int;
	DECLARE @INFO_VALUE  NVARCHAR(240);
	set  @SD_NUM=0;
	set  @SEQ_ID=0;
	set  @INFO_VALUE = N'';
	IF @FIELDLABEL =N'' 
	 RETURN N''
    IF @CURRENTTASKDESCRIPTION <>N''
    	BEGIN
	        SELECT TOP 1
	            @SD_NUM = SD_STP_NUM, 
	            @SEQ_ID = RELATION_SEQ_ID
	          FROM GPROCESS
	         WHERE SERV_PROV_CODE = @CLIENTID
	           AND B1_PER_ID1 = @PID1
	           AND B1_PER_ID2 = @PID2
	           AND B1_PER_ID3 = @PID3
	           AND UPPER(SD_PRO_DES) = UPPER(@CURRENTTASKDESCRIPTION)
 		SELECT TOP 1
	               @INFO_VALUE = G.B1_CHECKLIST_COMMENT
	          FROM GPROCESS_SPEC_INFO G,
                       R2CHCKBOX R
	         WHERE 
	               G.SERV_PROV_CODE =  R.SERV_PROV_CODE
                   AND G.B1_CHECKBOX_TYPE = R.R1_CHECKBOX_TYPE
                   AND G.B1_CHECKBOX_DESC = R.R1_CHECKBOX_DESC
                   AND (@P_CODE=N'' OR (@P_CODE<>N'' AND UPPER(R.R1_CHECKBOX_CODE) = UPPER(@P_CODE)))
                   AND R.R1_CHECKBOX_GROUP=N'WORKFLOW TASK'  
	           AND R.REC_STATUS = N'A'
                   AND G.SERV_PROV_CODE = @CLIENTID
	           AND G.B1_PER_ID1 = @PID1
	           AND G.B1_PER_ID2 = @PID2
	           AND G.B1_PER_ID3 = @PID3
	           AND G.REC_STATUS = N'A'
                   AND UPPER(G.B1_CHECKBOX_TYPE) LIKE UPPER(@TYP)
	           AND UPPER(G.B1_CHECKBOX_DESC) = UPPER(@FIELDLABEL) 
                   AND SD_STP_NUM = @SD_NUM
	END
    ELSE
    	BEGIN
	        SELECT TOP 1
	               @INFO_VALUE = G.B1_CHECKLIST_COMMENT
	          FROM GPROCESS_SPEC_INFO G,
                       R2CHCKBOX  R
	         WHERE 
	               G.SERV_PROV_CODE =  R.SERV_PROV_CODE
                   AND G.B1_CHECKBOX_TYPE = R.R1_CHECKBOX_TYPE
                   AND G.B1_CHECKBOX_DESC = R.R1_CHECKBOX_DESC
                   AND (@P_CODE=N'' OR (@P_CODE<>N'' AND UPPER(R.R1_CHECKBOX_CODE) = UPPER(@P_CODE)))
                   AND R.R1_CHECKBOX_GROUP=N'WORKFLOW TASK'  
	           AND R.REC_STATUS = N'A'
                   AND G.SERV_PROV_CODE = @CLIENTID
	           AND G.B1_PER_ID1 = @PID1
	           AND G.B1_PER_ID2 = @PID2
	           AND G.B1_PER_ID3 = @PID3
	           AND G.REC_STATUS = N'A'
                   AND UPPER(G.B1_CHECKBOX_TYPE) LIKE UPPER(@TYP)
	           AND UPPER(G.B1_CHECKBOX_DESC) = UPPER(@FIELDLABEL) 
       END
 RETURN(@INFO_VALUE);
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_SPEC_INFO_CS2] ( @CLIENT NVARCHAR(15),
					         @PID1 NVARCHAR(5),
					         @PID2 NVARCHAR(5),
					         @PID3 NVARCHAR(5),
                                                 @FirstTaskDescription   NVARCHAR(80),
                                                 @CurrentTaskDescription NVARCHAR(80),
                                                 @Get_Field              NVARCHAR(50)
                                                 ) RETURNS  NVARCHAR(240)  AS
    /*  Author           :   Roy Zhou 
        Create Date      :   04/11/2006
        Version          :   AA6.0 MSSQL
        Detail           :   RETURNS: Value of Task Specific Info field whose label is {ChecklistDescription} and whose task name is {CurrentTaskDescription}; if {FirstTaskDescription} is specified, the parent task of {CurrentTaskDescription} must be {FirstTaskDescription}.
                             ARGUMENTS: ClientID,  
                                        PrimaryTrackingID1, 
                                        PrimaryTrackingID2, 
                                        PrimaryTrackingID3,
                                        FirstTaskDescription (case-sensitive, optional), 
                                       CurrentTaskDescription (case-sensitive), 
                                       ChecklistDescription (case-sensitive).
        Revision History :   04/11/2006 Roy Zhou Initial Design
                             07/21/2006 Rainy Yu update @seq_id for AA6.2
                             05/14/2007   Lucky Song Correct parameter character lengths  
                             06/14/2007   Lydia Lim     Edit comments.
    */
BEGIN
	DECLARE
	   @VSTR NVARCHAR(240),
	   @sd_num INT,
	   @seq_id INT
	   set @VSTR=N''
           set @sd_num=0
           set @seq_id=0
  IF @Get_Field IS NULL 
    BEGIN
	   RETURN NULL
    END
  IF @CurrentTaskDescription IS NULL 
   BEGIN
    RETURN NULL
   END
   IF ISNULL(@FirstTaskDescription,N'')<>N''
     BEGIN
	    SELECT 
	      TOP 1
	      @VSTR  = T1.B1_CHECKLIST_COMMENT   
	    FROM 
	      GPROCESS_SPEC_INFO T1,
	      (         
	       SELECT
                       TOP 1
	               GG.RELATION_SEQ_ID,
		       P.SD_STP_NUM,
		       GG.SERV_PROV_CODE,
		       GG.B1_PER_ID1,
		       GG.B1_PER_ID2,
		       GG.B1_PER_ID3,
		       P.REC_STATUS 
	       FROM 
	         GPROCESS P, 
	         GPROCESS_GROUP GG  
	       WHERE  
	            P.SERV_PROV_CODE=@CLIENT AND 
	            P.B1_PER_ID1= @PID1 AND 
	            P.B1_PER_ID2= @PID2 AND 
	            P.B1_PER_ID3= @PID3 AND 
	            p.SD_PRO_DES= @CurrentTaskDescription AND 
	            GG.SERV_PROV_CODE=P.SERV_PROV_CODE AND 
	            GG.B1_PER_ID1=P.B1_PER_ID1 AND
		    GG.B1_PER_ID2=P.B1_PER_ID2 AND
		    GG.B1_PER_ID3=P.B1_PER_ID3 AND 
	            P.RELATION_SEQ_ID = GG.RELATION_SEQ_ID AND 
	            P.RELATION_SEQ_ID=GG.RELATION_SEQ_ID AND
		    P.R1_PROCESS_CODE=GG.R1_PROCESS_CODE AND 
	            SUBSTRING(GG.PARENTTASKNAME,CHARINDEX(N'>',GG.PARENTTASKNAME)+1,LEN(GG.PARENTTASKNAME)-CHARINDEX(N'>',GG.PARENTTASKNAME)) = @FirstTaskDescription                      
	            ) RO
	     WHERE 
	       T1.SERV_PROV_CODE = RO.SERV_PROV_CODE AND
	       T1.B1_PER_ID1 = RO.B1_PER_ID1 AND
	       T1.B1_PER_ID2 = RO.B1_PER_ID2 AND
	       T1.B1_PER_ID3 = RO.B1_PER_ID3 AND
	       T1.REC_STATUS=N'A' AND 
	       T1.REC_STATUS = RO.REC_STATUS AND 	
	       T1.RELATION_SEQ_ID=RO.RELATION_SEQ_ID AND
	       T1.SD_STP_NUM=RO.SD_STP_NUM AND
	       T1.B1_CHECKBOX_DESC = @Get_Field 
    END                     
  ELSE   
    BEGIN   
        SELECT 
          TOP 1
          @sd_num=sd_stp_num, 
          @seq_id=relation_seq_id
         FROM GPROCESS
         WHERE SERV_PROV_CODE = @CLIENT
           AND B1_PER_ID1 =  @PID1
           AND B1_PER_ID2 =  @PID2
           AND B1_PER_ID3 =  @PID3
           AND sd_pro_des = @CurrentTaskDescription;
        SELECT 
         TOP 1
         @VSTR=B1_CHECKLIST_COMMENT
        FROM GPROCESS_SPEC_INFO
        WHERE SERV_PROV_CODE = @CLIENT
           AND B1_PER_ID1 = @PID1
           AND B1_PER_ID2 = @PID2
           AND B1_PER_ID3 = @PID3
           AND RELATION_SEQ_ID = @seq_id
           AND SD_STP_NUM = @sd_num
           AND REC_STATUS = N'A'
           AND b1_checkbox_desc = @Get_Field
     END       
   return(@VSTR) 
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_STATUS] (@CLIENTID  NVARCHAR(15),
											 				      	    @PID1    NVARCHAR(5),
											 				      	    @PID2    NVARCHAR(5),
											 				      	    @PID3   NVARCHAR(5),
											 				      	    @PRO_DES NVARCHAR(200),
 															      	    @APP_DES NVARCHAR(200)) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sunny Chen
    Create Date      :   07/11/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Current Status of the workflow task like {CurrentTaskDescription} whose current status is in the list {CurrentTaskStatus}; If {CurrentTaskStatus} is not specified in arguments, returns the current status of the workflow task {CurrentTaskDescription} regardless of status; Null if {CurrentTaskDescription} is not found.
                         ARGUMENTS: ClientID, 
                                    PrimaryTrackingID1, 
                                    PrimaryTrackingID2, 
                                    PrimaryTrackingID3, 
                                    CurrentTaskDescription (wildcard % may be used), 
                                    CurrentTaskStatus (optional, may be comma-delimited list).
    Revision History :   07/11/2005  Sunny Chen Initial Design
	                          06/14/2007  Lydia Lim   Add Coalesce() to allow NULL parameter value; add code to drop function before creating; allow wildcard to be used for @PRO_DES
*/
BEGIN
declare @VSQL NVARCHAR(4000) 
declare @RESULT NVARCHAR(4000) 
declare @VSTR NVARCHAR(4000)
declare @VTEM NVARCHAR(4000)
declare @LASTSTRING NVARCHAR(4000)
declare @STARTPOS INT
declare @ENDPOS INT
declare @TMPPOS INT
SET @STARTPOS = 1
SET @TMPPOS = 1
SET @VSTR = N''
WHILE (@TMPPOS<=LEN(@APP_DES))
BEGIN
	IF (SUBSTRING(@APP_DES,@TMPPOS,1) = N',')
                 BEGIN
	            SET @VTEM = LTRIM(RTRIM(SUBSTRING(@APP_DES,@STARTPOS,@TMPPOS-@STARTPOS)))                
		IF (@VTEM != N'')
      BEGIN
		             IF (@VSTR != N'')
		     	         SET @VSTR=@VSTR+N','''+@VTEM+N''''
	  	           ELSE
               	   SET @VSTR=N''''+@VTEM+N''''
      END
    SET @TMPPOS = @TMPPOS +1
		SET @STARTPOS = @TMPPOS
                  END
	 ELSE
                   SET @TMPPOS = @TMPPOS +1			
END
SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@APP_DES,@STARTPOS,@TMPPOS-@STARTPOS)))
IF (@LASTSTRING != N'')
BEGIN
IF (@VSTR=N'')
	SET @VSTR =@VSTR + N''''+ @LASTSTRING+N''''
ELSE
	SET @VSTR =@VSTR +  N','''+@LASTSTRING+N''''
END
	BEGIN				
		SELECT TOP 1
		   @RESULT = SD_APP_DES
		FROM
		    GPROCESS
		WHERE
		    SERV_PROV_CODE = @CLIENTID AND		
		    B1_PER_ID1 = @PID1 AND		
		    B1_PER_ID2 = @PID2 AND		
		    B1_PER_ID3 = @PID3 AND
		    REC_STATUS=N'A' AND
		    UPPER(SD_PRO_DES) LIKE UPPER(@PRO_DES) AND
		    ((COALESCE(@APP_DES,N'') <> N'' and CHARINDEX(UPPER(SD_APP_DES),UPPER(@VSTR))>0 ) OR
		      COALESCE(@APP_DES,N'') = N'')			      		      	  				
	END	
	RETURN @RESULT		
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_STATUS_COMMENT] (@CLIENTID  NVARCHAR(15),
 				      	    @PID1    NVARCHAR(5),
 				      	    @PID2    NVARCHAR(5),
 				      	    @PID3   NVARCHAR(5),
 				      	    @PRO_DES NVARCHAR(80),
 				      	    @APP_DES NVARCHAR(30)) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   05/19/2005
    Version          :   AA6.0
    Detail           :   RETURNS: The status comment for the task {CurrentTaskDescription} whose current status is {CurrentTaskStatus}; if {CurrentTaskStatus} is not specified in arguments, returns the current status comment for the task {CurrentTaskDescription}, regardless of task status.  
                         ARGUMENTS: CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, CurrentTaskDescription, CurrentTaskStatus (optional)
    Revision History :   05/19/2005  David Zheng Initial Design
                         07/25/2005  David Zheng changed the "=" to "LIKE" for flexible
                         05/14/2007   Lucky Song Correct parameter character lengths, and add codes to drop function before creating it     
*/
BEGIN
	DECLARE
           @VSTR NVARCHAR(4000)   
	BEGIN				
		SELECT TOP 1
		   @VSTR = SD_COMMENT
		FROM
		    GPROCESS
		WHERE
		    SERV_PROV_CODE = @CLIENTID AND		
		    B1_PER_ID1 = @PID1 AND		
		    B1_PER_ID2 = @PID2 AND		
		    B1_PER_ID3 = @PID3 AND
		    REC_STATUS=N'A' AND
		    UPPER(SD_PRO_DES) LIKE UPPER(@PRO_DES) AND
		    ((@APP_DES <> N'' and UPPER(SD_APP_DES) LIKE UPPER(@APP_DES)) OR
		      @APP_DES = N'')			      		      	  				
	END	
	RETURN @VSTR		
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_STATUS_COMMENT_ALL]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5),
	 @PTASK NVARCHAR(100),
	 @PSTAT NVARCHAR(100),
	 @FORMAT NVARCHAR(500)
	 )
RETURNS NVARCHAR(4000) AS
/* 
Author           : Arthur Miao
Create Date      : 07/22/2005
Version          : AA6.1 MS SQL
Detail           : RETURNS: List of all comments of the workflow task {TaskDescription} whose status is like {TaskDisposationDesc}; if no {TaskDisposationDesc} is specified, returns all comments for {TaskDescription}.  If {Format} is 'L', returns comments in a single line separated by spaces; if {Format} is 'B', returns comments in a stack, where each comment begins on a new line.                       
		   ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, TaskDescription, TaskDisposationDesc (optional), Format ('L' to show all comments in single line (default), 'B' to stack comments)
Revision History : Arthur Miao initial design
*/
BEGIN 
DECLARE
	@TEM          NVARCHAR(4000),
@Result       NVARCHAR(4000);
set  @TEM=N'';
set  @Result =N'';
DECLARE CURSOR_1 CURSOR FOR
SELECT
	       	ISNULL(SD_COMMENT,N'')
FROM
	       	GPROCESS
WHERE
	      	SERV_PROV_CODE = @CLIENTID AND
REC_STATUS = N'A' AND
	     	B1_PER_ID1= @PID1 AND
		B1_PER_ID2= @PID2 AND
	     	B1_PER_ID3= @PID3 AND
		UPPER(SD_PRO_DES) LIKE UPPER(@PTASK) AND
		((@PSTAT <> N'' and UPPER(SD_APP_DES) LIKE UPPER(@PSTAT)) OR @PSTAT = N'') 
ORDER BY G6_STAT_DD
OPEN CURSOR_1
FETCH NEXT FROM CURSOR_1 INTO @TEM
WHILE @@FETCH_STATUS = 0
BEGIN
		if (@TEM <> N'')
			if (@Result = N'')
				SET @Result = @TEM
			else
			     if UPPER(@FORMAT) = N'L'
				SET @Result = @Result +N' '+ @TEM
			     ELSE IF upper(@FORMAT) = N'B'
				SET @Result = @Result + CHAR(10) + @TEM
			     ELSE
			     	SET @Result = @Result + N' ' + @TEM
              	FETCH NEXT FROM CURSOR_1 INTO @TEM
	END;
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_TASK_STATUS_DATE] (@CLIENTID NVARCHAR(15),
					 @PID1 NVARCHAR(5),
					 @PID2 NVARCHAR(5),
					 @PID3 NVARCHAR(5),
					 @PRO_DES NVARCHAR(100),
					 @APP_DES NVARCHAR(100)
					 )RETURNS NVARCHAR(30) AS
/*  Author           :   Glory Wang
    Create Date      :   12/01/2004
    Version          :   AA6.0
    Detail           :   RETURNS: Current Status Date of the workflow task like {CurrentTaskDescription} whose current status is in {CurrentTaskStatus} list or is like {CurrentTaskStatus}; If {CurrentTaskStatus} is not specified in arguments, returns the current status date of the workflow task {CurrentTaskDescription} regardless of status; Null if {CurrentTaskDescription} is not found.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, CurrentTaskDescription (may contain % wildcard), CurrentTaskStatus (optional, may be comma-delimited list OR use %, but not both).
  	Revision History :   12/01/2004  Glory Wang Initial Design
			     07/12/2005  Sunny Chen add a additional function, user can input a list about parameter @APP_DES.For example:'PENDING,TABLED' and so on. 
			     07/22/2005  David Zheng add a "like" instance for Current Status Date of the workflow task 
*/
BEGIN
declare @V_DATE NVARCHAR(30)
declare @VSQL NVARCHAR(4000) 
declare @VSTR NVARCHAR(4000)
declare @VTEM NVARCHAR(4000)
declare @LASTSTRING NVARCHAR(4000)
declare @STARTPOS INT
declare @ENDPOS INT
declare @TMPPOS INT
SET @STARTPOS = 1
SET @TMPPOS = 1
SET @VSTR = N''
if CHARINDEX(N',',@APP_DES)=0 AND @APP_DES <> N''
   BEGIN
	SELECT TOP 1 
		@V_DATE = CONVERT(CHAR,G6_STAT_DD,101)
	FROM
		    GPROCESS
	WHERE
		    SERV_PROV_CODE = @CLIENTID AND		
		    B1_PER_ID1 = @PID1 AND		
		    B1_PER_ID2 = @PID2 AND		
		    B1_PER_ID3 = @PID3 AND
		    REC_STATUS=N'A' AND
		    UPPER(SD_PRO_DES) LIKE UPPER(@PRO_DES) AND
		    ((@APP_DES <> N'' and UPPER(SD_APP_DES) LIKE UPPER(@APP_DES) ) OR
		      @APP_DES = N'')
    END
ELSE
    BEGIN
	WHILE (@TMPPOS<=LEN(@APP_DES))
	BEGIN
		IF (SUBSTRING(@APP_DES,@TMPPOS,1) = N',')
	                 BEGIN
		            	SET @VTEM = LTRIM(RTRIM(SUBSTRING(@APP_DES,@STARTPOS,@TMPPOS-@STARTPOS)))                
				IF (@VTEM != N'')
				      BEGIN
					    IF (@VSTR != N'')
					     	 SET @VSTR=@VSTR+N','''+@VTEM+N''''
				  	    ELSE
			               	   	 SET @VSTR=N''''+@VTEM+N''''
				      END
		    		SET @TMPPOS = @TMPPOS +1
				SET @STARTPOS = @TMPPOS
	                END
		ELSE
	                   SET @TMPPOS = @TMPPOS +1			
	END
	SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@APP_DES,@STARTPOS,@TMPPOS-@STARTPOS)))
	IF (@LASTSTRING != N'')
		BEGIN
			IF (@VSTR=N'')
				SET @VSTR =@VSTR + N''''+ @LASTSTRING+N''''
			ELSE
				SET @VSTR =@VSTR +  N','''+@LASTSTRING+N''''
		END  
		SELECT TOP 1 
				@V_DATE = CONVERT(CHAR,G6_STAT_DD,101)
		FROM
		    GPROCESS
		WHERE
		    SERV_PROV_CODE = @CLIENTID AND		
		    B1_PER_ID1 = @PID1 AND		
		    B1_PER_ID2 = @PID2 AND		
		    B1_PER_ID3 = @PID3 AND
		    REC_STATUS=N'A' AND
		    UPPER(SD_PRO_DES) = UPPER(@PRO_DES) AND
	    	    ((@APP_DES <> N'' and CHARINDEX(UPPER(SD_APP_DES),UPPER(@VSTR))>0 ) OR
		      @APP_DES = N'')
	        ORDER BY REC_DATE DESC
   END
   RETURN @V_DATE
END
GO


ALTER FUNCTION [dbo].[FN_GET_USERNAME_BY_TITLE]( @CLIENTID NVARCHAR(15),
                                      @JobTitle  NVARCHAR(30),
                                      @NameFormat NVARCHAR(5)
                                      ) returns NVARCHAR(100) as
/*  Author           :   David Zheng
    Create Date      :   12/19/2005
    Version          :   AA6.1.1 MS SQL
    Detail           :   RETURNS: Name of the first user whose job title is {JobTitle}, in the format {NameFormat}.
			 ARGUMENTS: CLIENTID, JobTitle, NameFormat('FML'(default))
    Revision History : 	 12/19/2005  David Zheng Initial Design
                                           05/14/2007   Lucky Song Correct parameter character lengths  
*/
begin
declare 
	@VSTR NVARCHAR(100),
	@C_fname NVARCHAR(15),
	@C_mname NVARCHAR(15),
	@C_lname NVARCHAR(25)
  	SELECT TOP 1
  		@C_fname=GA_FNAME,  
	      	@C_lname=GA_LNAME, 
	      	@C_mname=GA_MNAME
  	FROM
  		G3STAFFS
  	WHERE
  		SERV_PROV_CODE =@CLIENTID AND
  		UPPER(GA_TITLE) = UPPER(@JobTitle) 
 BEGIN
 	IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
         END           
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
         END
      ELSE
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END 
         END   
 END
  return (@VSTR);
end
GO


ALTER FUNCTION [dbo].[FN_GET_VIOLATION_INFO](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5),
                                      @Get_Field NVARCHAR(400),
                                      @Format NVARCHAR(1),
                                      @Get_Seq_NBR INT
                                      ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sandy Yin
    Create Date      :   07/11/2005
    Version          :   AA5.3
    Detail           :   RETURNS: Information about violations for the Citation whose sequence number (not Citation #) is {CitationSeqNum}; if {CitationSeqNum} is not specified, returns information about all violations for the Case. If {Get_Field} is 'DESCRIPTION', returns all violation descriptions in the format {Format}; if {Get_Field} is 'CODE', returns all violation codes in the format {Format}.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, Get_Field ('DESCRIPTION' for violation description, 'CODE' for violation code), Format ('B' for Block (default), 'L' for comma-delimited Line), CitationSeqNum (optional)
    Revision History :   07/11/2005  sandy Yin Initial Design 
                                05/14/2007   Lucky Song Correct RETURN character lengths, and add codes to drop function before creating it                                
*/
BEGIN 
	DECLARE
		@TEM           NVARCHAR(4000),
		@C3_COM_TYP NVARCHAR(4000),
    		@C3_COMMENT NVARCHAR(4000),
		@Result        NVARCHAR(4000);
		set  @TEM=N'';
		set @Result =N'';
DECLARE my_cursor CURSOR FOR 
	SELECT
     		 C3_COM_TYP, 
    		 C3_COMMENT
	  FROM
	  	 C3CITNCMNT
	  WHERE
	  	((@Get_Seq_NBR <>N'' AND C3_CITATION_SEQ_NBR =@Get_Seq_NBR ) OR @Get_Seq_NBR =N'') AND    
	  	B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID 
OPEN my_cursor
FETCH NEXT FROM my_cursor INTO  @C3_COM_TYP,@C3_COMMENT 
 IF UPPER(@Get_Field)=N'CODE'  
   	SET 	@TEM= @C3_COM_TYP
  ELSE IF UPPER(@Get_Field)=N'DESCRIPTION'  
	SET 	@TEM=@C3_COMMENT
WHILE @@FETCH_STATUS = 0
BEGIN
	  IF (@Result  =N'')
	  begin
	    IF (@TEM<>N'' )
	      SET @Result =@Result + @TEM;
	  end 
	  else
	  BEGIN
	   IF @Format =N'B'
	    BEGIN
	     IF (@TEM <>N'' )
		 SET @Result = @Result+CHAR(10)+@TEM;  
            END
            ELSE IF @Format=N'L' 
            BEGIN
	     IF (@TEM <>N'' )
		 SET @Result = @Result+N', '+@TEM;  
            END
          END
              FETCH NEXT FROM my_cursor INTO @C3_COM_TYP,@C3_COMMENT 
          IF UPPER(@Get_Field)=N'CODE'  
   	    SET 	@TEM= @C3_COM_TYP
          ELSE IF UPPER(@Get_Field)=N'DESCRIPTION'  
	    SET 	@TEM=@C3_COMMENT
	END;
CLOSE my_cursor;
DEALLOCATE my_cursor;
return(@Result); 			
END
GO


ALTER FUNCTION [dbo].[FN_GET_WORKDAYS](@YM NVARCHAR(50)) RETURNS INT AS
/*  Author           :   Glory Wang
    Create Date      :   12/28/2004
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Number of working days for in the month of {Year-Month}.
    ARGUMENTS        :   Year-Month (in the format YYYY-MM).
    Revision History :   12/28/2004  Glory Wang		Initial
			 01/13/2005  Larry Cooper	Add code to drop function before creating it.
			 09/22/2005  Lydia Lim		Edit comment
*/
BEGIN
DECLARE 
  @DT_BEGIN DATETIME,
  @DT_END DATETIME ,
  @RE INT ,@I INT
SET @RE=0
SET @I=0
SELECT @DT_BEGIN=@YM+N'-01',
     @DT_END=DATEADD(MONTH,1,@DT_BEGIN)-1
SELECT @I=DATEDIFF(DAY,@DT_BEGIN,@DT_END)+1
WHILE @DT_BEGIN<=@DT_END
SELECT @RE=CASE WHEN DATEPART(WEEKDAY,@DT_BEGIN) IN(1,7)
                THEN @RE+1 
                ELSE @RE END,
       @DT_BEGIN=@DT_BEGIN+1
RETURN(@I-@RE)
END
GO


ALTER FUNCTION [dbo].[FN_IS_CONDITIONS_MET](@CLIENTID  NVARCHAR(15),
                                          @ID1   NVARCHAR(5),
                                          @ID2   NVARCHAR(5),
                                          @ID3   NVARCHAR(5),
					  @STATUS  NVARCHAR(100)
					    ) RETURNS NVARCHAR(5) as
/*  Author           :   Sandy Yin 
    Create Date      :   02/08/2007
    Version          :   AA6.4 MS SQL
    Detail           :   Returns: 'Y' if all conditions on the application have the status of {ConditionStatus} or if the application has no conditions. Returns 'N' if any condition on the application does not have the status of {ConditionStatus}. 
                    	 Arguments: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ConditionStatus.
    Revision History :   02/08/2007  Sandy Yin  Create function by modifying Oracle version of function (07SSP-00068)
                         05/10/2007 Rainy Yu change CLIENTID VARCHAR(10) into VARCHAR(15)
*/
Begin
declare
   @VNUM int,
   @VSTATUSNUM int,
   @VCHR NVARCHAR(5);
   SET  @VNUM=0;
   SET  @VSTATUSNUM=0;
   SET  @VCHR=N'Y';
   SELECT 
     @VNUM= COUNT(B1_CON_NBR) ,
     @VSTATUSNUM =SUM(case when UPPER(B1_CON_STATUS)=UPPER(@STATUS) then 1 else 0 end )
   FROM 
     B6CONDIT
   WHERE 
     SERV_PROV_CODE=@CLIENTID AND
     B1_PER_ID1=@ID1 AND 
     B1_PER_ID2=@ID2 AND
     B1_PER_ID3=@ID3 AND
     REC_STATUS=N'A'
   IF @VNUM=0 OR @VNUM=@VSTATUSNUM 
	 SET  @VCHR= N'Y';
   ELSE 
	 SET  @VCHR= N'N';
   RETURN(@VCHR);
END
GO



/*
-- Name of UDF: NEW_TIME (D Timestamp, Z1 Varchar(3), Z2 Varchar(3))
--
-- Description: Convert time of timezone Z1 to timezone Z2.
--              Z1 and Z2 must be following strings.
--
--              AST, ADT: Atlantic standard time and Atlantic daylight time
--              BST, BDT: Bering standard time and Bering daylight time
--              CST, CDT: Central standard time and Central daylight time
--              EST, EDT: Eastern standard time and Eastern daylight time
--              GMT:      Greenwich mean time
--              HST, HDT: Hawaiian standard time and Hawaiian daylight time
--              MST, MDT: Mountain standard time and Mountain daylight time
--              NST:      Newfoundland standard time
--              PST, PDT: Pacific standard time and Pacific daylight time
--              YST, YDT: Yukon standard time and Yukon daylight time
--
	Revision History:
	11/07/2003	Ken Wen		Initial design
*/
ALTER FUNCTION [dbo].[new_time](@D datetime, @Z1 NVARCHAR(3), @Z2 NVARCHAR(3))
 RETURNS datetime
 AS 
 BEGIN
 	DECLARE @rtnValue datetime 	
  	SET @rtnValue=DATEADD(hour,
	(
          CASE UPPER(@Z2)
          WHEN N'AST' THEN -4
          WHEN N'ADT' THEN -3
          WHEN N'BST' THEN -11
          WHEN N'BDT' THEN -10
          WHEN N'CST' THEN -6
          WHEN N'CDT' THEN -5
          WHEN N'EST' THEN -3
          WHEN N'EDT' THEN -2
          WHEN N'GMT' THEN  0
          WHEN N'HST' THEN -10
          WHEN N'HDT' THEN -9
          WHEN N'MST' THEN -7
          WHEN N'MDT' THEN -6
          WHEN N'NST' THEN -3.3
          WHEN N'PST' THEN -8
          WHEN N'PDT' THEN -7
          WHEN N'YST' THEN -9
          WHEN N'YDT' THEN -8
          ELSE null
          END )-(CASE UPPER(@Z1)
          WHEN N'AST' THEN -4
          WHEN N'ADT' THEN -3
          WHEN N'BST' THEN -11
          WHEN N'BDT' THEN -10
          WHEN N'CST' THEN -6
          WHEN N'CDT' THEN -5
          WHEN N'EST' THEN -3
          WHEN N'EDT' THEN -2
          WHEN N'GMT' THEN  0
          WHEN N'HST' THEN -10
          WHEN N'HDT' THEN -9
          WHEN N'MST' THEN -7
          WHEN N'MDT' THEN -6
          WHEN N'NST' THEN -3.3
          WHEN N'PST' THEN -8
          WHEN N'PDT' THEN -7
          WHEN N'YST' THEN -9
          WHEN N'YDT' THEN -8
          ELSE null
          END
        ),@D)
  RETURN @rtnValue
END
GO

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_B3APO_ATTRIBUTE] (
    [SERV_PROV_CODE]               NVARCHAR (15)  NOT NULL,
    [B1_PER_ID1]                   NVARCHAR (5)   NOT NULL,
    [B1_PER_ID2]                   NVARCHAR (5)   NOT NULL,
    [B1_PER_ID3]                   NVARCHAR (5)   NOT NULL,
    [B1_APO_NBR]                   NVARCHAR (24)  NOT NULL,
    [B1_APO_TYPE]                  NVARCHAR (30)  NOT NULL,
    [B1_ATTRIBUTE_NAME]            NVARCHAR (70)  NOT NULL,
    [B1_ATTRIBUTE_VALUE]           NVARCHAR (200) NULL,
    [B1_ATTRIBUTE_UNIT_TYPE]       NVARCHAR (10)  NULL,
    [B1_ATTRIBUTE_VALUE_DATA_TYPE] NVARCHAR (30)  NULL,
    [B1_ATTRIBUTE_VALUE_REQ_FLAG]  NVARCHAR (1)   NULL,
    [B1_DISP_ORDER]                BIGINT         NULL,
    [REC_DATE]                     DATETIME       NOT NULL,
    [REC_FUL_NAM]                  NVARCHAR (70)  NOT NULL,
    [REC_STATUS]                   NVARCHAR (1)   NULL,
    [VCH_DISP_FLAG]                NVARCHAR (1)   NULL,
    [VALUE_TO_DATE]                AS             (CASE [DBO].[FN_IS_DATE]([B1_ATTRIBUTE_VALUE]) WHEN (1) THEN CASE [B1_ATTRIBUTE_VALUE_DATA_TYPE] WHEN N'DATE' THEN CONVERT (DATETIME, [B1_ATTRIBUTE_VALUE], (101)) END END),
    [VALUE_TO_NUM]                 AS             (CASE [DBO].[FN_IS_NUMERIC]([B1_ATTRIBUTE_VALUE]) WHEN (1) THEN CASE [B1_ATTRIBUTE_VALUE_DATA_TYPE] WHEN N'NUMBER' THEN CONVERT (NUMERIC (38, 6), [B1_ATTRIBUTE_VALUE]) END END),
    CONSTRAINT [tmp_ms_xx_constraint_B3APO_ATTRIBUTE_PK1] PRIMARY KEY CLUSTERED ([SERV_PROV_CODE] ASC, [B1_PER_ID1] ASC, [B1_PER_ID2] ASC, [B1_PER_ID3] ASC, [B1_APO_NBR] ASC, [B1_APO_TYPE] ASC, [B1_ATTRIBUTE_NAME] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[B3APO_ATTRIBUTE])
    BEGIN
        INSERT INTO [dbo].[tmp_ms_xx_B3APO_ATTRIBUTE] ([SERV_PROV_CODE], [B1_PER_ID1], [B1_PER_ID2], [B1_PER_ID3], [B1_APO_NBR], [B1_APO_TYPE], [B1_ATTRIBUTE_NAME], [B1_ATTRIBUTE_VALUE], [B1_ATTRIBUTE_UNIT_TYPE], [B1_ATTRIBUTE_VALUE_DATA_TYPE], [B1_ATTRIBUTE_VALUE_REQ_FLAG], [B1_DISP_ORDER], [REC_DATE], [REC_FUL_NAM], [REC_STATUS], [VCH_DISP_FLAG])
        SELECT   [SERV_PROV_CODE],
                 [B1_PER_ID1],
                 [B1_PER_ID2],
                 [B1_PER_ID3],
                 [B1_APO_NBR],
                 [B1_APO_TYPE],
                 [B1_ATTRIBUTE_NAME],
                 [B1_ATTRIBUTE_VALUE],
                 [B1_ATTRIBUTE_UNIT_TYPE],
                 [B1_ATTRIBUTE_VALUE_DATA_TYPE],
                 [B1_ATTRIBUTE_VALUE_REQ_FLAG],
                 [B1_DISP_ORDER],
                 [REC_DATE],
                 [REC_FUL_NAM],
                 [REC_STATUS],
                 [VCH_DISP_FLAG]
        FROM     [dbo].[B3APO_ATTRIBUTE]
        ORDER BY [SERV_PROV_CODE] ASC, [B1_PER_ID1] ASC, [B1_PER_ID2] ASC, [B1_PER_ID3] ASC, [B1_APO_NBR] ASC, [B1_APO_TYPE] ASC, [B1_ATTRIBUTE_NAME] ASC;
    END

DROP TABLE [dbo].[B3APO_ATTRIBUTE];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_B3APO_ATTRIBUTE]', N'B3APO_ATTRIBUTE';

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_constraint_B3APO_ATTRIBUTE_PK1]', N'B3APO_ATTRIBUTE_PK', N'OBJECT';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO

CREATE NONCLUSTERED INDEX [B3APO_ATTRIBUTE_DATE_IX]
    ON [dbo].[B3APO_ATTRIBUTE]([SERV_PROV_CODE] ASC, [B1_APO_TYPE] ASC, [B1_ATTRIBUTE_NAME] ASC, [VALUE_TO_DATE] ASC);


GO

CREATE NONCLUSTERED INDEX [B3APO_ATTRIBUTE_NUM_IX]
    ON [dbo].[B3APO_ATTRIBUTE]([SERV_PROV_CODE] ASC, [B1_APO_TYPE] ASC, [B1_ATTRIBUTE_NAME] ASC, [VALUE_TO_NUM] ASC);


GO

CREATE NONCLUSTERED INDEX [B3APO_ATTRIBUTE_FIELD_IX]
    ON [dbo].[B3APO_ATTRIBUTE]([SERV_PROV_CODE] ASC, [B1_PER_ID1] ASC, [B1_PER_ID2] ASC, [B1_PER_ID3] ASC, [B1_APO_TYPE] ASC, [B1_ATTRIBUTE_NAME] ASC, [B1_ATTRIBUTE_VALUE] ASC);


GO


ALTER VIEW [dbo].[V_APO_ADDRESS_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + CONVERT(NVARCHAR, A.B1_APO_NBR) AS ID,
       N'ADDRESS_TEMPLATE' AS ENTITY,
       A.B1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.B1_ATTRIBUTE_VALUE AS VALUE
  FROM B3APO_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A' AND A.B1_APO_TYPE=N'ADDRESS'
)
GO


ALTER VIEW [dbo].[V_APO_OWNER_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 +  N'/' + CONVERT(NVARCHAR, A.B1_APO_NBR) AS ID,
       N'OWNER_TEMPLATE' AS ENTITY,
       A.B1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.B1_ATTRIBUTE_VALUE AS VALUE
  FROM B3APO_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A' AND A.B1_APO_TYPE=N'OWNER'
)
GO


ALTER VIEW [dbo].[V_APO_PARCEL_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + CONVERT(NVARCHAR, A.B1_APO_NBR) AS ID,
       N'PARCEL_TEMPLATE' AS ENTITY,
       A.B1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.B1_ATTRIBUTE_VALUE AS VALUE
  FROM B3APO_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A' AND A.B1_APO_TYPE=N'PARCEL'
)
GO

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_BCHCKBOX] (
    [SERV_PROV_CODE]               NVARCHAR (15)   NOT NULL,
    [B1_PER_ID1]                   NVARCHAR (5)    NOT NULL,
    [B1_PER_ID2]                   NVARCHAR (5)    NOT NULL,
    [B1_PER_ID3]                   NVARCHAR (5)    NOT NULL,
    [B1_PER_TYPE]                  NVARCHAR (30)   NOT NULL,
    [B1_PER_SUB_TYPE]              NVARCHAR (30)   NOT NULL,
    [B1_CHECKBOX_TYPE]             NVARCHAR (30)   NOT NULL,
    [B1_CHECKBOX_DESC]             NVARCHAR (100)  NOT NULL,
    [B1_CHECKBOX_IND]              NVARCHAR (1)    NULL,
    [B1_ACT_STATUS]                NVARCHAR (12)   NULL,
    [B1_START_DATE]                DATETIME        NULL,
    [B1_END_DATE]                  DATETIME        NULL,
    [B1_CHECKLIST_COMMENT]         NVARCHAR (4000) NULL,
    [REC_DATE]                     DATETIME        NOT NULL,
    [REC_FUL_NAM]                  NVARCHAR (70)   NOT NULL,
    [REC_STATUS]                   NVARCHAR (1)    NULL,
    [B1_DISPLAY_ORDER]             BIGINT          NOT NULL,
    [B1_FEE_INDICATOR]             NVARCHAR (30)   NULL,
    [B1_ATTRIBUTE_VALUE]           NVARCHAR (200)  NULL,
    [B1_ATTRIBUTE_UNIT_TYPE]       NVARCHAR (10)   NULL,
    [B1_ATTRIBUTE_VALUE_REQ_FLAG]  NVARCHAR (1)    NULL,
    [B1_VALIDATION_SCRIPT_NAME]    NVARCHAR (70)   NULL,
    [RELATION_SEQ_ID]              BIGINT          NOT NULL,
    [SD_STP_NUM]                   INT             NOT NULL,
    [B1_CHECKBOX_GROUP]            NVARCHAR (30)   NOT NULL,
    [MAX_LENGTH]                   SMALLINT        NULL,
    [DISPLAY_LENGTH]               SMALLINT        NULL,
    [B1_DEFAULT_SELECTED]          NVARCHAR (1)    NULL,
    [B1_GROUP_DISPLAY_ORDER]       INT             NULL,
    [VCH_DISP_FLAG]                NVARCHAR (1)    NULL,
    [R1_TASK_STATUS_REQ_FLAG]      NVARCHAR (10)   NULL,
    [B1_REQ_FEE_CALC]              NVARCHAR (1)    NULL,
    [B1_SUPERVISOR_EDIT_ONLY_FLAG] NVARCHAR (1)    NULL,
    [B1_ALIGNMENT]                 NVARCHAR (1)    NULL,
    [B1_CHECKBOX_CODE2]            NVARCHAR (12)   NULL,
    [B1_CHECKBOX_DESC_ALT]         NVARCHAR (900)  NULL,
    [B1_CHECKBOX_DESC_ALIAS]       NVARCHAR (100)  NULL,
    [VALUE_TO_DATE]                AS              (CASE [DBO].[FN_IS_DATE]([B1_CHECKLIST_COMMENT]) WHEN (1) THEN CASE [B1_CHECKBOX_IND] WHEN N'2' THEN CONVERT (DATETIME, [B1_CHECKLIST_COMMENT], (101)) END END),
    [VALUE_TO_NUM]                 AS              (CASE [DBO].[FN_IS_NUMERIC]([B1_CHECKLIST_COMMENT]) WHEN (1) THEN CASE [B1_CHECKBOX_IND] WHEN N'4' THEN CONVERT (NUMERIC (38, 6), [B1_CHECKLIST_COMMENT]) END END),
    CONSTRAINT [tmp_ms_xx_constraint_BCHCKBOX_PK1] PRIMARY KEY CLUSTERED ([SERV_PROV_CODE] ASC, [B1_PER_ID1] ASC, [B1_PER_ID2] ASC, [B1_PER_ID3] ASC, [B1_CHECKBOX_TYPE] ASC, [B1_CHECKBOX_DESC] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[BCHCKBOX])
    BEGIN
        INSERT INTO [dbo].[tmp_ms_xx_BCHCKBOX] ([SERV_PROV_CODE], [B1_PER_ID1], [B1_PER_ID2], [B1_PER_ID3], [B1_CHECKBOX_TYPE], [B1_CHECKBOX_DESC], [B1_PER_TYPE], [B1_PER_SUB_TYPE], [B1_CHECKBOX_IND], [B1_ACT_STATUS], [B1_START_DATE], [B1_END_DATE], [B1_CHECKLIST_COMMENT], [REC_DATE], [REC_FUL_NAM], [REC_STATUS], [B1_DISPLAY_ORDER], [B1_FEE_INDICATOR], [B1_ATTRIBUTE_VALUE], [B1_ATTRIBUTE_UNIT_TYPE], [B1_ATTRIBUTE_VALUE_REQ_FLAG], [B1_VALIDATION_SCRIPT_NAME], [RELATION_SEQ_ID], [SD_STP_NUM], [B1_CHECKBOX_GROUP], [MAX_LENGTH], [DISPLAY_LENGTH], [B1_DEFAULT_SELECTED], [B1_GROUP_DISPLAY_ORDER], [VCH_DISP_FLAG], [R1_TASK_STATUS_REQ_FLAG], [B1_REQ_FEE_CALC], [B1_SUPERVISOR_EDIT_ONLY_FLAG], [B1_ALIGNMENT], [B1_CHECKBOX_CODE2], [B1_CHECKBOX_DESC_ALT], [B1_CHECKBOX_DESC_ALIAS])
        SELECT   [SERV_PROV_CODE],
                 [B1_PER_ID1],
                 [B1_PER_ID2],
                 [B1_PER_ID3],
                 [B1_CHECKBOX_TYPE],
                 [B1_CHECKBOX_DESC],
                 [B1_PER_TYPE],
                 [B1_PER_SUB_TYPE],
                 [B1_CHECKBOX_IND],
                 [B1_ACT_STATUS],
                 [B1_START_DATE],
                 [B1_END_DATE],
                 [B1_CHECKLIST_COMMENT],
                 [REC_DATE],
                 [REC_FUL_NAM],
                 [REC_STATUS],
                 [B1_DISPLAY_ORDER],
                 [B1_FEE_INDICATOR],
                 [B1_ATTRIBUTE_VALUE],
                 [B1_ATTRIBUTE_UNIT_TYPE],
                 [B1_ATTRIBUTE_VALUE_REQ_FLAG],
                 [B1_VALIDATION_SCRIPT_NAME],
                 [RELATION_SEQ_ID],
                 [SD_STP_NUM],
                 [B1_CHECKBOX_GROUP],
                 [MAX_LENGTH],
                 [DISPLAY_LENGTH],
                 [B1_DEFAULT_SELECTED],
                 [B1_GROUP_DISPLAY_ORDER],
                 [VCH_DISP_FLAG],
                 [R1_TASK_STATUS_REQ_FLAG],
                 [B1_REQ_FEE_CALC],
                 [B1_SUPERVISOR_EDIT_ONLY_FLAG],
                 [B1_ALIGNMENT],
                 [B1_CHECKBOX_CODE2],
                 [B1_CHECKBOX_DESC_ALT],
                 [B1_CHECKBOX_DESC_ALIAS]
        FROM     [dbo].[BCHCKBOX]
        ORDER BY [SERV_PROV_CODE] ASC, [B1_PER_ID1] ASC, [B1_PER_ID2] ASC, [B1_PER_ID3] ASC, [B1_CHECKBOX_TYPE] ASC, [B1_CHECKBOX_DESC] ASC;
    END

DROP TABLE [dbo].[BCHCKBOX];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_BCHCKBOX]', N'BCHCKBOX';

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_constraint_BCHCKBOX_PK1]', N'BCHCKBOX_PK', N'OBJECT';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO

CREATE NONCLUSTERED INDEX [BCHCKBOX_DATE_IX]
    ON [dbo].[BCHCKBOX]([SERV_PROV_CODE] ASC, [B1_CHECKBOX_TYPE] ASC, [B1_CHECKBOX_DESC] ASC, [B1_CHECKBOX_IND] ASC, [VALUE_TO_DATE] ASC);


GO

CREATE NONCLUSTERED INDEX [BCHCKBOX_NUM_IX]
    ON [dbo].[BCHCKBOX]([SERV_PROV_CODE] ASC, [B1_CHECKBOX_TYPE] ASC, [B1_CHECKBOX_DESC] ASC, [B1_CHECKBOX_IND] ASC, [VALUE_TO_NUM] ASC);


GO

CREATE NONCLUSTERED INDEX [BCHCKBOX_ACT_STATUS_IX]
    ON [dbo].[BCHCKBOX]([SERV_PROV_CODE] ASC, [B1_ACT_STATUS] ASC);


GO

CREATE NONCLUSTERED INDEX [BCHCKBOX_FIELD_IX]
    ON [dbo].[BCHCKBOX]([SERV_PROV_CODE] ASC, [B1_CHECKBOX_DESC] ASC, [B1_CHECKBOX_TYPE] ASC)
    INCLUDE([B1_CHECKLIST_COMMENT]);


GO

CREATE NONCLUSTERED INDEX [BCHCKBOX_TYPE_IX]
    ON [dbo].[BCHCKBOX]([SERV_PROV_CODE] ASC, [B1_CHECKBOX_TYPE] ASC, [B1_ACT_STATUS] ASC);


GO

BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_L3APO_ATTRIBUTE] (
    [SOURCE_SEQ_NBR]               BIGINT         NOT NULL,
    [L1_APO_NBR]                   NVARCHAR (24)  NOT NULL,
    [L1_APO_TYPE]                  NVARCHAR (30)  NOT NULL,
    [L1_ATTRIBUTE_NAME]            NVARCHAR (70)  NOT NULL,
    [L1_ATTRIBUTE_VALUE]           NVARCHAR (200) NULL,
    [L1_ATTRIBUTE_UNIT_TYPE]       NVARCHAR (20)  NULL,
    [L1_ATTRIBUTE_VALUE_DATA_TYPE] NVARCHAR (30)  NULL,
    [L1_ATTRIBUTE_VALUE_REQ_FLAG]  NVARCHAR (1)   NULL,
    [L1_DISP_ORDER]                BIGINT         NULL,
    [REC_DATE]                     DATETIME       NOT NULL,
    [REC_FUL_NAM]                  NVARCHAR (70)  NOT NULL,
    [REC_STATUS]                   NVARCHAR (1)   NULL,
    [VCH_DISP_FLAG]                NVARCHAR (1)   NULL,
    [VALUE_TO_DATE]                AS             (CASE [DBO].[FN_IS_DATE]([L1_ATTRIBUTE_VALUE]) WHEN (1) THEN CASE [L1_ATTRIBUTE_VALUE_DATA_TYPE] WHEN N'DATE' THEN CONVERT (DATETIME, [L1_ATTRIBUTE_VALUE], (101)) END END),
    [VALUE_TO_NUM]                 AS             (CASE [DBO].[FN_IS_NUMERIC]([L1_ATTRIBUTE_VALUE]) WHEN (1) THEN CASE [L1_ATTRIBUTE_VALUE_DATA_TYPE] WHEN N'NUMBER' THEN CONVERT (NUMERIC (38, 6), [L1_ATTRIBUTE_VALUE]) END END),
    CONSTRAINT [tmp_ms_xx_constraint_L3APO_ATTRIBUTE_PK1] PRIMARY KEY CLUSTERED ([SOURCE_SEQ_NBR] ASC, [L1_APO_NBR] ASC, [L1_APO_TYPE] ASC, [L1_ATTRIBUTE_NAME] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[L3APO_ATTRIBUTE])
    BEGIN
        INSERT INTO [dbo].[tmp_ms_xx_L3APO_ATTRIBUTE] ([SOURCE_SEQ_NBR], [L1_APO_NBR], [L1_APO_TYPE], [L1_ATTRIBUTE_NAME], [L1_ATTRIBUTE_VALUE], [L1_ATTRIBUTE_UNIT_TYPE], [L1_ATTRIBUTE_VALUE_DATA_TYPE], [L1_ATTRIBUTE_VALUE_REQ_FLAG], [L1_DISP_ORDER], [REC_DATE], [REC_FUL_NAM], [REC_STATUS], [VCH_DISP_FLAG])
        SELECT   [SOURCE_SEQ_NBR],
                 [L1_APO_NBR],
                 [L1_APO_TYPE],
                 [L1_ATTRIBUTE_NAME],
                 [L1_ATTRIBUTE_VALUE],
                 [L1_ATTRIBUTE_UNIT_TYPE],
                 [L1_ATTRIBUTE_VALUE_DATA_TYPE],
                 [L1_ATTRIBUTE_VALUE_REQ_FLAG],
                 [L1_DISP_ORDER],
                 [REC_DATE],
                 [REC_FUL_NAM],
                 [REC_STATUS],
                 [VCH_DISP_FLAG]
        FROM     [dbo].[L3APO_ATTRIBUTE]
        ORDER BY [SOURCE_SEQ_NBR] ASC, [L1_APO_NBR] ASC, [L1_APO_TYPE] ASC, [L1_ATTRIBUTE_NAME] ASC;
    END

DROP TABLE [dbo].[L3APO_ATTRIBUTE];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_L3APO_ATTRIBUTE]', N'L3APO_ATTRIBUTE';

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_constraint_L3APO_ATTRIBUTE_PK1]', N'L3APO_ATTRIBUTE_PK', N'OBJECT';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO

CREATE NONCLUSTERED INDEX [L3APO_ATTRIBUTE_DATE_IX]
    ON [dbo].[L3APO_ATTRIBUTE]([SOURCE_SEQ_NBR] ASC, [L1_APO_TYPE] ASC, [L1_ATTRIBUTE_NAME] ASC, [VALUE_TO_DATE] ASC);


GO

CREATE NONCLUSTERED INDEX [L3APO_ATTRIBUTE_NUM_IX]
    ON [dbo].[L3APO_ATTRIBUTE]([SOURCE_SEQ_NBR] ASC, [L1_APO_TYPE] ASC, [L1_ATTRIBUTE_NAME] ASC, [VALUE_TO_NUM] ASC);


GO

CREATE NONCLUSTERED INDEX [L3APO_ATTRIBUTE_FIELD_IX]
    ON [dbo].[L3APO_ATTRIBUTE]([SOURCE_SEQ_NBR] ASC, [L1_APO_TYPE] ASC, [L1_ATTRIBUTE_NAME] ASC, [L1_ATTRIBUTE_VALUE] ASC);


GO

ALTER TABLE [dbo].[L3APO_ATTRIBUTE] WITH NOCHECK
    ADD CONSTRAINT [L3APO_ATTRIBUTE$RAPO_SOURCE_FK] FOREIGN KEY ([SOURCE_SEQ_NBR]) REFERENCES [dbo].[RAPO_SOURCE] ([SOURCE_SEQ_NBR]);


GO


ALTER VIEW [dbo].[V_REF_PARCEL_TEMPLATE_DATA] 
AS
SELECT B.SERV_PROV_CODE AS AGENCY_ID,
       CONVERT(NVARCHAR, A.L1_APO_NBR) AS ID,
       N'PARCEL_REF_TEMPLATE' AS ENTITY,
       A.L1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.L1_ATTRIBUTE_VALUE AS VALUE
  FROM L3APO_ATTRIBUTE A
 INNER JOIN RSERV_PROV B ON A.SOURCE_SEQ_NBR = B.APO_SRC_SEQ_NBR
 WHERE A.REC_STATUS = N'A'
   AND A.L1_APO_TYPE=N'PARCEL'
GO


--Functions

ALTER FUNCTION [dbo].[FN_GET_ADDRESS_ATTRIBUTE](  @CLIENTID NVARCHAR(15),
                                        @PID1  NVARCHAR(5),
                                        @PID2  NVARCHAR(5),
                                        @PID3  NVARCHAR(5),
					@NBR  NVARCHAR(30),
                                        @INFO_LABEL NVARCHAR(120)  
                                                   ) RETURNS NVARCHAR (500) as
/*  Author           :   Sandy Yin
    Create Date      :   09/11/2006
    Version          :   AA6.1.3 MSSQL
    Detail           :   RETURNS:   Value of custom attribute {addressAttribute} for the application address whose address number {AddressNbr}.  If {AddressNbr} is not specified, selects the first address found.  Returns Null if no such attribute is found.  Note that {addressAttribute} is the attribute NAME, not the attribute label.
                         ARGUMENTS: ClientID,
                                    PrimaryTrackingID1,
                                    PrimaryTrackingID2,
                                    PrimaryTrackingID3,
                                    AddressNbr (optional),
                                    AddressAttribute (case insensitive).
    Revision History :   08/05/2006 Sandy Yin  Create function by modifying Oracle version of function.
*/
BEGIN
DECLARE @TEM NVARCHAR(250)
 SELECT TOP 1   @TEM=B1_ATTRIBUTE_VALUE 
 FROM
  B3APO_ATTRIBUTE
 WHERE
  B1_PER_ID1 = @PID1 AND
  B1_PER_ID2 = @PID2 AND
  B1_PER_ID3 = @PID3 AND
  REC_STATUS = N'A' AND
  SERV_PROV_CODE = @CLIENTID AND
   B1_APO_TYPE  =N'ADDRESS' AND
   B1_ATTRIBUTE_NAME= UPPER(@INFO_LABEL) AND
   ((COALESCE(@NBR,N'')<>N'' AND B1_APO_NBR = @NBR) OR COALESCE(@NBR,N'')=N'')
 RETURN (@TEM)
END
GO


ALTER FUNCTION [dbo].[FN_GET_APP_SPEC_INFO](@CLIENTID  NVARCHAR(15),
 				                               @PID1    NVARCHAR(5),
                                       @PID2    NVARCHAR(5),
                                       @PID3   NVARCHAR(5),
                                       @info_label  NVARCHAR(250)
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author           :   Sandy Yin
    Create Date      :   11/29/2004
    Version          :   AA5.3 MSSQL
    Detail           :   RETURNS: Value in Application Specific Info field whose label is like {ChecklistDescription}; Null if the field is not found.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ChecklistDescription (can use % wildcard).
    Revision History :   07/12/2005  sandy Yin reivsed like.
                         08/24/2005 Glory Wang  Change logic per AA 6.1 changes
*/
BEGIN 
	DECLARE
		@TEM        NVARCHAR(250);
	  SET @TEM = N'';
	SELECT
		TOP 1 @TEM = ISNULL(B1_CHECKLIST_COMMENT,N'')     
	FROM
		BCHCKBOX
	WHERE
		B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID AND
		BCHCKBOX.B1_CHECKBOX_GROUP = N'APPLICATION' AND
		UPPER(B1_CHECKBOX_DESC) LIKE UPPER(@info_label) ;
	RETURN(@TEM);
END
GO


ALTER FUNCTION [dbo].[FN_GET_APP_SPEC_INFO_BYGROUP](@CLIENTID  NVARCHAR(15),
 				       @PID1    NVARCHAR(5),
                                       @PID2    NVARCHAR(5),
                                       @PID3   NVARCHAR(5),
				       @info_type   NVARCHAR(100),
                                       @info_label  NVARCHAR(250)
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author          :   Ava Wu
    Create Date     :   03/23/2006
    Version         :   AA6.1.3 MSSQL
    Detail          :   RETURNS: Value in Application Specific Info field whose group name is like {ChecklistTypeLevel} and label is like {ChecklistDescription}; Null if the field is not found.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ChecklistTypeLevel (wildcard % may be used), ChecklistDescription (wildcard % may be used).
    Revision History:   03/23/2006 Ava Wu Initial Design, based on FN_GET_APP_SPEC_INFO.SQL Oracle version.
*/
BEGIN 
	DECLARE
		@TEM        NVARCHAR(250);
	  SET @TEM = N'';
	SELECT
		TOP 1 @TEM = ISNULL(B1_CHECKLIST_COMMENT,N'')     
	FROM
		BCHCKBOX
	WHERE
		B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID AND
		UPPER(B1_CHECKBOX_GROUP) = N'APPLICATION' AND
		UPPER(B1_CHECKBOX_TYPE) like UPPER(@info_type) AND
		UPPER(B1_CHECKBOX_DESC) LIKE UPPER(@info_label) ;
	RETURN(@TEM);
END
GO


ALTER FUNCTION [dbo].[FN_GET_APP_SPEC_INFO_LLIKE](@CLIENTID  NVARCHAR(15),
 				      @PID1    NVARCHAR(5),
                                      @PID2    NVARCHAR(5),
                                      @PID3   NVARCHAR(5),
                                      @info_label  NVARCHAR(250)
                                      ) RETURNS NVARCHAR (500)  AS
/*  Author            :   Lucky Song
    Create Date       :   12/30/2004
    Version           :   AA6.0
    Detail            :   RETURNS: Value in Application Specific Info field whose label like {ChecklistDescription%}; '' if the field is not found.
    ARGUMENTS         :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ChecklistDescription.
    Revision History :
*/
BEGIN 
	DECLARE
		@TEM        NVARCHAR(250);		
		set  @TEM=N'';	
	SELECT
		TOP 1 @TEM = ISNULL(B1_CHECKLIST_COMMENT,N'')     
	FROM
		BCHCKBOX
	WHERE
		B1_PER_ID1 = @PID1 AND
		B1_PER_ID2 = @PID2 AND
		B1_PER_ID3 = @PID3 AND
		REC_STATUS = N'A' AND
		SERV_PROV_CODE = @CLIENTID AND
		BCHCKBOX.B1_CHECKBOX_GROUP = N'APPLICATION' AND
		UPPER(B1_CHECKBOX_DESC) LIKE UPPER(@info_label)+N'%'  
	        RETURN(@TEM);
END
GO


ALTER FUNCTION [dbo].[FN_GET_COMPLAINT_ADDRESS] (@CLIENTID  NVARCHAR(15),
 				      	    @PID1    NVARCHAR(5),
 				      	    @PID2    NVARCHAR(5),
 				      	    @PID3   NVARCHAR(5),
 				      	    @GET_FIELD NVARCHAR(20),
					    @CASE NVARCHAR(1)
 				      	    ) RETURNS NVARCHAR (200)  AS
/*  Author           :   David Zheng
    Create Date      :   05/19/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Reported Address on the Complaint. If {GET_FIELD} is 'FULLADDR_LINE', returns full address in block format; If {GET_FIELD} is 'FULLADDR_LINEA', returns full address in Line format;if {GET_FIELD} is 'PARTADDR_LINE', returns address in line format without city, state and zip. If {Case} is 'U', return value is in UPPERCASE; if {Case} is 'I', return value is in Initial Capitals; iF {cASE} is not specified in arguments, return value is in original case.
                         ARGUMENTS: @CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, Get_Field (Options:'FULLADDR_LINE','PARTADDR_LINE'), Case ('U' for uppercase, 'I' for initial-caps, blank for original case).
    Revision History :   05/19/2005  David Zheng Initial Design
                         08/03/2005  Cece Wang changed  @C_city VARCHAR(10) to @C_city VARCHAR(30)
                         10/12/2005  Jack Wang Added FULLADDR_LINEA condition.
                         11/29/2005  Lydia Lim Added code to drop function if exists
                         07/25/2006  Sandy Yin Add PART_ADDR_BLOCK to get address exclude address3(SAN:06SSP-000140)
*/
BEGIN 
DECLARE 
  @VSTR NVARCHAR(200),
  @C_addr1 NVARCHAR(40),
  @C_addr2 NVARCHAR(40),
  @C_addr3 NVARCHAR(40),
  @C_city NVARCHAR(30),
  @C_state NVARCHAR(2),
  @C_zip NVARCHAR(10),
  @CSZ NVARCHAR(50)
    BEGIN
      SELECT TOP 1 
        @C_addr1 = C3_VIOLATION_ADDRESS1,         
        @C_addr2 = C3_VIOLATION_ADDRESS2, 
        @C_addr3 = C3_VIOLATION_ADDRESS3, 
        @C_city =  C3_VIOLATION_CITY,     
        @C_state = C3_VIOLATION_STATE,             
        @C_zip =   C3_VIOLATION_ZIP                
      FROM  
        C3COMPLAINT
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 
    END
  /* Get Full Address  */
  IF upper(@GET_FIELD)=N'FULLADDR_LINE' 
    BEGIN
	    IF @C_addr1 <> N'' 
	      SET @VSTR = @C_addr1
	    ELSE
	      SET @VSTR = N''	    
	    IF @C_addr2 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + char(10) + @C_addr2
		      ELSE
		        SET @VSTR = @C_addr2
	      END
	    IF @C_addr3 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + char(10) + @C_addr3
		      ELSE
		        SET @VSTR = @C_addr3
	      END	      	    
	    IF @C_city <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + char(10) + @C_city
		      ELSE
		        SET @VSTR = @C_city
	      END 	
	    IF @VSTR <> N''
	    	BEGIN
		    IF UPPER(@CASE) = N'U' 
		      SET @VSTR = UPPER(@VSTR)
		    ELSE IF UPPER(@CASE) = N'I' 
		      SET @VSTR = DBO.FN_GET_INITCAP(@CLIENTID, @VSTR)
		    ELSE 
		      SET @VSTR = @VSTR      	    
	    	END
	    IF @C_state <> N'' OR @C_zip <> N''
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_state
		      ELSE
		        SET @VSTR = @C_state
	      END
	    IF @C_zip <> N'' 
	      SET @VSTR = @VSTR + N' ' + @C_zip	    	    	    
    END
   /* Get Address exclude address3 */
   ELSE IF UPPER(@GET_FIELD)=N'PART_ADDR_BLOCK' 
    BEGIN
	    IF @C_addr1 <> N'' 
	      SET @VSTR = @C_addr1
	    ELSE
	      SET @VSTR = N''	    
	    IF @C_addr2 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_addr2
		      ELSE
		        SET @VSTR = @C_addr2
	      END	    
	    IF @C_city <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_city
		      ELSE
		        SET @VSTR = @C_city
	      END
	    IF @VSTR <> N''
	    	BEGIN
		    IF UPPER(@CASE) = N'U' 
		      SET @VSTR = UPPER(@VSTR)
		    ELSE IF UPPER(@CASE) = N'I' 
		      SET @VSTR = DBO.FN_GET_INITCAP(@CLIENTID, @VSTR)
		    ELSE 
		      SET @VSTR = @VSTR      	    
	    	END
	    IF @C_state <> N'' OR @C_zip <> N''
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_state
		      ELSE
		        SET @VSTR = @C_state
	      END
	    IF @C_zip <> N'' 
	      SET @VSTR = @VSTR + N' ' + @C_zip	    	    	    
    END
  /* Get Address exclude city, state and zip  */
  ELSE IF UPPER(@GET_FIELD)=N'PARTADDR_LINE' 
    BEGIN
	    IF @C_addr1 <> N'' 
	      SET @VSTR = @C_addr1
	    ELSE
	      SET @VSTR = N''	    
	    IF @C_addr2 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N' ' + @C_addr2
		      ELSE
		        SET @VSTR = @C_addr2
	      END
	    IF @C_addr3 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N' ' + @C_addr3
		      ELSE
		        SET @VSTR = @C_addr3
	      END	      	    	  
	    IF @VSTR <> N''
	    	BEGIN
		    IF UPPER(@CASE) = N'U' 
		      SET @VSTR = UPPER(@VSTR)
		    ELSE IF UPPER(@CASE) = N'I' 
		      SET @VSTR = DBO.FN_GET_INITCAP(@CLIENTID, @VSTR)
		    ELSE 
		      SET @VSTR = @VSTR
	    	END
  END
  /* Get Full Address  */
  ELSE IF UPPER(@GET_FIELD)=N'FULLADDR_LINEA'
	 BEGIN
	    IF @C_addr1 <> N'' 
	      SET @VSTR = @C_addr1
	    ELSE
	      SET @VSTR = N''	    
	    IF @C_addr2 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_addr2
		      ELSE
		        SET @VSTR = @C_addr2
	      END
	    IF @C_addr3 <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_addr3
		      ELSE
		        SET @VSTR = @C_addr3
	      END	      	    
	    IF @C_city <> N'' 
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_city
		      ELSE
		        SET @VSTR = @C_city
	      END
	    IF @C_state <> N'' OR @C_zip <> N''
	      BEGIN
		      IF @VSTR <> N'' 
		        SET @VSTR = @VSTR + N', ' + @C_state
		      ELSE
		        SET @VSTR = @C_state
	      END
	    IF @C_zip <> N'' 
	      SET @VSTR = @VSTR + N' ' + @C_zip	    	    	    
    END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONTACT_BY_FULLNAME] (@CLIENTID  NVARCHAR(15),
                                            @PID1    NVARCHAR(5),
                                            @PID2    NVARCHAR(5),
                                            @PID3   NVARCHAR(5),
                                            @ContactType NVARCHAR(30),
                                            @Relation NVARCHAR(300),
                                            @PrimaryContactFlag NVARCHAR(10),
                                            @Get_Field NVARCHAR(30),
                                            @NameFormat NVARCHAR(3),
                                            @Case NVARCHAR(1),
                                            @FULLNAME NVARCHAR(100)
                                            ) RETURNS NVARCHAR (200)  AS
/*  Author           :   sandy Yin
    Create Date      :   04/11/2007
    Version          :   AA6.3 MS SQL
    Detail           :   RETURNS: Contact information for the contact whose full name is {FullName}. If {PrimaryContactFlag} is 'Y', returns primary contact else returns first contact. Returns contact whose contact type is {ContactType} (optional) and whose contact @Relationship is {@Relation} (optional). Returns field value as specified by {@Get_Field}. If {@Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {Case} is 'U', return value is in UPPERCASE if {Case} is 'I', return value is in Initial Capitals.
                         ARGUMENTS: @CLIENTID, 
                         	    PrimaryTrackingID1, 
                         	    PrimaryTrackingID2, 
                         	    PrimaryTrackingID3, 
                         	    ContactType (Optional), 
                         	    @Relation (optional), 
                         	    PrimaryContactFlag ('Y' or 'N'), 
                         	    @Get_Field (Options:'FullName','FirstName','MiddleName','LastName','Title','OrgName','Address1','Address2','Address3','City','State','Zip', 'Phone1','Phone2','Email','Fax','FullAddr_Block','FullAddr_Line','ContactType','ContactRelationship', blank or others for Full Name(FML)), 
                         	    NameFormat (Options: 'FML','LFM','FLM','FL','LF' optional, '' or others for FML), 
                         	    Case ('U' for uppercase, 'I' for initial-caps, '' for original case).
                                    FullName
    Revision History :   04/11/2007  sandy Yin Initial Design base on FN_GET_CONTACT_INFO add @FULLNAME for 07SSP-000121
*/
BEGIN 
DECLARE 
  @VSTR NVARCHAR(200),
  @C_Bname NVARCHAR(65),
  @C_FullName NVARCHAR(80),
  @C_title NVARCHAR(10),
  @C_fname NVARCHAR(15),
  @C_mname NVARCHAR(15),
  @C_lname NVARCHAR(35),
  @C_addr1 NVARCHAR(40),
  @C_addr2 NVARCHAR(40),
  @C_addr3 NVARCHAR(40),
  @C_city NVARCHAR(30),
  @C_state NVARCHAR(2),
  @C_zip NVARCHAR(10),
  @C_country NVARCHAR(30),
  @C_phone1 NVARCHAR(40),
  @V_Phone NVARCHAR(40),
  @C_phone2 NVARCHAR(40),
  @C_fax NVARCHAR(15),
  @C_email NVARCHAR(80),
  @C_Relation NVARCHAR(30),
  @C_ContactType NVARCHAR(30),
  @V_mname NVARCHAR(100),
  @V_lname NVARCHAR(100),
  @CSZ NVARCHAR(50),
  @ADDR NVARCHAR(200),
  @V_Fax NVARCHAR(10),
	@TEM	  NVARCHAR(4000),
	@Result	  NVARCHAR(4000),
	@VSTR2 NVARCHAR(4000),
	@VTEM NVARCHAR(4000),
	@LASTSTRING NVARCHAR(4000),
	@STARTPOS INT,
	@ENDPOS INT,
	@TMPPOS INT;
	set  @TEM=N'';
	set  @Result =N'';
	SET @STARTPOS = 1;
	SET @TMPPOS = 1;
	SET @VSTR2 = N'';
    SET  @ADDR =N'';
-- Processing for parameter @Relation  
WHILE (@TMPPOS<=LEN(@Relation))
BEGIN
	IF (SUBSTRING(@Relation,@TMPPOS,1) = N',')
                 BEGIN
	            SET @VTEM = LTRIM(RTRIM(SUBSTRING(@Relation,@STARTPOS,@TMPPOS-@STARTPOS)))                
		IF (@VTEM != N'')
      BEGIN
		IF (@VSTR2 != N'')
		        SET @VSTR2=@VSTR2+N','''+@VTEM+N''''
	  	ELSE
               		SET @VSTR2=N''''+@VTEM+N''''
      END
    SET @TMPPOS = @TMPPOS +1
    SET @STARTPOS = @TMPPOS
END
ELSE
    SET @TMPPOS = @TMPPOS +1			
END
SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@Relation,@STARTPOS,@TMPPOS-@STARTPOS)))
IF (@LASTSTRING != N'')
BEGIN
IF (@VSTR2=N'')
	SET @VSTR2 =@VSTR2 + N''''+ @LASTSTRING+N''''
ELSE
	SET @VSTR2 =@VSTR2 +  N','''+@LASTSTRING+N''''
END
  IF UPPER(@PrimaryContactFlag) = N'Y' 
    BEGIN
      SELECT TOP 1 
        @C_title = B1_TITLE,
        @C_fname = B1_FNAME,
        @C_mname = B1_MNAME,
        @C_lname = B1_LNAME,
        @C_FullName = B1_FULL_NAME,
        @C_Relation = B1_Relation,
        @C_Bname = B1_BUSINESS_NAME,
        @C_addr1 = B1_ADDRESS1,
        @C_addr2 = B1_ADDRESS2,
        @C_addr3 = B1_ADDRESS3,
        @C_city = B1_CITY,
        @C_state = B1_STATE,
        @C_zip = B1_ZIP,
        @C_country = B1_COUNTRY,
        @C_phone1 = B1_PHONE1,
        @C_phone2 = B1_PHONE2,
        @C_fax = B1_FAX,
        @C_email = B1_EMAIL,
        @C_ContactType = B1_CONTACT_TYPE
      FROM  
        B3CONTACT
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 AND
        ( @FULLNAME<>N'' AND UPPER(B1_FULL_NAME)=UPPER(@FULLNAME) or @FULLNAME =N'') and
        ((@ContactType <> N'' AND UPPER(B1_CONTACT_TYPE) LIKE UPPER(@ContactType)) OR @ContactType = N'') AND
        ((@Relation <> N'' AND CHARINDEX(UPPER(B1_RELATION),UPPER(@VSTR2))>0) OR @Relation = N'') AND
        UPPER (B1_FLAG) = N'Y' 
    END
  ELSE
    BEGIN
      SELECT TOP 1 
        @C_title = B1_TITLE,
        @C_fname = B1_FNAME,
        @C_mname = B1_MNAME,
        @C_lname = B1_LNAME,
        @C_FullName = B1_FULL_NAME,
        @C_Relation = B1_Relation,
        @C_Bname = B1_BUSINESS_NAME,
        @C_addr1 = B1_ADDRESS1,
        @C_addr2 = B1_ADDRESS2,
        @C_addr3 = B1_ADDRESS3,
        @C_city = B1_CITY,
        @C_state = B1_STATE,
        @C_zip = B1_ZIP,
        @C_country = B1_COUNTRY,
        @C_phone1 = B1_PHONE1,
        @C_phone2 = B1_PHONE2,
        @C_fax = B1_FAX,
        @C_email = B1_EMAIL,
        @C_ContactType = B1_CONTACT_TYPE
      FROM  
        B3CONTACT
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 AND
	( @FULLNAME<>N'' AND UPPER(B1_FULL_NAME)=UPPER(@FULLNAME) or @FULLNAME =N'') and
        ((@ContactType <> N'' AND UPPER(B1_CONTACT_TYPE) LIKE UPPER(@ContactType)) OR @ContactType = N'') AND
        ((@Relation <> N'' AND CHARINDEX(UPPER(B1_RELATION),UPPER(@VSTR2))>0) OR @Relation = N'')
      ORDER BY B1_FLAG DESC
    END
  /* Get Address  */
  IF UPPER(@Get_Field)=N'ADDRESS1' 
    BEGIN
    BEGIN
    	IF @C_addr1 <> N''
    	  SET @VSTR = @C_addr1
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
    BEGIN
    BEGIN
    	IF @C_addr2 <> N''
    	  SET @VSTR = @C_addr2
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3' 
    BEGIN
    BEGIN
    	IF @C_addr3 <> N''
    	  SET @VSTR = @C_addr3
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
    BEGIN
    BEGIN
    	IF @C_city <> N''
    	  SET @VSTR = @C_city
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'STATE' 
    BEGIN
    	IF @C_state <> N''
    	  SET @VSTR = @C_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP' 
    BEGIN
    	IF @C_zip <> N''
    	  SET @VSTR = @C_zip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
                                                            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/* Get All Address, Exclude Address3 */
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK_2' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/* Begin Get Full Name on first line, address line 1 2 3 on second line, City, state and zip on third line, whole formated in block */
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR123_CSZ_BLK' 
    BEGIN
	IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
        IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
	     SET @VSTR = @C_FULLNAME
        IF @C_addr1 <> N'' 
             set @ADDR = @C_addr1
     	ELSE
             SET  @ADDR = N''
        IF @C_addr2 <> N'' 
             BEGIN
             	IF @ADDR <>N''
             	    SET @ADDR = @ADDR + N', ' + @C_addr2
             	ELSE
             	    SET @ADDR = @C_addr2
             END
        IF @C_addr3 <> N'' 
             BEGIN
             	IF @ADDR <>N''
             	    SET @ADDR = @ADDR + N', ' + @C_addr3
             	ELSE
             	    SET @ADDR = @C_addr3
             END
        IF @ADDR <> N'' 
             BEGIN
             	IF @VSTR <>N''
             	    SET @VSTR = @VSTR + CHAR(10) + @ADDR
             	ELSE
             	    SET @VSTR = @ADDR
             END
	IF UPPER(@Case) = N'U' 
		SET @VSTR = UPPER(@VSTR)
	ELSE IF UPPER(@Case) = N'I' 
		SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	ELSE 
		SET @VSTR = @VSTR
	IF @C_city <> N'' 
		SET @CSZ = @C_city       
	IF UPPER(@Case) = N'U' 
		SET @CSZ = UPPER(@CSZ)
	ELSE IF UPPER(@Case) = N'I' 
		SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
	ELSE 
		SET @CSZ = @CSZ
	IF @C_state <> N'' OR @C_zip <> N''
	BEGIN
	      IF @CSZ <> N'' 
	           SET @CSZ = @CSZ + N', ' + @C_state
	      ELSE
	           SET @CSZ = @C_state
	END
	IF @C_zip <> N'' 
	BEGIN
	      IF @CSZ <> N''
	        SET @CSZ = @CSZ + N' ' + @C_zip
	      ELSE
	        SET @CSZ = @C_zip
	END
	IF @CSZ <> N'' 
	BEGIN
	      IF @VSTR <> N'' 
	        SET @VSTR = @VSTR + CHAR(10) + @CSZ
	      ELSE
	        SET @VSTR = @CSZ
	END
    END
/* End Get Full Name on first line, address line 1 2 3 on second line, City, state and zip on third line, whole formated in block */
/* Begin Get Full Name, address line 1, City, state and zip formated in block */
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR1_CSZ_BLK' 
    BEGIN
	IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
        IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
	     SET @VSTR = @C_FULLNAME
        IF @C_addr1 <> N'' 
             BEGIN
             	IF @VSTR <>N''
             	    SET @VSTR = @VSTR + CHAR(10) + @C_addr1
             	ELSE
             	    SET @VSTR = @C_addr1
             END
	IF UPPER(@Case) = N'U' 
		SET @VSTR = UPPER(@VSTR)
	ELSE IF UPPER(@Case) = N'I' 
		SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	ELSE 
		SET @VSTR = @VSTR
	IF @C_city <> N'' 
		SET @CSZ = @C_city       
	IF UPPER(@Case) = N'U' 
		SET @CSZ = UPPER(@CSZ)
	ELSE IF UPPER(@Case) = N'I' 
		SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
	ELSE 
		SET @CSZ = @CSZ
	IF @C_state <> N'' OR @C_zip <> N''
	BEGIN
	      IF @CSZ <> N'' 
	           SET @CSZ = @CSZ + N', ' + @C_state
	      ELSE
	           SET @CSZ = @C_state
	END
	IF @C_zip <> N'' 
	BEGIN
	      IF @CSZ <> N''
	        SET @CSZ = @CSZ + N' ' + @C_zip
	      ELSE
	        SET @CSZ = @C_zip
	END
	IF @CSZ <> N'' 
	BEGIN
	      IF @VSTR <> N'' 
	        SET @VSTR = @VSTR + CHAR(10) + @CSZ
	      ELSE
	        SET @VSTR = @CSZ
	END
    END
/* End Get Full Name, address line 1, City, state and zip formated in block */
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
    END
/* Get Address 1, 2 and 3 in line */
  ELSE IF UPPER(@Get_Field)=N'ADDRESS123_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END                   
    END
  /* Get City, State and Zip */
  ELSE IF UPPER(@Get_Field)=N'CSZ' 
    BEGIN                                          
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
    END
/*Get all information of business name & fullname & fulladdress & phone1 */  
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR123_PHONE'
BEGIN
       IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	   IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
           IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
            IF @C_phone1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_phone1
                      ELSE
                        SET @VSTR = @C_phone1
               END   
    END
/*12/15/2006  Sandy Yin  Added IF UPPER(@Get_Field)='NAME_ORAG_ADDRS' (Get all information of business name & fullname & address1,2,3) for SAN 06SSP-00124.R61214 */
  ELSE IF UPPER(@Get_Field)=N'NAME_ORAG_ADDRS'
  BEGIN
              IF @C_fname <> N''
              BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
               END
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	   IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
           IF @C_Bname <> N''
            BEGIN IF @VSTR<>N''
            SET @VSTR = @VSTR+CHAR(10)+ @C_Bname
            ELSE
             SET  @VSTR=@C_Bname
            END
	    IF UPPER(@Case) = N'U' 
	           SET @VSTR = UPPER(@VSTR)
	         ELSE IF UPPER(@Case) = N'I' 
	           SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	         ELSE 
	            SET @VSTR = @VSTR
              BEGIN
                      IF @C_addr1 <> N'' 
                        SET  @ADDR= @C_addr1
                      ELSE
                        SET  @ADDR = N''
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR + CHAR(10)+ @C_addr2
                      ELSE
                        SET @ADDR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR +CHAR(10) + @C_addr3
                      ELSE
                              SET @ADDR = @C_addr3
              END
            IF  @ADDR<>N'' 
              BEGIN
	              IF  @VSTR<>N'' 
	               SET  @VSTR=@VSTR+CHAR(10)+@ADDR
	              ELSE  SET @VSTR= @ADDR
              END
IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/*12/15/2006  Sandy Yin  Added IF UPPER(@Get_Field)='NAME_ORAG_ADDRS' (Get all information of business name & fullname & address1,2,3) for SAN 06SSP-00124.R61214  end */
/*12/22/2006  Sandy Yin  Added IF UPPER(@Get_Field)='ORAG_ADDRS' (Get all information of business name & address1,2,3) for SAN 06SSP-00124.R61214 */
  ELSE IF UPPER(@Get_Field)=N'ORAG_ADDRS'
  BEGIN
           IF @C_Bname <> N''
            BEGIN IF @VSTR<>N''
            SET @VSTR = @VSTR+CHAR(10)+ @C_Bname
            ELSE
             SET  @VSTR=@C_Bname
            END
	    IF UPPER(@Case) = N'U' 
	           SET @VSTR = UPPER(@VSTR)
	         ELSE IF UPPER(@Case) = N'I' 
	           SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	         ELSE 
	            SET @VSTR = @VSTR
              BEGIN
                      IF @C_addr1 <> N'' 
                        SET  @ADDR= @C_addr1
                      ELSE
                        SET  @ADDR = N''
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR + CHAR(10)+ @C_addr2
                      ELSE
                        SET @ADDR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR +CHAR(10) + @C_addr3
                      ELSE
                              SET @ADDR = @C_addr3
              END
            IF  @ADDR<>N'' 
              BEGIN
	              IF  @VSTR<>N'' 
	               SET  @VSTR=@VSTR+CHAR(10)+@ADDR
	              ELSE  SET @VSTR= @ADDR
              END
IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/*12/22/2006  Sandy Yin  Added IF UPPER(@Get_Field)='ORAG_ADDRS' (Get all information of business name & address1,2,3) for SAN 06SSP-00124.R61214  end */
/* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FIRSTNAME' 
    BEGIN
    	IF @C_fname <> N''
    	  SET @VSTR = @C_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LASTNAME' 
    BEGIN
    	IF @C_lname <> N''
    	  SET @VSTR = @C_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MIDDLENAME' 
    BEGIN
    	IF @C_mname <> N''
    	  SET @VSTR = @C_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END     
/* 02/10/2006 BEGIN  NameFormat='FMIL' for {First Name + ' ' + Middle Initial + ' ' + Last Name for 07SSP-00068 basically oracle function*/
   ELSE IF UPPER(@NameFormat) = N'FMIL' 
     BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
               IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
                 IF @C_mname <> N''
           	  	SET @V_mname = SUBSTRING(UPPER(@C_mname),1,1)
           	IF @C_lname <> N''
             	SET @V_lname = @C_lname
		IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@C_lname)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@C_lname)
                 ELSE 
                    SET @C_lname = @C_lname                
	                IF @VSTR<>N'' 
		                BEGIN
				  IF @V_mname<>N''
		 			SET @VSTR =@VSTR+N' '+@V_mname
	                         ELSE 
					SET @VSTR=@VSTR
				END
  			IF @VSTR<>N'' 
		                BEGIN
				  IF @V_lname<>N''
		 			SET @VSTR =@VSTR+N' '+@V_lname
	                         ELSE 
					SET @VSTR=@VSTR
				END
             END
    END
/* END  02/10/2006  NameFormat='FMIL' for {First Name + ' ' + Middle Initial + ' ' + Last Name for 07SSP-00068 basically oracle function*/         
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR       
         END                           
    END
  /* Get Business Name  */
  ELSE IF UPPER(@Get_Field)=N'ORGNAME' 
        BEGIN
          IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  /* Get Title  */
  ELSE IF UPPER(@Get_Field)=N'TITLE' 
     BEGIN
          IF @C_title <> N''
            SET @VSTR = @C_title
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
     END
  /* Get Phone  */
  ELSE IF UPPER(@Get_Field)=N'PHONE1' 
    BEGIN
    	IF @C_phone1 <> N''
    	  SET @VSTR = @C_phone1
    END
  ELSE IF UPPER(@Get_Field)=N'PHONE2' 
    BEGIN
    	IF @C_phone2 <> N''
    	  SET @VSTR = @C_phone2
    END
  /* Get Fax  */
  ELSE IF UPPER(@Get_Field)=N'FAX' 
    BEGIN
    	IF @C_fax <> N''
    	  SET @VSTR = @C_fax
    END
ELSE IF UPPER(@Get_Field)=N'FAX_PARENTHESES'  
--{(NNN) NNN-NNNN}
  BEGIN 
    if @C_fax <>N''
       SET @VSTR =N''
    else
      SET @V_Fax= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_fax)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
        BEGIN 
            IF  LEN(@V_Fax)>7 
               SET @VSTR =N'('+SUBSTRING(@V_Fax,1,3)+N')'+N' '+SUBSTRING(@V_Fax,4,3)+N'-'+SUBSTRING(@V_Fax,7,4)
            ELSE
                SET @VSTR = SUBSTRING(@V_Fax,1,3)+N'-'+SUBSTRing(@V_Fax,4,4)
            END;
 END 
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @C_country <> N''
              SET @VSTR = @C_country
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get Email  */
  ELSE IF UPPER(@Get_Field)=N'EMAIL' 
        BEGIN
            IF @C_email <> N''
              SET @VSTR = @C_email
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END    
  /* Get @Relation (Contact Relationship) */
  ELSE IF UPPER(@Get_Field)=N'CONTACTRELATIONSHIP' 
        BEGIN
            IF @C_Relation <> N''
              SET @VSTR = @C_Relation
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get Contact Type  */
  ELSE IF UPPER(@Get_Field)=N'CONTACTTYPE' 
        BEGIN
            IF @C_ContactType <> N''
              SET @VSTR = @C_ContactType
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
/*02/10/2007 BEGIN Sandy Yin basically oracle function for 06SSP-00068*/ 
 /* Get Phone or Phone with format */
   ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT7'  
      if @C_phone1  =N''
        SET @VSTR=null;
      else
        BEGIN 
        	SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
        BEGIN   
		IF  LEN(@V_Phone)>7  
	        	SET @VSTR=  SUBSTRING(SUBSTRING(@V_Phone,LEN(@V_Phone)-6,7),1,3)+N'-'+SUBSTRING(SUBSTRING(@V_Phone,LEN(@V_Phone)-6,7),4,7)
	            ELSE
	               SET @VSTR= SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,4)
	            END
       end 
 ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT10'   
 --{NNN-NNN-NNNN}
      if @C_phone1  =N''
        SET @VSTR=null;
      else
      BEGIN 
        SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
       BEGIN
           IF   LEN(@V_Phone)>7  
              SET @VSTR=   SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,3)+N'-'+SUBSTRING(@V_Phone,7,4)
            ELSE
               SET @VSTR=  SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,4)
            END
        END
  ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT10_PARENTHESES'   
   BEGIN 
     if @C_phone1  =N''
        SET @VSTR=null;
    else
     BEGIN 
      SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
	BEGIN   
	      IF  LEN(@V_Phone)>7  
	               SET @VSTR=   N'('+SUBSTRING(@V_Phone,1,3)+N')'+N' '+SUBSTRING(@V_Phone,4,3)+N'-'+SUBSTRING(@V_Phone,7,4)
	            ELSE
                	SET @VSTR= SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,4)
            END
     END
   END 
  /* FL_ORGNAME {First Name + ' ' + Last Name +', ' +Organization Name }  */
  ELSE IF UPPER(@Get_Field)=N'FL_ORGNAME'   
    BEGIN
         IF UPPER(@Case) = N'U'  
            SET @VSTR= UPPER(@C_fname + N' ' + @C_lname);
         ELSE IF  UPPER(@Case) = N'I'  
            SET @VSTR= DBO.FN_GET_INITCAP (N'',@C_fname + N' ' + @C_lname);
         ELSE
            SET @VSTR= @C_fname + N' ' + @C_lname;
         IF @C_BName <>N'' 
           IF UPPER(@Case) = N'U'  
              SET @VSTR=@VSTR+N', ' +  UPPER(@C_BName);
           ELSE IF  UPPER(@Case) = N'I'  
              SET @VSTR= @VSTR+N', ' +DBO.FN_GET_INITCAP (N'',@C_BName);
           ELSE
              SET @VSTR= @VSTR+N', ' +@C_BName;
    END;
/* 'FL_FULLADDR_PHONE1' {First Name + " " + Last Name + ", " + Address 1 + ", " + Address 2 + ", " + Address 3 + ", " + City + ", " + State + " " + Zip  +". Telephone: " + Phone 1} */
 ELSE IF  UPPER(@Get_Field)=N'FL_FULLADDR_PHONE1'   
    BEGIN
         IF @C_fname <>N''AND  @C_fname <>N'' 
          BEGIN 
           IF UPPER(@Case) = N'U'  
              SET @VSTR= UPPER(@C_fname + N' ' + @C_lname);
           ELSE IF  UPPER(@Case) = N'I'  
              SET @VSTR= DBO.FN_GET_INITCAP (N'',@C_fname + N' ' + @C_lname);
           ELSE
              SET @VSTR= @C_fname + N' ' + @C_lname;
         END
         IF @C_addr1 <>N'' 
            SET @VSTR= @VSTR +N', '+@C_addr1;
          IF @C_addr2 <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_addr2;
          IF @C_addr3 <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_addr3;
          IF @C_city <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_city;
          IF @C_state <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_state;
          IF @C_zip <>N'' 
            SET @VSTR= @VSTR + N' ' + @C_zip;
          IF UPPER(@Case) = N'U'  
            SET @VSTR= UPPER(@VSTR);
          ELSE IF  UPPER(@Case) = N'I'  
            SET @VSTR= DBO.FN_GET_INITCAP (N'',@VSTR);
          ELSE
            SET @VSTR= @VSTR;
         IF @VSTR <>N''  
            SET @VSTR= @VSTR +N'.';
         IF @C_phone1 <>N'' 
            SET @VSTR= @VSTR + N' Telephone:  ' +@C_phone1;
    END;    
  /* GET Full Name (FML),Address 1,Address 2,in block format */
ELSE IF  UPPER(@Get_Field)=N'NAME_ADDR12_BLK'  
 	BEGIN   
	    IF @C_addr1 <>N'' 
	      SET @VSTR= @C_addr1;
	     ELSE
	       SET @VSTR= N'';
	    IF @C_addr2 <>N'' 
	      IF @VSTR <>N'' 
	        SET @VSTR= @VSTR + CHAR(10) + @C_addr2;
	      ELSE
	        SET @VSTR= @C_addr2;
    IF UPPER(@NameFormat) = N'FML'  
      BEGIN
      		IF ltrim(@C_fname+@C_lname) <>N'' 
           		BEGIN 
	          		 IF @C_mname <>N'' 
	          		    BEGIN
				            IF @VSTR <>N'' 
				                SET @VSTR=ltrim(@C_fname + N' ' +@C_mname+ N' '+@C_lname)+CHAR(10)+@VSTR;
				            ELSE
					  	SET @VSTR=ltrim(@C_fname+N' '+@C_mname+N' '+@C_lname);
	           		    END 
                         END
           ELSE
	           BEGIN 
	            IF @VSTR <>N'' 
	                SET @VSTR=ltrim(@C_fname+N' '+@C_lname)+CHAR(10)+@VSTR;
	            ELSE
					SET @VSTR=ltrim(@C_fname+N' '+@C_lname);
	             END 
       END
	   IF UPPER(@Case) = N'U'  
		   SET @VSTR= UPPER(@VSTR);
		 ELSE IF  UPPER(@Case) = N'I'  
		   SET @VSTR= DBO.FN_GET_INITCAP (N'',@VSTR);
		 ELSE
		   SET @VSTR= @VSTR;
	  END
 /* 'ORG_FULLADDR_FL_PHONE1'  {Organization Name + ", " + Address 1 + ", " + Address 2 + ", " + Address 3 + ", " + City + ", " + State + " " + Zip  + ". Contact: " + First Name + " " + Last Name +' '+ Phone 1}    */
  ELSE IF UPPER(@Get_Field)=N'ORG_FULLADDR_FL_PHONE1'   
    BEGIN
         IF @C_BName <>N''
           BEGIN 
           IF UPPER(@case) = N'U'  
              set @VSTR =UPPER(@C_BName);
           ELSE IF UPPER(@case) = N'I'  
              set @VSTR =DBO.FN_GET_INITCAP(N'',@C_BName);
           ELSE
              set @VSTR =@C_BName;
           END 
         IF @C_addr1 <>N''
          BEGIN 
           IF @C_BName <>N''
              set @VSTR = @VSTR +N', ' +@C_addr1;
           ELSE
               set @VSTR =  @VSTR +@C_addr1;
           END 
          IF @C_addr2 <>N''
           BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_addr2;
            END
          IF @C_addr3 <>N''
            BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_addr3;
            END
          IF @C_city <>N''
           BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_city;
            END 
          IF @C_state <>N''
           BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_state;
            END 
          IF @C_zip <>N''
            set @VSTR = @VSTR + N' ' + @C_zip;
          IF UPPER(@case) = N'U'  
            set @VSTR = UPPER(@VSTR);
          ELSE IF UPPER(@case) = N'I'  
            set @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR);
          ELSE
            set @VSTR = @VSTR;
         IF @VSTR <>N''
            set @VSTR =@VSTR +N'.';
         IF @C_fname <>N''AND  @C_lname <>N''
         BEGIN
           IF UPPER(@case) = N'U'  
              set @VSTR = @VSTR +N' Contact: '+ UPPER(@C_fname + N' ' + @C_lname);
           ELSE IF UPPER(@case) = N'I'  
              set @VSTR = @VSTR +N' Contact: '+ DBO.FN_GET_INITCAP(N'',@C_fname + N' ' + @C_lname);
           ELSE
              set @VSTR = @VSTR +N' Contact: '+ @C_fname + N' ' + @C_lname;
           END 
         IF @C_phone1 <>N''
            set @VSTR = @VSTR + N' ' +@C_phone1;       
    END;
/*02/10/2007 END Sandy Yin basically oracle function for 06SSP-00068*/ 
  /* Get FullName as @Get_Field is not one of the correct options  */  
  ELSE
    BEGIN
      IF UPPER(@NameFormat) = N'LFM'         BEGIN
	   IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FML' 
        BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END     
      ELSE IF UPPER(@NameFormat) = N'LF' 
        BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FL' 
        BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE
        BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
       END
  END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONTACT_INFO] (@CLIENTID  NVARCHAR(15),
                                            @PID1    NVARCHAR(5),
                                            @PID2    NVARCHAR(5),
                                            @PID3   NVARCHAR(5),
                                            @ContactType NVARCHAR(30),
                                            @Relation NVARCHAR(300),
                                            @PrimaryContactFlag NVARCHAR(1),
                                            @Get_Field NVARCHAR(30),
                                            @NameFormat NVARCHAR(3),
                                            @Case NVARCHAR(1)
                                            ) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   04/19/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Contact information, as follows: If {PrimaryContactFlag} is 'Y', returns primary contact else returns first contact. Returns contact whose contact type is {ContactType} (optional) and whose contact @Relationship is {@Relation} (optional). Returns field value as specified by {@Get_Field}. If {@Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {Case} is 'U', return value is in UPPERCASE if {Case} is 'I', return value is in Initial Capitals.
                         ARGUMENTS: ClientID, 
                         	    PrimaryTrackingID1, 
                         	    PrimaryTrackingID2, 
                         	    PrimaryTrackingID3, 
                         	    ContactType (Optional), 
                         	    Relation (optional), 
                         	    PrimaryContactFlag ('Y' or 'N'), 
                         	    Get_Field (Options:'FullName','FirstName','MiddleName','LastName','Title','OrgName','Address1','Address2','Address3','City','State','Zip', 'Phone1','Phone2','Email','Fax','FullAddr_Block','FullAddr_Line','ContactType','ContactRelationship', blank or others for Full Name(FML)), 
                         	    NameFormat (Options: 'FML','LFM','FLM','FL','LF','FMIL', blank or others for FML), 
                         	    Case ('U' for uppercase, 'I' for initial-caps, blank for original case).
    Revision History :   04/19/2005  David Zheng Initial Design
    			 05/17/2005  David Zheng Added "CSZ" for get City, State and Zip
    			 05/20/2005  Angel Feng  Revised the City from 10 characters to 30 characters; Added "," between "city" and "zip" when the state is null.
    			 06/22/2005  Sunny Chen  Revised the format(applied by the parameter @case) of address1 & address2 & address3 & city & state when only get address1 or address2 or address3 or city or state.
    			 06/23/2005  Sunny Chen  Revised the State follow City and separated by a comma.
			 08/17/2005  Arthur Miao Added function that it can select data from muti "contact relations", changed @Relation from VARCHAR(30) to VARCHAR(300). We can send one more Relations from parameter @Relation. When we send "APPLICANT,AGENT FOR APPLICANT" to @Relation, we'll get data which Ralation are APPLICANT & AGENT FOR APPLICANT
                         09/23/2005  Arthur Miao Added "ORDER BY B1_FLAG DESC" for the 2nd query: If {PrimaryContactFlag} is 'N', primary contact is given selection priority.
                         11/08/2005  Cece  Wang  Added 'IF UPPER(@Get_Field)='FULLADDR_BLOCK_2''( Get All Address, Exclude Address3)
			 01/11/2006  Ava Wu Revised 'CSZ' for get City, State Zip
                         01/20/2006  Lydia Lim  correct 'ALTER FUNCTION' to 'CREATE FUNCTION'
                         02/16/2006  Ava Wu If Full Name is needed in default (FML) format, use B1_FULL_NAME instead of B1_FNAME, B1_MNAME, B1_LNAME, because converted data often populates B1_FULL_NAME without populating B1_FNAME, B1_MNAME, B1_LNAME.
			 08/15/2006  David Zheng Added "ADDRESS123_LINE" (Get Address 1,2 and 3 in line)
                         09/13/2006  Cece Wang Added IF UPPER(@Get_Field)='NAME_ADDR123_PHONE' (Get all information of business name & fullname & fulladdress & phone1)
                         12/15/2006  Sandy Yin  Added IF UPPER(@Get_Field)='NAME_ORAG_ADDRS' (Get all information of business name & fullname & address1,2,3)  for SAN 06SSP-00124.R61214 field L
                         12/22/2006  Sandy Yin  Added IF UPPER(@Get_Field)='ORAG_ADDRS' (Get all information of business name & address1,2,3)  for SAN 06SSP-00124.R61222 field L
                         01/03/2007  Angel Feng  Added IF UPPER(@Get_Field)='NAME_ADDR1_CSZ_BLK' (Use the Applicant contact elements of Full Name, address line 1, City, state and zip formated in block) for SAN 06SSP-00271 field D
                         01/03/2007  Angel Feng  Added IF UPPER(@Get_Field)='NAME_ADDR123_CSZ_BLK' (Get Full Name on first line, address line 1 2 3 on second line, City, state and zip on third line, whole formated in block) for 06SSP-00269 field B
                         02/10/2007 Sandy Yin basically oracle function for 06SSP-00068(
                                     1) Add NameFormat='FMIL' for {First Name || ' ' || Middle Initial || ' ' || Last Name}
                                     2) Add Get_Field = 'PHONE1_Format7' then get the last 7 phone number with format {NNN-NNNN}
                                     3) Add Get_Field = 'PHONE1_Format10', if length of phone number greater than 7 then get the phone number with format {NNN-NNN-NNNN}, else get phone number with format {NNN-NNNN}
                                     4) Add Get_Field = 'PHONE1_FORMAT10_PARENTHESES', if length of phone number greater than 7 then get the phone number with format {(NNN) NNN-NNNN}, else get phone number with format {NNN-NNNN}
                                     5) Add Get_Field = 'FAX_PARENTHESES', if length of phone number greater than 7 then get the phone number with format {(NNN) NNN-NNNN}, else get fax number with format {NNN-NNNN}
                                     6) Add Get_Field = 'FL_ORGNAME' {First Name || ' ' || Last Name ||', ' ||Organization Name }
                                     7) Add Get_Field = 'Org_Fulladdr_Fl_Phone1'  {Organization Name || ", " || Address 1 || ", " || Address 2 || ", " || Address 3 || ", " || City || ", " || State || " " || Zip  || ". Contact: " || First Name || " " || Last Name ||' '|| Phone 1}
                                     8) Add Get_Field = 'FL_FULLADDR_PHONE1' {First Name || " " || Last Name || ", " || Address 1 || ", " || Address 2 || ", " || Address 3 || ", " || City || ", " || State || " " || Zip  ||". Telephone: " || Phone 1}
                                     9) Add Get_Field = 'NAME_ADDR12_BLK' )
                        05/10/2007 Rainy Yu change @VSTR VARCHAR(4000)
                        05/28/2007 Rainy Yu Add IF UPPER(@Get_Field)='NAME_ADDR123'(Busniss name, name, address 06SSP-000209.C70525)
                        06/14/2007 Lydia Lim Add Coalesce() to allow NULL parameter values
                        08/17/2007 Lydia Lim Add Get_Field option 'PHONE1_FORMAT11_PARENTHESES'  07-078.C70720           
*/
BEGIN 
DECLARE 
  @VSTR NVARCHAR(4000),
  @C_Bname NVARCHAR(65),
  @C_FullName NVARCHAR(80),
  @C_title NVARCHAR(10),
  @C_fname NVARCHAR(15),
  @C_mname NVARCHAR(15),
  @C_lname NVARCHAR(35),
  @C_addr1 NVARCHAR(40),
  @C_addr2 NVARCHAR(40),
  @C_addr3 NVARCHAR(40),
  @C_city NVARCHAR(30),
  @C_state NVARCHAR(2),
  @C_zip NVARCHAR(10),
  @C_country NVARCHAR(30),
  @C_phone1 NVARCHAR(40),
  @V_Phone NVARCHAR(40),
  @C_phone2 NVARCHAR(40),
  @C_fax NVARCHAR(15),
  @C_email NVARCHAR(80),
  @C_Relation NVARCHAR(30),
  @C_ContactType NVARCHAR(30),
  @V_mname NVARCHAR(100),
  @V_lname NVARCHAR(100),
  @CSZ NVARCHAR(50),
  @ADDR NVARCHAR(200),
  @V_Fax NVARCHAR(10),
	@TEM	  NVARCHAR(4000),
	@Result	  NVARCHAR(4000),
	@VSTR2 NVARCHAR(4000),
	@VTEM NVARCHAR(4000),
	@LASTSTRING NVARCHAR(4000),
	@STARTPOS INT,
	@ENDPOS INT,
	@TMPPOS INT;
	set  @TEM=N'';
	set  @Result =N'';
	SET @STARTPOS = 1;
	SET @TMPPOS = 1;
	SET @VSTR2 = N'';
        SET  @ADDR =N'';
-- Processing for parameter @Relation  
WHILE (@TMPPOS<=LEN(@Relation))
BEGIN
	IF (SUBSTRING(@Relation,@TMPPOS,1) = N',')
                 BEGIN
	            SET @VTEM = LTRIM(RTRIM(SUBSTRING(@Relation,@STARTPOS,@TMPPOS-@STARTPOS)))                
		IF (@VTEM != N'')
      BEGIN
		IF (@VSTR2 != N'')
		        SET @VSTR2=@VSTR2+N','''+@VTEM+N''''
	  	ELSE
               		SET @VSTR2=N''''+@VTEM+N''''
      END
    SET @TMPPOS = @TMPPOS +1
    SET @STARTPOS = @TMPPOS
END
ELSE
    SET @TMPPOS = @TMPPOS +1			
END
SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@Relation,@STARTPOS,@TMPPOS-@STARTPOS)))
IF (@LASTSTRING != N'')
BEGIN
IF (@VSTR2=N'')
	SET @VSTR2 =@VSTR2 + N''''+ @LASTSTRING+N''''
ELSE
	SET @VSTR2 =@VSTR2 +  N','''+@LASTSTRING+N''''
END
  IF UPPER(@PrimaryContactFlag) = N'Y' 
    BEGIN
      SELECT TOP 1 
        @C_title = B1_TITLE,
        @C_fname = B1_FNAME,
        @C_mname = B1_MNAME,
        @C_lname = B1_LNAME,
        @C_FullName = B1_FULL_NAME,
        @C_Relation = B1_Relation,
        @C_Bname = B1_BUSINESS_NAME,
        @C_addr1 = B1_ADDRESS1,
        @C_addr2 = B1_ADDRESS2,
        @C_addr3 = B1_ADDRESS3,
        @C_city = B1_CITY,
        @C_state = B1_STATE,
        @C_zip = B1_ZIP,
        @C_country = B1_COUNTRY,
        @C_phone1 = B1_PHONE1,
        @C_phone2 = B1_PHONE2,
        @C_fax = B1_FAX,
        @C_email = B1_EMAIL,
        @C_ContactType = B1_CONTACT_TYPE
      FROM  
        B3CONTACT
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 AND
        (UPPER(B1_CONTACT_TYPE) LIKE UPPER(@ContactType) OR COALESCE(@ContactType,N'') = N'') AND
        ((COALESCE(@Relation,N'') <> N'' AND CHARINDEX(UPPER(B1_RELATION),UPPER(@VSTR2))>0) OR COALESCE(@Relation,N'') = N'') AND
        UPPER (B1_FLAG) = N'Y' 
    END
  ELSE
    BEGIN
      SELECT TOP 1 
        @C_title = B1_TITLE,
        @C_fname = B1_FNAME,
        @C_mname = B1_MNAME,
        @C_lname = B1_LNAME,
        @C_FullName = B1_FULL_NAME,
        @C_Relation = B1_Relation,
        @C_Bname = B1_BUSINESS_NAME,
        @C_addr1 = B1_ADDRESS1,
        @C_addr2 = B1_ADDRESS2,
        @C_addr3 = B1_ADDRESS3,
        @C_city = B1_CITY,
        @C_state = B1_STATE,
        @C_zip = B1_ZIP,
        @C_country = B1_COUNTRY,
        @C_phone1 = B1_PHONE1,
        @C_phone2 = B1_PHONE2,
        @C_fax = B1_FAX,
        @C_email = B1_EMAIL,
        @C_ContactType = B1_CONTACT_TYPE
      FROM  
        B3CONTACT
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 AND
        (UPPER(B1_CONTACT_TYPE) LIKE UPPER(@ContactType) OR COALESCE(@ContactType,N'') = N'') AND
        ((COALESCE(@Relation,N'') <> N'' AND CHARINDEX(UPPER(B1_RELATION),UPPER(@VSTR2))>0) OR COALESCE(@Relation,N'') = N'')
      ORDER BY B1_FLAG DESC
    END
  /* Get Address  */
  IF UPPER(@Get_Field)=N'ADDRESS1' 
    BEGIN
    BEGIN
    	IF @C_addr1 <> N''
    	  SET @VSTR = @C_addr1
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
    BEGIN
    BEGIN
    	IF @C_addr2 <> N''
    	  SET @VSTR = @C_addr2
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3' 
    BEGIN
    BEGIN
    	IF @C_addr3 <> N''
    	  SET @VSTR = @C_addr3
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
    BEGIN
    BEGIN
    	IF @C_city <> N''
    	  SET @VSTR = @C_city
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'STATE' 
    BEGIN
    	IF @C_state <> N''
    	  SET @VSTR = @C_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP' 
    BEGIN
    	IF @C_zip <> N''
    	  SET @VSTR = @C_zip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
                                                            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/* Get All Address, Exclude Address3 */
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK_2' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/* Begin Get Full Name on first line, address line 1 2 3 on second line, City, state and zip on third line, whole formated in block */
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR123_CSZ_BLK' 
    BEGIN
	IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
        IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
	     SET @VSTR = @C_FULLNAME
        IF @C_addr1 <> N'' 
             set @ADDR = @C_addr1
     	ELSE
             SET  @ADDR = N''
        IF @C_addr2 <> N'' 
             BEGIN
             	IF @ADDR <>N''
             	    SET @ADDR = @ADDR + N', ' + @C_addr2
             	ELSE
             	    SET @ADDR = @C_addr2
             END
        IF @C_addr3 <> N'' 
             BEGIN
             	IF @ADDR <>N''
             	    SET @ADDR = @ADDR + N', ' + @C_addr3
             	ELSE
             	    SET @ADDR = @C_addr3
             END
        IF @ADDR <> N'' 
             BEGIN
             	IF @VSTR <>N''
             	    SET @VSTR = @VSTR + CHAR(10) + @ADDR
             	ELSE
             	    SET @VSTR = @ADDR
             END
	IF UPPER(@Case) = N'U' 
		SET @VSTR = UPPER(@VSTR)
	ELSE IF UPPER(@Case) = N'I' 
		SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	ELSE 
		SET @VSTR = @VSTR
	IF @C_city <> N'' 
		SET @CSZ = @C_city       
	IF UPPER(@Case) = N'U' 
		SET @CSZ = UPPER(@CSZ)
	ELSE IF UPPER(@Case) = N'I' 
		SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
	ELSE 
		SET @CSZ = @CSZ
	IF @C_state <> N'' OR @C_zip <> N''
	BEGIN
	      IF @CSZ <> N'' 
	           SET @CSZ = @CSZ + N', ' + @C_state
	      ELSE
	           SET @CSZ = @C_state
	END
	IF @C_zip <> N'' 
	BEGIN
	      IF @CSZ <> N''
	        SET @CSZ = @CSZ + N' ' + @C_zip
	      ELSE
	        SET @CSZ = @C_zip
	END
	IF @CSZ <> N'' 
	BEGIN
	      IF @VSTR <> N'' 
	        SET @VSTR = @VSTR + CHAR(10) + @CSZ
	      ELSE
	        SET @VSTR = @CSZ
	END
    END
/* End Get Full Name on first line, address line 1 2 3 on second line, City, state and zip on third line, whole formated in block */
/* Begin Get Full Name, address line 1, City, state and zip formated in block */
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR1_CSZ_BLK' 
    BEGIN
	IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
        IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
	     SET @VSTR = @C_FULLNAME
        IF @C_addr1 <> N'' 
             BEGIN
             	IF @VSTR <>N''
             	    SET @VSTR = @VSTR + CHAR(10) + @C_addr1
             	ELSE
             	    SET @VSTR = @C_addr1
             END
	IF UPPER(@Case) = N'U' 
		SET @VSTR = UPPER(@VSTR)
	ELSE IF UPPER(@Case) = N'I' 
		SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	ELSE 
		SET @VSTR = @VSTR
	IF @C_city <> N'' 
		SET @CSZ = @C_city       
	IF UPPER(@Case) = N'U' 
		SET @CSZ = UPPER(@CSZ)
	ELSE IF UPPER(@Case) = N'I' 
		SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
	ELSE 
		SET @CSZ = @CSZ
	IF @C_state <> N'' OR @C_zip <> N''
	BEGIN
	      IF @CSZ <> N'' 
	           SET @CSZ = @CSZ + N', ' + @C_state
	      ELSE
	           SET @CSZ = @C_state
	END
	IF @C_zip <> N'' 
	BEGIN
	      IF @CSZ <> N''
	        SET @CSZ = @CSZ + N' ' + @C_zip
	      ELSE
	        SET @CSZ = @C_zip
	END
	IF @CSZ <> N'' 
	BEGIN
	      IF @VSTR <> N'' 
	        SET @VSTR = @VSTR + CHAR(10) + @CSZ
	      ELSE
	        SET @VSTR = @CSZ
	END
    END
/* End Get Full Name, address line 1, City, state and zip formated in block */
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
    END
/* Get Address 1, 2 and 3 in line */
  ELSE IF UPPER(@Get_Field)=N'ADDRESS123_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END                   
    END
  /* Get City, State and Zip */
  ELSE IF UPPER(@Get_Field)=N'CSZ' 
    BEGIN                                          
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
    END
/*Get all information of business name & fullname & fulladdress */  
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR123'
BEGIN
       IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	   IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
           IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/*Get all information of business name & fullname & fulladdress & phone1 */  
  ELSE IF UPPER(@Get_Field)=N'NAME_ADDR123_PHONE'
BEGIN
       IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        IF @C_fname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	   IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
           IF @C_addr1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr1
                      ELSE
                        SET @VSTR = @C_addr1
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
            IF @C_phone1 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_phone1
                      ELSE
                        SET @VSTR = @C_phone1
               END   
    END
/*12/15/2006  Sandy Yin  Added IF UPPER(@Get_Field)='NAME_ORAG_ADDRS' (Get all information of business name & fullname & address1,2,3) for SAN 06SSP-00124.R61214 */
  ELSE IF UPPER(@Get_Field)=N'NAME_ORAG_ADDRS'
  BEGIN
              IF @C_fname <> N''
              BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + CHAR(10) + @C_fname
               ELSE
                        SET @VSTR = @C_fname
               END
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	   IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
           IF @C_Bname <> N''
            BEGIN IF @VSTR<>N''
            SET @VSTR = @VSTR+CHAR(10)+ @C_Bname
            ELSE
             SET  @VSTR=@C_Bname
            END
	    IF UPPER(@Case) = N'U' 
	           SET @VSTR = UPPER(@VSTR)
	         ELSE IF UPPER(@Case) = N'I' 
	           SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	         ELSE 
	            SET @VSTR = @VSTR
              BEGIN
                      IF @C_addr1 <> N'' 
                        SET  @ADDR= @C_addr1
                      ELSE
                        SET  @ADDR = N''
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR + CHAR(10)+ @C_addr2
                      ELSE
                        SET @ADDR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR +CHAR(10) + @C_addr3
                      ELSE
                              SET @ADDR = @C_addr3
              END
            IF  @ADDR<>N'' 
              BEGIN
	              IF  @VSTR<>N'' 
	               SET  @VSTR=@VSTR+CHAR(10)+@ADDR
	              ELSE  SET @VSTR= @ADDR
              END
IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/*12/15/2006  Sandy Yin  Added IF UPPER(@Get_Field)='NAME_ORAG_ADDRS' (Get all information of business name & fullname & address1,2,3) for SAN 06SSP-00124.R61214  end */
/*12/22/2006  Sandy Yin  Added IF UPPER(@Get_Field)='ORAG_ADDRS' (Get all information of business name & address1,2,3) for SAN 06SSP-00124.R61214 */
  ELSE IF UPPER(@Get_Field)=N'ORAG_ADDRS'
  BEGIN
           IF @C_Bname <> N''
            BEGIN IF @VSTR<>N''
            SET @VSTR = @VSTR+CHAR(10)+ @C_Bname
            ELSE
             SET  @VSTR=@C_Bname
            END
	    IF UPPER(@Case) = N'U' 
	           SET @VSTR = UPPER(@VSTR)
	         ELSE IF UPPER(@Case) = N'I' 
	           SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
	         ELSE 
	            SET @VSTR = @VSTR
              BEGIN
                      IF @C_addr1 <> N'' 
                        SET  @ADDR= @C_addr1
                      ELSE
                        SET  @ADDR = N''
              END         
            IF @C_addr2 <> N''
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR + CHAR(10)+ @C_addr2
                      ELSE
                        SET @ADDR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @ADDR <> N'' 
                        SET @ADDR = @ADDR +CHAR(10) + @C_addr3
                      ELSE
                              SET @ADDR = @C_addr3
              END
            IF  @ADDR<>N'' 
              BEGIN
	              IF  @VSTR<>N'' 
	               SET  @VSTR=@VSTR+CHAR(10)+@ADDR
	              ELSE  SET @VSTR= @ADDR
              END
IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP (N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
/*12/22/2006  Sandy Yin  Added IF UPPER(@Get_Field)='ORAG_ADDRS' (Get all information of business name & address1,2,3) for SAN 06SSP-00124.R61214  end */
/* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FIRSTNAME' 
    BEGIN
    	IF @C_fname <> N''
    	  SET @VSTR = @C_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LASTNAME' 
    BEGIN
    	IF @C_lname <> N''
    	  SET @VSTR = @C_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MIDDLENAME' 
    BEGIN
    	IF @C_mname <> N''
    	  SET @VSTR = @C_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END     
/* 02/10/2006 BEGIN  NameFormat='FMIL' for {First Name + ' ' + Middle Initial + ' ' + Last Name for 07SSP-00068 basically oracle function*/
   ELSE IF UPPER(@NameFormat) = N'FMIL' 
     BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
               IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
                 IF @C_mname <> N''
           	  	SET @V_mname = SUBSTRING(UPPER(@C_mname),1,1)
           	IF @C_lname <> N''
             	SET @V_lname = @C_lname
		IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@C_lname)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@C_lname)
                 ELSE 
                    SET @C_lname = @C_lname                
	                IF @VSTR<>N'' 
		                BEGIN
				  IF @V_mname<>N''
		 			SET @VSTR =@VSTR+N' '+@V_mname
	                         ELSE 
					SET @VSTR=@VSTR
				END
  			IF @VSTR<>N'' 
		                BEGIN
				  IF @V_lname<>N''
		 			SET @VSTR =@VSTR+N' '+@V_lname
	                         ELSE 
					SET @VSTR=@VSTR
				END
             END
    END
/* END  02/10/2006  NameFormat='FMIL' for {First Name + ' ' + Middle Initial + ' ' + Last Name for 07SSP-00068 basically oracle function*/         
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR       
         END                           
    END
  /* Get Business Name  */
  ELSE IF UPPER(@Get_Field)=N'ORGNAME' 
        BEGIN
          IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  /* Get Title  */
  ELSE IF UPPER(@Get_Field)=N'TITLE' 
     BEGIN
          IF @C_title <> N''
            SET @VSTR = @C_title
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
     END
  /* Get Phone  */
  ELSE IF UPPER(@Get_Field)=N'PHONE1' 
    BEGIN
    	IF @C_phone1 <> N''
    	  SET @VSTR = @C_phone1
    END
  ELSE IF UPPER(@Get_Field)=N'PHONE2' 
    BEGIN
    	IF @C_phone2 <> N''
    	  SET @VSTR = @C_phone2
    END
  /* Get Fax  */
  ELSE IF UPPER(@Get_Field)=N'FAX' 
    BEGIN
    	IF @C_fax <> N''
    	  SET @VSTR = @C_fax
    END
ELSE IF UPPER(@Get_Field)=N'FAX_PARENTHESES'  
--{(NNN) NNN-NNNN}
  BEGIN 
    if @C_fax <>N''
       SET @VSTR =N''
    else
      SET @V_Fax= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_fax)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
        BEGIN 
            IF  LEN(@V_Fax)>7 
               SET @VSTR =N'('+SUBSTRING(@V_Fax,1,3)+N')'+N' '+SUBSTRING(@V_Fax,4,3)+N'-'+SUBSTRING(@V_Fax,7,4)
            ELSE
                SET @VSTR = SUBSTRING(@V_Fax,1,3)+N'-'+SUBSTRing(@V_Fax,4,4)
            END;
 END 
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @C_country <> N''
              SET @VSTR = @C_country
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get Email  */
  ELSE IF UPPER(@Get_Field)=N'EMAIL' 
        BEGIN
            IF @C_email <> N''
              SET @VSTR = @C_email
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END    
  /* Get @Relation (Contact Relationship) */
  ELSE IF UPPER(@Get_Field)=N'CONTACTRELATIONSHIP' 
        BEGIN
            IF @C_Relation <> N''
              SET @VSTR = @C_Relation
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get Contact Type  */
  ELSE IF UPPER(@Get_Field)=N'CONTACTTYPE' 
        BEGIN
            IF @C_ContactType <> N''
              SET @VSTR = @C_ContactType
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END 
 /* Get Phone or Phone with format */
   ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT7'  
      if @C_phone1  =N''
        SET @VSTR=null;
      else
        BEGIN 
        	SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
        BEGIN   
		IF  LEN(@V_Phone)>7  
	        	SET @VSTR=  SUBSTRING(SUBSTRING(@V_Phone,LEN(@V_Phone)-6,7),1,3)+N'-'+SUBSTRING(SUBSTRING(@V_Phone,LEN(@V_Phone)-6,7),4,7)
	            ELSE
	               SET @VSTR= SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,4)
	            END
       end 
 /* PHONE1_FORMAT10  -  Formats phone # as NNN-NNN-NNNN or NNN-NNNN */
 ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT10'   
      if @C_phone1  =N''
        SET @VSTR=null;
      else
      BEGIN 
        SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
       BEGIN
           IF   LEN(@V_Phone)>7  
              SET @VSTR=   SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,3)+N'-'+SUBSTRING(@V_Phone,7,4)
            ELSE
               SET @VSTR=  SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,4)
            END
        END
  /* PHONE1_FORMAT10_PARENTHESES  -  Formats phone # as (NNN) NNN-NNNN or NNN-NNNN */
  ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT10_PARENTHESES'   
   BEGIN 
     if @C_phone1  =N''
        SET @VSTR=null;
    else
     BEGIN 
      SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
	  BEGIN   
        IF  LEN(@V_Phone)>7  
	               SET @VSTR=   N'('+SUBSTRING(@V_Phone,1,3)+N')'+N' '+SUBSTRING(@V_Phone,4,3)+N'-'+SUBSTRING(@V_Phone,7,4)
        ELSE
                	SET @VSTR= SUBSTRING(@V_Phone,1,3)+N'-'+SUBSTRING(@V_Phone,4,4)
      END
     END
   END 
  /* PHONE1_FORMAT11_PARENTHESES  -  Formats phone # as (NNN) NNN NNNN or NNN NNNN */
  ELSE IF UPPER(@Get_Field)=N'PHONE1_FORMAT11_PARENTHESES'   
    BEGIN
	  IF @C_phone1=N'' OR @C_phone1 IS NULL
		SET @VSTR = N''
	  ELSE
		BEGIN 
          SET @V_Phone= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(@C_phone1)),N'-',N''),N'_',N''),N' ',N''),N'(',N''),N')',N'')
          IF LEN(@V_Phone)>7  
            SET @VSTR=N'('+SUBSTRING(@V_Phone,1,3)+N')'+N' '+SUBSTRING(@V_Phone,4,3)+N' '+SUBSTRING(@V_Phone,7,4)
          ELSE
            SET @VSTR= SUBSTRING(@V_Phone,1,3)+N' '+SUBSTRING(@V_Phone,4,4)
	    END
    END		
  /* FL_ORGNAME {First Name + ' ' + Last Name +', ' +Organization Name }  */
  ELSE IF UPPER(@Get_Field)=N'FL_ORGNAME'   
    BEGIN
         IF UPPER(@Case) = N'U'  
            SET @VSTR= UPPER(@C_fname + N' ' + @C_lname);
         ELSE IF  UPPER(@Case) = N'I'  
            SET @VSTR= DBO.FN_GET_INITCAP (N'',@C_fname + N' ' + @C_lname);
         ELSE
            SET @VSTR= @C_fname + N' ' + @C_lname;
         IF @C_BName <>N'' 
           IF UPPER(@Case) = N'U'  
              SET @VSTR=@VSTR+N', ' +  UPPER(@C_BName);
           ELSE IF  UPPER(@Case) = N'I'  
              SET @VSTR= @VSTR+N', ' +DBO.FN_GET_INITCAP (N'',@C_BName);
           ELSE
              SET @VSTR= @VSTR+N', ' +@C_BName;
    END;
/* 'FL_FULLADDR_PHONE1' {First Name + " " + Last Name + ", " + Address 1 + ", " + Address 2 + ", " + Address 3 + ", " + City + ", " + State + " " + Zip  +". Telephone: " + Phone 1} */
 ELSE IF  UPPER(@Get_Field)=N'FL_FULLADDR_PHONE1'   
    BEGIN
         IF @C_fname <>N''AND  @C_fname <>N'' 
          BEGIN 
           IF UPPER(@Case) = N'U'  
              SET @VSTR= UPPER(@C_fname + N' ' + @C_lname);
           ELSE IF  UPPER(@Case) = N'I'  
              SET @VSTR= DBO.FN_GET_INITCAP (N'',@C_fname + N' ' + @C_lname);
           ELSE
              SET @VSTR= @C_fname + N' ' + @C_lname;
         END
         IF @C_addr1 <>N'' 
            SET @VSTR= @VSTR +N', '+@C_addr1;
          IF @C_addr2 <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_addr2;
          IF @C_addr3 <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_addr3;
          IF @C_city <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_city;
          IF @C_state <>N'' 
            IF @VSTR <>N'' 
              SET @VSTR= @VSTR + N', ' + @C_state;
          IF @C_zip <>N'' 
            SET @VSTR= @VSTR + N' ' + @C_zip;
          IF UPPER(@Case) = N'U'  
            SET @VSTR= UPPER(@VSTR);
          ELSE IF  UPPER(@Case) = N'I'  
            SET @VSTR= DBO.FN_GET_INITCAP (N'',@VSTR);
          ELSE
            SET @VSTR= @VSTR;
         IF @VSTR <>N''  
            SET @VSTR= @VSTR +N'.';
         IF @C_phone1 <>N'' 
            SET @VSTR= @VSTR + N' Telephone:  ' +@C_phone1;
    END;    
  /* GET Full Name (FML),Address 1,Address 2,in block format */
ELSE IF  UPPER(@Get_Field)=N'NAME_ADDR12_BLK'  
 	BEGIN   
	    IF @C_addr1 <>N'' 
	      SET @VSTR= @C_addr1;
	     ELSE
	       SET @VSTR= N'';
	    IF @C_addr2 <>N'' 
	      IF @VSTR <>N'' 
	        SET @VSTR= @VSTR + CHAR(10) + @C_addr2;
	      ELSE
	        SET @VSTR= @C_addr2;
    IF UPPER(@NameFormat) = N'FML'  
      BEGIN
      		IF ltrim(@C_fname+@C_lname) <>N'' 
           		BEGIN 
	          		 IF @C_mname <>N'' 
	          		    BEGIN
				            IF @VSTR <>N'' 
				                SET @VSTR=ltrim(@C_fname + N' ' +@C_mname+ N' '+@C_lname)+CHAR(10)+@VSTR;
				            ELSE
					  	SET @VSTR=ltrim(@C_fname+N' '+@C_mname+N' '+@C_lname);
	           		    END 
                         END
           ELSE
	           BEGIN 
	            IF @VSTR <>N'' 
	                SET @VSTR=ltrim(@C_fname+N' '+@C_lname)+CHAR(10)+@VSTR;
	            ELSE
					SET @VSTR=ltrim(@C_fname+N' '+@C_lname);
	             END 
       END
	   IF UPPER(@Case) = N'U'  
		   SET @VSTR= UPPER(@VSTR);
		 ELSE IF  UPPER(@Case) = N'I'  
		   SET @VSTR= DBO.FN_GET_INITCAP (N'',@VSTR);
		 ELSE
		   SET @VSTR= @VSTR;
	  END
 /* 'ORG_FULLADDR_FL_PHONE1'  {Organization Name + ", " + Address 1 + ", " + Address 2 + ", " + Address 3 + ", " + City + ", " + State + " " + Zip  + ". Contact: " + First Name + " " + Last Name +' '+ Phone 1}    */
  ELSE IF UPPER(@Get_Field)=N'ORG_FULLADDR_FL_PHONE1'   
    BEGIN
         IF @C_BName <>N''
           BEGIN 
           IF UPPER(@case) = N'U'  
              set @VSTR =UPPER(@C_BName);
           ELSE IF UPPER(@case) = N'I'  
              set @VSTR =DBO.FN_GET_INITCAP(N'',@C_BName);
           ELSE
              set @VSTR =@C_BName;
           END 
         IF @C_addr1 <>N''
          BEGIN 
           IF @C_BName <>N''
              set @VSTR = @VSTR +N', ' +@C_addr1;
           ELSE
               set @VSTR =  @VSTR +@C_addr1;
           END 
          IF @C_addr2 <>N''
           BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_addr2;
            END
          IF @C_addr3 <>N''
            BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_addr3;
            END
          IF @C_city <>N''
           BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_city;
            END 
          IF @C_state <>N''
           BEGIN 
            IF @VSTR <>N''
              set @VSTR = @VSTR + N', ' + @C_state;
            END 
          IF @C_zip <>N''
            set @VSTR = @VSTR + N' ' + @C_zip;
          IF UPPER(@case) = N'U'  
            set @VSTR = UPPER(@VSTR);
          ELSE IF UPPER(@case) = N'I'  
            set @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR);
          ELSE
            set @VSTR = @VSTR;
         IF @VSTR <>N''
            set @VSTR =@VSTR +N'.';
         IF @C_fname <>N''AND  @C_lname <>N''
         BEGIN
           IF UPPER(@case) = N'U'  
              set @VSTR = @VSTR +N' Contact: '+ UPPER(@C_fname + N' ' + @C_lname);
           ELSE IF UPPER(@case) = N'I'  
              set @VSTR = @VSTR +N' Contact: '+ DBO.FN_GET_INITCAP(N'',@C_fname + N' ' + @C_lname);
           ELSE
              set @VSTR = @VSTR +N' Contact: '+ @C_fname + N' ' + @C_lname;
           END 
         IF @C_phone1 <>N''
            set @VSTR = @VSTR + N' ' +@C_phone1;       
    END;
  /* Get FullName as @Get_Field is not one of the correct options  */  
  ELSE
    BEGIN
      IF UPPER(@NameFormat) = N'LFM'         BEGIN
	   IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FML' 
        BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END     
      ELSE IF UPPER(@NameFormat) = N'LF' 
        BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FL' 
        BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE
        BEGIN
           IF @C_FULLNAME = N'' OR @C_FULLNAME IS NULL
             BEGIN
           	IF @C_fname <> N''
         	    SET @VSTR = @C_fname
        	IF @C_mname <> N''
           	  	BEGIN
              		 IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_mname
               		 ELSE
                         	SET @VSTR = @C_mname
             		END
           	IF @C_lname <> N''
             		BEGIN
               		  IF @VSTR <>N''                            
                       		SET @VSTR = @VSTR + N' ' + @C_lname
              		  ELSE
                        	SET @VSTR = @C_lname
             		END
             END
           IF @C_FULLNAME <>N'' OR @C_FULLNAME IS NOT NULL
		SET @VSTR = @C_FULLNAME
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP (N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
       END
  END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONTACT_INFO_ALL]
	(@CLIENTID NVARCHAR(15),
	 @PID1 NVARCHAR(5),
	 @PID2 NVARCHAR(5),
	 @PID3 NVARCHAR(5),
	 @ContactType NVARCHAR(30),
	 @Get_Field NVARCHAR(100),
	 @NameFormat NVARCHAR(20),
         @Case NVARCHAR(1),
	 @Delimiter NVARCHAR(20)
	 )
RETURNS NVARCHAR(4000) AS
/*  Author          :  	Arthur Miao
    Create Date     :   07/14/2005
    Version         :  	AA6.1 MS SQL
    Detail          :   RETURNS: All Contacts whose contact type is in {ContactType}; if no {ContactType} is specified, returns all Contacts.  Returns field value as specified by {Get_Field}. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {Case} is 'U', return value is in UPPERCASE; if {Case} is 'I', return value is in Initial Capitals. Values will be separated by {Delimiter} or line breaks if {Delimiter} is not specified.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ContactType (optional, may be comma-delimited list), Get_Field (Options: 'FULLNAME','ADDRESS','FULLNAME_BLOCK_ORGNAME'), NameFormat (Options: 'FML' for First Middle Initial Last; 'FULLFML' for First Middle Last), Case (optional, 'U' for uppercase, 'I' for initial case), Delimiter (default is single line break).
  Revision History :	07/14/2005 Arthur Miao initial design 
  			07/26/2005 Sandy Yin   add field  FULLNAME_BLOCK_ORGNAME (full_name and Business name, use line Break.) 
			09/08/2005 Sunny Chen  add 'FULLFML' for 'First Middle Last'
*/
BEGIN 
DECLARE
	@TEM	  NVARCHAR(4000),
	@Result	  NVARCHAR(4000),
	@VSTR NVARCHAR(4000),
	@VTEM NVARCHAR(4000),
	@LASTSTRING NVARCHAR(4000),
	@STARTPOS INT,
	@ENDPOS INT,
	@TMPPOS INT;
	set  @TEM=N'';
	set  @Result =N'';
	SET @STARTPOS = 1;
	SET @TMPPOS = 1;
	SET @VSTR = N'';
WHILE (@TMPPOS<=LEN(@ContactType))
BEGIN
	IF (SUBSTRING(@ContactType,@TMPPOS,1) = N',')
                 BEGIN
	            SET @VTEM = LTRIM(RTRIM(SUBSTRING(@ContactType,@STARTPOS,@TMPPOS-@STARTPOS)))                
		IF (@VTEM != N'')
      BEGIN
		IF (@VSTR != N'')
		        SET @VSTR=@VSTR+N','''+@VTEM+N''''
	  	ELSE
               		SET @VSTR=N''''+@VTEM+N''''
      END
    SET @TMPPOS = @TMPPOS +1
    SET @STARTPOS = @TMPPOS
END
ELSE
    SET @TMPPOS = @TMPPOS +1			
END
SET @LASTSTRING = LTRIM(RTRIM(SUBSTRING(@ContactType,@STARTPOS,@TMPPOS-@STARTPOS)))
IF (@LASTSTRING != N'')
BEGIN
IF (@VSTR=N'')
	SET @VSTR =@VSTR + N''''+ @LASTSTRING+N''''
ELSE
	SET @VSTR =@VSTR +  N','''+@LASTSTRING+N''''
END
  BEGIN
	DECLARE CURSOR_1 CURSOR FOR
	SELECT 
	 CASE WHEN UPPER(@Get_Field) = N'FULLNAME'  
	      THEN CASE WHEN UPPER(@NameFormat) = N'FML'
	      		THEN CASE WHEN ISNULL(B1_FNAME,N'')=N'' THEN B1_LNAME
		         ELSE 
		  	    	 CASE WHEN ISNULL(B1_MNAME,N'')=N'' THEN LTRIM(RTRIM(B1_FNAME+N' '+ISNULL(B1_LNAME,N'')))
			        	  ELSE LTRIM(RTRIM(B1_FNAME+N' '+UPPER(SUBSTRING(ltrim(B1_MNAME),1,1)) +N' '+ISNULL(B1_LNAME,N'')))
		    	    	  END
			      END
	      	        WHEN UPPER(@NameFormat) = N'FULLFML'
	      		THEN CASE WHEN ISNULL(B1_FNAME,N'')=N'' THEN 
				CASE WHEN ISNULL(B1_MNAME,N'')= N'' THEN N'' 
		    			 ELSE B1_MNAME + N' ' END + CASE WHEN ISNULL(B1_LNAME,N'')= N'' THEN N'' ELSE B1_LNAME END
		         ELSE 
		  	     CASE WHEN ISNULL(B1_MNAME,N'')=N'' THEN LTRIM(RTRIM(B1_FNAME+N' '+ISNULL(B1_LNAME,N'')))
			          ELSE LTRIM(RTRIM(B1_FNAME+N' '+UPPER(ltrim(B1_MNAME)) +N' '+ISNULL(B1_LNAME,N'')))
		    	     END END
	            END
	     WHEN UPPER(@Get_Field) = N'ADDRESS'
	     THEN B1_ADDRESS1
	     WHEN  UPPER(@Get_Field) = N'FULLNAME_BLOCK_ORGNAME'
	     THEN  (LTRIM(CASE WHEN ISNULL(B1_FNAME,N'') =N'' THEN N'' ELSE B1_FNAME+N' ' END) +ISNULL(B1_LNAME,N'')+
	           CASE WHEN ISNULL(B1_BUSINESS_NAME,N'')=N'' THEN N'' 
	                ELSE CASE WHEN ISNULL(B1_FNAME,N'')+ISNULL(B1_LNAME,N'')=N'' THEN B1_BUSINESS_NAME 
	                	ELSE  CHAR(10)+B1_BUSINESS_NAME END 
	      END)
	 END
	FROM 
	  B3CONTACT
	WHERE 
	  REC_STATUS = N'A' AND
	  SERV_PROV_CODE = @CLIENTID AND
	  B1_PER_ID1 = @PID1 AND
	  B1_PER_ID2 = @PID2 AND
	  B1_PER_ID3 = @PID3 AND
	  ((@ContactType <> N'' and CHARINDEX(UPPER(B1_CONTACT_TYPE),UPPER(@VSTR))>0) OR @ContactType = N'')
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @TEM
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if (@TEM <> N'')
			if (@Result = N'')
				SET @Result = @TEM
			else
			     if @Delimiter <> N''
				SET @Result = @Result + @Delimiter+ @TEM
			     ELSE
			     	SET @Result = @Result + CHAR(10) + @TEM
	FETCH NEXT FROM CURSOR_1 INTO @TEM
	END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
  END
IF UPPER(@Case)=N'U'
   set @Result=upper(@Result)
IF UPPER(@Case)=N'I'
   set @Result=dbo.FN_GET_INITCAP(N'',@Result)
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_CONTACT_INFO_BY_NBR] (@CLIENTID  NVARCHAR(15),
                                            @PID1    NVARCHAR(5),
                                            @PID2    NVARCHAR(5),
                                            @PID3   NVARCHAR(5),
                                            @ContactNbr BIGINT,
                                            @Get_Field NVARCHAR(20),
                                            @NameFormat NVARCHAR(3),
                                            @Case NVARCHAR(1)
                                            ) RETURNS NVARCHAR (200)  AS
/*  Author           :   David Zheng
    Create Date      :   07/22/2005
    Version          :   AA6.0 MS SQL
    Detail           :   RETURNS: Contact information, as follows:  Returns contact whose contact number is {ContactNbr}. Returns field value as specified by {Get_Field}. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {Case} is 'U', return value is in UPPERCASE if {Case} is 'I', return value is in Initial Capitals.
                         ARGUMENTS: @CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, ContactNbr, Get_Field (Options:'FullName','FirstName','MiddleName','LastName','Title','OrgName','Address1','Address2','Address3','City','State','Zip', 'Phone1','Phone2','Email','Fax','FullAddr_Block','FullAddr_Line','ContactType','ContactRelationship', blank or others for Full Name(FML)), NameFormat (Options: 'FML','LFM','FLM','FL','LF' optional, blank or others for FML), Case ('U' for uppercase, 'I' for initial-caps, blank for original case).
    Revision History :   07/22/2005  David Zheng Initial Design
*/
BEGIN 
DECLARE 
  @VSTR NVARCHAR(200),
  @C_Bname NVARCHAR(65),
  @C_FullName NVARCHAR(80),
  @C_title NVARCHAR(10),
  @C_fname NVARCHAR(15),
  @C_mname NVARCHAR(15),
  @C_lname NVARCHAR(35),
  @C_addr1 NVARCHAR(40),
  @C_addr2 NVARCHAR(40),
  @C_addr3 NVARCHAR(40),
  @C_city NVARCHAR(30),
  @C_state NVARCHAR(2),
  @C_zip NVARCHAR(10),
  @C_country NVARCHAR(30),
  @C_phone1 NVARCHAR(40),
  @C_phone2 NVARCHAR(40),
  @C_fax NVARCHAR(15),
  @C_email NVARCHAR(80),
  @C_Relation NVARCHAR(30),
  @C_ContactType NVARCHAR(30),
  @CSZ NVARCHAR(50)
    BEGIN
      SELECT TOP 1 
        @C_title = B1_TITLE,
        @C_fname = B1_FNAME,
        @C_mname = B1_MNAME,
        @C_lname = B1_LNAME,
        @C_FullName = B1_FULL_NAME,
        @C_Relation = B1_Relation,
        @C_Bname = B1_BUSINESS_NAME,
        @C_addr1 = B1_ADDRESS1,
        @C_addr2 = B1_ADDRESS2,
        @C_addr3 = B1_ADDRESS3,
        @C_city = B1_CITY,
        @C_state = B1_STATE,
        @C_zip = B1_ZIP,
        @C_country = B1_COUNTRY,
        @C_phone1 = B1_PHONE1,
        @C_phone2 = B1_PHONE2,
        @C_fax = B1_FAX,
        @C_email = B1_EMAIL,
        @C_ContactType = B1_CONTACT_TYPE
      FROM  
        B3CONTACT
      WHERE 
        SERV_PROV_CODE = @CLIENTID AND
        REC_STATUS = N'A' AND
        B1_PER_ID1 = @PID1 AND
        B1_PER_ID2 = @PID2 AND
        B1_PER_ID3 = @PID3 AND
        B1_CONTACT_NBR = @ContactNbr
    END
  /* Get Address  */
  IF UPPER(@Get_Field)=N'ADDRESS1' 
    BEGIN
    BEGIN
    	IF @C_addr1 <> N''
    	  SET @VSTR = @C_addr1
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
    BEGIN
    BEGIN
    	IF @C_addr2 <> N''
    	  SET @VSTR = @C_addr2
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3' 
    BEGIN
    BEGIN
    	IF @C_addr3 <> N''
    	  SET @VSTR = @C_addr3
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
    BEGIN
    BEGIN
    	IF @C_city <> N''
    	  SET @VSTR = @C_city
    END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'STATE' 
    BEGIN
    	IF @C_state <> N''
    	  SET @VSTR = @C_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP' 
    BEGIN
    	IF @C_zip <> N''
    	  SET @VSTR = @C_zip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @CSZ = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @CSZ = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @CSZ = @CSZ
            IF @C_state <> N'' 
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
    END
  /* Get City, State and Zip */
  ELSE IF UPPER(@Get_Field)=N'CSZ' 
    BEGIN                                          
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @VSTR = @CSZ
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END                        
    END
  /* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FIRSTNAME' 
    BEGIN
    	IF @C_fname <> N''
    	  SET @VSTR = @C_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LASTNAME' 
    BEGIN
    	IF @C_lname <> N''
    	  SET @VSTR = @C_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MIDDLENAME' 
    BEGIN
    	IF @C_mname <> N''
    	  SET @VSTR = @C_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END           
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR       
         END                           
    END
  /* Get Business Name  */
  ELSE IF UPPER(@Get_Field)=N'ORGNAME' 
        BEGIN
          IF @C_Bname <> N''
            SET @VSTR = @C_Bname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  /* Get Title  */
  ELSE IF UPPER(@Get_Field)=N'TITLE' 
     BEGIN
          IF @C_title <> N''
            SET @VSTR = @C_title
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
     END
  /* Get Phone  */
  ELSE IF UPPER(@Get_Field)=N'PHONE1' 
    BEGIN
    	IF @C_phone1 <> N''
    	  SET @VSTR = @C_phone1
    END
  ELSE IF UPPER(@Get_Field)=N'PHONE2' 
    BEGIN
    	IF @C_phone2 <> N''
    	  SET @VSTR = @C_phone2
    END
  /* Get Fax  */
  ELSE IF UPPER(@Get_Field)=N'FAX' 
    BEGIN
    	IF @C_fax <> N''
    	  SET @VSTR = @C_fax
    END
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @C_country <> N''
              SET @VSTR = @C_country
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get Email  */
  ELSE IF UPPER(@Get_Field)=N'EMAIL' 
        BEGIN
            IF @C_email <> N''
              SET @VSTR = @C_email
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END    
  /* Get @Relation (Contact Relationship) */
  ELSE IF UPPER(@Get_Field)=N'CONTACTRELATIONSHIP' 
        BEGIN
            IF @C_Relation <> N''
              SET @VSTR = @C_Relation
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get Contact Type  */
  ELSE IF UPPER(@Get_Field)=N'CONTACTTYPE' 
        BEGIN
            IF @C_ContactType <> N''
              SET @VSTR = @C_ContactType
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  ELSE
  /* Get Name as @Get_Field not one of the correct options  */
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
        BEGIN
	   IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FML' 
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
        END     
      ELSE IF UPPER(@NameFormat) = N'LF' 
        BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE IF UPPER(@NameFormat) = N'FL' 
        BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
        END
      ELSE
        BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
       END
  END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_DEFENDANT_INFO] (@CLIENTID  NVARCHAR(15),
 				      	    @PID1    NVARCHAR(5),
 				      	    @PID2    NVARCHAR(5),
 				      	    @PID3   NVARCHAR(5),
                                            @PrimaryDefendant NVARCHAR(1),
                                            @Get_Field NVARCHAR(20),
                                            @NameFormat NVARCHAR(3),
 				      	    @CASE NVARCHAR(1)) RETURNS NVARCHAR (4000)  AS
/*  Author           :   David Zheng
    Create Date      :   05/19/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Defendant information, as follows: If {PrimaryDefendant} is 'Y', returns primary Defendant; else returns first Defendant. Returns contact whose contact type is {ContactType} (optional) and whose contact relationship is {Relation} (optional). Returns field value as specified by {Get_Field}. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {UI_Case} is 'U', return value is in UPPERCASE; if {UI_Case} is 'I', return value is in Initial Capitals.
                         ARGUMENTS: CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, PrimaryDefendant (Optional), Get_Field (Options:'FullName','FirstName','MiddleName','LastName','Title','OrgName','Address1','Address2','Address3','City','State','Zip', 'Phone1','Phone', Email', 'Fax','FullAddr_Block','FullAddr_Line','ContactType','ContactRelationship', blank or others for Full Name(FML)), NameFormat (Options: 'FML','LFM','FL','LF'; optional, blank or others for FML), UI_Case ('U' for uppercase, 'I' for initial-caps, blank for original case).
    Revision History :   05/19/2005  David Zheng Initial Design
*/
BEGIN
DECLARE
  @VSTR NVARCHAR(4000),
  @C_FullName NVARCHAR(80),
  @C_fname NVARCHAR(15),
  @C_mname NVARCHAR(15),
  @C_lname NVARCHAR(35),
  @C_addr1 NVARCHAR(40),
  @C_addr2 NVARCHAR(40),
  @C_addr3 NVARCHAR(40),
  @C_city NVARCHAR(30),
  @C_state NVARCHAR(2),
  @C_zip NVARCHAR(10),
  @C_country NVARCHAR(30),
  @C_comment NVARCHAR(240),
  @CSZ NVARCHAR(50)
  IF UPPER(@PrimaryDefendant) = N'Y' 
    BEGIN			
	SELECT 	TOP 1 
	      @C_addr1=C3_DEFENDANT_ADDRESS1, 
	      @C_addr2=C3_DEFENDANT_ADDRESS2, 
	      @C_addr3=C3_DEFENDANT_ADDRESS3, 
	      @C_city=C3_DEFENDANT_CITY, 
	      @C_comment=C3_DEFENDANT_COMMENT, 
	      @C_country=C3_DEFENDANT_COUNTRY, 
	      @C_fname=C3_DEFENDANT_FNAME, 
	      @C_fullname=C3_DEFENDANT_FULL_NAME,  
	      @C_lname=C3_DEFENDANT_LNAME, 
	      @C_mname=C3_DEFENDANT_MNAME, 
	      @C_state=C3_DEFENDANT_STATE, 
	      @C_zip=C3_DEFENDANT_ZIP
	FROM	
	      C3DEFENDANT
	WHERE	
	      SERV_PROV_CODE = @CLIENTID AND		
	      B1_PER_ID1 = @PID1 AND		
	      B1_PER_ID2 = @PID2 AND		
	      B1_PER_ID3 = @PID3 AND 	
	      REC_STATUS = N'A'  AND
	      C3_PRIMARY_DEFENDANT = N'A'
	      ORDER BY C3_PRIMARY_DEFENDANT
    END
  ELSE
    BEGIN
	SELECT 	TOP 1 
	      @C_addr1=C3_DEFENDANT_ADDRESS1, 
	      @C_addr2=C3_DEFENDANT_ADDRESS2, 
	      @C_addr3=C3_DEFENDANT_ADDRESS3, 
	      @C_city=C3_DEFENDANT_CITY, 
	      @C_comment=C3_DEFENDANT_COMMENT, 
	      @C_country=C3_DEFENDANT_COUNTRY, 
	      @C_fname=C3_DEFENDANT_FNAME, 
	      @C_fullname=C3_DEFENDANT_FULL_NAME,  
	      @C_lname=C3_DEFENDANT_LNAME, 
	      @C_mname=C3_DEFENDANT_MNAME, 
	      @C_state=C3_DEFENDANT_STATE, 
	      @C_zip=C3_DEFENDANT_ZIP
	FROM	
	      C3DEFENDANT
	WHERE	
	      SERV_PROV_CODE = @CLIENTID AND		
	      B1_PER_ID1 = @PID1 AND		
	      B1_PER_ID2 = @PID2 AND		
	      B1_PER_ID3 = @PID3 AND 	
	      REC_STATUS = N'A' 
	      ORDER BY C3_PRIMARY_DEFENDANT
  END
  /* Get Address  */
  IF UPPER(@Get_Field)=N'ADDRESS1' 
    BEGIN
    	IF @C_addr1 <> N''
    	  SET @VSTR = @C_addr1
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
    BEGIN
    	IF @C_addr2 <> N''
    	  SET @VSTR = @C_addr2
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3' 
    BEGIN
    	IF @C_addr3 <> N''
    	  SET @VSTR = @C_addr3
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
    BEGIN
    	IF @C_city <> N''
    	  SET @VSTR = @C_city
    END
  ELSE IF UPPER(@Get_Field)=N'STATE' 
    BEGIN
    	IF @C_state <> N''
    	  SET @VSTR = @C_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP' 
    BEGIN
    	IF @C_zip <> N''
    	  SET @VSTR = @C_zip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
    END
  /* Get City, State and Zip */
  ELSE IF UPPER(@Get_Field)=N'CSZ' 
    BEGIN                                          
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END                        
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @VSTR = @CSZ
    END
  /* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FIRSTNAME' 
    BEGIN
    	IF @C_fname <> N''
    	  SET @VSTR = @C_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LASTNAME' 
    BEGIN
    	IF @C_lname <> N''
    	  SET @VSTR = @C_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MIDDLENAME' 
    BEGIN
    	IF @C_mname <> N''
    	  SET @VSTR = @C_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END           
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR       
         END                           
    END
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @C_country <> N''
              SET @VSTR = @C_country
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get DEFENDANT FULL Name  */
  ELSE IF UPPER(@Get_Field)=N'DEFENDANTFULLNAME' 
        BEGIN
          IF @C_fullname <> N''
            SET @VSTR = @C_fullname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
          IF @C_country <> N''
            SET @VSTR = @C_country
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_DEFENDANT_INFO_ALL] (@CLIENTID NVARCHAR(15),
						 @PID1 NVARCHAR(5),
						 @PID2 NVARCHAR(5),
						 @PID3 NVARCHAR(5),
						 @Get_Field NVARCHAR(100),
						 @NameFormat NVARCHAR(20),
					   @Case NVARCHAR(1),
						 @Delimiter NVARCHAR(20)
						 )
							RETURNS NVARCHAR(4000) AS
/*  Author          :  	Sunny Chen
    Create Date     :   09/02/2005
    Version         :  	AA6.1 MS SQL
    Detail          :   RETURNS: Info about all Defendants on the Case. Returns field value as specified by {Get_Field}. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {Case} is 'U', return value is in UPPERCASE; if {Case} is 'I', return value is in Initial Capitals. Values will be separated by {Delimiter} or line breaks if {Delimiter} is not specified.
                        ARGUMENTS: ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, Get_Field (Options: 'FULLNAME','ADDRESS','FULLNAME_BLOCK_ORGNAME'), NameFormat (Options: 'FML' for First Middle Initial Last; 'FULLFML' for First Middle Last), Case (optional, 'U' for uppercase, 'I' for initial case), Delimiter (default is single line break).
  Revision History :	Sunny Chen initial design 09/02/2005
*/
BEGIN 
DECLARE
	@TEM	  NVARCHAR(4000),
	@Result	  NVARCHAR(4000);
	set  @TEM=N'';
	set  @Result =N'';
  BEGIN
	DECLARE CURSOR_1 CURSOR FOR
SELECT 
	 CASE WHEN UPPER(@Get_Field) = N'FULLNAME' AND UPPER(@NameFormat) = N'FULLFML'
	      THEN  CASE WHEN ISNULL(C3_DEFENDANT_FNAME,N'')=N'' THEN 
		CASE WHEN ISNULL(C3_DEFENDANT_MNAME,N'')= N'' THEN N'' 
		     ELSE C3_DEFENDANT_MNAME + N' ' END + CASE WHEN ISNULL(C3_DEFENDANT_LNAME,N'')= N'' THEN N'' ELSE C3_DEFENDANT_LNAME END
		         ELSE 
		  	     CASE WHEN ISNULL(C3_DEFENDANT_MNAME,N'')=N'' THEN LTRIM(RTRIM(C3_DEFENDANT_FNAME+N' '+ISNULL(C3_DEFENDANT_LNAME,N'')))
			          ELSE LTRIM(RTRIM(C3_DEFENDANT_FNAME+N' '+UPPER(ltrim(C3_DEFENDANT_MNAME)) +N' '+ISNULL(C3_DEFENDANT_LNAME,N'')))
		    	     END
	            END
	 END
	FROM 
	  C3DEFENDANT
	WHERE 
	  REC_STATUS = N'A' AND
	  SERV_PROV_CODE = @CLIENTID AND
	  B1_PER_ID1 = @PID1 AND
	  B1_PER_ID2 = @PID2 AND
	  B1_PER_ID3 = @PID3 
	OPEN CURSOR_1
	FETCH NEXT FROM CURSOR_1 INTO @TEM
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if (@TEM <> N'')
			if (@Result = N'')
				SET @Result = @TEM
			else
			     if @Delimiter <> N''
				SET @Result = @Result + @Delimiter+ @TEM
			     ELSE
			     	SET @Result = @Result + CHAR(10) + @TEM
	FETCH NEXT FROM CURSOR_1 INTO @TEM
	END 
	CLOSE CURSOR_1;
	DEALLOCATE CURSOR_1;
  END
IF UPPER(@Case)=N'U'
   set @Result=upper(@Result)
IF UPPER(@Case)=N'I'
   set @Result=dbo.FN_GET_INITCAP(N'',@Result)
RETURN  @Result
END
GO


ALTER FUNCTION [dbo].[FN_GET_DEFENDANT_INFO_BY_CITATN] (@CLIENTID  NVARCHAR(15),
 				      	    @PID1    NVARCHAR(5),
 				      	    @PID2    NVARCHAR(5),
 				      	    @PID3   NVARCHAR(5),
					    @CitationCaseNum NVARCHAR(30),
                                            @PrimaryDefendant NVARCHAR(1),
                                            @Get_Field NVARCHAR(20),
                                            @NameFormat NVARCHAR(3),
 				      	    @CASE NVARCHAR(1)) RETURNS NVARCHAR (4000)  AS
/*  Author           :   Sandy Yin
    Create Date      :   07/12/2005
    Version          :   AA6.0 MSSQL
    Detail           :   RETURNS: Defendant information for Citation number {CitationCaseNum}, as follows: If {PrimaryDefendant} is 'Y', returns primary Defendant; else returns first Defendant. If {Get_Field} is 'FullName', returns full name in the format specified by {NameFormat}. If {UI_Case} is 'U', return value is in UPPERCASE; if {UI_Case} is 'I', return value is in Initial Capitals.
                         ARGUMENTS: CLIENTID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, CitationCaseNum, PrimaryDefendant ('Y' or 'N'), Get_Field (Options:'FullName','FirstName','MiddleName','LastName','Title','OrgName','Address1','Address2','Address3','City','State','Zip', 'Phone1','Phone', Email', 'Fax','FullAddr_Block','FullAddr_Line','ContactType','ContactRelationship', blank or others for Full Name(FML)), NameFormat (Options: 'FML','LFM','FL','LF'; optional, blank or others for FML), UI_Case ('U' for uppercase, 'I' for initial-caps, blank for original case).
    Revision History :   07/12/2005  sandy Yin Initial Design
*/
BEGIN
DECLARE
  @VSTR NVARCHAR(4000),
  @C_FullName NVARCHAR(80),
  @C_fname NVARCHAR(15),
  @C_mname NVARCHAR(15),
  @C_lname NVARCHAR(35),
  @C_addr1 NVARCHAR(40),
  @C_addr2 NVARCHAR(40),
  @C_addr3 NVARCHAR(40),
  @C_city NVARCHAR(30),
  @C_state NVARCHAR(2),
  @C_zip NVARCHAR(10),
  @C_country NVARCHAR(30),
  @C_comment NVARCHAR(240),
  @CSZ NVARCHAR(50)
  IF UPPER(@PrimaryDefendant) = N'Y' 
    BEGIN			
	SELECT 	TOP 1 
	      @C_addr1=C3_DEFENDANT_ADDRESS1, 
	      @C_addr2=C3_DEFENDANT_ADDRESS2, 
	      @C_addr3=C3_DEFENDANT_ADDRESS3, 
	      @C_city=C3_DEFENDANT_CITY, 
	      @C_comment=C3_DEFENDANT_COMMENT, 
	      @C_country=C3_DEFENDANT_COUNTRY, 
	      @C_fname=C3_DEFENDANT_FNAME, 
	      @C_fullname=C3_DEFENDANT_FULL_NAME,  
	      @C_lname=C3_DEFENDANT_LNAME, 
	      @C_mname=C3_DEFENDANT_MNAME, 
	      @C_state=C3_DEFENDANT_STATE, 
	      @C_zip=C3_DEFENDANT_ZIP
	FROM	
	      C3DEFENDANT
	WHERE	
              ((@CitationCaseNum <> N'' and C3_CITATION_SEQ_NBR =@CitationCaseNum) OR @CitationCaseNum = N'') AND
	      SERV_PROV_CODE = @CLIENTID AND		
	      B1_PER_ID1 = @PID1 AND		
	      B1_PER_ID2 = @PID2 AND		
	      B1_PER_ID3 = @PID3 AND 	
	      REC_STATUS = N'A'  AND
	      C3_PRIMARY_DEFENDANT = N'A'
	      ORDER BY C3_PRIMARY_DEFENDANT
    END
  ELSE
    BEGIN
	SELECT 	TOP 1 
	      @C_addr1=C3_DEFENDANT_ADDRESS1, 
	      @C_addr2=C3_DEFENDANT_ADDRESS2, 
	      @C_addr3=C3_DEFENDANT_ADDRESS3, 
	      @C_city=C3_DEFENDANT_CITY, 
	      @C_comment=C3_DEFENDANT_COMMENT, 
	      @C_country=C3_DEFENDANT_COUNTRY, 
	      @C_fname=C3_DEFENDANT_FNAME, 
	      @C_fullname=C3_DEFENDANT_FULL_NAME,  
	      @C_lname=C3_DEFENDANT_LNAME, 
	      @C_mname=C3_DEFENDANT_MNAME, 
	      @C_state=C3_DEFENDANT_STATE, 
	      @C_zip=C3_DEFENDANT_ZIP
	FROM	
	      C3DEFENDANT
	WHERE	
	     ((@CitationCaseNum <>N'' AND  C3_CITATION_SEQ_NBR =@CitationCaseNum )OR @CitationCaseNum =N'') AND 
	      SERV_PROV_CODE = @CLIENTID AND		
	      B1_PER_ID1 = @PID1 AND		
	      B1_PER_ID2 = @PID2 AND		
	      B1_PER_ID3 = @PID3 AND 	
	      REC_STATUS = N'A' 
	      ORDER BY C3_PRIMARY_DEFENDANT
  END
  /* Get Address  */
  IF UPPER(@Get_Field)=N'ADDRESS1' 
    BEGIN
    	IF @C_addr1 <> N''
    	  SET @VSTR = @C_addr1
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS2' 
    BEGIN
    	IF @C_addr2 <> N''
    	  SET @VSTR = @C_addr2
    END
  ELSE IF UPPER(@Get_Field)=N'ADDRESS3' 
    BEGIN
    	IF @C_addr3 <> N''
    	  SET @VSTR = @C_addr3
    END
  ELSE IF UPPER(@Get_Field)=N'CITY' 
    BEGIN
    	IF @C_city <> N''
    	  SET @VSTR = @C_city
    END
  ELSE IF UPPER(@Get_Field)=N'STATE' 
    BEGIN
    	IF @C_state <> N''
    	  SET @VSTR = @C_state
    END
  ELSE IF UPPER(@Get_Field)=N'ZIP' 
    BEGIN
    	IF @C_zip <> N''
    	  SET @VSTR = @C_zip
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_BLOCK' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1       
            IF @C_addr2 <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END   
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @C_addr3
                      ELSE
                              SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END
            IF @CSZ <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + CHAR(10) + @CSZ
                      ELSE
                        SET @VSTR = @CSZ
              END
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
                SET @VSTR = @VSTR
    END
  ELSE IF UPPER(@Get_Field)=N'FULLADDR_LINE' 
    BEGIN
            IF @C_addr1 <> N'' 
              SET @VSTR = @C_addr1        
            IF @C_addr2 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr2
                      ELSE
                        SET @VSTR = @C_addr2
              END
            IF @C_addr3 <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_addr3
                      ELSE
                        SET @VSTR = @C_addr3
              END
            IF @C_city <> N'' 
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_city
                      ELSE
                        SET @VSTR = @C_city
              END                   
            IF @C_state <> N'' OR @C_zip <> N''
              BEGIN
                      IF @VSTR <> N'' 
                        SET @VSTR = @VSTR + N', ' + @C_state
                      ELSE
                        SET @VSTR = @C_state
              END
            IF @C_zip <> N'' 
              BEGIN
	              IF @VSTR <> N''
	                SET @VSTR = @VSTR + N' ' + @C_zip
	              ELSE
	                SET @VSTR = @C_zip
              END
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
    END
  /* Get City, State and Zip */
  ELSE IF UPPER(@Get_Field)=N'CSZ' 
    BEGIN                                          
            IF @C_city <> N'' 
              SET @CSZ = @C_city       
            IF @C_state <> N'' OR @C_zip <> N''
             BEGIN
                      IF @CSZ <> N'' 
                           SET @CSZ = @CSZ + N', ' + @C_state
                      ELSE
                           SET @CSZ = @C_state
             END
            IF @C_zip <> N'' 
              BEGIN
	              IF @CSZ <> N''
	                SET @CSZ = @CSZ + N' ' + @C_zip
	              ELSE
	                SET @CSZ = @C_zip
              END                        
            IF UPPER(@Case) = N'U' 
                SET @VSTR = UPPER(@CSZ)
            ELSE IF UPPER(@Case) = N'I' 
                SET @VSTR = DBO.FN_GET_INITCAP(N'',@CSZ)
            ELSE 
                SET @VSTR = @CSZ
    END
  /* Get Name  */
  ELSE IF UPPER(@Get_Field)=N'FIRSTNAME' 
    BEGIN
    	IF @C_fname <> N''
    	  SET @VSTR = @C_fname
    END
  ELSE IF UPPER(@Get_Field)=N'LASTNAME' 
    BEGIN
    	IF @C_lname <> N''
    	  SET @VSTR = @C_lname
    END
  ELSE IF UPPER(@Get_Field)=N'MIDDLENAME' 
    BEGIN
    	IF @C_mname <> N''
    	  SET @VSTR = @C_mname
    END
  ELSE IF UPPER(@Get_Field)=N'FULLNAME'  
    BEGIN
      IF UPPER(@NameFormat) = N'LFM' 
         BEGIN
           IF @C_lname <> N''
             SET @VSTR = @C_lname
           IF @C_fname <> N'' OR @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N', ' + @C_fname
               ELSE
                        SET @VSTR = @C_fname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FLM' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'FML' 
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR
         END
      ELSE IF UPPER(@NameFormat) = N'LF' 
         BEGIN
         	IF @C_lname <> N''
         	  SET @VSTR = @C_lname
         	IF @C_fname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_fname
         	    ELSE
         	      SET @VSTR = @C_fname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END           
      ELSE IF UPPER(@NameFormat) = N'FL' 
         BEGIN
                IF @C_fname <> N''
                  SET @VSTR = @C_fname
         	IF @C_lname <> N''
         	  BEGIN
         	    IF @VSTR <> N''
         	      SET @VSTR = @VSTR + N' ' + @C_lname
         	    ELSE
         	      SET @VSTR = @C_lname
         	  END
                 IF UPPER(@Case) = N'U' 
                    SET @VSTR = UPPER(@VSTR)
                 ELSE IF UPPER(@Case) = N'I' 
                    SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
                 ELSE 
                    SET @VSTR = @VSTR
         END
      ELSE
         BEGIN
           IF @C_fname <> N''
             SET @VSTR = @C_fname
           IF @C_mname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_mname
               ELSE
                        SET @VSTR = @C_mname
             END
           IF @C_lname <> N''
             BEGIN
               IF @VSTR <>N''                            
                        SET @VSTR = @VSTR + N' ' + @C_lname
               ELSE
                        SET @VSTR = @C_lname
             END
           IF UPPER(@Case) = N'U' 
             SET @VSTR = UPPER(@VSTR)  
           ELSE IF UPPER(@Case) = N'I' 
             SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR) 
           ELSE 
             SET @VSTR = @VSTR       
         END                           
    END
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
            IF @C_country <> N''
              SET @VSTR = @C_country
            IF UPPER(@Case) = N'U' 
              SET @VSTR = UPPER(@VSTR)
            ELSE IF UPPER(@Case) = N'I' 
              SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
            ELSE 
              SET @VSTR = @VSTR
        END
  /* Get DEFENDANT FULL Name  */
  ELSE IF UPPER(@Get_Field)=N'DEFENDANTFULLNAME' 
        BEGIN
          IF @C_fullname <> N''
            SET @VSTR = @C_fullname
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  /* Get Country  */
  ELSE IF UPPER(@Get_Field)=N'COUNTRY' 
        BEGIN
          IF @C_country <> N''
            SET @VSTR = @C_country
          IF UPPER(@Case) = N'U' 
            SET @VSTR = UPPER(@VSTR)
          ELSE IF UPPER(@Case) = N'I' 
            SET @VSTR = DBO.FN_GET_INITCAP(N'',@VSTR)
          ELSE 
            SET @VSTR = @VSTR
        END
  RETURN @VSTR
END
GO


ALTER FUNCTION [dbo].[FN_GET_JOB_VALUE] (@CLIENTID  NVARCHAR(50),
                                           @PID1    NVARCHAR(50),
                                           @PID2    NVARCHAR(50),
                                           @PID3   NVARCHAR(50)
                                           ) RETURNS FLOAT AS
/*  Author           :  Lucky Song
    Create Date      :  12/30/2004
    Version          :  AA6.0 MSSQL
    Detail           :  RETURNs: Contractor job value or calculated job value, depending on which is selected for the application.
                        ARGUMENTS: ClientID, 
                                   PrimaryTrackingID1, 
                                   PrimaryTrackingID2, 
                                   PrimaryTrackingID3
  Revision History   :  12/30/2004  Lucky Song Initial Design
			04/13/2005  Sandy Yin optimize the function 
			10/17/2005  Lucky Song renames the function name as FN_GET_JOB_VALUE
                        02/06/2006  Lydia Lim  Drop function before creating it.
*/  				      	   
begin
	DECLARE			      	    
	@Flag NVARCHAR(10),
	@Job_Value1 FLOAT,
	@Result float set @Result=0;
			SELECT	TOP 1
			        @Job_Value1= isnull(G3_VALUE_TTL,0),
			        @Flag=G3_FEE_FACTOR_FLG
			FROM    BVALUATN 
			WHERE  SERV_PROV_CODE = @CLIENTID AND
			       UPPER(REC_STATUS) = N'A' AND
			       B1_PER_ID1 = @PID1 AND		
			       B1_PER_ID2 = @PID2 AND		
			       B1_PER_ID3 = @PID3 AND
	                       UPPER(REC_STATUS) = N'A';
			if UPPER(@Flag)=N'CONT' OR @Flag IS NULL 
	          		set @Result=@Job_Value1;
	     		 else 
	         		set @Result = dbo.FN_GET_JOB_VALUE_CALC(@CLIENTID, @PID1, @PID2, @PID3);  
	    return @Result;
END
GO
------------------------- Create Functions -------------------------


ALTER FUNCTION [dbo].[FN_GET_PARCEL_ATTRIBUTE] (@CLIENTID NVARCHAR(15),
					 @PID1 NVARCHAR(5),
					 @PID2 NVARCHAR(5),
					 @PID3 NVARCHAR(5),
					 @ATTNAME NVARCHAR(70)
					 )RETURNS NVARCHAR(200) AS
/*  Author           :   Glory Wang
    Create Date      :   12/01/2004
    Version          :   AA6.0
    Detail           :   Value of specified parcel custom attribute; Null if no such attribute is found.  Note that {ParcelAttribute} is the attribute name, not the attribute label.
    ARGUMENTS        :   ClientID, PrimaryTrackingID1, PrimaryTrackingID2, PrimaryTrackingID3, AttribName ,ChecklistDescription.
  Revision History :
				12/01/2004	Glory Wang 	Initial Design
				16/05/2005	David Zheng 	Change "=" to "LIKE" for more reusable.
*/
BEGIN
DECLARE
  @V_VALUE NVARCHAR(200)
  SELECT TOP 1
	@V_VALUE = B1_ATTRIBUTE_VALUE 
  FROM 
	B3APO_ATTRIBUTE
  WHERE SERV_PROV_CODE = @CLIENTID
  AND   B1_PER_ID1 = @PID1
  AND   B1_PER_ID2 = @PID2
  AND   B1_PER_ID3 = @PID3
  AND   UPPER(B1_APO_TYPE) = N'PARCEL'
  AND   REC_STATUS = N'A'
  AND   UPPER(B1_ATTRIBUTE_NAME) LIKE UPPER(@ATTNAME)
RETURN @V_VALUE
END
GO


ALTER FUNCTION [dbo].[FN_GET_PARCEL_NBR_ATTRIBUTE](@CLIENTID  NVARCHAR(15),
         					@id1  NVARCHAR(5),
                                            	@id2  NVARCHAR(5),
                                            	@id3  NVARCHAR(5),
					        @nbr  NVARCHAR(24),
                                            	@info_label  NVARCHAR(70)
                                                   ) RETURNS NVARCHAR(200) AS
/*  Author           :   Sandy Yin
    Create Date      :   02/09/2007
    Version          :   AA6.4 MS SQL
    Detail           :   RETURNS:   Value of custom attribute {ParcelAttribute} for parcel number {ParcelNbr}; Null if no such attribute is found.  Note that {ParcelAttribute} is the attribute NAME, not the attribute label.
                         ARGUMENTS: ClientID,
                                    PrimaryTrackingID1,
                                    PrimaryTrackingID2,
                                    PrimaryTrackingID3,
                                    ParcelNbr,
                                    ParcelAttribute (case insensitive).
    Revision History :   02/09/2007  Sandy Yin  Create by modifying Oracle version of function (07SSP-00068)
                         05/10/2007  Rainy Yu change @nbr VARCHAR(24) and @info_label VARCHAR(70)
                         06/13/2007  Lydia Lim  Edited comments.
*/
BEGIN
DECLARE
@TEM NVARCHAR(200)
 SELECT
  TOP 1  @TEM=B1_ATTRIBUTE_VALUE 
 FROM
  B3APO_ATTRIBUTE
 WHERE
  B1_PER_ID1 = @id1 AND
  B1_PER_ID2 = @id2 AND
  B1_PER_ID3 = @id3 AND
  REC_STATUS = N'A' AND
  SERV_PROV_CODE = @CLIENTID AND
  B1_APO_TYPE=N'PARCEL' AND
  UPPER(B1_ATTRIBUTE_NAME)= UPPER(@info_label) AND
  UPPER(B1_APO_NBR) = UPPER(@nbr) 
  RETURN(@TEM);
END
GO
