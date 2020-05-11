/*
URL and other confirguration items required when:
    1. migrating an Agency from Oracle to SQL Server;
    2. copying an Agency database from one environment to another (e.g. prod to non-prod; prod to dev);
    3. 

Assumptions:
    1. the URL structures have been defined and agreed upon, and will always be the same, with the only variances in the Agency Name and the Environment Purpose
    2. 

NOTE: The "SET NOEXEC ON" statement is being used to prevent accidential execution. Kindly comment out this line if you want the script to execute in it's entirety.
*/
SET NOCOUNT ON;
SET NOEXEC OFF;
/*
TODO:
1.  Add logging, that is, output the data changes using PRINT statements. These will show up in the SSMS Messages tab, in the console when running using SQLCMD, or when running using PowerShell 
    with the "-Verbose" parameter. Report both existing value/s and new value/s.

*/
-- remove
BEGIN TRY
    DROP TABLE #ScriptParams;
    DROP TABLE #AuditData;
END TRY
BEGIN CATCH
    -- do nothing
END CATCH
GO
-- will store parameter (configuration) values used to initialize an Agency
CREATE TABLE #ScriptParams (
    PARAM_NAME nvarchar(50) NOT NULL,
    PARAM_VALUE nvarchar(max) NOT NULL
);
-- TODO: Log to this table?
CREATE TABLE #AuditData (
    AuditID int IDENTITY(1,1) NOT NULL,
    AuditTable nvarchar(128) NOT NULL,
    AuditOldValue xml NOT NULL,
    AuditNewValue xml NULL,
    AuditRowsUpdated int NULL,
    AuditTimestamp datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GO
DECLARE @AGENCY_NAME nvarchar(15);
DECLARE @ENVIRONMENT_PURPOSE nvarchar(15);
-- these values will determine the URL values:
SET @AGENCY_NAME = N'PORTSEATTLE'; -- define this value
SET @ENVIRONMENT_PURPOSE = N'supp'; -- define this value
--
INSERT INTO #ScriptParams (PARAM_NAME, PARAM_VALUE)
VALUES 
    (N'AGENCY_NAME',                UPPER(@AGENCY_NAME)), -- NOTE: please use a maximum of 15 characters!
