--************************************************************
---------------------------------
-- SQL Server data scramble script
-- last updated 2019-08-02
---------------------------------
--1. payment related configuration
--2. report related configuration
--3. Update AV URLs in My Navigation
--4. Update ACA_SITE address
--5. Update EDMS ADS_SERVER_URL
--6. Update batch job URL or Disable BATCH JOB
--7. external APO related configuration
--8. AGIS and JSAGIS url
--9.  clean up email columns
--10. clean up SSN#
--11. clean up phone (optional)
--12. clean up revt_agency_script email address
--13. miscellaneous (optional)
--************************************************************

SET NOCOUNT ON;

CREATE TABLE #SampleAgencies (AgencyCode nvarchar(15) NOT NULL);
-- add more agency codes to exclude/include in filters
INSERT INTO #SampleAgencies (AgencyCode)
VALUES 
    (N'QA'),
    (N'BPTDEV');
GO

IF OBJECT_ID('dbo.FN_CLEAN_URL') IS NULL
    EXEC sp_executesql N'CREATE FUNCTION dbo.FN_CLEAN_URL() RETURNS nvarchar(max) AS BEGIN RETURN N''Hello World!''; END;';
GO
ALTER FUNCTION dbo.FN_CLEAN_URL (
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @Output nvarchar(max);
    IF ((@InputString LIKE 'http://%') OR (@InputString LIKE 'https://%'))
    BEGIN
        SET @Output = N'https://donothing.accela.com' + SUBSTRING(@InputString, CHARINDEX('/', @InputString, 10), LEN(@InputString))
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
    @InputString nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @Output nvarchar(max);
    IF ((@InputString LIKE '%@%') AND (@InputString NOT LIKE '%@ACCELA%'))
    BEGIN
        SET @Output = SUBSTRING(@InputString,1,CHARINDEX('@', @InputString)) + 'donothing.accela.com'
    END
    ELSE
    BEGIN
        SET @Output = @InputString;
    END
    RETURN @Output;
END
GO


--************************************************************
--1. payment related configuration (with finacial interface )
--************************************************************
 
UPDATE R1SERVER_CONSTANT SET CONSTANT_VALUE = dbo.FN_CLEAN_URL(CONSTANT_VALUE)
WHERE CONSTANT_NAME LIKE 'PA_AFTER_ACCOUNT_ACTIVATION_URL' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
UPDATE RBIZDOMAIN_VALUE SET BIZDOMAIN_VALUE = dbo.FN_CLEAN_URL(BIZDOMAIN_VALUE)
WHERE BIZDOMAIN LIKE 'ACA_ONLINEPAYMENT_WEBSERVICE_URL'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
UPDATE RBIZDOMAIN_VALUE SET BIZDOMAIN_VALUE = dbo.FN_CLEAN_URL(BIZDOMAIN_VALUE)
WHERE BIZDOMAIN LIKE 'ONLINEPAYMENT_WEBSERVICE_URL'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE '%ONLINE%' AND LOWER(VALUE_DESC) LIKE '%officialpayments%'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
UPDATE XPOLICY SET DATA2 = dbo.FN_CLEAN_URL(DATA2), 
    DATA3 = dbo.FN_CLEAN_URL(DATA3)
WHERE LEVEL_DATA='OPSTP_Live' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
UPDATE XPOLICY SET DATA2 = dbo.FN_CLEAN_URL(DATA2),
    DATA4 = dbo.FN_CLEAN_URL(DATA4)
WHERE LEVEL_DATA='OPCoBrandPlus_Live' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
UPDATE XPOLICY SET DATA4 = dbo.FN_CLEAN_URL(DATA4),
    DATA2 = dbo.FN_CLEAN_URL(DATA2)
WHERE POLICY_NAME = 'PaymentAdapterSec'
AND LEVEL_TYPE = 'Adapter'
AND LEVEL_DATA LIKE 'Govolution%'
AND DATA4 LIKE '%ApplicationID=1146%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--disable all payment adaptor
UPDATE XPOLICY SET REC_STATUS='I'
WHERE POLICY_NAME = 'PaymentAdapterSec' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);   
GO
 