-- Environment URL/IPs: 
    (N'AA',                         LOWER(@AGENCY_NAME) + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'-av.accela.com'),
    (N'AV',                         LOWER(@AGENCY_NAME) + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'-av.accela.com'),
    (N'ACA',                        N'aca' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/' + LOWER(@AGENCY_NAME) ),
    (N'AMO',                        N'amo' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/amo'),
    (N'AGIS',                       N'agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/agis'),
    (N'JSAGIS',                     N'agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/jsagis'),
    (N'ADS_SERVER_URL',             N'http://ads' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/documentservice/index.cfm'),
    (N'BATCH_JOB_SERVER',           N'10.165.96.160'), -- define this value
    --
    (N'AMO_APPSERVER_URL',          N'http://10.165.96.215:3080/wireless/GovXMLServlet'), -- define this value
    (N'REPOSITORY_FILE_DATABASE',   N'D:\FileDb'), -- Sample value. For example, it'll be '\\nonprodstorageapp.file.core.windows.net\FileDB' for AzureMT NonProd
    --
    (N'REPORTS_URL_ADHOC_XREPORT',  N'https://adhoc-' + ISNULL(NULLIF(@ENVIRONMENT_PURPOSE, ''), N'') + N'.accela.com/AdhocReportWeb' + LOWER(@AGENCY_NAME) + N'/AdhocReportAdapter/XReport.aspx'),
    (N'REPORTS_URL_ADHOC_FILEDIR',  N'https://adhoc-' + ISNULL(NULLIF(@ENVIRONMENT_PURPOSE, ''), N'') + N'.accela.com/AdhocReportWeb' + LOWER(@AGENCY_NAME) + N'/AdhocReportAdapter/FileDirectory.aspx'),
    (N'REPORTS_URL_CRYSTAL_XREPORT', N'https://crystal.' + ISNULL((NULLIF(@ENVIRONMENT_PURPOSE, '') + N'-'), N'') + N'accela.com/myreports/adapter/XReport_' + LOWER(@AGENCY_NAME) + N'.aspx'),
    (N'REPORTS_URL_CRYSTAL_FILEDIR', N'https://crystal.' + ISNULL((NULLIF(@ENVIRONMENT_PURPOSE, '') + N'-'), N'') + N'accela.com/myreports/adapter/FileDirectory.asp'),
/*
    -- Original below. A decision is required on which to use
    (N'REPORTS_URL_CRYSTAL_XREPORT', N'https://crystal1.accela.com/' + ISNULL((NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'/myreports/adapter/XReport_' + LOWER(@AGENCY_NAME) + N'.aspx'),
    (N'REPORTS_URL_CRYSTAL_FILEDIR', N'https://crystal1.accela.com/' + ISNULL((NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'/myreports/adapter/FileDirectory.asp'),
*/
    (N'REPORTS_URL_SSRS',           N''), -- TODO
    --
    (N'GIS_SERVICE_URL',            N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/agis'),
    (N'GIS_JAVASCRIPT_API_URL',     N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/jsagis/api'),
    --
    (N'EAS_SOURCE_REST_API_URL',    N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/jsagis/'),
    (N'EAS_SOURCE_URL',             N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/agis/xapo.asmx?WSDL'),
    --
    (N'EDR_WEB_SERVICE_URL',        N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/agis/xapo.asmx?WSDL'),
    --
    (N'EOR_SOURCE_REST_API_URL',    N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/jsagis/'),
    (N'EOS_SOURCE_URL',             N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/agis/xapo.asmx?WSDL'),
    --
    (N'EXP_SOURCE_REST_API_URL',    N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/jsagis/'),
    (N'EXP_SOURCE_URL',             N'https://agis' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/agis/xapo.asmx?WSDL')
;

INSERT INTO #ScriptParams (PARAM_NAME, PARAM_VALUE)
VALUES (N'ADHOC_REPORT_SETTINGS',      N'https://adhoc' + ISNULL((N'-' + NULLIF(@ENVIRONMENT_PURPOSE, '')), N'') + N'.accela.com/AdhocReportWeb' + LOWER(@AGENCY_NAME) + N'/Report/Index.aspx');

-- AMO EDMS String
DECLARE @AMO_EDMS_STRING nvarchar(max);
SET @AMO_EDMS_STRING = N''; -- initialize
-- build the string; no spaces, no CRLF, or other invisible characters
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'EDMS_VENDOR=ADS;';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'EDMS_DOCUMENT_SIZE_MAX=;';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'ADS_SERVER_URL=' + COALESCE((SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = 'ADS_SERVER_URL'), N'') + N';';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'ADS_SERVER_SECURITY_KEY=' + COALESCE((SELECT [SECURITY_KEY] FROM [ADS].[dbo].[RDOC_CONFIG_SERVER] WHERE [SERVER_CODE] = 'SERVER'), N'') + N';';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'ADS_SERV_PROV_CODE=' + @AGENCY_NAME + N';';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'ADS_CLEARANCE_KEY=' + COALESCE((SELECT [CLEARANCE_KEY] FROM [ADS].[dbo].[RDOC_CONFIG_PROV] WHERE SERV_PROV_CODE = @AGENCY_NAME), N'') + N';';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'ADS_SECURITY_KEY=' + COALESCE((SELECT [SECURITY_KEY] FROM [ADS].[dbo].[RDOC_CONFIG_PROV] WHERE SERV_PROV_CODE = @AGENCY_NAME), N'') + N';';
SET @AMO_EDMS_STRING = @AMO_EDMS_STRING + N'DEFAULT=YES';

-- PRINT @AMO_EDMS_STRING;
INSERT INTO #ScriptParams (PARAM_NAME, PARAM_VALUE)
VALUES (N'ADS_EDMS_STRING', @AMO_EDMS_STRING);
GO

SELECT * FROM #ScriptParams;
GO

-- the following line prevents anything beyond this to be executed
SET NOEXEC ON;
GO

IF OBJECT_ID('dbo.FN_CLEAN_URL') IS NULL
    EXEC sp_executesql N'CREATE FUNCTION dbo.FN_CLEAN_URL() RETURNS nvarchar(max) AS BEGIN RETURN N''Hello World!''; END;';
GO
ALTER FUNCTION dbo.FN_CLEAN_URL (
    @InputString nvarchar(max),
	@URLRoot nvarchar(50) = N'donothing.accela.com'
)
RETURNS nvarchar(max)
AS
BEGIN
    -- simple implementation of a URL checker
    -- A CLR function using a Regular Expression could be used to get more accurate results
    -- see https://mathiasbynens.be/demo/url-regex
    -- the only way to verify that a URL is valid would be to ping it at input stage
    DECLARE @Output nvarchar(max);
    DECLARE @CheckURL nvarchar(max);
    SET @CheckURL = LOWER(@InputString);
    IF ((@CheckURL IS NOT NULL)
        AND (LEN(@CheckURL) > 4) -- arbitary value based on sample URL "t.me"
        AND ((@CheckURL LIKE 'http://%') OR (@CheckURL LIKE 'https://%'))
        AND (@CheckURL LIKE '%.accela.com%'))
    BEGIN
        DECLARE @FirstCharOfRoot tinyint;
        DECLARE @HTTProtocol varchar(8); -- stores 'http://' or 'https://'
        DECLARE @FirstForwardSlashPos tinyint;
        -- get positional values
        SET @FirstCharOfRoot = CHARINDEX('://', @InputString, 1)+2;
        SET @HTTProtocol = SUBSTRING(@InputString, 1, @FirstCharOfRoot);
        SET @FirstForwardSlashPos = CHARINDEX('/', @InputString, 10);
        IF (@FirstForwardSlashPos > 4)
        BEGIN
            SET @Output = @HTTProtocol + @URLRoot + SUBSTRING(@InputString, @FirstForwardSlashPos, LEN(@InputString));
        END
        ELSE
        BEGIN
            SET @Output = @HTTProtocol + @URLRoot;
        END
    END
    ELSE
    BEGIN
        SET @Output = @InputString;
    END
    RETURN @Output;
END
GO

IF OBJECT_ID('dbo.FN_CLEAN_EMAIL') IS NULL
    EXEC sp_executesql N'CREATE FUNCTION dbo.FN_CLEAN_EMAIL() RETURNS nvarchar(max) AS BEGIN RETURN N''Hello World!''; END;';
GO
ALTER FUNCTION dbo.FN_CLEAN_EMAIL (
    @InputString nvarchar(max),
	@EmailSuffix nvarchar(50) = N'donothing.accela.com'
)
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @Output nvarchar(max);
    SET @InputString = LOWER(@InputString);
    IF ((@InputString IS NOT NULL)
        AND (LEN(@InputString) > 6) -- arbitary value based on sample email address "a@b.com"
        AND (@InputString NOT LIKE '%@%@%')
        AND (CHARINDEX('.@',@InputString) = 0)
        AND (CHARINDEX('..',@InputString) = 0)
        AND (CHARINDEX(',',@InputString) = 0)
        AND (@InputString LIKE '%@%') 
        AND (@InputString NOT LIKE '%@accela.com%')
        AND (RIGHT(@InputString,1) LIKE '[a-z]')
        )
    BEGIN
        SET @Output = SUBSTRING(@InputString,1,CHARINDEX('@', @InputString)) + @EmailSuffix
    END
    ELSE
    BEGIN
        SET @Output = @InputString;
    END
    RETURN @Output;
END
GO

IF OBJECT_ID('dbo.FN_EXTRACT_URLS') IS NULL
    EXEC sp_executesql N'CREATE FUNCTION dbo.FN_EXTRACT_URLS() RETURNS TABLE AS RETURN (SELECT CURRENT_TIMESTAMP AS [NOW]);';
GO
ALTER FUNCTION dbo.FN_EXTRACT_URLS (
    @InputString nvarchar(max)
)
RETURNS TABLE
AS
RETURN (
    -- create a CTE that will be used to generate row numbers
    -- derived and adapted from https://www.sqlservercentral.com/forums/topic/replace-url-with-a-hrefurlurla-from-a-string-using-sql
    WITH T (N) AS (
	    SELECT N
	    FROM (
		    VALUES (NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
			    ,(NULL)
		    ) AS X(N)
    )
    -- extract number of URL instances
    ,PARSED_SET AS (
	    SELECT TP.URL_ID
		    ,TP.URL_TEXT
		    ,NM.N
		    ,ROW_NUMBER() OVER (PARTITION BY TP.URL_ID ORDER BY NM.N) + (
			    ROW_NUMBER() OVER (PARTITION BY TP.URL_ID ORDER BY NM.N) % 2
			    ) AS GRP_NO
		    ,ASCII(SUBSTRING(TP.URL_TEXT, NM.N, 1)) AS CHR_CODE
		    ,SUBSTRING(TP.URL_TEXT, NM.N, 1) AS CHR_VAL
	    FROM (SELECT 1 AS URL_ID, COALESCE(@InputString, '') AS URL_TEXT) TP
	    CROSS APPLY (
		    SELECT TOP (LEN(TP.URL_TEXT)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
		    FROM T T1, 
                T T2, 
                T T3, 
                T T4
		    ) AS NM(N)
	    WHERE ASCII(SUBSTRING(TP.URL_TEXT, NM.N, 1)) IN (34,60,62) 
        -- 34: "
        -- 60: <
        -- 62: >
    )
    -- find start and end points of each URL
    ,URL_PARSE AS (
	    SELECT MIN(PS.URL_ID) AS URL_ID
		    ,PS.URL_TEXT
		    ,PS.GRP_NO
		    ,MIN(PS.N) AS MIN_N
		    ,MAX(PS.N) AS MAX_N
		    ,SUM(PS.CHR_CODE) AS SUM_CHAR_CODE
	    FROM PARSED_SET PS
	    GROUP BY PS.GRP_NO, PS.URL_TEXT
	    HAVING MIN(PS.CHR_VAL) = '"'
    )
    -- extract URL and return
    SELECT UP.URL_ID
	    ,SUBSTRING(
            UP.URL_TEXT, 
            1 + MAX(CASE WHEN UP.SUM_CHAR_CODE = 94 THEN UP.MAX_N END), 
            ( MAX(CASE WHEN UP.SUM_CHAR_CODE = 96 THEN UP.MIN_N END) - MAX(CASE WHEN UP.SUM_CHAR_CODE = 94 THEN UP.MAX_N END) ) - 1) AS [URL]
	    ,UP.URL_TEXT
    FROM URL_PARSE UP
    GROUP BY UP.URL_ID, UP.URL_TEXT, (UP.GRP_NO - CASE WHEN UP.SUM_CHAR_CODE = 96 THEN 2 ELSE 0 END)
)
GO

/*
-- Example usage:
UPDATE GMESSAGE 
SET MESSAGE_TEXT = REPLACE(MESSAGE_TEXT, f.[URL], dbo.FN_CLEAN_URL(f.[URL], 'donothing.accela.com'))
-- SELECT MESSAGE_ID, MESSAGE_TEXT, REPLACE(MESSAGE_TEXT, f.[URL], dbo.FN_CLEAN_URL(f.[URL], 'donothing.accela.com'))
FROM GMESSAGE 
    CROSS APPLY dbo.FN_EXTRACT_URLS(MESSAGE_TEXT) f
WHERE MESSAGE_TEXT LIKE '%http%accela.com%';
*/


--************************************************************
--                  ALL SET AND READY TO GO
--************************************************************
-- TODO: Add checks for existence of data affected by the UPDATE, and INSERT if missing - not all cases
-- TODO: Audit changed records
-- a supporting database
IF NOT EXISTS(SELECT 1 FROM [master].sys.databases WHERE [name] = 'Migration')
BEGIN
    EXEC sp_executesql N'CREATE DATABASE [Migration];';
	-- Nested "sp_executesql" since CREATE SCHEMA has to be the first statement executed in a batch
	EXEC sp_executesql N'EXEC [Migration]..sp_executesql N''CREATE SCHEMA [URLupdateAA] AUTHORIZATION [dbo];''';
END
GO

--BEGIN TRANSACTION --ROLLs BACK by default
	DECLARE @timeStamp varchar(26) = CONVERT(varchar(26),CURRENT_TIMESTAMP,112) + REPLACE(CONVERT(varchar(26),CURRENT_TIMESTAMP,108),':','');
	DECLARE @SqlCmd nvarchar(4000);

	DECLARE @PARAM_NAME nvarchar(50),
	        @PARAM_VALUE nvarchar(max);
	        
	DECLARE @PARAM_NAME_AA nvarchar(50),
	        @PARAM_VALUE_AA nvarchar(max);
    
	DECLARE @AGENCY_NAME nvarchar(15);
	SET @AGENCY_NAME = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = 'AGENCY_NAME');

	-- variables used for auditing
	DECLARE @AUDITTABLE nvarchar(128);
	DECLARE @AUDITOLDVALUE xml;
	DECLARE @AUDITNEWVALUE xml;
	DECLARE @AUDITROWSUPDATED int;

	SET @SqlCmd = 'SELECT * INTO Migration.URLupdateAA.'+@AGENCY_NAME+'_RBIZDOMAIN_VALUE_'+ @timeStamp + ' FROM dbo.RBIZDOMAIN_VALUE;';
	EXEC sp_executesql @SqlCmd;

	SET @SqlCmd = 'SELECT * INTO Migration.URLupdateAA.'+@AGENCY_NAME+'_AGIS_SERVICE_'+ @timeStamp + ' FROM dbo.AGIS_SERVICE;';
	EXEC sp_executesql @SqlCmd;
	
    SET @SqlCmd = 'SELECT * INTO Migration.URLupdateAA.'+@AGENCY_NAME+'_GPORTLET_'+ @timeStamp + ' FROM dbo.GPORTLET;';
	EXEC sp_executesql @SqlCmd;
	
    SET @SqlCmd = 'SELECT * INTO Migration.URLupdateAA.'+@AGENCY_NAME+'_BPORTLETLINKS_'+ @timeStamp + ' FROM dbo.BPORTLETLINKS;';
	EXEC sp_executesql @SqlCmd;
	
    SET @SqlCmd = 'SELECT * INTO Migration.URLupdateAA.'+@AGENCY_NAME+'_XPOLICY_'+ @timeStamp + ' FROM dbo.XPOLICY;'
	EXEC sp_executesql @SqlCmd;

	-- *****
	SET @PARAM_NAME_AA = N'AA';
	SET @PARAM_VALUE_AA = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = @PARAM_NAME_AA);
	--BPORTLETLINKS
	/*
	SET @AUDITTABLE = N'BPORTLETLINKS';
	SET @AUDITOLDVALUE = (
		SELECT * FROM BPORTLETLINKS 
		WHERE SERV_PROV_CODE = @AGENCY_NAME
		AND LINK_TYP = 'URL' AND LINK_URL LIKE 'http%'
		FOR XML PATH('row'), ROOT('BPORTLETLINKS'), ELEMENTS XSINIL
	);
	*/
	UPDATE BPORTLETLINKS 
	SET LINK_URL = dbo.FN_CLEAN_URL(LINK_URL, @PARAM_VALUE_AA)
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND LINK_TYP = 'URL' AND LINK_URL LIKE 'http%';

	--GPORTLET
	UPDATE GPORTLET 
	SET PORTLET_URL = dbo.FN_CLEAN_URL(PORTLET_URL, @PARAM_VALUE_AA),
		PORTLET_ICON = dbo.FN_CLEAN_URL(PORTLET_ICON, @PARAM_VALUE_AA)
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND ((PORTLET_URL LIKE 'http%') OR (PORTLET_ICON LIKE 'http%'));

	--RBIZDOMAIN_VALUE
	UPDATE RBIZDOMAIN_VALUE 
	SET BIZDOMAIN_VALUE = dbo.FN_CLEAN_URL(BIZDOMAIN_VALUE, @PARAM_VALUE_AA), 
		VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC, @PARAM_VALUE_AA)
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND ((BIZDOMAIN_VALUE LIKE 'http%') OR (VALUE_DESC LIKE 'http%'));

	--SJH--
    -- *****
	SET @PARAM_NAME = N'AV';
	SET @PARAM_VALUE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = @PARAM_NAME);
	--RBIZDOMAIN_VALUE - ACA
	UPDATE RBIZDOMAIN_VALUE 
	SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC, @PARAM_VALUE)
	FROM RBIZDOMAIN_VALUE
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN='ACA_CONFIGS' AND (BIZDOMAIN_VALUE IN ('ACA_SITE','OFFICIAL_WEBSITE_URL'))
	AND VALUE_DESC IS NOT NULL;

	--RBIZDOMAIN_VALUE - EDMS
	UPDATE RBIZDOMAIN_VALUE 
	SET VALUE_DESC = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'ADS_EDMS_STRING')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN='EDMS' AND BIZDOMAIN_VALUE LIKE '%ADS%';

	-- ADHOC System-level setting
	UPDATE dbo.RBIZDOMAIN_VALUE     SET VALUE_DESC = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'ADHOC_REPORT_SETTINGS')    WHERE SERV_PROV_CODE = 'ADMIN' AND UPPER(BIZDOMAIN) = 'ADHOC_REPORT_SETTINGS';

	--XPOLICY ADHOC Reports XReport
	UPDATE XPOLICY --CHECK!!
	SET DATA1 = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPORTS_URL_ADHOC_XREPORT')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND POLICY_NAME = 'ReportService' AND LEVEL_DATA = N'url'
	AND	LEVEL_TYPE IN (
        SELECT LEVEL_TYPE
		FROM dbo.XPOLICY
		WHERE POLICY_NAME = 'REPORTSERVICE'
		AND UPPER(LEVEL_DATA) = 'TYPE'
		AND UPPER(DATA1) = 'ADHOC'
    );


	--XPOLICY ADHOC Reports FileDirectory
	UPDATE XPOLICY --CHECK!!
	SET DATA1 = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPORTS_URL_ADHOC_FILEDIR')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND POLICY_NAME = 'ReportService' AND LEVEL_DATA = N'reportNameURL'
	AND	LEVEL_TYPE IN (
        SELECT LEVEL_TYPE
		FROM dbo.XPOLICY
		WHERE POLICY_NAME = 'REPORTSERVICE'
		AND UPPER(LEVEL_DATA) = 'TYPE'
		AND UPPER(DATA1) = 'ADHOC'
    );

	--XPOLICY Crystal reports
	UPDATE XPOLICY --CHECK!!
	SET DATA1 = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPORTS_URL_CRYSTAL_XREPORT')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND POLICY_NAME = 'ReportService' AND LEVEL_DATA = N'url'
	AND	LEVEL_TYPE IN (
        SELECT LEVEL_TYPE
	    FROM dbo.XPOLICY
	    WHERE POLICY_NAME = 'REPORTSERVICE'
	    AND UPPER(LEVEL_DATA) = 'TYPE'
	    AND UPPER(DATA1) = 'CRYSTAL'
    );

	UPDATE XPOLICY --CHECK!!
	SET DATA1 = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPORTS_URL_CRYSTAL_FILEDIR')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND POLICY_NAME = 'ReportService' AND LEVEL_DATA = N'reportNameURL'
	AND	LEVEL_TYPE IN (
        SELECT LEVEL_TYPE
	    FROM dbo.XPOLICY
	    WHERE POLICY_NAME = 'REPORTSERVICE'
	    AND UPPER(LEVEL_DATA) = 'TYPE'
	    AND UPPER(DATA1) = 'CRYSTAL'
    );

	--SSRS report
	--TODO: commented out to prevent UPDATE from executing
	/*
	UPDATE XPOLICY 
	SET DATA1 = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPORTS_URL_SSRS')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND POLICY_NAME ='ReportService' AND LEVEL_DATA='serviceName';
	*/

	--=================================================================================================================
	 
	-- update APP server URL in AMO
	UPDATE AMO..AGENCY 
	SET ACCELAGISSERVER = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'AGIS')
	WHERE ACCELAGISSERVER IS NOT NULL; --- WHY? SHOULD'T WE SIMPLY REPLACE THE EXISTING VALUE?

	--select * from AMO.AGENCY order by provider_code
	UPDATE AMO..AGENCY 
	SET APP_SERVER = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'AMO_APPSERVER_URL')
	WHERE PROVIDER_CODE = @AGENCY_NAME; --code like %_supp%_test

	-- CHECK
	UPDATE ADS..RDOC_CONFIG_PROFILE
	SET PROFILE_DEFAULT_VALUE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPOSITORY_FILE_DATABASE')
	WHERE PROFILE_GROUP = 'ServiceProvider' AND PROFILE_NAME = 'FileRepository-FileDatabase';

	UPDATE ADS..RDOC_CONFIG_PROV_PROFILE 
	SET PROFILE_VALUE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPOSITORY_FILE_DATABASE')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND PROFILE_NAME='FileRepository-FileDatabase';

	-- CHECK
	UPDATE ADS..EDOC_INDEX
	SET REPOSITORY_FILE_DATABASE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'REPOSITORY_FILE_DATABASE')
	WHERE SERV_PROV_CODE = @AGENCY_NAME;

	--AGIS/JSAGIS
	UPDATE AGIS_SERVICE -- sjh: retain nulls
	SET GIS_SERVICE_URL = case when GIS_SERVICE_URL is null then GIS_SERVICE_URL else (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'GIS_SERVICE_URL') end,
	    GIS_JAVASCRIPT_API_URL = case when GIS_JAVASCRIPT_API_URL is null then GIS_JAVASCRIPT_API_URL else (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'GIS_JAVASCRIPT_API_URL') end
	WHERE AGENCY IN (
	    SELECT APO_SRC_SEQ_NBR FROM RSERV_PROV WHERE SERV_PROV_CODE = @AGENCY_NAME
	    )
	AND GIS_SERVICE_URL LIKE '%accela.com%';


	-- optional:
	-- replace values with valid URLs for the environment
	UPDATE XUI_TEXT 
	SET STRING_VALUE = REPLACE(STRING_VALUE, f.[URL], dbo.FN_CLEAN_URL(f.[URL], @PARAM_VALUE_AA)) -- text field contains reference to URL
	FROM XUI_TEXT 
	    CROSS APPLY dbo.FN_EXTRACT_URLS(STRING_VALUE) f
	WHERE STRING_VALUE LIKE '%http%accela.com%';


	UPDATE REVT_AGENCY_SCRIPT 
	SET SCRIPT_TEXT = REPLACE(SCRIPT_TEXT, f.[URL], dbo.FN_CLEAN_URL(f.[URL], @PARAM_VALUE_AA)) -- text field contains reference to URL
	FROM REVT_AGENCY_SCRIPT 
	    CROSS APPLY dbo.FN_EXTRACT_URLS(SCRIPT_TEXT) f
	WHERE SCRIPT_TEXT LIKE '%http%accela.com%';


	UPDATE GMESSAGE 
	SET MESSAGE_TEXT = REPLACE(MESSAGE_TEXT, f.[URL], dbo.FN_CLEAN_URL(f.[URL], @PARAM_VALUE_AA)) -- text field contains reference to URL
	FROM GMESSAGE 
	    CROSS APPLY dbo.FN_EXTRACT_URLS(MESSAGE_TEXT) f
	WHERE MESSAGE_TEXT LIKE '%http%accela.com%';


	UPDATE BCUSTOMIZED_CONTENT 
	SET CONTENT_TEXT = REPLACE(CONTENT_TEXT, f.[URL], dbo.FN_CLEAN_URL(f.[URL], @PARAM_VALUE_AA)) -- text field contains reference to URL
	FROM BCUSTOMIZED_CONTENT 
	    CROSS APPLY dbo.FN_EXTRACT_URLS(CONTENT_TEXT) f
	WHERE CONTENT_TEXT LIKE '%http%accela.com%';


	--TODO: CHECK!
	UPDATE RCOMMUNICATION_ACCOUNT
	SET ACCOUNT_NAME = REPLACE(dbo.FN_CLEAN_EMAIL(ACCOUNT_NAME, DEFAULT), '@', '@' + CAST(NEWID() AS varchar(40)) + '.'),
        ACCOUNT_INFO = REPLACE(dbo.FN_CLEAN_EMAIL(ACCOUNT_INFO, DEFAULT), '@', '@' + CAST(NEWID() AS varchar(40)) + '.'),
        DISPLAY_NAME = REPLACE(dbo.FN_CLEAN_EMAIL(DISPLAY_NAME, DEFAULT), '@', '@' + CAST(NEWID() AS varchar(40)) + '.')
	-- SELECT RES_ID, SERV_PROV_CODE, ACCOUNT_NAME, ACCOUNT_INFO, DISPLAY_NAME FROM RCOMMUNICATION_ACCOUNT -- email addresses?
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND ((ACCOUNT_NAME LIKE '%@%') OR (ACCOUNT_INFO LIKE '%@%') OR (DISPLAY_NAME LIKE '%@%'));


	-- RBIZDOMAIN_VALUE: EXTERNAL_ADDRESS_SOURCE 
	SET @PARAM_VALUE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EAS_SOURCE_REST_API_URL');
	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC, @PARAM_VALUE)
	FROM RBIZDOMAIN_VALUE 
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_ADDRESS_SOURCE' AND BIZDOMAIN_VALUE = 'SOURCE_REST_API_URL'

	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EAS_SOURCE_URL')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_ADDRESS_SOURCE' AND BIZDOMAIN_VALUE = 'SOURCE_URL'

	-- RBIZDOMAIN_VALUE: EXTERNAL_DOC_REVIEW
	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EDR_WEB_SERVICE_URL')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_DOC_REVIEW' AND BIZDOMAIN_VALUE = 'WEB_SERVICE_URL'

	-- RBIZDOMAIN_VALUE: EXTERNAL_OWNER_SOURCE
	SET @PARAM_VALUE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EOR_SOURCE_REST_API_URL')
	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC, @PARAM_VALUE)
	FROM RBIZDOMAIN_VALUE 
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_OWNER_SOURCE' AND BIZDOMAIN_VALUE = 'SOURCE_REST_API_URL'

	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EOS_SOURCE_URL')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_OWNER_SOURCE' AND BIZDOMAIN_VALUE = 'SOURCE_URL'

	-- RBIZDOMAIN_VALUE: EXTERNAL_PARCEL_SOURCE
	SET @PARAM_VALUE = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EXP_SOURCE_REST_API_URL')
	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC, @PARAM_VALUE)
	FROM RBIZDOMAIN_VALUE 
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_PARCEL_SOURCE' AND BIZDOMAIN_VALUE = 'SOURCE_REST_API_URL'

	UPDATE RBIZDOMAIN_VALUE
	SET VALUE_DESC = (SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'EXP_SOURCE_URL')
	WHERE SERV_PROV_CODE = @AGENCY_NAME
	AND BIZDOMAIN = 'EXTERNAL_PARCEL_SOURCE' AND BIZDOMAIN_VALUE = 'SOURCE_URL'


	--BATCH_JOB - Set or NULL-ify value
	UPDATE BATCH_JOB 
    SET INSTANCE_NO = NULLIF((SELECT PARAM_VALUE FROM #ScriptParams WHERE PARAM_NAME = N'BATCH_JOB_SERVER'), '') -- NULL if empty
	WHERE INSTANCE_NO IS NOT NULL;


	-- Cleanup Accela data duplicates
	-- RESOLVE: requires production/supp/test values where BIZDomain_Value != value_desc
	UPDATE RBIZDOMAIN_VALUE
	SET BIZDOMAIN_VALUE = VALUE_DESC
	WHERE BIZDOMAIN_VALUE LIKE 'http%';

    
    SET @SqlCmd = N'
SELECT 
    ''PREcommit: rbizdomain HTTP'' AS [STATUS], 
    CASE WHEN orig.VALUE_DESC = mods.VALUE_DESC THEN ''='' ELSE ''<>'' END AS [COMPARE], 
    orig.VALUE_DESC AS [FROM Value_desc], mods.VALUE_DESC AS [TO Value_desc], mods.BIZDOMAIN_VALUE AS [TO BIZDomain_Value], orig.* 
FROM dbo.RBIZDOMAIN_VALUE mods
    JOIN Migration.URLupdateAA.'+@AGENCY_NAME+'_RBIZDOMAIN_VALUE_'+ @timeStamp + ' orig ON orig.BDV_SEQ_NBR = mods.BDV_SEQ_NBR AND orig.SERV_PROV_CODE = mods.SERV_PROV_CODE 
WHERE orig.SERV_PROV_CODE = '''+@AGENCY_NAME+''' AND orig.REC_STATUS = ''A'' AND orig.VALUE_DESC LIKE ''%http%://%''
ORDER BY orig.VALUE_DESC;';
    EXEC sp_executesql @SqlCmd;

    SET @SqlCmd = N'
SELECT 
    ''PREcommit: bportlet HTTP'' AS [STATUS],
    CASE WHEN orig.LINK_URL = mods.LINK_URL THEN ''='' ELSE ''<>'' END AS [COMPARE],
    orig.LINK_URL AS [FROM link_url], mods.LINK_URL AS [TO link_url], orig.*
FROM dbo.BPORTLETLINKS mods
    JOIN Migration.URLupdateAA.'+@AGENCY_NAME+'_BPORTLETLINKS_'+ @timeStamp + ' orig ON orig.LINK_ID = mods.LINK_ID AND orig.SERV_PROV_CODE = mods.SERV_PROV_CODE 
WHERE orig.SERV_PROV_CODE = '''+@AGENCY_NAME+''' AND orig.REC_STATUS = ''A'' AND orig.LINK_URL LIKE ''%http%://%''
ORDER BY orig.LINK_URL;';
    EXEC sp_executesql @SqlCmd;

    SET @SqlCmd = N'
SELECT 
    ''PREcommit: XPolicy HTTP'' AS [STATUS],
    CASE WHEN orig.DATA1 = mods.DATA1 THEN ''='' ELSE ''<>'' END AS [COMPARE],
    orig.DATA1 AS [FROM data1], mods.DATA1 AS [TO data1], orig.*
FROM dbo.XPOLICY mods
    JOIN Migration.URLupdateAA.'+@AGENCY_NAME+'_XPOLICY_'+ @timeStamp + ' orig ON orig.POLICY_NAME = mods.POLICY_NAME AND orig.POLICY_SEQ = mods.POLICY_SEQ AND orig.SERV_PROV_CODE = mods.SERV_PROV_CODE
WHERE orig.SERV_PROV_CODE = '''+@AGENCY_NAME+''' AND orig.REC_STATUS = ''A'' AND orig.DATA1 LIKE ''%http%://%''
ORDER BY orig.DATA1;';
    EXEC sp_executesql @SqlCmd;

    SET @SqlCmd = N'
SELECT 
    ''PREcommit: GPORTLET HTTP'' AS [STATUS],
    CASE WHEN orig.PORTLET_URL = mods.PORTLET_URL THEN ''='' ELSE ''<>'' END AS [COMPARE],
    orig.PORTLET_URL AS [FROM Portlet_URL], mods.PORTLET_URL AS [TO Portlet_URL], orig.* 
FROM dbo.GPORTLET mods
    JOIN Migration.URLupdateAA.'+@AGENCY_NAME+'_GPORTLET_'+ @timeStamp + ' orig ON orig.PORTLET_ID = mods.PORTLET_ID AND orig.SERV_PROV_CODE = mods.SERV_PROV_CODE 
WHERE orig.SERV_PROV_CODE = '''+@AGENCY_NAME+''' AND orig.REC_STATUS = ''A'' AND orig.PORTLET_URL LIKE ''%http%://%''
ORDER BY orig.PORTLET_URL;';
    EXEC sp_executesql @SqlCmd;

    SET @SqlCmd = N'
SELECT 
    ''PREcommit: AGIS_SERVICE HTTP'' AS [STATUS], 
    CASE WHEN orig.GIS_SERVICE_URL = mods.GIS_SERVICE_URL THEN ''='' ELSE ''<>'' END AS [COMPARE],
    orig.GIS_SERVICE_URL AS [FROM GIS_SERVICE_URL], mods.GIS_SERVICE_URL AS [TO GIS_SERVICE_URL], orig.GIS_JAVASCRIPT_API_URL AS [FROM gis_javascript_api_url], 
    mods.GIS_JAVASCRIPT_API_URL AS [TO gis_javascript_api_url], orig.*
FROM dbo.AGIS_SERVICE mods
    JOIN Migration.URLupdateAA.'+@AGENCY_NAME+'_AGIS_SERVICE_'+ @timeStamp + ' orig ON orig.GIS_SERVICE_ID = mods.GIS_SERVICE_ID AND orig.AGENCY = mods.AGENCY 
WHERE orig.GIS_SERVICE_ID LIKE '''+@AGENCY_NAME+'%''
ORDER BY orig.GIS_SERVICE_URL;';
    EXEC sp_executesql @SqlCmd;

--ROLLBACK

/*
SELECT SERV_PROV_CODE, LINK_DES, LINK_URL,
    dbo.FN_CLEAN_URL(LINK_URL, 'bptdev-soleng-aa.accela.com')
FROM BPORTLETLINKS 
WHERE LINK_TYP = 'URL' AND LINK_URL LIKE 'http%';

SELECT PORTLET_DES, PORTLET_URL, PORTLET_ICON 
FROM GPORTLET 
WHERE ((PORTLET_URL LIKE 'http%') OR (PORTLET_ICON LIKE 'http%'));

SELECT SERV_PROV_CODE, BIZDOMAIN, BIZDOMAIN_VALUE, VALUE_DESC,
    dbo.FN_CLEAN_URL(BIZDOMAIN_VALUE, DEFAULT), 
    dbo.FN_CLEAN_URL(VALUE_DESC, DEFAULT)
FROM RBIZDOMAIN_VALUE 
WHERE ((BIZDOMAIN_VALUE LIKE 'http%') OR (VALUE_DESC LIKE 'http%'));

SELECT SERV_PROV_CODE, BIZDOMAIN, BIZDOMAIN_VALUE, VALUE_DESC 
FROM RBIZDOMAIN_VALUE 
WHERE BIZDOMAIN='EDMS' AND BIZDOMAIN_VALUE LIKE '%ADS%';

SELECT SERV_PROV_CODE, POLICY_NAME, LEVEL_TYPE, LEVEL_DATA, 
    DATA1, DATA2, DATA3, DATA4,
    dbo.FN_CLEAN_URL(DATA1, DEFAULT), 
    dbo.FN_CLEAN_URL(DATA2, DEFAULT), 
    dbo.FN_CLEAN_URL(DATA3, DEFAULT), 
    dbo.FN_CLEAN_URL(DATA4, DEFAULT) 
FROM XPOLICY 
WHERE ((DATA1 LIKE 'http%') OR (DATA2 LIKE 'http%') OR (DATA3 LIKE 'http%') OR (DATA4 LIKE 'http%'));

SELECT SERV_PROV_CODE, POLICY_NAME, LEVEL_TYPE, LEVEL_DATA, DATA1, DATA2, DATA3, DATA4 FROM XPOLICY 
WHERE POLICY_NAME ='ReportService' AND LEVEL_DATA='serviceName';

SELECT code, description, app_server, provider_code, accelagisserver FROM AMO..agency;

SELECT * FROM ADS..EDOC_INDEX;

SELECT SERV_PROV_CODE, PROFILE_NAME, PROFILE_VALUE FROM ADS..RDOC_CONFIG_PROV_PROFILE 
WHERE ((PROFILE_VALUE LIKE 'http%') OR (PROFILE_VALUE LIKE '\\%') OR (PROFILE_VALUE LIKE '[a-zA-Z]:\%'));

SELECT AGENCY, GIS_SERVICE_ID, GIS_SERVICE_URL, GIS_JAVASCRIPT_API_URL FROM AGIS_SERVICE
WHERE ((GIS_SERVICE_URL LIKE 'http%') OR (GIS_JAVASCRIPT_API_URL LIKE 'http%'));

SELECT SERV_PROV_CODE, APO_SRC_SEQ_NBR, NAME, NAME2 FROM RSERV_PROV;
*/



PRINT 'Clean up'
-- clean up
IF OBJECT_ID('dbo.FN_CLEAN_URL') IS NOT NULL
    EXEC sp_executesql N'DROP FUNCTION dbo.FN_CLEAN_URL;';
GO
IF OBJECT_ID('dbo.FN_CLEAN_EMAIL') IS NOT NULL
    EXEC sp_executesql N'DROP FUNCTION dbo.FN_CLEAN_EMAIL;';
GO
IF OBJECT_ID('dbo.FN_EXTRACT_URLS') IS NOT NULL
    EXEC sp_executesql N'DROP FUNCTION dbo.FN_EXTRACT_URLS;';
GO
BEGIN TRY
    DROP TABLE #ScriptParams;
    DROP TABLE #AuditData;
END TRY
BEGIN CATCH
    -- do nothing
END CATCH
GO