UPDATE XPOLICY SET DATA4 = dbo.FN_CLEAN_URL(DATA4)
WHERE UPPER(DATA4) LIKE '%PRODUCTID=%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE XPOLICY SET DATA3 = dbo.FN_CLEAN_URL(DATA3)
WHERE UPPER(DATA3) LIKE '%CLIENTID=%' OR UPPER(DATA3) LIKE '%PRODUCTID=%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--************************************************************
--2. report related configuration
--************************************************************

UPDATE R1SERVER_CONSTANT SET CONSTANT_VALUE = dbo.FN_CLEAN_URL(CONSTANT_VALUE)
WHERE CONSTANT_NAME LIKE 'REPORT.SERVICE.NAMETRIGGER.ARW' AND UPPER(CONSTANT_VALUE) NOT LIKE '%ACCELA%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO

UPDATE R1SERVER_CONSTANT SET CONSTANT_VALUE = dbo.FN_CLEAN_URL(CONSTANT_VALUE)
WHERE CONSTANT_NAME LIKE 'REPORT.SERVICE.REPORTNAME.CRYSTAL' AND UPPER(CONSTANT_VALUE) NOT LIKE '%ACCELA%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE R1SERVER_CONSTANT SET CONSTANT_VALUE = dbo.FN_CLEAN_URL(CONSTANT_VALUE)
WHERE CONSTANT_NAME LIKE 'REPORT.SERVICE.REPORTNAME.ARW' AND UPPER(CONSTANT_VALUE) NOT LIKE '%ACCELA%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE R1SERVER_CONSTANT SET CONSTANT_VALUE = dbo.FN_CLEAN_URL(CONSTANT_VALUE)
WHERE CONSTANT_NAME LIKE 'REPORT.SERVICE.REPORTNAME.ORACLE' AND UPPER(CONSTANT_VALUE) NOT LIKE '%ACCELA%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE 'REPORTS FROM GIS OBJECTS' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE 'REPORT_SERVICE_EXAMPLE_URL' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- report service URL
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
UPDATE XPOLICY SET DATA1=dbo.FN_CLEAN_URL(DATA1)
WHERE POLICY_NAME ='ReportService' AND LOWER(LEVEL_DATA) LIKE '%url%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE XPOLICY SET DATA1='NOTHING'
WHERE POLICY_NAME ='ReportService'
AND LEVEL_DATA='enviroment' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--update xpolicy set data1 = SUBSTR(data1,0,INSTR(data1,'http://',1,1)+6)||'donothing.accela.com:8080'||SUBSTR(data1,INSTR(data1,'/',1,3))
UPDATE XPOLICY SET DATA1 = dbo.FN_CLEAN_URL(DATA1)
--WHERE POLICY_NAME LIKE 'LoginPolicy' AND DATA1 LIKE '%http://%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
WHERE POLICY_NAME LIKE 'LoginPolicy' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- oracle report 
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- UPDATE XPOLICY SET DATA1=REPLACE(DATA1,'72.166.191.60','100.100.100.100')
UPDATE XPOLICY SET DATA1=dbo.FN_CLEAN_URL(DATA1)
WHERE POLICY_NAME ='ReportService'
-- AND DATA1 LIKE '%72.166.191.60%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);

 
--************************************************************
--3.  AV URLs in My Navigation
--************************************************************
 
-- UPDATE BPORTLETLINKS SET LINK_URL = replace(LINK_URL, 'av3.accela.com', 'donothing.accela.com')
UPDATE BPORTLETLINKS SET LINK_URL = dbo.FN_CLEAN_URL(LINK_URL)
-- WHERE LINK_URL LIKE '%av3.accela.com%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);

/* 
UPDATE BPORTLETLINKS SET LINK_URL = replace(LINK_URL, 'av3.accela.com', 'donothing.accela.com')
WHERE  LINK_URL LIKE '%av3.accela.com%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
*/

--UPDATE GPORTLET SET PORTLET_URL = replace(PORTLET_URL, 'av3.accela.com', 'donothing.accela.com')
UPDATE GPORTLET SET PORTLET_URL = dbo.FN_CLEAN_URL(PORTLET_URL)
-- WHERE PORTLET_URL LIKE '%av3.accela.com%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
 
 
--************************************************************
--4.  ACA_SITE address
--************************************************************
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE 'ACA_CONFIGS' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--************************************************************
--5.  EDMS ADS_SERVER_URL=http://ads.accela.com
--************************************************************
 
--UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = replace(VALUE_DESC,'ads.accela.com','ads.donothing.accela.com')
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
--where VALUE_DESC LIKE '%ads.accela.com%'  AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
update RBIZDOMAIN_VALUE set value_desc = dbo.FN_CLEAN_URL(value_desc)
WHERE BIZDOMAIN LIKE 'EDMS%' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE R1SERVER_CONSTANT SET CONSTANT_VALUE = dbo.FN_CLEAN_URL(CONSTANT_VALUE)
WHERE CONSTANT_NAME LIKE 'EDMS%' AND UPPER(CONSTANT_VALUE) NOT LIKE '%ACCELA%' AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
 
--************************************************************
--6. BATCH JOB
--************************************************************

UPDATE BATCH_JOB SET BATCH_JOB_URL = dbo.FN_CLEAN_URL(BATCH_JOB_url), INSTANCE_NO='', EMAIL_ID=''
--where BATCH_JOB_url like 'http%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--update BATCH_JOB set set instance_no='', email_id='', rec_status='I'
UPDATE BATCH_JOB SET INSTANCE_NO='', EMAIL_ID='', REC_STATUS='I'
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO

--update BATCH_JOB set BATCH_JOB_url = dbo.FN_CLEAN_URL(BATCH_JOB_url), instance_no='', email_id=''
--where BATCH_JOB_url like 'http%' AND SERV_PROV_CODE NOT IN ('QA','BPTDEV');
 
--************************************************************
--7. external APO related configuration
--************************************************************
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(value_desc)
WHERE BIZDOMAIN LIKE 'EXTERNAL_ADDRESS_SOURCE' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
AND UPPER(BIZDOMAIN_VALUE) = 'SOURCE_URL'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO

UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE 'EXTERNAL_PARCEL_SOURCE' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
AND UPPER(BIZDOMAIN_VALUE) = 'SOURCE_URL'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE 'ENABLE_PERMITS_PLUS_SEARCH' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
AND UPPER(BIZDOMAIN_VALUE) = 'PP_WEB_SERVICE_URL'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC = dbo.FN_CLEAN_URL(VALUE_DESC)
WHERE BIZDOMAIN LIKE 'EXTERNAL_OWNER_SOURCE' AND UPPER(VALUE_DESC) NOT LIKE '%ACCELA%'
AND UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
AND UPPER(BIZDOMAIN_VALUE) = 'SOURCE_URL'
AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
--************************************************************
--8.  AGIS, AMO, JSAGIS
--************************************************************
UPDATE AGIS_SERVICE SET REC_STATUS ='I' WHERE AGENCY IN (
    --SELECT to_char(APO_SRC_SEQ_NBR)
    SELECT CAST(APO_SRC_SEQ_NBR AS nvarchar(15))
    FROM RSERV_PROV WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies)
);
 
 
/*
--update agis_service set gis_service_url='https://agis-ccsf-pre.accela.com/agis',GIS_JAVASCRIPT_API_URL='https://agis-ccsf-pre.accela.com/jsagis/api' where gis_service_id='CCSF';
 
--Agis appserverurl update
--update agisuser.configuration set appserverurl='http://10.111.30.75:3080'&nbsp; where agency='CCSF';
--AMO app_server, accelagisserver update
--UPDATE AMO.AGENCY SET app_server='http://10.111.30.75:3080/wireless/GovXMLServlet',ACCELAGISSERVER='https://agis-ccsf-prd.accela.com/agis'
COMMIT;
*/
 
--************************************************************
--9.  clean up email
--************************************************************
UPDATE RSTATE_LIC
   --SET EMAIL = SUBSTR(EMAIL,0,INSTR(EMAIL,'@',1,1)) || 'donothing.accela.com'
   SET EMAIL = dbo.FN_CLEAN_EMAIL(EMAIL)
-- WHERE UPPER(EMAIL) NOT LIKE '%@ACCELA%'
--   AND UPPER(EMAIL) LIKE '%@%' AND 
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RPART_CONTACT
   SET CONTACT_EMAIL = dbo.FN_CLEAN_EMAIL(CONTACT_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE R3APPTYP
   SET R1_HR_EMAIL = dbo.FN_CLEAN_EMAIL(R1_HR_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE PUBLICUSER
   SET EMAIL_ID = dbo.FN_CLEAN_EMAIL(EMAIL_ID);
/*
SET EMAIL_ID = SUBSTR(EMAIL_ID,0,INSTR(EMAIL_ID,'@',1,1)) || 'donothing.accela.com'
 WHERE UPPER(EMAIL_ID) NOT LIKE '%@ACCELA%'
   AND UPPER(EMAIL_ID) LIKE '%@%' ;
*/
GO
-- TODO
UPDATE PUBLICUSER
   SET EMAIL_ID = '*****'||EMAIL_ID
 WHERE UPPER(EMAIL_ID) NOT LIKE '%@ACCELA%'
   AND UPPER(EMAIL_ID) LIKE '%@%' ;
GO
 
UPDATE PERMIT_CLIENT_FEE
   SET USER_EMAIL = dbo.FN_CLEAN_EMAIL(USER_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE L3OWNERS
   SET L1_EMAIL = dbo.FN_CLEAN_EMAIL(L1_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE GDATASET
   SET EMAIL_ADDRESS = dbo.FN_CLEAN_EMAIL(EMAIL_ADDRESS)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE G3STAFFS
   SET GA_EMAIL = dbo.FN_CLEAN_EMAIL(GA_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE G3DPTTYP
   SET R3_EMAIL = dbo.FN_CLEAN_EMAIL(R3_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE G3CONTACT
   SET G1_EMAIL = dbo.FN_CLEAN_EMAIL(G1_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE ELIC_PROF
   SET EMAIL = dbo.FN_CLEAN_EMAIL(EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE C3CITATION
   SET C3_COURT_EMAIL = dbo.FN_CLEAN_EMAIL(C3_COURT_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE B3CONTRA
   SET B1_EMAIL = dbo.FN_CLEAN_EMAIL(B1_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE B3CONTACT
   SET B1_EMAIL = dbo.FN_CLEAN_EMAIL(B1_EMAIL)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RBIZDOMAIN_VALUE
   SET BIZDOMAIN_VALUE = dbo.FN_CLEAN_EMAIL(BIZDOMAIN_VALUE)
 WHERE UPPER(BIZDOMAIN) NOT LIKE 'ACA_CONFIG%'
   AND UPPER(BIZDOMAIN) LIKE '%EMAIL%'
    AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE SPROCESS_NOTE
   SET DISTRIBUTION_DESTINATION = dbo.FN_CLEAN_EMAIL(DISTRIBUTION_DESTINATION)
 WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);
GO
 
UPDATE RCOMMUNICATION_ACCOUNT SET REC_STATUS = 'I'
WHERE ACCOUNT_INFO IN ('eBUILD-noreply@cityofchesapeake.net','autotest@accela.com')
AND SERV_PROV_CODE IN ('ACCELAOPS',SELECT AgencyCode FROM #SampleAgencies);
GO
 
 
UPDATE RCOMMUNICATION_ACCOUNT SET REC_STATUS = 'I'
WHERE SERV_PROV_CODE NOT IN ('ACCELAOPS',SELECT AgencyCode FROM #SampleAgencies);
GO
 
--UPDATE gmessage SET message_text = SUBSTR(message_text,0,INSTR(message_text,'@',1,1)) || 'donothing.accela.com'
--where message_text LIKE '%com%'  ;
--COMMIT;
 
--************************************************************
--10.  clean up SSN
--************************************************************
 
UPDATE PUBLICUSER_UOCB SET SOCIAL_SECURITY_NBR='123-45-6789' WHERE SOCIAL_SECURITY_NBR IS NOT NULL ;                                              
GO                                                                                                                                          
 
UPDATE PUBLICUSER SET SOCIAL_SECURITY_NBR='123-45-6789' WHERE SOCIAL_SECURITY_NBR IS NOT NULL ;                                                   
GO                                                                                                                                          
 
UPDATE G3CONTACT SET G1_SOCIAL_SECURITY_NUMBER='123-45-6789' WHERE G1_SOCIAL_SECURITY_NUMBER IS NOT NULL AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);                                        
GO                                                                                                                                          
 
UPDATE RSTATE_LIC SET LIC_SOCIAL_SECURITY_NBR='123-45-6789' WHERE LIC_SOCIAL_SECURITY_NBR IS NOT NULL AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);                                           
GO                                                                                                                                          
 
UPDATE B3CONTACT SET B1_SOCIAL_SECURITY_NUMBER='123-45-6789' WHERE B1_SOCIAL_SECURITY_NUMBER IS NOT NULL AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);                                        
GO                                                                                                                                          
 
UPDATE B3CONTRA SET B1_SOCIAL_SECURITY_NBR='123-45-6789' WHERE B1_SOCIAL_SECURITY_NBR IS NOT NULL AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);                                               
GO  
 
 
--************************************************************
--11.  clean up phone #  (optional)
--************************************************************
--generate and execute script
DECLARE @SQLCmd nvarchar(max) = N'';
DECLARE @ExecCursor CURSOR;

SET @ExecCursor = CURSOR LOCAL FORWARD_ONLY FOR
    SELECT 
        'UPDATE ' + TABLE_NAME + ' SET ' + COLUMN_NAME + '=REPLACE(' + COLUMN_NAME + ',''0123456789_-'',''9876543210_-'')  AND SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies);'''
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE COLUMN_NAME LIKE '%PHONE%' 
    AND TABLE_NAME IN (
        SELECT OBJECT_NAME FROM AA_OBJECTS WHERE OBJECT_TYPE='TABLE') 
    AND SERV_PROV_CODE NOT IN (
        SELECT AgencyCode FROM #SampleAgencies);
OPEN @ExecCursor
FETCH NEXT FROM @ExecCursor INTO @SQLCmd;
WHILE (@@FETCH_STATUS=0)
BEGIN
    PRINT @SQLCmd
    --EXEC sp_executesql @SQLCmd
    FETCH NEXT FROM @ExecCursor INTO @SQLCmd;
END
CLOSE @ExecCursor;
DEALLOCATE @ExecCursor;
 
 
--************************************************************
--12.  clean up revt_agency_script email address
--************************************************************
--
--update revt_agency_script set script_text=dbo.FN_CLEAN_URL(script_text)
--where  serv_prov_code not in ('QA','BPTDEV');
 
GO
 
--************************************************************
--13.  miscellaneous
--************************************************************
--EMSETOOLCONFIG url username/password
--
--select * from rbizdomain_value where bizdomain = 'EMSEToolConfig' ;
 
UPDATE RBIZDOMAIN_VALUE SET VALUE_DESC='password'
WHERE SERV_PROV_CODE NOT IN (SELECT AgencyCode FROM #SampleAgencies) AND BIZDOMAIN = 'EMSEToolConfig' AND BIZDOMAIN_VALUE LIKE '%repo_password%';
GO
