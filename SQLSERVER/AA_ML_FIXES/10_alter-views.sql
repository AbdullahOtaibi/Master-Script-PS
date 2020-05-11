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

ALTER VIEW [dbo].[AAVERSION_MODULE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.MODULE_NAME MODULE_NAME_V
  FROM      AAVERSION_MODULE T 
  LEFT JOIN AAVERSION_MODULE_I18N I
    ON T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_FEE_PAYMENT_HISTORY] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.TRAN_DATE                      AS UPDATED_DATE
--=== Fee Payment History Info  
  ,B.ACTION                         AS ACTION
  ,B.TRAN_AMOUNT                    AS AMOUNT
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.BANK_NAME END)
                                    AS BANK_NAME
  ,C.BATCH_TRANSACTION_NBR          AS BATCH_TRANSACT_ID                                  
  ,B.TERMINAL_ID                    AS CASH_DRAWER
  ,B.CASHIER_ID                     AS CASHIER_USERID
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.CHECK_HOLDER_EMAIL END)
                                    AS CHECK_HOLDER_EMAIL
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.CHECK_HOLDER_NAME END)
                                    AS CHECK_HOLDER_NAME
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.CHECK_NUMBER END)
                                    AS CHECK_NUMBER
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.CHECK_TYPE END)
                                    AS CHECK_TYPE
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.PAYMENT_DATE END)
                                    AS DATE_PAYMENT
  ,B.TRAN_DATE                      AS DATE_TRANSACTION
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.DRIVER_LICENSE END)
                                    AS DRIVER_LICENSE
  ,B.GF_L1                          AS FEE_ACCT_CODE_1
  ,B.GF_L2                          AS FEE_ACCT_CODE_2
  ,B.GF_L3                          AS FEE_ACCT_CODE_3
  ,B.GF_FEE                         AS FEE_AMOUNT_ASSESSED
  ,B.GF_COD                         AS FEE_CODE
  ,B.GF_DES                         AS FEE_DESCRIPTION
  ,B.FEEITEM_SEQ_NBR                AS FEE_ID
  ,B.GF_UNIT                        AS FEE_QUANTITY
  ,B.GF_FEE_SCHEDULE                AS FEE_SCHEDULE
  ,B.INVOICE_NBR                    AS INVOICE_ID
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.PAYMENT_COMMENT END)
                                    AS PAYMENT_COMMENTS
  ,B.PAYMENT_SEQ_NBR                AS PAYMENT_ID
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN B.PAYMENT_METHOD END)
                                    AS PAYMENT_METHOD
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN B.PAYMENT_REF_NBR END)
                                    AS PAYMENT_REFERENCE
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.PAYEE   END)
                                    AS PAYOR
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.PHONE_NUMBER END)
                                    AS PHONE_NUMBER
  ,C.POS_TRANS_SEQ                  AS POS_ID
  ,E.MODULE_NAME                    AS POS_MODULE
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.RECEIPT_NBR END)
                                    AS RECEIPT_ID
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN R.RECEIPT_CUSTOMIZED_NBR END)
                                    AS RECEIPT_NUMBER
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN R.RECEIPT_AMOUNT END)
                                    AS RECEIPT_TOTAL
  ,(CASE WHEN B.ACTION<>N'Refund Applied' THEN C.PAYMENT_RECEIVED_CHANNEL END) 
                                    AS RECEIVED
  ,(CASE WHEN C.POS_TRANS_SEQ IS NULL THEN A.B1_ALT_ID ELSE NULL END)
                                    AS RECORD_ID#
  ,(CASE WHEN C.POS_TRANS_SEQ IS NULL THEN A.B1_PER_GROUP ELSE NULL END)                                  
                                    AS RECORD_MODULE#
  ,(CASE WHEN C.POS_TRANS_SEQ IS NULL THEN A.B1_FILE_DD ELSE NULL END)                                  
                                    AS RECORD_OPEN_DATE#
  ,(  CASE WHEN C.POS_TRANS_SEQ IS NULL
        THEN A.B1_ALT_ID
        ELSE N'POS ' + RTRIM(CAST(C.POS_TRANS_SEQ AS CHAR))
      END
  )                               AS RECORD_OR_POS_ID#
  ,(  CASE WHEN C.POS_TRANS_SEQ IS NULL
        THEN A.B1_PER_GROUP
        ELSE E.MODULE_NAME
      END
  )                                 AS RECORD_OR_POS_MODU#  
  ,(CASE WHEN C.POS_TRANS_SEQ IS NULL THEN A.B1_APPL_STATUS ELSE NULL END)                                
                                    AS RECORD_STATUS#
  ,(CASE WHEN C.POS_TRANS_SEQ IS NULL THEN B1_APPL_STATUS_DATE ELSE NULL END)
                                    AS RECORD_STATUS_DATE#
  ,B.SESSION_NBR                    AS SESSION_ID
  ,B.SET_ID                         AS SET_ID
  ,B.TRUST_ACCOUNT_ID               AS TRUST_ACCOUNT_ID
  ,B.WORKSTATION_ID                 AS WORKSTATION
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  ACCOUNTING_AUDIT_TRAIL B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  JOIN
  F4PAYMENT C
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = C.B1_PER_ID1 
    AND B.B1_PER_ID2 = C.B1_PER_ID2 
    AND B.B1_PER_ID3 = C.B1_PER_ID3 
    AND B.PAYMENT_SEQ_NBR = C.PAYMENT_SEQ_NBR
  LEFT JOIN
  F4POS_TRANSACTION E
    ON  C.SERV_PROV_CODE = E.SERV_PROV_CODE 
    AND C.POS_TRANS_SEQ = E.POS_TRANS_SEQ
  LEFT JOIN
  F4RECEIPT R
    ON  C.SERV_PROV_CODE = R.SERV_PROV_CODE
    AND C.RECEIPT_NBR = R.RECEIPT_NBR
WHERE
  A.REC_STATUS = N'A'
--**** Only Payment Applied, Void Payment Applied, and Refund Applied transactions
  AND B.ACTION IN (N'Payment Applied',N'Void Payment Applied',N'Refund Applied')
GO

ALTER VIEW [dbo].[AGIS_PROXIMITY_ALERTS_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.ALERT_MSG ALERT_MSG_V
  FROM      AGIS_PROXIMITY_ALERTS T 
  LEFT JOIN AGIS_PROXIMITY_ALERTS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[APP_EVENT_HISTORY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.EVENT_NAME EVENT_NAME_V, 
       I.HEARING_BODY HEARING_BODY_V
  FROM      APP_EVENT_HISTORY T 
  LEFT JOIN APP_EVENT_HISTORY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[APP_STATUS_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.STATUS STATUS_V
  FROM      APP_STATUS_GROUP T 
  LEFT JOIN APP_STATUS_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_RECORD_LICENSE] 
AS
SELECT
--=== Record Info - Common to Views
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,A.REC_FUL_NAM                    AS UPDATED_BY
--=== Record Info  
  ,A.B1_CREATED_BY_ACA              AS ACA_INITIATED
  --ADDR_FULL_LINE# - full address, line format, priority to primary
  ,(  select TOP 1  
        isnull(rtrim(cast(y.b1_hse_nbr_start as char)),N'')
        +
        (case when isnull(y.b1_hse_frac_nbr_start,N'')<>N'' then N' '+y.b1_hse_frac_nbr_start else N'' end)
        +
        (case when isnull(y.b1_str_dir,N'')<>N'' then N' '+y.b1_str_dir else N'' end)
        +
        (case when isnull(y.b1_str_name,N'')<>N'' then N' '+y.b1_str_name else N'' end)
        +
        (case when isnull(y.b1_str_suffix,N'')<>N'' then N' '+y.b1_str_suffix else N'' end)
        +
        (case when isnull(y.b1_str_suffix_dir,N'')<>N'' then N' '+y.b1_str_suffix_dir else N'' end)
        --if unit number only
        +
        ( case when isnull(y.b1_unit_type,N'')=N'' and isnull(y.b1_unit_start,N'')<>N''
            then N', #'+y.b1_unit_start else N''
          end
        )
        --if unit type available
        +
        (case when isnull(y.b1_unit_type,N'')<>N'' then N', '+y.b1_unit_type+N' '+isnull(y.b1_unit_start,N'') else N'' end)
        --city, state zip
        +
        (case when isnull(y.b1_situs_city,N'')=N'' then N'' else N', '+y.b1_situs_city end)
        +
        (case when isnull(y.b1_situs_state,N'')=N'' then N'' else N', ' +y.b1_situs_state end)
        +
        N' '+isnull(y.b1_situs_zip,N'')
      from    
        b3addres y
      where   
        A.SERV_PROV_CODE = y.serv_prov_code 
        and A.B1_PER_ID1 = y.b1_per_id1 
        and A.B1_PER_ID2 = y.b1_per_id2 
        and A.B1_PER_ID3 = y.b1_per_id3
      order by isnull(nullif(y.b1_primary_addr_flg,N''),N'N') desc, y.b1_address_nbr
  )                                 AS ADDR_FULL_LINE#
  ,A.B1_APPL_CLASS                  AS APP_COMPLETENESS
  ,D.B1_ASGN_STAFF                  AS ASSIGNED_USERID
  ,D.BALANCE                        AS BALANCE_DUE
  ,D.B1_CLOSEDBY                    AS CLOSED_USERID
  ,D.B1_COMPLETE_BY                 AS COMPLETED_USERID
  ,D.B1_ASGN_DATE                   AS DATE_ASSIGNED
  ,D.B1_CLOSED_DATE                 AS DATE_CLOSED
  ,D.B1_COMPLETE_DATE               AS DATE_COMPLETED
  ,C.EXPIRATION_DATE                AS DATE_EXPIRATION
  ,A.B1_FILE_DD                     AS DATE_OPENED
  ,A.REC_DATE                       AS DATE_OPENED_ORIGINAL
  ,A.B1_APPL_STATUS_DATE            AS DATE_STATUS
  ,D.B1_TRACK_START_DATE            AS DATE_TRACK_START
  ,C.EXPIRATION_CODE                AS EXPIRATION_CODE
  ,C.EXPIRATION_DATE                AS EXPIRATION_DATE
  ,C.EXPIRATION_STATUS              AS EXPIRATION_STATUS
  ,B.B1_WORK_DESC                   AS DESCRIPTION
  ,D.B1_IN_POSSESSION_TIME          AS IN_POSSESSION_HRS
  ,D.C6_INSPECTOR_NAME              AS INSPECTOR_USERID
  ,D.C6_ENFORCE_OFFICER_NAME        AS OFFICER_USERID
  ,D.B1_CREATED_BY                  AS OPENED_USERID
  ,(  select TOP 1
          j.b1_alt_id  
      from 
          xapp2ref x inner join  
          b1permit j on
              x.serv_prov_code = j.serv_prov_code and
              x.b1_master_id1 = j.b1_per_id1 and
              x.b1_master_id2 = j.b1_per_id2 and
              x.b1_master_id3 = j.b1_per_id3
      where 
          x.serv_prov_code = A.SERV_PROV_CODE AND 
          x.b1_per_id1 = A.B1_PER_ID1 AND
          x.b1_per_id2 = A.B1_PER_ID2 AND
          x.b1_per_id3 = A.B1_PER_ID3 AND
          x.rec_status = N'A' and 
          j.rec_status = N'A' and
          (j.b1_appl_status<>N'void' or j.b1_appl_status is null) 
  )                                 AS PARENT_RECORD_ID#
  ,D.PERCENT_COMPLETE               AS PERCENT_COMPLETE
  ,D.B1_PRIORITY                    AS PRIORITY
  ,DATEDIFF(
    d
    ,CONVERT(DATETIME,A.B1_FILE_DD)
    ,CONVERT(DATETIME,GETDATE())
  )                                 AS RECORD_AGE
  ,D.B1_OVERALL_APPLICATION_TIME    AS RECORD_OPEN_HRS
  ,A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY 
                                    AS RECORD_TYPE_4LEVEL#
  ,A.B1_PER_CATEGORY                AS RECORD_TYPE_CATEGORY
  ,A.B1_PER_GROUP                   AS RECORD_TYPE_GROUP
  ,A.B1_PER_SUB_TYPE                AS RECORD_TYPE_SUBTYPE
  ,A.B1_PER_TYPE                    AS RECORD_TYPE_TYPE
  ,D.B1_REPORTED_CHANNEL            AS REPORTED_CHANNEL
  ,D.B1_SHORT_NOTES                 AS SHORT_NOTES
  ,A.B1_APPL_STATUS                 AS STATUS
  ,D.TOTAL_FEE                      AS TOTAL_INVOICED
  ,D.TOTAL_PAY                      AS TOTAL_PAID
  ,E.ACCT_BALANCE                   AS TRUST_ACCOUNT_BAL
  ,E.ACCT_DESC                      AS TRUST_ACCOUNT_DESC
  ,E.ACCT_ID                        AS TRUST_ACCOUNT_ID_PRI
  ,E.ACCT_STATUS                    AS TRUST_ACCOUNT_STATUS
    --- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A
  LEFT JOIN
  BWORKDES B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  B1_EXPIRATION C
    ON  A.SERV_PROV_CODE = C.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = C.B1_PER_ID1 
    AND A.B1_PER_ID2 = C.B1_PER_ID2 
    AND A.B1_PER_ID3 = C.B1_PER_ID3
  JOIN
  BPERMIT_DETAIL D
    ON  A.SERV_PROV_CODE = D.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = D.B1_PER_ID1 
    AND A.B1_PER_ID2 = D.B1_PER_ID2 
    AND A.B1_PER_ID3 = D.B1_PER_ID3
  LEFT JOIN
  RACCOUNT E
    ON  D.SERV_PROV_CODE = E.SERV_PROV_CODE
    AND D.PRIMARY_TRUST_ACCOUNT_NUM = E.ACCT_SEQ_NBR
WHERE
  ( A.B1_APPL_STATUS NOT IN (N'VOID',N'VOIDED')
    OR 
    A.B1_APPL_STATUS IS NULL 
  )
  AND A.REC_STATUS=N'A'
  AND A.B1_PER_GROUP=N'Licenses'
GO

-----------------------------------------------------------------------
--Accela Views (begin)
-----------------------------------------------------------------------
ALTER VIEW [dbo].[V_ADDRESS] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE        AS AGENCY_ID
  ,A.B1_ALT_ID            AS RECORD_ID
  ,A.B1_PER_GROUP         AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT      AS RECORD_NAME
  ,A.B1_FILE_DD           AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS       AS RECORD_STATUS
  ,A.B1_APPL_STATUS_DATE  AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)        AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM          AS UPDATED_BY
  ,B.REC_DATE             AS UPDATED_DATE
--=== Address Concatenated
  --ADDR_FULL_BLOCK - full address, block format
   ,(
      ISNULL(RTRIM(CAST(B.B1_HSE_NBR_START AS CHAR)),N'')
      +
      (CASE WHEN ISNULL(B.B1_HSE_FRAC_NBR_START,N'')<>N'' THEN N' '+B.B1_HSE_FRAC_NBR_START ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_DIR,N'')<>N'' THEN N' '+B.B1_STR_DIR ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_NAME,N'')<>N'' THEN N' '+B.B1_STR_NAME ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX_DIR,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX_DIR ELSE N'' END)
      --If only Unit #, show at end of 1st line
      +
      ( CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')=N'' AND ISNULL(B.B1_UNIT_START,N'')<>N''
          THEN N' #'+B.B1_UNIT_START ELSE N''
        END
      )
      --If Unit Type available, show on 2nd line
      +
      (CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')<>N'' THEN CHAR(10)+B.B1_UNIT_TYPE+N' '+ISNULL(B.B1_UNIT_START,N'') ELSE N'' END)
      --City, State ZIP on 3rd line
      +
      (  CASE WHEN ISNULL(B.B1_SITUS_CITY,N'')=N'' AND ISNULL(B.B1_SITUS_STATE,N'')=N'' AND ISNULL(B.B1_SITUS_ZIP,N'')=N''
          THEN N''
          ELSE CHAR(10)
               +
               ISNULL(B.B1_SITUS_CITY,N'') + CASE WHEN ISNULL(B.B1_SITUS_CITY,N'')<>N'' THEN N', ' ELSE N'' END
               +
               ISNULL(B.B1_SITUS_STATE,N'') + CASE WHEN ISNULL(B.B1_SITUS_STATE,N'')<>N'' THEN N' ' ELSE N'' END
               +
               ISNULL(B.B1_SITUS_ZIP,N'')
         END
      )
  )                       AS ADDR_FULL_BLOCK
  --ADDR_FULL_LINE - full address, line format
  ,(
      ISNULL(RTRIM(CAST(B.B1_HSE_NBR_START AS CHAR)),N'')
      +
      (CASE WHEN ISNULL(B.B1_HSE_FRAC_NBR_START,N'')<>N'' THEN N' '+B.B1_HSE_FRAC_NBR_START ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_DIR,N'')<>N'' THEN N' '+B.B1_STR_DIR ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_NAME,N'')<>N'' THEN N' '+B.B1_STR_NAME ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX_DIR,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX_DIR ELSE N'' END)
      --IF UNIT NUMBER ONLY
      +
      ( CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')=N'' AND ISNULL(B.B1_UNIT_START,N'')<>N''
          THEN N', #'+B.B1_UNIT_START ELSE N''
        END
      )
      --IF UNIT TYPE AVAILABLE
      +
      (CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')<>N'' THEN N', '+B.B1_UNIT_TYPE+N' '+ISNULL(B.B1_UNIT_START,N'') ELSE N'' END)
      --CITY, STATE ZIP
      +
      (CASE WHEN ISNULL(B.B1_SITUS_CITY,N'')=N'' THEN N'' ELSE N', '+B.B1_SITUS_CITY END)
      +
      (CASE WHEN ISNULL(B.B1_SITUS_STATE,N'')=N'' THEN N'' ELSE N', ' +B.B1_SITUS_STATE END)
      +
      N' '+ISNULL(B.B1_SITUS_ZIP,N'')
  )                       AS ADDR_FULL_LINE
  --ADDR_PARTIAL - Partial address, line format
  ,(
      ISNULL(RTRIM(CAST(B.B1_HSE_NBR_START AS CHAR)),N'')
      +
      (CASE WHEN ISNULL(B.B1_HSE_FRAC_NBR_START,N'')<>N'' THEN N' '+B.B1_HSE_FRAC_NBR_START ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_DIR,N'')<>N'' THEN N' '+B.B1_STR_DIR ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_NAME,N'')<>N'' THEN N' '+B.B1_STR_NAME ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX_DIR,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX_DIR ELSE N'' END)
      --If Unit Number only
      +
      ( CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')=N'' AND ISNULL(B.B1_UNIT_START,N'')<>N''
          THEN N', #'+B.B1_UNIT_START ELSE N''
        END
      )
      --If Unit Type available
      +
      (CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')<>N'' THEN N', '+B.B1_UNIT_TYPE+N' '+ISNULL(B.B1_UNIT_START,N'') ELSE N'' END)
  )                         AS ADDR_PARTIAL
   --ADDR_FULL_BLOCK1 - full address, block format
   ,(
      ISNULL(RTRIM(CAST(B.B1_HSE_NBR_ALPHA_START AS CHAR)),N'')
      +
      (CASE WHEN ISNULL(B.B1_HSE_FRAC_NBR_START,N'')<>N'' THEN N' '+B.B1_HSE_FRAC_NBR_START ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_DIR,N'')<>N'' THEN N' '+B.B1_STR_DIR ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_NAME,N'')<>N'' THEN N' '+B.B1_STR_NAME ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX_DIR,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX_DIR ELSE N'' END)
      --If only Unit #, show at end of 1st line
      +
      ( CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')=N'' AND ISNULL(B.B1_UNIT_START,N'')<>N''
          THEN N' #'+B.B1_UNIT_START ELSE N''
        END
      )
      --If Unit Type available, show on 2nd line
      +
      (CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')<>N'' THEN CHAR(10)+B.B1_UNIT_TYPE+N' '+ISNULL(B.B1_UNIT_START,N'') ELSE N'' END)
      --City, State ZIP on 3rd line
      +
      (  CASE WHEN ISNULL(B.B1_SITUS_CITY,N'')=N'' AND ISNULL(B.B1_SITUS_STATE,N'')=N'' AND ISNULL(B.B1_SITUS_ZIP,N'')=N''
          THEN N''
          ELSE CHAR(10)
               +
               ISNULL(B.B1_SITUS_CITY,N'') + CASE WHEN ISNULL(B.B1_SITUS_CITY,N'')<>N'' THEN N', ' ELSE N'' END
               +
               ISNULL(B.B1_SITUS_STATE,N'') + CASE WHEN ISNULL(B.B1_SITUS_STATE,N'')<>N'' THEN N' ' ELSE N'' END
               +
               ISNULL(B.B1_SITUS_ZIP,N'')
         END
      )
  )                       AS ADDR_FULL_BLOCK1
  --ADDR_FULL_LINE1 - full address, line format
  ,(
      ISNULL(RTRIM(CAST(B.B1_HSE_NBR_ALPHA_START AS CHAR)),N'')
      +
      (CASE WHEN ISNULL(B.B1_HSE_FRAC_NBR_START,N'')<>N'' THEN N' '+B.B1_HSE_FRAC_NBR_START ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_DIR,N'')<>N'' THEN N' '+B.B1_STR_DIR ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_NAME,N'')<>N'' THEN N' '+B.B1_STR_NAME ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX_DIR,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX_DIR ELSE N'' END)
      --If Unit Number only
      +
      ( CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')=N'' AND ISNULL(B.B1_UNIT_START,N'')<>N''
          THEN N', #'+B.B1_UNIT_START ELSE N''
        END
      )
      --If Unit Type available
      +
      (CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')<>N'' THEN N', '+B.B1_UNIT_TYPE+N' '+ISNULL(B.B1_UNIT_START,N'') ELSE N'' END)
      --City, State ZIP
      +
      (CASE WHEN ISNULL(B.B1_SITUS_CITY,N'')=N'' THEN N'' ELSE N', '+B.B1_SITUS_CITY END)
      +
      (CASE WHEN ISNULL(B.B1_SITUS_STATE,N'')=N'' THEN N'' ELSE N', ' +B.B1_SITUS_STATE END)
      +
      N' '+ISNULL(B.B1_SITUS_ZIP,N'')
  )                       AS ADDR_FULL_LINE1
  --ADDR_PARTIAL1 - Partial address, line format
  ,(
      ISNULL(RTRIM(CAST(B.B1_HSE_NBR_ALPHA_START AS CHAR)),N'')
      +
      (CASE WHEN ISNULL(B.B1_HSE_FRAC_NBR_START,N'')<>N'' THEN N' '+B.B1_HSE_FRAC_NBR_START ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_DIR,N'')<>N'' THEN N' '+B.B1_STR_DIR ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_NAME,N'')<>N'' THEN N' '+B.B1_STR_NAME ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX ELSE N'' END)
      +
      (CASE WHEN ISNULL(B.B1_STR_SUFFIX_DIR,N'')<>N'' THEN N' '+B.B1_STR_SUFFIX_DIR ELSE N'' END)
      --If Unit Number only
      +
      ( CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')=N'' AND ISNULL(B.B1_UNIT_START,N'')<>N''
          THEN N', #'+B.B1_UNIT_START ELSE N''
        END
      )
      --If Unit Type available
      +
      (CASE WHEN ISNULL(B.B1_UNIT_TYPE,N'')<>N'' THEN N', '+B.B1_UNIT_TYPE+N' '+ISNULL(B.B1_UNIT_START,N'') ELSE N'' END)
  )                         AS ADDR_PARTIAL1
--=== Address Parts
  ,B.L1_ADDRESS_NBR         AS ADDRESS_REF_ID
  ,B.B1_ADDRESS1            AS ADDRESS_LINE_1
  ,B.B1_ADDRESS2            AS ADDRESS_LINE_2
  ,B.B1_SITUS_CITY          AS CITY
  ,ISNULL(NULLIF(B.B1_PRIMARY_ADDR_FLG,N''),N'N')
                            AS PRIMARY_
  ,B.B1_STR_SUFFIX_DIR      AS QUADRANT
  ,B.B1_SITUS_STATE         AS STATE_
  ,B.B1_SITUS_COUNTY        AS COUNTY
  ,B.B1_STR_DIR             AS STREET_DIRECTION
  ,B.B1_STR_NAME            AS STREET_NAME
  ,B.B1_HSE_NBR_START       AS STREET_NBR
  ,B.B1_HSE_NBR_ALPHA_START AS STREET_NBR_ALPHA
  ,B.B1_HSE_FRAC_NBR_START  AS STREET_NBR_FRACTION
  ,B.B1_STR_SUFFIX          AS STREET_TYPE
  ,B.B1_UNIT_START          AS UNIT_NBR
  ,B.B1_UNIT_TYPE           AS UNIT_TYPE
  ,B.B1_SITUS_ZIP           AS ZIP
 ---- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' +  CONVERT(NVARCHAR, B.B1_ADDRESS_NBR) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,CONVERT(NVARCHAR, B.B1_ADDRESS_NBR) AS T_ID4
FROM
  B1PERMIT A
  JOIN
  B3ADDRES B
    ON  A.SERV_PROV_CODE=B.SERV_PROV_CODE
    AND A.B1_PER_ID1=B.B1_PER_ID1
    AND A.B1_PER_ID2=B.B1_PER_ID2
    AND A.B1_PER_ID3=B.B1_PER_ID3
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_COMMENT_RECORD] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Record Comment Info  
  ,D2.R3_DEPTNAME                   AS ADDED_BY_DEPT
  ,S.GA_FNAME                       AS ADDED_BY_NAME_F 
  --ADDED_BY_NAME_FML#
  ,RTRIM(  S.GA_FNAME+N' '+
      (CASE WHEN S.GA_MNAME IS NOT NULL THEN S.GA_MNAME+N' ' ELSE N'' END)+
      S.GA_LNAME
  )                                 AS ADDED_BY_NAME_FML#
  ,S.GA_LNAME                       AS ADDED_BY_NAME_L
  ,S.GA_MNAME                       AS ADDED_BY_NAME_M
  ,B.REC_FUL_NAM                    AS ADDED_BY_USERID
  ,B.DISPLAY_ON_INSPECTION          AS APPLY_TO_INSP
  ,B.REC_DATE                       AS COMMENT_DATE
  ,B.TEXT                           AS COMMENTS
  ,SUBSTRING(B.TEXT, 1, 2000)       AS COMMENTS_CHAR
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  BPERMIT_COMMENT B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  JOIN
  G3STAFFS S
    ON  S.SERV_PROV_CODE=B.SERV_PROV_CODE
    AND S.USER_NAME=B.REC_FUL_NAM
  LEFT JOIN
  G3DPTTYP D2
  -- Dept
    ON  S.SERV_PROV_CODE = D2.SERV_PROV_CODE 
    AND S.GA_AGENCY_CODE = D2.R3_AGENCY_CODE 
    AND S.GA_BUREAU_CODE = D2.R3_BUREAU_CODE 
    AND S.GA_DIVISION_CODE = D2.R3_DIVISION_CODE 
    AND S.GA_SECTION_CODE = D2.R3_SECTION_CODE 
    AND S.GA_GROUP_CODE = D2.R3_GROUP_CODE 
    AND S.GA_OFFICE_CODE = D2.R3_OFFICE_CODE  
WHERE
  B.COMMENT_TYPE=N'APP LEVEL COMMENT'
  AND A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_CONDITION_RECORD] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Condition Info  
  ,D2.R3_DEPTNAME                   AS ACTION_BY_DEPT
  ,B.B1_CON_STAT_FNAME              AS ACTION_BY_NAME_F 
  --ACTION_BY_NAME_FML#
  ,LTRIM(  
    ISNULL(B.B1_CON_STAT_FNAME,N'')+N' '+
    (CASE WHEN NULLIF(B.B1_CON_STAT_MNAME,N'') IS NOT NULL THEN B.B1_CON_STAT_MNAME+N' ' ELSE N'' END)+
    ISNULL(B.B1_CON_STAT_LNAME,N'')
  )                                 AS ACTION_BY_NAME_FML#
  ,B.B1_CON_STAT_LNAME              AS ACTION_BY_NAME_L
  ,B.B1_CON_STAT_MNAME              AS ACTION_BY_NAME_M
  --ACTION_BY_USERID# - Pull first match by name, priority to active user
  ,(  select  top 1 p.user_name
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.B1_CON_STAT_FNAME
              and p.lname=B.B1_CON_STAT_LNAME
              and (
                nullif(p.mname,N'') is null AND NULLIF(B.B1_CON_STAT_MNAME,N'') IS NULL
                  or
                p.mname=B.B1_CON_STAT_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS ACTION_BY_USERID#
  ,D1.R3_DEPTNAME                   AS APPLIED_BY_DEPT
  ,B.B1_CON_ISS_FNAME               AS APPLIED_BY_NAME_F
  --APPLIED_BY_NAME_FML#
  ,LTRIM(  
    ISNULL(B.B1_CON_ISS_FNAME,N'')+N' '+
    (CASE WHEN NULLIF(B.B1_CON_ISS_MNAME,N'') IS NOT NULL THEN B.B1_CON_ISS_MNAME+N' ' ELSE N'' END)+
    ISNULL(B.B1_CON_ISS_LNAME,N'')
  )                                 AS APPLIED_BY_NAME_FML#
  ,B.B1_CON_ISS_LNAME               AS APPLIED_BY_NAME_L
  ,B.B1_CON_ISS_MNAME               AS APPLIED_BY_NAME_M
  --APPLIED_BY_USERID# - Pull first match by name, priority to active user
  ,(  select  TOP 1 p.user_name
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.B1_CON_ISS_FNAME
              and p.lname=B.B1_CON_ISS_LNAME
              and (
                nullif(p.mname,N'') is null AND NULLIF(B.B1_CON_ISS_MNAME,N'') IS NULL
                  or
                p.mname=B.B1_CON_ISS_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS APPLIED_BY_USERID#
  ,B.B1_CON_ISS_DD                  AS APPLIED_DATE  
  ,B.B1_CON_LONG_COMMENT            AS COMMENTS_LONG
  ,B.B1_CON_COMMENT                 AS COMMENTS_SHORT
  ,B.B1_CON_NBR                     AS CONDITION_ID
  ,B.B1_CON_DES                     AS CONDITION_NAME
  ,B.B1_CON_ISS_DD                  AS DATE_APPLIED
  ,B.B1_CON_EFF_DD1                 AS DATE_EFFECTIVE
  ,B.B1_CON_EXPIR_DD                AS DATE_EXPIRE
  ,B.B1_CON_DIS_CON_NOTICE          AS DISPLAY_NOTICE_AA
  ,B.B1_CON_DIS_NOTICE_ACA          AS DISPLAY_NOTICE_ACA
  ,B.B1_CON_DIS_NOTICE_ACA_FEE      AS DISPLAY_NOTICE_ACA_FEE
  ,B.B1_DISPLAY_ORDER               AS DISPLAY_ORDER
  ,C.B1_CON_PUBLIC_DIS_MESSAGE      AS DISPLAYED_MESSAGE
  ,B.B1_CON_GROUP                   AS GROUP_
  ,B.B1_CON_INHERITABLE             AS INHERITABLE
  ,B.G6_ACT_NUM                     AS INSPECTION_ID
  ,C.B1_CON_RESOLUTION_ACTION       AS RESOLUTION_ACTION
  ,B.B1_CON_IMPACT_CODE             AS SEVERITY
  ,B.B1_CON_STATUS                  AS STATUS
  ,B.B1_CON_TYP                     AS TYPE_
  ,B.REC_STATUS                     AS CONDITION_REC_STATUS
  --- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' +  CONVERT(NVARCHAR, B.B1_CON_NBR) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,CONVERT(NVARCHAR, B.B1_CON_NBR) AS T_ID4
FROM
  B1PERMIT A 
  JOIN
  B6CONDIT B
    ON  A.SERV_PROV_CODE=B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN 
  B6CONDIT_DETAIL C
    ON  B.SERV_PROV_CODE=C.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = C.B1_PER_ID1 
    AND B.B1_PER_ID2 = C.B1_PER_ID2 
    AND B.B1_PER_ID3 = C.B1_PER_ID3 
    AND B.B1_CON_NBR = C.B1_CON_NBR
  LEFT JOIN
  G3DPTTYP D1
 --Applied by Dept
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE 
    AND B.B1_CON_ISS_AGENCY_CODE = D1.R3_AGENCY_CODE 
    AND B.B1_CON_ISS_BUREAU_CODE = D1.R3_BUREAU_CODE 
    AND B.B1_CON_ISS_DIVISION_CODE = D1.R3_DIVISION_CODE 
    AND B.B1_CON_ISS_SECTION_CODE = D1.R3_SECTION_CODE 
    AND B.B1_CON_ISS_GROUP_CODE = D1.R3_GROUP_CODE 
    AND B.B1_CON_ISS_OFFICE_CODE = D1.R3_OFFICE_CODE
  LEFT JOIN
  G3DPTTYP D2
  --Action Dept
    ON  B.SERV_PROV_CODE = D2.SERV_PROV_CODE 
    AND B.B1_CON_STAT_AGENCY_CODE = D2.R3_AGENCY_CODE 
    AND B.B1_CON_STAT_BUREAU_CODE = D2.R3_BUREAU_CODE 
    AND B.B1_CON_STAT_DIVISION_CODE=D2.R3_DIVISION_CODE 
    AND B.B1_CON_STAT_SECTION_CODE=D2.R3_SECTION_CODE 
    AND B.B1_CON_STAT_GROUP_CODE = D2.R3_GROUP_CODE 
    AND B.B1_CON_STAT_OFFICE_CODE = D2.R3_OFFICE_CODE  
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_CONTACT] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Contact Info  
  --Added by Shirley Li on 20131018 for client's request for field 'B1_CONTACT_NBR'
  ,B.B1_CONTACT_NBR                 AS CONTACT_NBR
  ,B.B1_ADDRESS1                    AS ADDRESS_LINE1
  ,B.B1_ADDRESS2                    AS ADDRESS_LINE2
  ,B.B1_ADDRESS3                    AS ADDRESS_LINE3
  ,B.B1_CITY                        AS ADDRESS_CITY
  ,B.B1_POST_OFFICE_BOX             AS ADDRESS_PO_BOX
  ,B.B1_STATE                       AS ADDRESS_STATE
  ,B.B1_ZIP                         AS ADDRESS_ZIP
  ,B.B1_COUNTRY                     AS ADDRESS_COUNTRY
  ,B.B1_BUSINESS_NAME               AS BUSINESS_NAME  
  ,B.G1_CONTACT_NBR                 AS CONTACT_REF_ID
  ,B.B1_CONTACT_TYPE                AS CONTACT_TYPE
  ,B.B1_EMAIL                       AS EMAIL  
  ,B.B1_FAX                         AS FAX  
  ,B.B1_FAX_COUNTRY_CODE            AS FAX_COUNTRY_CODE
  ,B.B1_FEDERAL_EMPLOYER_ID_NUM     AS FEIN  
  ,B.B1_FNAME                       AS NAME_FIRST
  ,B.B1_MNAME                       AS NAME_MIDDLE
  ,B.B1_LNAME                       AS NAME_LAST
  ,LTRIM(
    ISNULL(B.B1_FNAME,N'')+N' '+
    (CASE WHEN NULLIF(B.B1_MNAME,N'') IS NOT NULL THEN B.B1_MNAME+N' ' ELSE N'' END)+
    ISNULL(B.B1_LNAME,N'')
  )                                 AS NAME_FML#
  ,B.B1_FULL_NAME                   AS NAME_FULL
  ,B.B1_PHONE1                      AS PHONE1
  ,B.B1_PHONE1_COUNTRY_CODE         AS PHONE1_COUNTRY_CODE
  ,B.B1_PHONE2                      AS PHONE2
  ,B.B1_PHONE2_COUNTRY_CODE         AS PHONE2_COUNTRY_CODE
  ,B.B1_PHONE3                      AS PHONE3
  ,B.B1_PHONE3_COUNTRY_CODE         AS PHONE3_COUNTRY_CODE
  ,(  CASE 
        WHEN B.B1_PREFERRED_CHANNEL=0 OR B.B1_PREFERRED_CHANNEL IS NULL
          THEN N''
        ELSE COALESCE(NULLIF(C1.VALUE_DESC,N''),NULLIF(C2.VALUE_DESC,N''),N'')
      END    
  )                                 AS PREFERRED_CHANNEL
  ,ISNULL(NULLIF(B.B1_FLAG,N''),N'N') AS PRIMARY_
  ,B.B1_RELATION                    AS RELATIONSHIP  
  ,B.B1_SALUTATION                  AS SALUTATION  
  ,B.B1_TITLE                       AS TITLE
  ,B.B1_TRADE_NAME                  AS TRADE_NAME    
  --- column to support build relation with Templates.  
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + B.B1_CONTACT_TYPE + N'/' +  CONVERT(NVARCHAR, B.B1_CONTACT_NBR) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,B.B1_CONTACT_TYPE AS T_ID4
  ,CONVERT(NVARCHAR, B.B1_CONTACT_NBR) AS T_ID5
FROM
  B1PERMIT A 
  JOIN
  B3CONTACT B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  RBIZDOMAIN_VALUE C1
    ON  B.SERV_PROV_CODE = C1.SERV_PROV_CODE
    AND C1.BIZDOMAIN = N'CONTACT_PREFERRED_CHANNEL'
    AND B.B1_PREFERRED_CHANNEL = C1.BIZDOMAIN_VALUE
    AND C1.REC_STATUS = N'A'
  LEFT JOIN
  RBIZDOMAIN_VALUE C2
    ON  C2.SERV_PROV_CODE = N'STANDARDDATA'
    AND C2.BIZDOMAIN = N'CONTACT_PREFERRED_CHANNEL'
    AND B.B1_PREFERRED_CHANNEL = C2.BIZDOMAIN_VALUE
    AND C2.REC_STATUS = N'A'
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_CONTACT_ADDRESS] 
AS
SELECT 
--=== Row Update Info
       A.REC_DATE AS UPDATED_DATE,
       A.REC_FUL_NAM AS UPDATED_BY,
       --=== Address Concatenated
        --ADDR_FULL_BLOCK - full address, block format
               (
            CAST(A.G7_HSE_NBR_START AS CHAR)
            +
            --(CASE WHEN A.G7_HSE_FRAC_NBR_START IS NOT NULL THEN ' '||A.G7_HSE_FRAC_NBR_START ELSE '' END)
            (CASE WHEN A.G7_STR_DIR IS NOT NULL THEN N' '+A.G7_STR_DIR ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_NAME IS NOT NULL THEN N' '+A.G7_STR_NAME ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_SUFFIX IS NOT NULL THEN N' '+A.G7_STR_SUFFIX ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_SUFFIX_DIR IS NOT NULL THEN N' '+A.G7_STR_SUFFIX_DIR ELSE N'' END)
            --If only Unit #, show at end of 1st line
            +
            ( CASE WHEN A.G7_UNIT_TYPE IS NULL AND A.G7_UNIT_START IS NOT NULL
                THEN N' #'+A.G7_UNIT_START ELSE N''
              END
            )
            --If Unit Type available, show on 2nd line
            +
            (CASE WHEN A.G7_UNIT_TYPE IS NOT NULL THEN CHAR(10)+A.G7_UNIT_TYPE+N' '+A.G7_UNIT_START ELSE N'' END)
            --City, State ZIP on 3rd line
            +
            (  CASE WHEN A.G7_CITY IS NULL AND A.G7_STATE IS NULL AND A.G7_CITY IS NULL
                THEN N''
                ELSE CHAR(10)
                     +
                     A.G7_CITY + CASE WHEN A.G7_CITY IS NOT NULL THEN N', ' ELSE N'' END
                     +
                     A.G7_STATE + CASE WHEN A.G7_STATE IS NOT NULL THEN N' ' ELSE N'' END
                     +
                     A.G7_ZIP
               END
            )
      )                       AS ADDR_FULL_BLOCK#,
         --ADDR_FULL_LINE - full address, line format
          (
            CAST(A.G7_HSE_NBR_START AS CHAR)
            +
            --(CASE WHEN A.G7_HSE_FRAC_NBR_START IS NOT NULL THEN ' '||A.B1_HSE_FRAC_NBR_START ELSE '' END)
            (CASE WHEN A.G7_STR_DIR IS NOT NULL THEN N' '+A.G7_STR_DIR ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_NAME IS NOT NULL THEN N' '+A.G7_STR_NAME ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_SUFFIX IS NOT NULL THEN N' '+A.G7_STR_SUFFIX ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_SUFFIX_DIR IS NOT NULL THEN N' '+A.G7_STR_SUFFIX_DIR ELSE N'' END)
            --If Unit Number only
            +
            ( CASE WHEN A.G7_UNIT_TYPE IS NULL AND A.G7_UNIT_START IS NOT NULL
                THEN N', #'+A.G7_UNIT_START ELSE N''
              END
            )
            --If Unit Type available
            +
            (CASE WHEN A.G7_UNIT_TYPE IS NOT NULL THEN N', '+A.G7_UNIT_TYPE+N' '+A.G7_UNIT_START ELSE N'' END)
            --City, State ZIP
            +
            (case when A.G7_CITY is null then N'' else N', '+A.G7_CITY end)
            +
            (case when A.G7_STATE is null then N'' else N', ' +A.G7_STATE end)
            +
            N' '+A.G7_ZIP
      )                       AS ADDR_FULL_LINE#,
          --ADDR_PARTIAL - Partial address, line format
        (
            CAST(A.G7_HSE_NBR_START AS CHAR)
            +
            --(CASE WHEN B.B1_HSE_FRAC_NBR_START IS NOT NULL THEN ' '||B.B1_HSE_FRAC_NBR_START ELSE '' END)
            (CASE WHEN A.G7_STR_DIR IS NOT NULL THEN N' '+A.G7_STR_DIR ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_NAME IS NOT NULL THEN N' '+A.G7_STR_NAME ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_SUFFIX IS NOT NULL THEN N' '+A.G7_STR_SUFFIX ELSE N'' END)
            +
            (CASE WHEN A.G7_STR_SUFFIX_DIR IS NOT NULL THEN N' '+A.G7_STR_SUFFIX_DIR ELSE N'' END)
            --If Unit Number only
            +
            ( CASE WHEN A.G7_UNIT_TYPE IS NULL AND A.G7_UNIT_START IS NOT NULL
                THEN N', #'+A.G7_UNIT_START ELSE N''
              END
            )
            --If Unit Type available
            +
            (CASE WHEN A.G7_UNIT_TYPE IS NOT NULL THEN N', '+A.G7_UNIT_TYPE+N' '+A.G7_UNIT_START ELSE N'' END)
     )                         AS ADDR_PARTIAL#,
       --=== Address Parts
       A.SERV_PROV_CODE   AS AGENCY_ID,
       A.RES_ID AS CONTACT_ADDRESS_ID,
       A.G7_ENTITY_TYPE       AS ENTITY_TYPE,
       A.G7_ENTITY_ID AS ENTITY_ID,
       A.G7_ADDRESS_TYPE AS ADDRESS_TYPE,
       A.G7_EFF_DATE AS EFFECTIVE_DATE,
       A.G7_EXPR_DATE AS EXPIRATION_DATE,
       A.G7_RECIPIENT AS RECIPIENT,
       A.G7_FULL_ADDRESS AS FULL_ADDRESS,
       A.G7_ADDRESS1 AS ADDRESS_LINE1,
       A.G7_ADDRESS2 AS ADDRESS_LINE2,
       A.G7_ADDRESS3 AS ADDRESS_LINE3,
       A.G7_HSE_NBR_START AS STREET#_START,
       A.G7_HSE_NBR_END AS STREET#_END,
       A.G7_STR_DIR AS STREET_DIRECTION,
       A.G7_STR_PREFIX AS STREET_PREFIX,
       A.G7_STR_NAME AS STREET_NAME,
       A.G7_STR_SUFFIX AS STREET_TYPE,
       A.G7_UNIT_TYPE AS UNIT_TYPE,
       A.G7_UNIT_START AS UNIT#_START,
       A.G7_UNIT_END AS UNIT#_END,
       A.G7_STR_SUFFIX_DIR AS QUADRANT,
       A.G7_COUNTRY_CODE AS COUNTRY_CODE,
       A.G7_CITY AS CITY,
       A.G7_STATE AS STATE_,
       A.G7_ZIP AS ZIP,
       A.G7_PHONE AS PHONE,
       A.G7_PHONE_COUNTRY_CODE AS PHONE_COUNTRY_CODE,
       A.G7_FAX AS FAX,
       A.G7_FAX_COUNTRY_CODE AS FAX_COUNTRY_CODE,
       A.REC_STATUS AS STATUS,      
       A.G7_HSE_NBR_ALPHA_START AS STREET#_START_ALPHA,
       A.G7_HSE_NBR_ALPHA_END AS STREET#_END_ALPHA,
       A.G7_LEVEL_PREFIX AS LEVEL_PREFIX,
       A.G7_LEVEL_NBR_START AS LEVEL#__START,
       A.G7_LEVEL_NBR_END AS LEVEL#__END,
       COALESCE(A.G7_VALIDATE_ADDR_FLAG,N'N')          AS VALIDATION_FLAG,
    ----  Related Record Information
      B.B1_CONTACT_NBR AS CONTACT_NBR,
       (SELECT C.B1_ALT_ID
          FROM dbo.B1PERMIT C
         WHERE C.SERV_PROV_CODE = B.SERV_PROV_CODE
           AND C.B1_PER_ID1 = B.B1_PER_ID1
           AND C.B1_PER_ID2 = B.B1_PER_ID2
           AND C.B1_PER_ID3 = B.B1_PER_ID3) AS RECORD_ID,
       CASE
         WHEN A.G7_ENTITY_TYPE = N'CONTACT' THEN
          A.G7_ENTITY_ID
       END AS CONTACT_REF_ID,
       B.PRIMARY_FLAG
	   ,B.B1_PER_ID1 AS T_ID1
	   ,B.B1_PER_ID2 AS T_ID2
	   ,B.B1_PER_ID3 AS T_ID3
       FROM  dbo.G7CONTACT_ADDRESS A
       LEFT JOIN dbo.XRECORD_CONTACT_ENTITY B
       ON A.G7_ENTITY_TYPE = B.ENT_TYPE
       AND A.RES_ID = B.ENT_ID1
       AND A.SERV_PROV_CODE = B.SERV_PROV_CODE
       AND B.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_FEE] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                        AS AGENCY_ID
  ,A.B1_ALT_ID                            AS RECORD_ID
  ,A.B1_PER_GROUP                         AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                      AS RECORD_NAME  
  ,A.B1_FILE_DD                           AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                       AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE                  AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                      AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                          AS UPDATED_BY
  ,B.REC_DATE                             AS UPDATED_DATE
--=== Fee Info    
  ,B.GF_L1                                AS ACCT_CODE_1
  ,B.GF_L2                                AS ACCT_CODE_2
  ,B.GF_L3                                AS ACCT_CODE_3
  ,B.GF_FEE                               AS AMOUNT
  --AMOUNT_CREDITED
  ,(  CASE WHEN B.GF_ITEM_STATUS_FLAG<>N'CREDITED'
        THEN 0
        ELSE B.GF_FEE*(-1)
      END
  )                                       AS AMOUNT_CREDITED
  --AMOUNT_DUE#
  ,(  CASE WHEN B.GF_ITEM_STATUS_FLAG = N'INVOICED'
        THEN B.GF_FEE - COALESCE(
           (  select  sum(p.FEE_ALLOCATION) 
              from    x4payment_feeitem p
              where   p.serv_prov_code=B.SERV_PROV_CODE
                      and p.b1_per_id1=B.B1_PER_ID1
                      and p.b1_per_id2=B.B1_PER_ID2
                      and p.b1_per_id3=B.B1_PER_ID3
                      and p.feeitem_seq_nbr=B.feeitem_seq_nbr 
                      and nullif(p.payment_feeitem_status,N'') is null
            ),0)
        ELSE 0
      END
  )                                       AS AMOUNT_DUE#    
  --AMOUNT_PAID#
  ,COALESCE(
   (  select  sum(p.FEE_ALLOCATION) 
      from    x4payment_feeitem p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.b1_per_id1=B.B1_PER_ID1
              and p.b1_per_id2=B.B1_PER_ID2
              and p.b1_per_id3=B.B1_PER_ID3
              and p.feeitem_seq_nbr=B.feeitem_seq_nbr 
              and nullif(p.payment_feeitem_status,N'') is null
  ),0)                                    AS AMOUNT_PAID#
  ,B.GF_FEE_APPLY_DATE                    AS DATE_ASSESSED
  ,B.GF_FEE_EFFECT_DATE                   AS DATE_EFFECTIVE
  ,B.GF_FEE_EXPIRE_DATE                   AS DATE_EXPIRES
  ,I.INVOICE_DATE                         AS DATE_INVOICED   
  ,B.GF_DES                               AS DESCRIPTION
  ,B.GF_DISPLAY                           AS DISPLAY_ORDER  
  ,B.GF_COD                               AS FEE_CODE  
  ,B.FEEITEM_SEQ_NBR                      AS FEE_ID
  ,(  DATEDIFF(d
        ,CONVERT(DATE,I.INVOICE_DATE) 
        ,CONVERT(DATE,GETDATE()) 
      )
  )                                       AS INVOICE_AGE  
  ,I.BALANCE_DUE                          AS INVOICE_BAL_DUE  
  ,I.INVOICE_DATE                         AS INVOICE_DATE  
  --INVOICE_FULLY_PAID#    
  ,( CASE 
      WHEN I.BALANCE_DUE=0 AND I.INVOICE_AMOUNT >= 0 THEN N'Y' 
      WHEN I.BALANCE_DUE>0 THEN N'N'
      ELSE NULL 
     END 
  )                                       AS INVOICE_FULLY_PAID#   
  ,I.INVOICE_NBR                          AS INVOICE_ID  
  ,I.INVOICE_LEVEL                        AS INVOICE_LEVEL
  ,I.INVOICE_CUSTOMIZED_NBR               AS INVOICE_NUMBER
  ,I.INVOICE_AMOUNT                       AS INVOICE_TOTAL 
  ,B.FEE_NOTES                            AS NOTES                                        
  ,B.POS_TRANS_SEQ                        AS POS_ID     
  ,P.MODULE_NAME                          AS POS_MODULE
  ,B.GF_UNIT                              AS QUANTITY  
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_ALT_ID ELSE NULL END)
                                          AS RECORD_ID#
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_PER_GROUP ELSE NULL END)                                  
                                          AS RECORD_MODULE#
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_FILE_DD ELSE NULL END)                                  
                                          AS RECORD_OPEN_DATE#
  ,(  CASE WHEN B.POS_TRANS_SEQ IS NULL
        THEN A.B1_ALT_ID
        ELSE N'POS ' + RTRIM(CAST(B.POS_TRANS_SEQ AS CHAR))
      END
  )                                       AS RECORD_OR_POS_ID#
  ,(  CASE WHEN B.POS_TRANS_SEQ IS NULL
        THEN A.B1_PER_GROUP
        ELSE P.MODULE_NAME
      END
  )                                       AS RECORD_OR_POS_MODU#  
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_APPL_STATUS ELSE NULL END)                                
                                          AS RECORD_STATUS#
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN B1_APPL_STATUS_DATE ELSE NULL END)
                                          AS RECORD_STATUS_DATE#  
  ,B.GF_FEE_SCHEDULE                      AS SCHEDULE
  ,B.GF_ITEM_STATUS_FLAG                  AS STATUS
  ,B.GF_UDES                              AS UNIT
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  F4FEEITEM B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  X4FEEITEM_INVOICE X
    ON  B.SERV_PROV_CODE = X.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = X.B1_PER_ID1 
    AND B.B1_PER_ID2 = X.B1_PER_ID2 
    AND B.B1_PER_ID3 = X.B1_PER_ID3
    AND B.FEEITEM_SEQ_NBR = X.FEEITEM_SEQ_NBR
  LEFT JOIN
  F4INVOICE I
    ON  X.SERV_PROV_CODE = I.SERV_PROV_CODE
    AND X.INVOICE_NBR = I.INVOICE_NBR
  LEFT JOIN
  F4POS_TRANSACTION P
    ON  B.SERV_PROV_CODE = P.SERV_PROV_CODE
    AND B.POS_TRANS_SEQ = P.POS_TRANS_SEQ    
WHERE
  ( A.B1_APPL_STATUS NOT IN (N'VOID',N'VOIDED')
    OR 
    A.B1_APPL_STATUS IS NULL 
  )
  AND A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_HEARING] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE              AS AGENCY_ID
  ,A.B1_ALT_ID                  AS RECORD_ID
  ,A.B1_PER_GROUP               AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT            AS RECORD_NAME  
  ,A.B1_FILE_DD                 AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS             AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE        AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)            AS RECORD_TYPE
--=== Row Update Info
  ,X.REC_FUL_NAM                AS UPDATED_BY
  ,X.REC_DATE                   AS UPDATED_DATE
--=== Calendar/Hearing Info  
  ,N'Scheduled'                  AS ASSIGN_STATUS
  ,B.CALENDAR_ID                AS CALENDAR_ID
  ,B.EVENT_NAME                 AS CALENDAR_ITEM
  ,C.CALENDAR_NAME              AS CALENDAR_NAME
  ,C.CALENDAR_TYPE              AS CALENDAR_TYPE
  ,X.EVENT_COMMENT              AS COMMENTS
  ,B.EVENT_NOTICE_DATE          AS DATE_NOTICE
  ,B.END_DATE                   AS DATETIME_END
  ,B.START_DATE                 AS DATETIME_START
  ,(  CASE B.DAY_OF_WEEK
        WHEN 1 THEN N'Monday'
        WHEN 2 THEN N'Tuesday'
        WHEN 3 THEN N'Wednesday'
        WHEN 4 THEN N'Thursday'
        WHEN 5 THEN N'Friday'
        WHEN 6 THEN N'Saturday'
        WHEN 7 THEN N'Sunday'
        ELSE NULL
      END
  )                             AS DAY_OF_WEEK
  ,X.APP_DURATION               AS DURATION_APP_MINS
  ,B.EVENT_DURATION             AS DURATION_HEAR_MINS
  ,B.HEARING_BODY               AS HEARING_BODY
  ,B.EVENT_TYPE                 AS HEARING_TYPE
  ,B.EVENT_LOCATION             AS LOCATION
  ,B.MAX_UNITS                  AS MAXIMUM_ITEMS
  ,X.EVENT_REASON               AS REASON
  ,LTRIM(RIGHT(CONVERT(CHAR(19),B.END_DATE,100),7))   
                                AS TIME_END
  ,LTRIM(RIGHT(CONVERT(CHAR(19),B.START_DATE,100),7)) 
                                AS TIME_START
  ,B.IS_VOTE                    AS VOTE_BY_MEMBERS
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
    B1PERMIT A    
    INNER JOIN
    XAPP_EVENT X ON
        A.SERV_PROV_CODE = X.SERV_PROV_CODE AND
        A.B1_PER_ID1 = X.B1_PER_ID1 AND
        A.B1_PER_ID2 = X.B1_PER_ID2 AND
        A.B1_PER_ID3 = X.B1_PER_ID3 AND
        A.REC_STATUS = X.REC_STATUS
    INNER JOIN
    CALENDAR_EVENT B ON  
        X.SERV_PROV_CODE = B.SERV_PROV_CODE AND
        X.EVENT_ID = B.EVENT_ID AND
        X.CALENDAR_ID = B.CALENDAR_ID AND
        X.REC_STATUS = B.REC_STATUS
    INNER JOIN
    CALENDAR C ON
        B.SERV_PROV_CODE = C.SERV_PROV_CODE
        AND B.CALENDAR_ID = C.CALENDAR_ID
        AND B.REC_STATUS = C.REC_STATUS       
WHERE
  ( A.B1_APPL_STATUS NOT IN (N'VOID',N'VOIDED')
    OR 
    A.B1_APPL_STATUS IS NULL 
  ) 
  AND A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_INSPECTION] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Inspection Info  
  ,B.INSP_BILLABLE                  AS BILLABLE
  ,E.TEXT                           AS COMMENTS_RESULT
  ,C.TEXT                           AS COMMENTS_SCHEDULE
  ,COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)
                                    AS DATE_INSP_OR_SCHE#
  ,B.G6_COMPL_DD                    AS DATE_INSPECTION
  ,B.G6_REC_DD                      AS DATE_REQUEST
  ,B.G6_ACT_DD                      AS DATE_SCHEDULED
  ,B.G6_DOC_DES                     AS DISPOSITION_STATUS
  ,B.G6_ACT_NUM                     AS INSPECTION_ID
  ,B.G6_ACT_TYP                     AS INSPECTION_TYPE
  ,D1.R3_DEPTNAME                   AS INSPECTOR_DEPT
  ,COALESCE(NULLIF(B.GA_FNAME,N''),U.FNAME)   
                                    AS INSPECTOR_NAME_F
  ,(  CASE WHEN NULLIF(B.GA_FNAME,N'') is not null AND NULLIF(B.GA_LNAME,N'') is not null 
        THEN
          (CASE WHEN NULLIF(B.GA_MNAME,N'') IS NULL THEN ISNULL(B.GA_FNAME,N'')+N' '+ISNULL(B.GA_LNAME,N'') ELSE ISNULL(B.GA_FNAME,N'')+N' '+B.GA_MNAME+N' '+ISNULL(B.GA_LNAME,N'') END)
        ELSE
          (CASE WHEN NULLIF(U.MNAME,N'') IS NULL THEN ISNULL(U.FNAME,N'')+N' '+ISNULL(U.LNAME,N'') ELSE ISNULL(U.FNAME,N'')+N' '+U.MNAME+N' '+ISNULL(U.LNAME,N'') END)
      END
  )                                 AS INSPECTOR_NAME_FML#
  ,COALESCE(NULLIF(B.GA_LNAME,N''),U.LNAME)    
                                    AS INSPECTOR_NAME_L
  ,COALESCE(NULLIF(B.GA_MNAME,N''),U.MNAME)    
                                    AS INSPECTOR_NAME_M
  ,B.GA_USERID                      AS INSPECTOR_USERID
  ,B.LATITUDE_COORDINATE            AS LATITUDE
  ,B.LONGITUDE_COORDINATE           AS LONGITUDE
  ,B.G6_MILE_T2                     AS MILEAGE_END
  ,B.G6_MILE_T1                     AS MILEAGE_START
  ,B.G6_MILE_TT                     AS MILEAGE_TOTAL
  --NEXT_INSP_DATE#
  ,(  select  TOP 1 (coalesce(i.g6_compl_dd,i.g6_act_dd))
      from    g6action i 
                 --inspections whose date is after current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) > CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd), coalesce(i.g6_compl_t1,i.g6_act_t1)
  )                                 AS NEXT_INSP_DATE#
  --NEXT_INSP_STATUS#
  ,(  select  TOP 1 (i.g6_status)
      from    g6action i
                --inspections whose date is after current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) > CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd), coalesce(i.g6_compl_t1,i.g6_act_t1)
  )                                 AS NEXT_INSP_STATUS#
  --NEXT_INSP_TYPE#
  ,(  select  TOP 1 (i.g6_act_typ)
      from    g6action i
               --inspections whose date is after current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) > CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd), coalesce(i.g6_compl_t1,i.g6_act_t1)
  )                                 AS NEXT_INSP_TYPE#
  --NEXT_INSP_USERID#
  ,(  select  TOP 1 (i.ga_userid)
      from    g6action i
                --inspections whose date is after current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) > CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd), coalesce(i.g6_compl_t1,i.g6_act_t1)
  )                                 AS NEXT_INSP_USERID#
  --PRIOR_INSP_DATE#
  ,(  select  TOP 1 (coalesce(i.g6_compl_dd,i.g6_act_dd))
      from    g6action i
               --inspections whose date is before current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) < CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, coalesce(i.g6_compl_t1,i.g6_act_t1) DESC
  )                                 AS PRIOR_INSP_DATE#
  --PRIOR_INSP_STATUS#
  ,(  select  TOP 1 (i.g6_status)
      from    g6action i
                --inspections whose date is before current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) < CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, coalesce(i.g6_compl_t1,i.g6_act_t1) DESC
  )                                 AS PRIOR_INSP_STATUS#
  --PRIOR_INSP_TYPE#
  ,(  select  TOP 1 (i.g6_act_typ)
      from    g6action i
         --inspections whose date is before current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) < CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, coalesce(i.g6_compl_t1,i.g6_act_t1) DESC
  )                                 AS PRIOR_INSP_TYPE#
  --PRIOR_INSP_USERID#
  ,(  select  TOP 1 (i.ga_userid)
      from    g6action i
          --inspections whose date is before current insp date
      where   B.SERV_PROV_CODE = i.serv_prov_code
                  AND B.B1_PER_ID1 = i.b1_per_id1 
              AND B.B1_PER_ID2 = i.b1_per_id2 
              AND B.B1_PER_ID3 = i.b1_per_id3
              AND i.G6_STATUS<>N'Rescheduled' 
              AND i.rec_status=N'A'
              AND CONVERT(DATE,(COALESCE(i.G6_COMPL_DD,i.G6_ACT_DD))) < CONVERT(DATE,(COALESCE(B.G6_COMPL_DD,B.G6_ACT_DD)))
      order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, coalesce(i.g6_compl_t1,i.g6_act_t1) DESC
  )                                 AS PRIOR_INSP_USERID#
  ,B.SD_OVERTIME                    AS OVERTIME  
  ,B.REQUESTOR_FNAME                AS REQUESTOR_NAME_F
  ,(  ISNULL(B.REQUESTOR_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(B.REQUESTOR_MNAME,N'') IS NOT NULL THEN B.REQUESTOR_MNAME+N' ' ELSE N'' END)+
      ISNULL(B.REQUESTOR_LNAME,N'')
  )                                 AS REQUESTOR_NAME_FML
  ,B.REQUESTOR_LNAME                AS REQUESTOR_NAME_L
  ,B.REQUESTOR_MNAME                AS REQUESTOR_NAME_M
  ,B.G6_REQ_PHONE_NUM               AS REQUESTOR_PHONE
  ,B.REQUESTOR_USERID               AS REQUESTOR_USERID
  --RESULT_: Only show if not Scheduled or not (Unscheduled) Pending
  ,(  CASE WHEN B.G6_STATUS = N'Scheduled' OR ( B.G6_ACT_DD IS NULL AND B.G6_COMPL_DD IS NULL )
        THEN NULL
        ELSE B.G6_STATUS     
      END
  )                                 AS RESULT_
  --RESULT_TYPE: only show if insp was resulted
  ,(  CASE WHEN B.G6_STATUS = N'Scheduled' OR ( B.G6_ACT_DD IS NULL AND B.G6_COMPL_DD IS NULL )
        THEN NULL
        ELSE B.INSP_RESULT_TYPE
      END
  )                                 AS RESULT_TYPE
  ,B.G6_REC_TYP                     AS ROUTE_ORDER
  ,B.TOTAL_SCORE                    AS SCORE
  ,B.G6_STATUS                      AS STATUS
  ,ltrim(RIGHT(convert(CHAR(19),B.G6_END_TIME,100),7))
                                    AS TIME_INSP_END
  ,ltrim(RIGHT(convert(CHAR(19),B.G6_START_TIME,100),7))
                                    AS TIME_INSP_START  
  ,( CASE WHEN NULLIF(B.G6_COMPL_T2,N'') IS NULL THEN B.G6_COMPL_T1 ELSE B.G6_COMPL_T2+ISNULL(B.G6_COMPL_T1,N'') END )                                AS TIME_INSPECTION
  ,( CASE WHEN NULLIF(B.G6_ACT_T2,N'') IS NULL THEN B.G6_ACT_T1 ELSE B.G6_ACT_T2+ISNULL(B.G6_ACT_T1,N'') END )
                                    AS TIME_SCHEDULED
  ,B.G6_ACT_TT                      AS TIME_SPENT_HOURS
  ,B.UNIT_NBR                       AS UNIT_NBR
  ,B.G6_VEHICLE_NUM                 AS VEHICLE_NUMBER
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  G6ACTION B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  BACTIVITY_COMMENT C
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = C.B1_PER_ID1 
    AND B.B1_PER_ID2 = C.B1_PER_ID2 
    AND B.B1_PER_ID3 = C.B1_PER_ID3 
    AND B.G6_ACT_NUM = C.G6_ACT_NUM
    AND C.COMMENT_TYPE = N'Inspection Request Comment'
  LEFT JOIN
  BACTIVITY_COMMENT E
    ON  B.SERV_PROV_CODE = E.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = E.B1_PER_ID1 
    AND B.B1_PER_ID2 = E.B1_PER_ID2 
    AND B.B1_PER_ID3 = E.B1_PER_ID3 
    AND B.G6_ACT_NUM = E.G6_ACT_NUM
    AND E.COMMENT_TYPE = N'Inspection Result Comment'
  LEFT JOIN
  G3DPTTYP D1 
     --Inspector Dept
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE 
    AND B.R3_AGENCY_CODE = D1.R3_AGENCY_CODE 
    AND B.R3_BUREAU_CODE = D1.R3_BUREAU_CODE 
    AND B.R3_DIVISION_CODE =D1.R3_DIVISION_CODE 
    AND B.R3_SECTION_CODE =D1.R3_SECTION_CODE 
    AND B.R3_GROUP_CODE = D1.R3_GROUP_CODE 
    AND B.R3_OFFICE_CODE = D1.R3_OFFICE_CODE
  LEFT JOIN
  PUSER U
    ON  B.SERV_PROV_CODE = U.SERV_PROV_CODE
    AND B.GA_USERID = U.GA_USER_ID
WHERE
  A.REC_STATUS = N'A'
--**** Exclude canceled inspections
  AND B.REC_STATUS = N'A' 
--**** Exclude rescheduled inspections (original row)
  AND B.G6_STATUS<>N'Rescheduled'
GO

ALTER VIEW [dbo].[V_INSPECTION_1ST_LAST] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== COMPLETED FIRST =======================
  --COMPL_1ST_DATE#
  ,(
     select min(i.g6_compl_dd) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.G6_DOC_DES in (N'Insp Completed', N'Insp Compeleted')
  )                                 AS COMPL_1ST_DATE#
  --COMPL_1ST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted')
     order by i.g6_compl_dd, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'ZZ' else i.g6_compl_t1 end)
  )                                 AS COMPL_1ST_INSP#
  --COMPL_1ST_RESULT#
  ,(
     select TOP 1 (i.g6_status) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted')
     order by i.g6_compl_dd, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'ZZ' else i.g6_compl_t1 end)
  )                                 AS COMPL_1ST_RESULT#
  --COMPL_1ST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted')
     order by i.g6_compl_dd, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'ZZ' else i.g6_compl_t1 end)            
  )                                 AS COMPL_1ST_STAFF#
--==== COMPLETED LAST =====================
  --COMPL_LAST_DATE#
  ,(
     select max(i.g6_compl_dd) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.G6_DOC_DES in (N'Insp Completed', N'Insp Compeleted')
  )                                 AS COMPL_LAST_DATE#
  --COMPL_LAST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted')
     order by i.g6_compl_dd DESC, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'AA' else i.g6_compl_t1 end) DESC
  )                                 AS COMPL_LAST_INSP#
  --COMPL_LAST_RESULT#
  ,(
     select TOP 1 (i.g6_status) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted')
     order by i.g6_compl_dd DESC, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'AA' else i.g6_compl_t1 end) DESC
  )                                 AS COMPL_LAST_RESULT#
  --COMPL_LAST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted')
     order by i.g6_compl_dd DESC, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'AA' else i.g6_compl_t1 end) DESC            
  )                                 AS COMPL_LAST_STAFF#
--==== PERFORMED FIRST ===========================
  --DONE_1ST_DATE#
  ,(
     select min(i.g6_compl_dd)
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled') 
            and i.g6_status<>N'Scheduled'
  )                                 AS DONE_1ST_DATE#  
  --DONE_1ST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled') 
     order by i.g6_compl_dd, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'ZZ' else i.g6_compl_t1 end)
  )                                 AS DONE_1ST_INSP#
  --DONE_1ST_RESULT#
  ,(
     select TOP 1 (i.g6_status) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled') 
     order by i.g6_compl_dd, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'ZZ' else i.g6_compl_t1 end)
  )                                 AS DONE_1ST_RESULT#
  --DONE_1ST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled') 
     order by i.g6_compl_dd, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'ZZ' else i.g6_compl_t1 end)            
  )                                  AS DONE_1ST_STAFF#
--==== PERFORMED LAST ===========================
  --DONE_LAST_DATE#
  ,(
     select max(i.g6_compl_dd)
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled') 
            and i.g6_status<>N'Scheduled'
  )                                 AS DONE_LAST_DATE#  
  --DONE_LAST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled')
     order by i.g6_compl_dd DESC, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'AA' else i.g6_compl_t1 end) DESC
  )                                 AS DONE_LAST_INSP#
  --DONE_LAST_RESULT#
  ,(
     select TOP 1 (i.g6_status) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled')
     order by i.g6_compl_dd DESC, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'AA' else i.g6_compl_t1 end) DESC
  )                                 AS DONE_LAST_RESULT#
  --DONE_LAST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_compl_dd is not null
            and i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Cancelled',N'Insp Scheduled')
     order by i.g6_compl_dd DESC, (case when nullif(i.g6_compl_t1,N'') is null or i.g6_compl_t1=N'N/A' then N'AA' else i.g6_compl_t1 end) DESC            
  )                                 AS DONE_LAST_STAFF#  
--==== EARLEST INSPECTION, SCHEDULED OR PERFORMED
  --INSP_1ST_DATE#
  ,(
     select min(coalesce(i.g6_compl_dd,i.g6_act_dd))
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A' 
            --AA 7.1+, Canceled inspections have rec_status='I'
  )                                 AS INSP_1ST_DATE#
  --INSP_1ST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
             --AA 7.1+, Canceled inspections have rec_status='I'
    order by coalesce(i.g6_compl_dd,i.g6_act_dd), (case when coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) is null or coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N''))=N'N/A' then N'ZZ' else coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) end)
  )                                 AS INSP_1ST_INSP#
  --INSP_1ST_RESULT#
  ,(
     select TOP 1 (i.g6_status) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
             --AA 7.1+, Canceled inspections have rec_status='I'
    order by coalesce(i.g6_compl_dd,i.g6_act_dd), (case when coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) is null or coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N''))=N'N/A' then N'ZZ' else coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) end)
  )                                 AS INSP_1ST_RESULT#  
  --INSP_1ST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
            --AA 7.1+, Canceled inspections have rec_status='I'
     order by coalesce(i.g6_compl_dd,i.g6_act_dd), (case when coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) is null or coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N''))=N'N/A' then N'ZZ' else coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) end)            
  )                                 AS INSP_1ST_STAFF#  
--==== LATEST INSPECTION, SCHEDULED OR PERFORMED
  --INSP_LAST_DATE#
  ,(
     select max(coalesce(i.g6_compl_dd,i.g6_act_dd))
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
             --AA 7.1+, Canceled inspections have rec_status='I'
  )                                 AS INSP_LAST_DATE#
  --INSP_LAST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
            --AA 7.1+, Canceled inspections have rec_status='I'
    order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, (case when coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) is null or coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N''))=N'N/A' then N'AA' else coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) end) DESC
  )                                 AS INSP_LAST_INSP#
  --INSP_LAST_RESULT#
  ,(
     select TOP 1 (i.g6_status) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
            --AA 7.1+, Canceled inspections have rec_status='I'
    order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, (case when coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) is null or coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N''))=N'N/A' then N'AA' else coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) end) DESC
  )                                 AS INSP_LAST_RESULT#  
  --INSP_LAST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and (
              i.g6_doc_des in (N'Insp Completed', N'Insp Compeleted',N'Insp Scheduled') 
                OR
              --AA 7.0 and below, DENIED type result 
              i.g6_doc_des = N'Insp Cancelled' 
              and i.g6_compl_dd is not null
            )
            and i.g6_act_dd is not null
            and i.rec_status=N'A'
            --AA 7.1+, Canceled inspections have rec_status='I'
     order by coalesce(i.g6_compl_dd,i.g6_act_dd) DESC, (case when coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) is null or coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N''))=N'N/A' then N'AA' else coalesce(nullif(i.g6_compl_t1,N''),nullif(i.g6_act_t1,N'')) end) DESC           
  )                                 AS INSP_LAST_STAFF#  
--==== SCHEDULED INSPECTION - EARLIEST ===============================  
  --SCHE_1ST_DATE#
  ,(
     select min(i.g6_act_dd)
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_act_dd is not null
            and i.g6_status=N'Scheduled'
  )                                 AS SCHE_1ST_DATE#
  --SCHE_1ST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_act_dd is not null
            and i.g6_status=N'Scheduled'
     order by i.g6_act_dd, (case when nullif(i.g6_act_t1,N'') is null or i.g6_act_t1=N'N/A' then N'ZZ' else i.g6_act_t1 end)
  )                                 AS SCHE_1ST_INSP#
  --SCHE_1ST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_act_dd is not null
            and i.g6_status=N'Scheduled'
     order by i.g6_act_dd, (case when nullif(i.g6_act_t1,N'') is null or i.g6_act_t1=N'N/A' then N'ZZ' else i.g6_act_t1 end)
  )                                 AS SCHE_1ST_STAFF#
  --==== SCHEDULED INSPECTION - LATEST ===============================  
  --SCHE_LAST_DATE#
  ,(
     select max(i.g6_act_dd)
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_act_dd is not null
            and i.g6_status=N'Scheduled'
  )                                 AS SCHE_LAST_DATE#
  --SCHE_LAST_INSP#
  ,(
     select TOP 1 (i.g6_act_typ) 
     from   g6action i 
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_act_dd is not null
            and i.g6_status=N'Scheduled'
     order by i.g6_act_dd DESC, (case when nullif(i.g6_act_t1,N'') is null or i.g6_act_t1=N'N/A' then N'AA' else i.g6_act_t1 end) DESC
  )                                 AS SCHE_LAST_INSP#
  --SCHE_LAST_STAFF#
  ,(
     select TOP 1 ( 
              case when nullif(i.ga_fname,N'') is not null and nullif(i.ga_lname,N'') is not null 
                then
                  (case when nullif(i.ga_mname,N'') is null then isnull(i.ga_fname,N'')+N' '+isnull(i.ga_lname,N'') else isnull(i.ga_fname,N'')+N' '+i.ga_mname+N' '+isnull(i.ga_lname,N'') end)
                else
                  (case when nullif(u.mname,N'') is null then isnull(u.fname,N'')+N' '+isnull(u.lname,N'') else isnull(u.fname,N'')+N' '+u.mname+N' '+isnull(u.lname,N'') end)
              end
            ) 
     from   g6action i 
            left join
            puser u
              on  i.serv_prov_code=u.serv_prov_code
              and i.ga_userid=u.ga_user_id
     where  A.SERV_PROV_CODE = i.serv_prov_code
            AND A.B1_PER_ID1 = i.b1_per_id1 
            AND A.B1_PER_ID2 = i.b1_per_id2 
            AND A.B1_PER_ID3 = i.b1_per_id3
            and i.g6_act_dd is not null
            and i.g6_status=N'Scheduled'
     order by i.g6_act_dd DESC, (case when nullif(i.g6_act_t1,N'') is null or i.g6_act_t1=N'N/A' then N'AA' else i.g6_act_t1 end) DESC
  )                                 AS SCHE_LAST_STAFF#
  ,getdate()                        AS TODAY
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_OWNER] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Owner Info  
  ,B.B1_MAIL_CITY                   AS ADDRESS_CITY
  ,B.B1_MAIL_COUNTRY                AS ADDRESS_COUNTRY
  ,B.B1_MAIL_ADDRESS1               AS ADDRESS_LINE1
  ,B.B1_MAIL_ADDRESS2               AS ADDRESS_LINE2
  ,B.B1_MAIL_ADDRESS3               AS ADDRESS_LINE3
  ,B.B1_MAIL_STATE                  AS ADDRESS_STATE
  ,B.B1_MAIL_ZIP                    AS ADDRESS_ZIP
  ,B.B1_EMAIL                       AS EMAIL
  ,B.B1_FAX                         AS FAX
  ,B.B1_FAX_COUNTRY_CODE            AS FAX_COUNTRY_CODE
  ,B.B1_OWNER_FULL_NAME             AS NAME_FULL
  ,B.L1_OWNER_NBR                   AS OWNER_REF_ID
  ,B.B1_PHONE                       AS PHONE
  ,B.B1_PHONE_COUNTRY_CODE          AS PHONE_COUNTRY_CODE
  ,ISNULL(NULLIF(B.B1_PRIMARY_OWNER,N''),N'N') 
                                    AS PRIMARY_
  ,B.B1_TAX_ID                      AS TAX_IDENTIFICATION
  ,B.B1_OWNER_TITLE                 AS TITLE
   --- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' +  CONVERT(NVARCHAR, B.B1_OWNER_NBR) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,CONVERT(NVARCHAR, B.B1_OWNER_NBR) AS T_ID4
FROM
  B1PERMIT A 
  JOIN
  B3OWNERS B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_PARCEL] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE              AS AGENCY_ID
  ,A.B1_ALT_ID                  AS RECORD_ID
  ,A.B1_PER_GROUP               AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT            AS RECORD_NAME  
  ,A.B1_FILE_DD                 AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS             AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE        AS RECORD_STATUS_DATE
  ,A.B1_APP_TYPE_ALIAS          AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                AS UPDATED_BY
  ,B.REC_DATE                   AS UPDATED_DATE
--=== Parcel Info  
  ,B.B1_PARCEL_NBR              AS APN
  ,B.B1_PARCEL_AREA             AS AREA_PARCEL
  ,B.B1_PLAN_AREA               AS AREA_PLAN
  ,B.B1_BLOCK                   AS BLOCK
  ,B.B1_BOOK                    AS BOOK
  ,B.B1_CENSUS_TRACT            AS CENSUS_TRACT
  ,B.B1_COUNCIL_DISTRICT        AS DISTRICT_COUNCIL
  ,B.B1_INSPECTION_DISTRICT     AS DISTRICT_INSPECTION
  ,B.B1_SUPERVISOR_DISTRICT     AS DISTRICT_SUPERVISOR
  ,B.B1_LEGAL_DESC              AS LEGAL_DESCRIPTION
  ,B.B1_LOT                     AS LOT
  ,B.B1_MAP_NBR                 AS MAP_GRID
  ,B.B1_MAP_REF                 AS MAP_REFERENCE
  ,B.B1_PAGE                    AS PAGE
  ,B.B1_PARCEL                  AS PARCEL
  ,B.B1_PARCEL_NBR              AS PARCEL_NBR
  ,B.L1_PARCEL_NBR              AS PARCEL_REF_ID  
  ,ISNULL(NULLIF(B.B1_PRIMARY_PAR_FLG,N''),N'N')
                                AS PRIMARY_
  ,B.B1_RANGE                   AS RANGE_
  ,B.B1_SECTION                 AS SECTION_
  ,B.B1_SUBDIVISION             AS SUBDIVISION
  ,B.B1_TOWNSHIP                AS TOWNSHIP
  ,B.B1_TRACT                   AS TRACT
  ,B.B1_EXEMPT_VALUE            AS VALUE_EXEMPT
  ,B.B1_IMPROVED_VALUE          AS VALUE_IMPROVED
  ,B.B1_LAND_VALUE              AS VALUE_LAND
  --- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' +  CONVERT(NVARCHAR, B.B1_PARCEL_NBR) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,CONVERT(NVARCHAR, B.B1_PARCEL_NBR) AS T_ID4
FROM
  B1PERMIT A 
  JOIN
  B3PARCEL B
    ON  A.SERV_PROV_CODE=B.SERV_PROV_CODE 
    AND A.B1_PER_ID1=B.B1_PER_ID1 
    AND A.B1_PER_ID2=B.B1_PER_ID2 
    AND A.B1_PER_ID3=B.B1_PER_ID3
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_PAYMENT] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Payment Info    
  ,B.PAYMENT_AMOUNT                 AS AMOUNT
  ,B.AMOUNT_NOTALLOCATED            AS AMOUNT_NOT_APPLIED 
  ,B.BATCH_TRANSACTION_NBR          AS BATCH_TRANSACT_ID
  ,B.BANK_NAME                      AS BANK_NAME  
  ,B.TERMINAL_ID                    AS CASH_DRAWER
  ,B.CASHIER_ID                     AS CASHIER_USERID  
  ,B.CHECK_HOLDER_EMAIL             AS CHECK_HOLDER_EMAIL  
  ,B.CHECK_HOLDER_NAME              AS CHECK_HOLDER_NAME 
  ,B.CHECK_NUMBER                   AS CHECK_NUMBER
  ,B.CHECK_TYPE                     AS CHECK_TYPE  
  ,B.PAYMENT_COMMENT                AS COMMENTS 
  ,B.PAYMENT_DATE                   AS DATE_PAYMENT
  ,B.DRIVER_LICENSE                 AS DRIVER_LICENSE  
  ,B.PAYMENT_METHOD                 AS PAYMENT_METHOD    
  ,B.PAYMENT_SEQ_NBR                AS PAYMENT_ID
  ,B.PAYMENT_REF_NBR                AS PAYMENT_REFERENCE  
  ,B.PAYEE                          AS PAYOR  
  ,B.PHONE_NUMBER                   AS PHONE_NUMBER
  ,B.POS_TRANS_SEQ                  AS POS_ID  
  ,P.MODULE_NAME                    AS POS_MODULE  
  ,B.RECEIPT_NBR                    AS RECEIPT_ID  
  ,R.RECEIPT_CUSTOMIZED_NBR         AS RECEIPT_NUMBER
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_ALT_ID ELSE NULL END)
                                    AS RECORD_ID#
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_PER_GROUP ELSE NULL END)                                  
                                    AS RECORD_MODULE#
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_FILE_DD ELSE NULL END)                                  
                                    AS RECORD_OPEN_DATE#
  ,(  CASE WHEN B.POS_TRANS_SEQ IS NULL
        THEN A.B1_ALT_ID
        ELSE N'POS ' + RTRIM(CAST(B.POS_TRANS_SEQ AS CHAR))
      END
  )                                 AS RECORD_OR_POS_ID#
  ,(  CASE WHEN B.POS_TRANS_SEQ IS NULL
        THEN A.B1_PER_GROUP
        ELSE P.MODULE_NAME
      END
  )                                 AS RECORD_OR_POS_MODU#  
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN A.B1_APPL_STATUS ELSE NULL END)                                
                                    AS RECORD_STATUS#
  ,(CASE WHEN B.POS_TRANS_SEQ IS NULL THEN B1_APPL_STATUS_DATE ELSE NULL END)
                                    AS RECORD_STATUS_DATE#
  ,B.SESSION_NBR                    AS SESSION_ID  
  ,(  CASE WHEN B.PAYMENT_AMOUNT<0 AND UPPER(B.PAYMENT_STATUS)=N'PAID' 
        THEN N'Refund'
        ELSE B.PAYMENT_STATUS
      END
  )                                 AS STATUS   
  ,(  CASE
        WHEN B.PAYMENT_AMOUNT>0 AND COALESCE(NULLIF(B.PAYMENT_METHOD,N''),N'A')<>N'Fund Transfer'
          THEN N'Payment'
        WHEN B.PAYMENT_AMOUNT<0 AND COALESCE(NULLIF(B.PAYMENT_METHOD,N''),N'A')<>N'Fund Transfer'
          THEN N'Refund'
        WHEN B.PAYMENT_AMOUNT>0 AND B.PAYMENT_METHOD=N'Fund Transfer'
          THEN N'Fund Transfer In'
        WHEN B.PAYMENT_AMOUNT<0 AND B.PAYMENT_METHOD=N'Fund Transfer'
          THEN N'Fund Transfer Out'
      END
  )                                 AS TRANSACTION_TYPE
  ,B.ACCT_ID                        AS TRUST_ACCOUNT_ID
  ,B.WORKSTATION_ID                 AS WORKSTATION
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  F4PAYMENT B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  F4RECEIPT R
    ON  B.SERV_PROV_CODE = R.SERV_PROV_CODE
    AND B.RECEIPT_NBR = R.RECEIPT_NBR
  LEFT JOIN
  F4POS_TRANSACTION P
    ON  B.SERV_PROV_CODE = P.SERV_PROV_CODE
    AND B.POS_TRANS_SEQ = P.POS_TRANS_SEQ
WHERE
  A.REC_STATUS = N'A'
GO

ALTER VIEW [dbo].[V_PROFESSIONAL] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS    
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info  
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE  
--=== Professional Info  
  ,B.B1_CITY                        AS ADDRESS_CITY
  ,B.B1_COUNTRY                     AS ADDRESS_COUNTRY
  ,B.B1_ADDRESS1                    AS ADDRESS_LINE1
  ,B.B1_ADDRESS2                    AS ADDRESS_LINE2
  ,B.B1_ADDRESS3                    AS ADDRESS_LINE3
  ,B.B1_POST_OFFICE_BOX             AS ADDRESS_PO_BOX
  ,B.B1_STATE                       AS ADDRESS_STATE
  ,B.B1_ZIP                         AS ADDRESS_ZIP
  ,B.B1_BUS_LIC                     AS BUSINESS_LIC_NBR
  ,B.B1_BUS_NAME                    AS BUSINESS_NAME
  ,B.B1_BUS_NAME2                   AS BUSINESS_NAME2
  ,B.B1_COMMENT                     AS COMMENTS
  ,B.B1_BIRTH_DATE                  AS DATE_BIRTH
  ,B.B1_EMAIL                       AS EMAIL
  ,B.B1_FAX                         AS FAX
  ,B.B1_FAX_COUNTRY_CODE            AS FAX_COUNTRY_CODE
  ,B.B1_FEDERAL_EMPLOYER_ID_NBR     AS FEIN
  ,B.B1_GENDER                      AS GENDER
  ,B.B1_LIC_BOARD                   AS LICENSE_BOARD
  ,B.B1_LICENSE_NBR                 AS LICENSE_NBR
  ,B.LIC_SEQ_NBR                    AS LICENSE_REF_ID  
  ,B.B1_LICENSE_TYPE                AS LICENSE_TYPE
  ,B.B1_CAE_FNAME                   AS NAME_FIRST
  ,B.B1_CAE_LNAME                   AS NAME_LAST
  ,B.B1_CAE_MNAME                   AS NAME_MIDDLE
  ,(  
    ISNULL(B.B1_CAE_FNAME,N'') +
    (CASE WHEN NULLIF(B.B1_CAE_MNAME,N'') IS NULL THEN N'' ELSE N' '+B.B1_CAE_MNAME END) +
    N' '+ISNULL(B.B1_CAE_LNAME,N'')
  )                                 AS NAME_FML#
  ,B.B1_PHONE1                      AS PHONE1
  ,B.B1_PHONE1_COUNTRY_CODE         AS PHONE1_COUNTRY_CODE
  ,B.B1_PHONE2                      AS PHONE2
  ,B.B1_PHONE2_COUNTRY_CODE         AS PHONE2_COUNTRY_CODE
  ,B.PHONE3                         AS PHONE3
  ,B.PHONE3_COUNTRY_CODE            AS PHONE3_COUNTRY_CODE
  ,COALESCE(NULLIF(B.B1_PRINT_FLAG,N''),N'N')  
                                    AS PRIMARY_
  ,B.B1_SALUTATION                  AS SALUTATION
  ,B.B1_SOCIAL_SECURITY_NBR         AS SSN
  ,B.B1_TITLE                       AS TITLE
   ---- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + B.B1_LICENSE_TYPE + N'/' + CONVERT(NVARCHAR, B.B1_LICENSE_NBR) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,B.B1_LICENSE_TYPE AS T_ID4
  ,CONVERT(NVARCHAR, B.B1_LICENSE_NBR) AS T_ID5
FROM
  dbo.B1PERMIT A 
  JOIN
  dbo.B3CONTRA B
    ON  A.SERV_PROV_CODE=B.SERV_PROV_CODE 
    AND A.B1_PER_ID1=B.B1_PER_ID1 
    AND A.B1_PER_ID2=B.B1_PER_ID2 
    AND A.B1_PER_ID3=B.B1_PER_ID3
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_RECORD] 
AS
SELECT
--=== Record Info - Common to Views
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,A.REC_FUL_NAM                    AS UPDATED_BY
--=== Record Info  
  ,A.B1_CREATED_BY_ACA              AS ACA_INITIATED
  --ADDR_FULL_LINE# - full address, line format, priority to primary
  ,(  select TOP 1  
        isnull(rtrim(cast(y.b1_hse_nbr_start as char)),N'')
        +
        (case when isnull(y.b1_hse_frac_nbr_start,N'')<>N'' then N' '+y.b1_hse_frac_nbr_start else N'' end)
        +
        (case when isnull(y.b1_str_dir,N'')<>N'' then N' '+y.b1_str_dir else N'' end)
        +
        (case when isnull(y.b1_str_name,N'')<>N'' then N' '+y.b1_str_name else N'' end)
        +
        (case when isnull(y.b1_str_suffix,N'')<>N'' then N' '+y.b1_str_suffix else N'' end)
        +
        (case when isnull(y.b1_str_suffix_dir,N'')<>N'' then N' '+y.b1_str_suffix_dir else N'' end)
        --if unit number only
        +
        ( case when isnull(y.b1_unit_type,N'')=N'' and isnull(y.b1_unit_start,N'')<>N''
            then N', #'+y.b1_unit_start else N''
          end
        )
        --if unit type available
        +
        (case when isnull(y.b1_unit_type,N'')<>N'' then N', '+y.b1_unit_type+N' '+isnull(y.b1_unit_start,N'') else N'' end)
        --city, state zip
        +
        (case when isnull(y.b1_situs_city,N'')=N'' then N'' else N', '+y.b1_situs_city end)
        +
        (case when isnull(y.b1_situs_state,N'')=N'' then N'' else N', ' +y.b1_situs_state end)
        +
        N' '+isnull(y.b1_situs_zip,N'')
      from
        b3addres y
      where
        A.SERV_PROV_CODE = y.serv_prov_code
        and A.B1_PER_ID1 = y.b1_per_id1
        and A.B1_PER_ID2 = y.b1_per_id2
        and A.B1_PER_ID3 = y.b1_per_id3
      order by isnull(nullif(y.b1_primary_addr_flg,N''),N'N') desc, y.b1_address_nbr
  )                                 AS ADDR_FULL_LINE#
--ADDR_FULL_LINE1# - full address, line format, priority to primary
  ,(  select TOP 1  
        isnull(rtrim(cast(y.b1_hse_nbr_alpha_start as char)),N'')
        +
        (case when isnull(y.b1_hse_frac_nbr_start,N'')<>N'' then N' '+y.b1_hse_frac_nbr_start else N'' end)
        +
        (case when isnull(y.b1_str_dir,N'')<>N'' then N' '+y.b1_str_dir else N'' end)
        +
        (case when isnull(y.b1_str_name,N'')<>N'' then N' '+y.b1_str_name else N'' end)
        +
        (case when isnull(y.b1_str_suffix,N'')<>N'' then N' '+y.b1_str_suffix else N'' end)
        +
        (case when isnull(y.b1_str_suffix_dir,N'')<>N'' then N' '+y.b1_str_suffix_dir else N'' end)
        --if unit number only
        +
        ( case when isnull(y.b1_unit_type,N'')=N'' and isnull(y.b1_unit_start,N'')<>N''
            then N', #'+y.b1_unit_start else N''
          end
        )
        --if unit type available
        +
        (case when isnull(y.b1_unit_type,N'')<>N'' then N', '+y.b1_unit_type+N' '+isnull(y.b1_unit_start,N'') else N'' end)
        --city, state zip
        +
        (case when isnull(y.b1_situs_city,N'')=N'' then N'' else N', '+y.b1_situs_city end)
        +
        (case when isnull(y.b1_situs_state,N'')=N'' then N'' else N', ' +y.b1_situs_state end)
        +
        N' '+isnull(y.b1_situs_zip,N'')
      from
        b3addres y
      where
        A.SERV_PROV_CODE = y.serv_prov_code
        and A.B1_PER_ID1 = y.b1_per_id1
        and A.B1_PER_ID2 = y.b1_per_id2
        and A.B1_PER_ID3 = y.b1_per_id3
      order by isnull(nullif(y.b1_primary_addr_flg,N''),N'N') desc, y.b1_address_nbr
  )                                 AS ADDR_FULL_LINE1#
  ,D.B1_ASGN_STAFF                  AS ASSIGNED_USERID
  ,D.BALANCE                        AS BALANCE_DUE
  ,D.BUILDING_COUNT                 AS BUILDING_COUNT
  ,D.B1_CLOSEDBY                    AS CLOSED_USERID
  ,D.B1_COMPLETE_BY                 AS COMPLETED_USERID
  ,D.CONST_TYPE_CODE                AS CONST_TYPE_CODE
  ,D.B1_ASGN_DATE                   AS DATE_ASSIGNED
  ,D.B1_CLOSED_DATE                 AS DATE_CLOSED
  ,D.B1_COMPLETE_DATE               AS DATE_COMPLETED
  ,A.B1_FILE_DD                     AS DATE_OPENED
  ,A.REC_DATE                       AS DATE_OPENED_ORIGINAL
  ,A.B1_APPL_STATUS_DATE            AS DATE_STATUS
  ,D.B1_TRACK_START_DATE            AS DATE_TRACK_START
  ,B.B1_WORK_DESC                   AS DESCRIPTION
  ,D.HOUSE_COUNT                    AS HOUSING_UNITS
  ,D.B1_IN_POSSESSION_TIME          AS IN_POSSESSION_HRS
  ,D.C6_INSPECTOR_NAME              AS INSPECTOR_USERID
  --JOB_VALUE
  ,(  CASE COALESCE(NULLIF(C.G3_FEE_FACTOR_FLG,N''),N'CONT')
        WHEN N'CONT' THEN C.G3_VALUE_TTL
        ELSE C.G3_CALC_VALUE
      END
  )                                 AS JOB_VALUE
  ,C.G3_CALC_VALUE                  AS JOB_VALUE_CALCULATED
  ,C.G3_VALUE_TTL                   AS JOB_VALUE_CONTRACTOR
  ,D.C6_ENFORCE_OFFICER_NAME        AS OFFICER_USERID
  ,D.B1_CREATED_BY                  AS OPENED_USERID
  ,(  select TOP 1
          j.b1_alt_id  
      from 
          xapp2ref x inner join  
          b1permit j on
              x.serv_prov_code = j.serv_prov_code and
              x.b1_master_id1 = j.b1_per_id1 and
              x.b1_master_id2 = j.b1_per_id2 and
              x.b1_master_id3 = j.b1_per_id3
      where 
          x.serv_prov_code = A.SERV_PROV_CODE AND 
          x.b1_per_id1 = A.B1_PER_ID1 AND
          x.b1_per_id2 = A.B1_PER_ID2 AND
          x.b1_per_id3 = A.B1_PER_ID3 AND
          x.rec_status = N'A' and 
          j.rec_status = N'A' and
          (j.b1_appl_status<>N'void' or j.b1_appl_status is null) 
  )                                 AS PARENT_RECORD_ID#
  ,D.PERCENT_COMPLETE               AS PERCENT_COMPLETE
  ,D.B1_PRIORITY                    AS PRIORITY
  ,D.PUBLIC_OWNED                   AS PUBLIC_OWNED
  ,DATEDIFF(
    d
    ,CONVERT(DATETIME,A.B1_FILE_DD)
    ,CONVERT(DATETIME,GETDATE())
  )                                 AS RECORD_AGE
  ,D.B1_OVERALL_APPLICATION_TIME    AS RECORD_OPEN_HRS
  ,A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY 
                                    AS RECORD_TYPE_4LEVEL#
  ,A.B1_PER_CATEGORY                AS RECORD_TYPE_CATEGORY
  ,A.B1_PER_GROUP                   AS RECORD_TYPE_GROUP
  ,A.B1_PER_SUB_TYPE                AS RECORD_TYPE_SUBTYPE
  ,A.B1_PER_TYPE                    AS RECORD_TYPE_TYPE
  ,D.B1_REPORTED_CHANNEL            AS REPORTED_CHANNEL
  ,D.B1_SHORT_NOTES                 AS SHORT_NOTES
  ,A.B1_APPL_STATUS                 AS STATUS
  ,D.TOTAL_FEE                      AS TOTAL_INVOICED
  ,D.TOTAL_PAY                      AS TOTAL_PAID
  ,E.ACCT_BALANCE                   AS TRUST_ACCOUNT_BAL
  ,E.ACCT_DESC                      AS TRUST_ACCOUNT_DESC
  ,E.ACCT_ID                        AS TRUST_ACCOUNT_ID_PRI
  ,E.ACCT_STATUS                    AS TRUST_ACCOUNT_STATUS
   --- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,F.B1_HSE_NBR_ALPHA_START AS STREET_NBR_ALPHA
FROM
  B1PERMIT A
  LEFT JOIN
  BWORKDES B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  BVALUATN C
    ON  A.SERV_PROV_CODE = C.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = C.B1_PER_ID1 
    AND A.B1_PER_ID2 = C.B1_PER_ID2 
    AND A.B1_PER_ID3 = C.B1_PER_ID3
  JOIN
  BPERMIT_DETAIL D
    ON  A.SERV_PROV_CODE = D.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = D.B1_PER_ID1 
    AND A.B1_PER_ID2 = D.B1_PER_ID2 
    AND A.B1_PER_ID3 = D.B1_PER_ID3
  LEFT JOIN
  RACCOUNT E
    ON  D.SERV_PROV_CODE = E.SERV_PROV_CODE
    AND D.PRIMARY_TRUST_ACCOUNT_NUM = E.ACCT_SEQ_NBR
     LEFT JOIN 
  dbo.B3ADDRES F
  ON    A.SERV_PROV_CODE = F.SERV_PROV_CODE
        AND A.B1_PER_ID1 = F.B1_PER_ID1
        AND A.B1_PER_ID2 = F.B1_PER_ID2
        AND A.B1_PER_ID3 = F.B1_PER_ID3
WHERE
  ( A.B1_APPL_STATUS NOT IN (N'VOID',N'VOIDED')
    OR 
    A.B1_APPL_STATUS IS NULL 
  )
  AND (A.B1_APPL_CLASS=N'COMPLETE' OR NULLIF(A.B1_APPL_CLASS,N'') IS NULL)
  AND A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_RECORD_DATES_STAFF] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE        AS AGENCY_ID
  ,A.B1_ALT_ID            AS RECORD_ID
  ,A.B1_PER_GROUP         AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT      AS RECORD_NAME  
  ,A.B1_FILE_DD           AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS       AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE  AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)      AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM          AS UPDATED_BY
  ,B.REC_DATE             AS UPDATED_DATE
--Opened 
  ,A.B1_FILE_DD           AS OPENED_DATE
  ,ISNULL(S0.GA_FNAME,N'')+N' '+(CASE WHEN NULLIF(S0.GA_MNAME,N'') IS NOT NULL THEN S0.GA_MNAME+N' ' ELSE N'' END)+ISNULL(S0.GA_LNAME,N'')      AS OPENED_NAME
  ,B.b1_created_by        AS OPENED_USERID
  ,S0.GA_TITLE            AS OPENED_TITLE
  ,D0.R3_DEPTNAME         AS OPENED_DEPT
  ,S0.GA_EMPLOY_PH1       AS OPENED_PHONE      
  ,S0.GA_EMAIL            AS OPENED_EMAIL
--Assigned 
  ,B.B1_ASGN_DATE         AS ASSIGNED_DATE
  ,ISNULL(S1.GA_FNAME,N'')+N' '+(CASE WHEN NULLIF(S1.GA_MNAME,N'') IS NOT NULL THEN S1.GA_MNAME+N' ' ELSE N'' END)+ISNULL(S1.GA_LNAME,N'')      AS ASSIGNED_NAME
  ,B.B1_ASGN_STAFF        AS ASSIGNED_USERID
  ,S1.GA_TITLE            AS ASSIGNED_TITLE
  ,D1.R3_DEPTNAME         AS ASSIGNED_DEPT
  ,S1.GA_EMPLOY_PH1       AS ASSIGNED_PHONE      
  ,S1.GA_EMAIL            AS ASSIGNED_EMAIL
--Completed
  ,B.B1_COMPLETE_DATE     AS COMPLETED_DATE
  ,ISNULL(S2.GA_FNAME,N'')+N' '+(CASE WHEN NULLIF(S2.GA_MNAME,N'') IS NOT NULL THEN S2.GA_MNAME+N' ' ELSE N'' END)+ISNULL(S2.GA_LNAME,N'')      AS COMPLETED_NAME
  ,B.B1_COMPLETE_BY       AS COMPLETED_USERID
  ,S2.GA_TITLE            AS COMPLETED_TITLE
  ,D2.R3_DEPTNAME         AS COMPLETED_DEPT
  ,S2.GA_EMPLOY_PH1       AS COMPLETED_PHONE      
  ,S2.GA_EMAIL            AS COMPLETED_EMAIL
--Closed
  ,B.B1_CLOSED_DATE       AS CLOSED_DATE
  ,ISNULL(S3.GA_FNAME,N'')+N' '+(CASE WHEN NULLIF(S3.GA_MNAME,N'') IS NOT NULL THEN S3.GA_MNAME+N' ' ELSE N'' END)+ISNULL(S3.GA_LNAME,N'')      AS CLOSED_NAME
  ,B.B1_CLOSEDBY          AS CLOSED_USERID
  ,S3.GA_TITLE            AS CLOSED_TITLE
  ,D3.R3_DEPTNAME         AS CLOSED_DEPT
  ,S3.GA_EMPLOY_PH1       AS CLOSED_PHONE      
  ,S3.GA_EMAIL            AS CLOSED_EMAIL
--Inspector
  ,ISNULL(S4.GA_FNAME,N'')+N' '+(CASE WHEN NULLIF(S4.GA_MNAME,N'') IS NOT NULL THEN S4.GA_MNAME+N' ' ELSE N'' END)+ISNULL(S4.GA_LNAME,N'')      AS INSPECTOR_NAME
  ,B.C6_INSPECTOR_NAME    AS INSPECTOR_USERID
  ,S4.GA_TITLE            AS INSPECTOR_TITLE
  ,D4.R3_DEPTNAME         AS INSPECTOR_DEPT
  ,S4.GA_EMPLOY_PH1       AS INSPECTOR_PHONE      
  ,S4.GA_EMAIL            AS INSPECTOR_EMAIL
--Officer
  ,ISNULL(S5.GA_FNAME,N'')+N' '+(CASE WHEN NULLIF(S5.GA_MNAME,N'') IS NOT NULL THEN S5.GA_MNAME+N' ' ELSE N'' END)+ISNULL(S5.GA_LNAME,N'')      AS OFFICER_NAME
  ,B.C6_ENFORCE_OFFICER_NAME
                          AS OFFICER_USERID
  ,S5.GA_TITLE            AS OFFICER_TITLE
  ,D5.R3_DEPTNAME         AS OFFICER_DEPT
  ,S5.GA_EMPLOY_PH1       AS OFFICER_PHONE      
  ,S5.GA_EMAIL            AS OFFICER_EMAIL
   --- column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  BPERMIT_DETAIL B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  --Opened by Staff
  G3STAFFS S0
    ON  B.SERV_PROV_CODE = S0.SERV_PROV_CODE
    AND B.B1_CREATED_BY = S0.USER_NAME
  LEFT JOIN
  --Opened by Department
  G3DPTTYP D0
    ON  D0.SERV_PROV_CODE = S0.SERV_PROV_CODE
    AND D0.R3_AGENCY_CODE = S0.GA_AGENCY_CODE
    AND D0.R3_BUREAU_CODE = S0.GA_BUREAU_CODE
    AND D0.R3_DIVISION_CODE = S0.GA_DIVISION_CODE
    AND D0.R3_SECTION_CODE = S0.GA_SECTION_CODE
    AND D0.R3_GROUP_CODE = S0.GA_GROUP_CODE
    AND D0.R3_OFFICE_CODE = S0.GA_OFFICE_CODE
  LEFT JOIN
  --Assigned To Staff
  G3STAFFS S1
    ON  B.SERV_PROV_CODE = S1.SERV_PROV_CODE
    AND B.B1_ASGN_STAFF = S1.GA_USER_ID
  LEFT JOIN
  --Assigned to Dept
  G3DPTTYP D1
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE
    AND B.B1_ASGN_DEPT = D1.SERV_PROV_CODE+N'/'+D1.R3_AGENCY_CODE+N'/'+D1.R3_BUREAU_CODE+N'/'+D1.R3_DIVISION_CODE+N'/'+D1.R3_SECTION_CODE+N'/'+D1.R3_GROUP_CODE+N'/'+D1.R3_OFFICE_CODE
  LEFT JOIN
  --Completed by Staff
  G3STAFFS S2
    ON  B.SERV_PROV_CODE=S2.SERV_PROV_CODE
    AND B.B1_COMPLETE_BY=S2.GA_USER_ID
  LEFT JOIN
  --Completed by Dept
  G3DPTTYP D2
    ON  B.SERV_PROV_CODE = D2.SERV_PROV_CODE
    AND B.B1_COMPLETE_DEPT = D2.SERV_PROV_CODE+N'/'+D2.R3_AGENCY_CODE+N'/'+D2.R3_BUREAU_CODE+N'/'+D2.R3_DIVISION_CODE+N'/'+D2.R3_SECTION_CODE+N'/'+D2.R3_GROUP_CODE+N'/'+D2.R3_OFFICE_CODE
  LEFT JOIN
  --Closed by Staff
  G3STAFFS S3
    ON  B.SERV_PROV_CODE = S3.SERV_PROV_CODE
    AND B.B1_CLOSEDBY = S3.GA_USER_ID
  LEFT JOIN
   --Closed by Dept
  G3DPTTYP D3
    ON  B.SERV_PROV_CODE = D3.SERV_PROV_CODE
    AND B.B1_CLOSED_DEPT = D3.SERV_PROV_CODE+N'/'+D3.R3_AGENCY_CODE+N'/'+D3.R3_BUREAU_CODE+N'/'+D3.R3_DIVISION_CODE+N'/'+D3.R3_SECTION_CODE+N'/'+D3.R3_GROUP_CODE+N'/'+D3.R3_OFFICE_CODE
  LEFT JOIN
  --Inspector
  G3STAFFS S4
    ON  B.SERV_PROV_CODE = S4.SERV_PROV_CODE
    AND B.C6_INSPECTOR_NAME = S4.GA_USER_ID
  LEFT JOIN
  --Inspector Dept
  G3DPTTYP D4
    ON  B.SERV_PROV_CODE = D4.SERV_PROV_CODE
    AND B.C6_INSPECTOR_DEPT = D4.SERV_PROV_CODE+N'/'+D4.R3_AGENCY_CODE+N'/'+D4.R3_BUREAU_CODE+N'/'+D4.R3_DIVISION_CODE+N'/'+D4.R3_SECTION_CODE+N'/'+D4.R3_GROUP_CODE+N'/'+D4.R3_OFFICE_CODE
  LEFT JOIN
  --Officer
  G3STAFFS S5
    ON  B.SERV_PROV_CODE = S5.SERV_PROV_CODE
    AND B.C6_ENFORCE_OFFICER_NAME = S5.GA_USER_ID
  LEFT JOIN
   --Officer Dept
  G3DPTTYP D5
    ON  B.SERV_PROV_CODE = D5.SERV_PROV_CODE
    AND B.C6_ENFORCE_DEPT = D5.SERV_PROV_CODE+N'/'+D5.R3_AGENCY_CODE+N'/'+D5.R3_BUREAU_CODE+N'/'+D5.R3_DIVISION_CODE+N'/'+D5.R3_SECTION_CODE+N'/'+D5.R3_GROUP_CODE+N'/'+D5.R3_OFFICE_CODE   
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_RELATED_RECORD] 
AS
SELECT
  A.SERV_PROV_CODE                  AS AGENCY_ID
--=== Child Info  
  ,B.B1_CREATED_BY_ACA              AS CHILD_ACA_INITIATED
  ,B.B1_APPL_CLASS                  AS CHILD_COMPLETENESS
  ,B.B1_PER_GROUP                   AS CHILD_MODULE
  ,B.B1_SPECIAL_TEXT                AS CHILD_NAME
  ,B.B1_FILE_DD                     AS CHILD_OPEN_DATE
  ,B.REC_DATE                       AS CHILD_OPEN_DATE_ORIG
  ,B.B1_ALT_ID                      AS CHILD_RECORD_ID
  ,X.B1_STATUS                      AS CHILD_RENEWAL_STATUS
  ,B.B1_APPL_STATUS                 AS CHILD_STATUS
  ,B.B1_APPL_STATUS_DATE            AS CHILD_STATUS_DATE
  ,B.B1_APP_TYPE_ALIAS              AS CHILD_TYPE
  ,B.B1_PER_GROUP+N'/'+B.B1_PER_TYPE+N'/'+B.B1_PER_SUB_TYPE+N'/'+B.B1_PER_CATEGORY
                                    AS CHILD_TYPE_4LEVEL#
  ,B.B1_PER_CATEGORY                AS CHILD_TYPE_CATEGORY
  ,B.B1_PER_GROUP                   AS CHILD_TYPE_GROUP
  ,B.B1_PER_SUB_TYPE                AS CHILD_TYPE_SUBTYPE
  ,B.B1_PER_TYPE                    AS CHILD_TYPE_TYPE
  ,B.REC_FUL_NAM                    AS CHILD_UPDATED_BY
--=== Parent Info  
  ,A.B1_CREATED_BY_ACA              AS PARENT_ACA_INITIATED
  ,A.B1_APPL_CLASS                  AS PARENT_COMPLETENESS
  ,A.B1_PER_GROUP                   AS PARENT_MODULE
  ,A.B1_SPECIAL_TEXT                AS PARENT_NAME
  ,A.B1_FILE_DD                     AS PARENT_OPEN_DATE
  ,A.REC_DATE                       AS PARENT_OPEN_DATE_ORIG
  ,A.B1_ALT_ID                      AS PARENT_RECORD_ID
  ,A.B1_APPL_STATUS                 AS PARENT_STATUS
  ,A.B1_APPL_STATUS_DATE            AS PARENT_STATUS_DATE
  ,A.B1_APP_TYPE_ALIAS              AS PARENT_TYPE
  ,A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY
                                    AS PARENT_TYPE_4LEVEL#
  ,A.B1_PER_CATEGORY                AS PARENT_TYPE_CATEGORY
  ,A.B1_PER_GROUP                   AS PARENT_TYPE_GROUP
  ,A.B1_PER_SUB_TYPE                AS PARENT_TYPE_SUBTYPE
  ,A.B1_PER_TYPE                    AS PARENT_TYPE_TYPE
  ,A.REC_FUL_NAM                    AS PARENT_UPDATED_BY
  ,X.B1_RELATIONSHIP                AS RELATIONSHIP_TYPE
FROM
    dbo.B1PERMIT A    
	--parent CAP
    INNER JOIN
    dbo.XAPP2REF X ON
        A.SERV_PROV_CODE = X.SERV_PROV_CODE AND
        A.B1_PER_ID1 = X.B1_MASTER_ID1 AND
        A.B1_PER_ID2 = X.B1_MASTER_ID2 AND
        A.B1_PER_ID3 = X.B1_MASTER_ID3 AND
        A.REC_STATUS = X.REC_STATUS
    INNER JOIN
    dbo.B1PERMIT B ON  
	--child CAP
        X.SERV_PROV_CODE = B.SERV_PROV_CODE AND
        X.B1_PER_ID1 = B.B1_PER_ID1 AND
        X.B1_PER_ID2 = B.B1_PER_ID2 AND
        X.B1_PER_ID3 = B.B1_PER_ID3 AND
        X.REC_STATUS = B.REC_STATUS
WHERE
  ( A.B1_APPL_STATUS NOT IN (N'VOID',N'VOIDED')
    OR 
    A.B1_APPL_STATUS IS NULL 
  ) 
  AND
  ( B.B1_APPL_STATUS NOT IN (N'VOID',N'VOIDED')
    OR 
    B.B1_APPL_STATUS IS NULL 
  )
  AND A.REC_STATUS = N'A'
  AND X.B1_RELATIONSHIP<>N'EST'
GO

ALTER VIEW [dbo].[V_SET] 
AS
SELECT
  C.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,COALESCE(B.REC_FUL_NAM,C.REC_FUL_NAM)
                                    AS UPDATED_BY
  ,COALESCE(B.REC_DATE,C.REC_DATE)  AS UPDATED_DATE
--=== Set and Member Info  
  ,B.L1_ADDRESS_NBR                 AS ADDRESS_REF_ID
  ,B.LIC_SEQ_NBR                    AS LICENSE_REF_ID
  ,B.CHILD_SET_ID                   AS MEMBER_SET_ID
  ,B.L1_PARCEL_NBR                  AS PARCEL_REF_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,A.B1_APP_TYPE_ALIAS              AS RECORD_TYPE  
  ,C.SET_COMMENT                    AS SET_COMMENTS
  ,C.SET_ID                         AS SET_ID
  ,C.SET_TITLE                      AS SET_NAME
  ,C.SET_TYPE                       AS SET_TYPE
  ,B.SOURCE_SEQ_NBR                 AS SOURCE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  SETHEADER C
  LEFT JOIN
  SETDETAILS B
    ON  C.SERV_PROV_CODE=B.SERV_PROV_CODE
    AND C.SET_ID=B.SET_ID
  LEFT JOIN  
  B1PERMIT A 
    ON  A.SERV_PROV_CODE=B.SERV_PROV_CODE 
    AND A.B1_PER_ID1=B.B1_PER_ID1 
    AND A.B1_PER_ID2=B.B1_PER_ID2 
    AND A.B1_PER_ID3=B.B1_PER_ID3 
    AND A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_STATUS_HISTORY] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Status History Info  
  ,D2.R3_DEPTNAME                   AS ACTION_BY_DEPT
  ,B.ACTBY_FNAME                    AS ACTION_BY_NAME_F 
  --ACTION_BY_NAME_FML#
  ,LTRIM(  
    ISNULL(B.ACTBY_FNAME,N'')+N' '+
    (CASE WHEN nullif(B.ACTBY_MNAME,N'') IS NOT NULL THEN B.ACTBY_MNAME+N' ' ELSE N'' END)+
    ISNULL(B.ACTBY_LNAME,N'')
  )                                 AS ACTION_BY_NAME_FML#
  ,B.ACTBY_LNAME                    AS ACTION_BY_NAME_L
  ,B.ACTBY_MNAME                    AS ACTION_BY_NAME_M
  ,B.STATUS_COMMENT                 AS COMMENTS
  ,B.APP_IN_POSSESSION_TIME         AS IN_POSSESSION_HRS
  ,B.STATUS                         AS STATUS
  ,B.STATUS_DATE                    AS STATUS_DATE
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  STATUS_HISTORY B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  LEFT JOIN
  G3DPTTYP D2
   --Action Dept
    ON  B.SERV_PROV_CODE = D2.SERV_PROV_CODE 
    AND B.ACTBY_AGENCY_CODE = D2.R3_AGENCY_CODE 
    AND B.ACTBY_BUREAU_CODE = D2.R3_BUREAU_CODE 
    AND B.ACTBY_DIVISION_CODE = D2.R3_DIVISION_CODE 
    AND B.ACTBY_SECTION_CODE = D2.R3_SECTION_CODE 
    AND B.ACTBY_GROUP_CODE = D2.R3_GROUP_CODE 
    AND B.ACTBY_OFFICE_CODE = D2.R3_OFFICE_CODE  
WHERE
  A.REC_STATUS=N'A'
  AND B.TYPE=N'APPLICATION'
  AND B.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_TIME_ACCOUNTING] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,B.B1_ALT_ID                      AS RECORD_ID
  ,B.B1_PER_GROUP                   AS RECORD_MODULE
  ,B.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,B.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,B.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,B.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(B.B1_APP_TYPE_ALIAS,N''), B.B1_PER_GROUP+N'/'+B.B1_PER_TYPE+N'/'+B.B1_PER_SUB_TYPE+N'/'+B.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,A.REC_FUL_NAM                    AS UPDATED_BY
  ,A.REC_DATE                       AS UPDATED_DATE
--=== Time Accounting Entry Info  
  ,D2.R3_DEPTNAME                   AS ACTION_BY_DEPT
  ,S.GA_FNAME                       AS ACTION_BY_NAME_F 
  --ACTION_BY_NAME_FML#
  ,(  ISNULL(S.GA_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(S.GA_MNAME,N'') IS NOT NULL THEN S.GA_MNAME+N' ' ELSE N'' END)+
      ISNULL(S.GA_LNAME,N'')
  )                                 AS ACTION_BY_NAME_FML#
  ,S.GA_MNAME                       AS ACTION_BY_NAME_M 
  ,S.GA_LNAME                       AS ACTION_BY_NAME_L
  ,S.GA_EMPLOY_PH1                  AS ACTION_BY_PHONE
  ,S.GA_TITLE                       AS ACTION_BY_TITLE
  ,A.USER_NAME                      AS ACTION_BY_USERID
  ,A.BILLABLE_FLAG                  AS BILLABLE
  ,A.ENTRY_COST                     AS COST
  ,A.ENTRY_PCT                      AS COST_ADJUST_PERCENT
  ,A.CREATED_BY                     AS CREATED_BY_USERID
  ,A.CREATED_DATE                   AS DATE_CREATED
  ,A.LOG_DATE                       AS DATE_LOGGED
  ,A.TIME_END                       AS DATETIME_END
  ,A.TIME_START                     AS DATETIME_START
  ,ROUND(A.TOTAL_MINUTES/60, 4)     AS DURATION_HOURS
  ,A.TOTAL_MINUTES                  AS DURATION_MINUTES
  ,A.ENTITY_TYPE                    AS ENTITY_TYPE
  ,C.TIME_GROUP_NAME                AS GROUP_
  ,A.ENTRY_RATE                     AS HOURLY_RATE
  ,IC.TEXT                          AS INSPECTION_COMMENTS
  ,I.G6_COMPL_DD                    AS INSPECTION_DATE
  ,I.G6_ACT_NUM                     AS INSPECTION_ID
  ,I.G6_ACT_TYP                     AS INSPECTION_NAME
  ,I.G6_STATUS                      AS INSPECTION_STATUS
  ,( CASE WHEN NULLIF(I.G6_COMPL_T2,N'') IS NULL THEN ISNULL(I.G6_COMPL_T1,N'') ELSE I.G6_COMPL_T2+N' '+ISNULL(I.G6_COMPL_T1,N'') END )     
                                    AS INSPECTION_TIME
  ,A.MATERIALS_DESC                 AS MATERIALS
  ,A.MATERIALS_COST                 AS MATERIALS_COST
  ,A.MILEAGE_END                    AS MILEAGE_END
  ,A.MILEAGE_START                  AS MILEAGE_START
  ,A.MILAGE_TOTAL                   AS MILEAGE_TOTAL
  ,A.NOTATION                       AS NOTATION
  ,A.TIME_LOG_STATUS                AS STATUS
  ,ltrim(RIGHT(convert(CHAR(19),A.TIME_END,100),7))            
                                    AS TIME_END
  ,ROUND(A.TOTAL_MINUTES/60, 4)     AS TIME_IN_HOURS
  ,A.TOTAL_MINUTES                  AS TIME_IN_MINUTES                                  
  ,ltrim(RIGHT(convert(CHAR(19),A.TIME_START,100),7))   
                                    AS TIME_START
  ,E.TIME_TYPE_NAME                 AS TYPE_
  ,W.SD_COMMENT                     AS WORKFLOW_COMMENTS
  ,W.ESTIMATED_HOURS                AS WORKFLOW_EST_HOURS
  ,W.SD_OVERTIME                    AS WORKFLOW_OVERTIME
  ,W.SD_APP_DES                     AS WORKFLOW_STATUS
  ,W.G6_STAT_DD                     AS WORKFLOW_STATUS_DATE
  ,W.SD_PRO_DES                     AS WORKFLOW_TASK
  ,B.B1_PER_ID1 AS T_ID1
  ,B.B1_PER_ID2 AS T_ID2
  ,B.B1_PER_ID3 AS T_ID3
FROM
  T1_TIME_LOG A 
  LEFT JOIN
  B1PERMIT B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
  JOIN
  G3STAFFS S
    ON  S.SERV_PROV_CODE = A.SERV_PROV_CODE
    AND S.USER_NAME = A.USER_NAME
  JOIN
  G3DPTTYP D2
   -- Dept
    ON  S.SERV_PROV_CODE = D2.SERV_PROV_CODE 
    AND S.GA_AGENCY_CODE = D2.R3_AGENCY_CODE 
    AND S.GA_BUREAU_CODE = D2.R3_BUREAU_CODE 
    AND S.GA_DIVISION_CODE = D2.R3_DIVISION_CODE 
    AND S.GA_SECTION_CODE = D2.R3_SECTION_CODE 
    AND S.GA_GROUP_CODE = D2.R3_GROUP_CODE 
    AND S.GA_OFFICE_CODE = D2.R3_OFFICE_CODE 
  JOIN
  R1_TIME_GROUP C
    ON  A.SERV_PROV_CODE = C.SERV_PROV_CODE
    AND A.TIME_GROUP_SEQ = C.TIME_GROUP_SEQ
  JOIN
  R1_TIME_TYPES E
    ON  A.SERV_PROV_CODE = E.SERV_PROV_CODE
    AND A.TIME_TYPE_SEQ = E.TIME_TYPE_SEQ
  LEFT JOIN
  G6ACTION I
    ON  A.SERV_PROV_CODE = I.SERV_PROV_CODE
    AND A.B1_PER_ID1 = I.B1_PER_ID1
    AND A.B1_PER_ID2 = I.B1_PER_ID2
    AND A.B1_PER_ID3 = I.B1_PER_ID3
    AND A.ENTITY_TYPE = N'INSPECTION'
    AND A.ENTITY_ID = RTRIM(CAST(I.G6_ACT_NUM AS CHAR))
  LEFT JOIN
  BACTIVITY_COMMENT IC
    ON  I.SERV_PROV_CODE = IC.SERV_PROV_CODE
    AND I.B1_PER_ID1 = IC.B1_PER_ID1
    AND I.B1_PER_ID2 = IC.B1_PER_ID2
    AND I.B1_PER_ID3 = IC.B1_PER_ID3
    AND I.G6_ACT_NUM = IC.G6_ACT_NUM
    AND IC.COMMENT_TYPE = N'Inspection Result Comment'
  LEFT JOIN
  GPROCESS W
    ON  A.SERV_PROV_CODE = W.SERV_PROV_CODE
    AND A.B1_PER_ID1 = W.B1_PER_ID1
    AND A.B1_PER_ID2 = W.B1_PER_ID2
    AND A.B1_PER_ID3 = W.B1_PER_ID3
    AND A.ENTITY_TYPE = N'WORKFLOW'
    AND A.ENTITY_ID = RTRIM(CAST(W.SD_STP_NUM AS CHAR))+N':'+RTRIM(CAST(W.RELATION_SEQ_ID AS CHAR))
WHERE
  A.REC_STATUS = N'A'
  AND B.REC_STATUS = N'A'
GO

ALTER VIEW [dbo].[V_TRUST_ACCT_ASSOCIATED] 
AS
--======= Query 1: Associated Address, Parcel, Contact, Professional
SELECT
  B.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE  
--=== Associated Address, Parcel, People Info  
  ,( CASE B.PEOPLE_TYPE WHEN N'Address' THEN B.PEOPLE_SEQ_NBR ELSE NULL END )
                                    AS ADDRESS_REF_ID
  ,B.PEOPLE_TYPE                    AS ASSOCIATED_ITEM
  ,( CASE B.PEOPLE_TYPE WHEN N'Contact' THEN B.PEOPLE_SEQ_NBR ELSE NULL END )
                                    AS CONTACT_REF_ID
  ,( CASE B.PEOPLE_TYPE WHEN N'Licensed People' THEN B.PEOPLE_SEQ_NBR ELSE NULL END )
                                    AS LICENSE_REF_ID
  ,( CASE B.PEOPLE_TYPE WHEN N'Parcel' THEN B.PARCEL_NBR ELSE NULL END )
                                    AS PARCEL_REF_ID
  ,NULL                             AS RECORD_ID                                  
  ,B.SOURCE_SEQ_NBR                 AS SOURCE_ID
  ,A.ACCT_ID                        AS TRUST_ACCOUNT_ID
  ,NULL AS T_ID1
  ,NULL AS T_ID2
  ,NULL AS T_ID3
FROM
  RACCOUNT A
  JOIN
  XACCT_PEOPLE B
    ON A.SERV_PROV_CODE=B.SERV_PROV_CODE
    AND A.ACCT_SEQ_NBR=B.ACCT_SEQ_NBR
--=============
UNION ALL
--=============
SELECT
  B.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE  
--=== Associated Address, Parcel, People Info  
  ,NULL                             AS ADDRESS_REF_ID
  ,N'Record'                         AS ASSOCIATED_ITEM
  ,NULL                             AS CONTACT_REF_ID
  ,NULL                             AS LICENSE_REF_ID
  ,NULL                             AS PARCEL_REF_ID
  ,C.B1_ALT_ID                      AS RECORD_ID                                  
  ,NULL                             AS SOURCE_ID
  ,A.ACCT_ID                        AS TRUST_ACCOUNT_ID
  ,C.B1_PER_ID1 AS T_ID1
  ,C.B1_PER_ID2 AS T_ID2
  ,C.B1_PER_ID3 AS T_ID3
FROM
  RACCOUNT A
  JOIN
  XACCT_PERMIT B
    ON A.SERV_PROV_CODE = B.SERV_PROV_CODE
    AND A.ACCT_SEQ_NBR = B.TRUST_ACCOUNT_NUM
  JOIN
  B1PERMIT C
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = C.B1_PER_ID1 
    AND B.B1_PER_ID2 = C.B1_PER_ID2 
    AND B.B1_PER_ID3 = C.B1_PER_ID3
WHERE
  C.REC_STATUS = N'A'
GO

ALTER VIEW [dbo].[V_WORKFLOW] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID	                    AS RECORD_ID
  ,A.B1_PER_GROUP	                AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT	            AS RECORD_NAME  
  ,A.B1_FILE_DD	                    AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)	               AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM	                AS UPDATED_BY
  ,B.REC_DATE	                    AS UPDATED_DATE
--=== Workflow Info  
  ,D2.R3_DEPTNAME                   AS ACTION_BY_DEPT
  ,B.GA_FNAME	                    AS ACTION_BY_NAME_F 
  --ACTION_BY_NAME_FML
  ,(  ISNULL(B.GA_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(B.GA_MNAME,N'') IS NOT NULL THEN B.GA_MNAME+N' ' ELSE N'' END)+
      ISNULL(B.GA_LNAME,N'')
  )                                 AS ACTION_BY_NAME_FML#
  ,B.GA_LNAME	                    AS ACTION_BY_NAME_L
  ,B.GA_MNAME	                    AS ACTION_BY_NAME_M
  --ACTION_BY_USERID# - Pull first match by name, priority to active user
  ,(  select  TOP 1 (p.user_name) 
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.GA_FNAME
              and p.lname=B.GA_LNAME
              and (
                NULLIF(p.mname,N'') is null AND NULLIF(B.GA_MNAME,N'') IS NULL
                  or
                p.mname=B.GA_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS ACTION_BY_USERID#
  ,D1.R3_DEPTNAME	                AS ASSIGNED_DEPT
  ,B.ASGN_FNAME	                    AS ASSIGNED_NAME_F 
  ,(  ISNULL(B.ASGN_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(B.ASGN_MNAME,N'') IS NOT NULL THEN B.ASGN_MNAME+N' ' ELSE N'' END)+
      ISNULL(B.ASGN_LNAME,N'')
  )                                 AS ASSIGNED_NAME_FML#
  ,B.ASGN_LNAME	                    AS ASSIGNED_NAME_L
  ,B.ASGN_MNAME	                    AS ASSIGNED_NAME_M  
--ASSIGNED_USERID# - Pull first match by name, priority to active user
  ,(  select  TOP 1 (p.user_name) 
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.ASGN_FNAME
              and p.lname=B.ASGN_LNAME
              and (
                NULLIF(p.mname,N'') is null AND NULLIF(B.ASGN_MNAME,N'') IS NULL
                  or
                p.mname=B.ASGN_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS ASSIGNED_USERID#
  ,B.SD_BILLABLE	                AS BILLABLE
  ,B.SD_COMMENT	                    AS COMMENTS
  ,B.G6_ASGN_DD	                    AS DATE_ASSIGNED
  ,B.B1_DUE_DD	                    AS DATE_DUE
  ,B.SD_ESTIMATED_DUE_DATE	        AS DATE_EST_COMPLETE  
  ,B.G6_STAT_DD	                    AS DATE_STATUS
  ,B.SD_TRACK_START_DATE	        AS DATE_TRACK_START
  --DAYS_BTW_COMPL_DUE
  ,(
    CASE WHEN B.SD_CHK_LV2=N'Y' AND B.G6_STAT_DD IS NOT NULL AND B.B1_DUE_DD IS NOT NULL
      THEN DATEDIFF(d, CONVERT(DATETIME,B.B1_DUE_DD), CONVERT(DATETIME,B.G6_STAT_DD))
      ELSE NULL
    END
  )                                 AS DAYS_BTW_COMPL_DUE
  --DAYS_PAST_DUE
 ,(  
    CASE WHEN B.SD_CHK_LV1=N'Y' AND B.SD_CHK_LV2=N'N' AND CONVERT(DATETIME, CONVERT(NVARCHAR(10), GETDATE(), 120)) > CONVERT(DATETIME, CONVERT(NVARCHAR(10), B.B1_DUE_DD, 120))
      THEN DATEDIFF(d, CONVERT(DATETIME,B.B1_DUE_DD), CONVERT(DATETIME,GETDATE()))
      ELSE 0
    END
  )                                 AS DAYS_PAST_DUE
  --DAYS_SINCE_ASSIGNED
  ,DATEDIFF(d, CONVERT(DATETIME,B.G6_ASGN_DD), CONVERT(DATETIME,GETDATE()))
                                  AS DAYS_SINCE_ASSIGNED
  --DAYS_TO_COMPLETE
  ,(
    CASE WHEN B.SD_CHK_LV2=N'Y' AND B.G6_STAT_DD IS NOT NULL AND B.G6_ASGN_DD IS NOT NULL
      THEN DATEDIFF(d, CONVERT(DATETIME,B.G6_ASGN_DD), CONVERT(DATETIME,B.G6_STAT_DD))
      ELSE NULL
    END
  )                                 AS DAYS_TO_COMPLETE
  ,B.RESTRICT_COMMENT_FOR_ACA	    AS DISPLAY_CMT_ACA
  --DISPLAY_CMT_ACA_TO#
  ,(
    CASE B.RESTRICT_ROLE	
      WHEN N'0000000000' then N'No One'
      WHEN N'1111100000' THEN N'All ACA Users, Record Creator, Licensed Professional, Contact, Owner'
      ELSE REVERSE(SUBSTRING(
        REVERSE(
        (CASE SUBSTRING(B.RESTRICT_ROLE,1,1) WHEN N'1' THEN N'All ACA Users, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,2,1) WHEN N'1' THEN N'Record Creator, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,3,1) WHEN N'1' THEN N'Licensed Professional, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,4,1) WHEN N'1' THEN N'Contact, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,5,1) WHEN N'1' THEN N'Owner, ' ELSE N'' END) 
        )
        --remove the comma and space at end ('reversed' to start of string)
        ,3
        ,100
      ))
    END
  )                                 AS DISPLAY_CMT_ACA_TO#
  ,B.ASGN_EMAIL_DISPLAY_FOR_ACA	    AS DISPLAY_EMAIL_ACA  
  --DURATION_PLANNED
  ,DATEDIFF(d, CONVERT(DATETIME,B.G6_ASGN_DD), CONVERT(DATETIME, B.B1_DUE_DD))
                                    AS DURATION_PLANNED
  ,B.ESTIMATED_HOURS	            AS ESTIMATED_HOURS                                  
  ,B.SD_HOURS_SPENT	                AS HOURS_SPENT
  ,B.SD_IN_POSSESSION_TIME 	        AS IN_POSSESSION_HRS
  ,B.SD_OVERTIME	                AS OVERTIME
  --PARENT_TASK
  ,(  select  TOP 1 p.parenttaskname
      from    gprocess_group p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              AND p.b1_per_id1=B.B1_PER_ID1
              AND p.b1_per_id2=B.B1_PER_ID2
              AND p.b1_per_id3=B.B1_PER_ID3
              AND p.RELATION_SEQ_ID=B.RELATION_SEQ_ID
  )                                 AS PARENT_TASK#
  ,B.R1_PROCESS_CODE	            AS PROCESS_NAME
  ,B.SD_APP_DES	                    AS STATUS
  ,B.SD_PRO_DES	                    AS TASK
  ,B.SD_CHK_LV1	                    AS TASK_IS_ACTIVE
  ,B.SD_CHK_LV2	                    AS TASK_IS_COMPLETE
  ,LTRIM(RIGHT(CONVERT(CHAR(19),B.SD_START_TIME,100),7))
                                    AS TIME_START
  ,LTRIM(RIGHT(CONVERT(CHAR(19),B.SD_END_TIME,100),7))
                                    AS TIME_END
--=== column to support build relation with Templates.
  ,A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' +  CONVERT(NVARCHAR, B.RELATION_SEQ_ID) + N'/' +  CONVERT(NVARCHAR, B.SD_STP_NUM) AS TEMPLATE_ID
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
  ,CONVERT(NVARCHAR, B.RELATION_SEQ_ID) AS T_ID4
  ,CONVERT(NVARCHAR, B.SD_STP_NUM) AS T_ID5
FROM
  B1PERMIT A 
  JOIN
  GPROCESS B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3
  LEFT JOIN
  --Assigned Dept
  G3DPTTYP D1
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE
    AND B.ASGN_AGENCY_CODE = D1.R3_AGENCY_CODE
    AND B.ASGN_BUREAU_CODE = D1.R3_BUREAU_CODE
    AND B.ASGN_DIVISION_CODE = D1.R3_DIVISION_CODE
    AND B.ASGN_SECTION_CODE = D1.R3_SECTION_CODE
    AND B.ASGN_GROUP_CODE = D1.R3_GROUP_CODE
    AND B.ASGN_OFFICE_CODE = D1.R3_OFFICE_CODE
  LEFT JOIN
  --Action Dept
  G3DPTTYP D2
    ON  B.SERV_PROV_CODE = D2.SERV_PROV_CODE
    AND B.SD_AGENCY_CODE = D2.R3_AGENCY_CODE
    AND B.SD_BUREAU_CODE = D2.R3_BUREAU_CODE
    AND B.SD_DIVISION_CODE = D2.R3_DIVISION_CODE
    AND B.SD_SECTION_CODE = D2.R3_SECTION_CODE
    AND B.SD_GROUP_CODE = D2.R3_GROUP_CODE
    AND B.SD_OFFICE_CODE = D2.R3_OFFICE_CODE
WHERE
  A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_WORKFLOW_HISTORY] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
  ,A.B1_ALT_ID                      AS RECORD_ID
  ,A.B1_PER_GROUP                   AS RECORD_MODULE
  ,A.B1_SPECIAL_TEXT                AS RECORD_NAME  
  ,A.B1_FILE_DD                     AS RECORD_OPEN_DATE
  ,A.B1_APPL_STATUS                 AS RECORD_STATUS 
  ,A.B1_APPL_STATUS_DATE            AS RECORD_STATUS_DATE
  ,ISNULL(NULLIF(A.B1_APP_TYPE_ALIAS,N''), A.B1_PER_GROUP+N'/'+A.B1_PER_TYPE+N'/'+A.B1_PER_SUB_TYPE+N'/'+A.B1_PER_CATEGORY)                AS RECORD_TYPE
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Workflow History Info  
  ,D2.R3_DEPTNAME                   AS ACTION_BY_DEPT
  ,B.G6_ISS_FNAME                   AS ACTION_BY_NAME_F 
  --ACTION_BY_NAME_FML
  ,(  ISNULL(B.G6_ISS_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(B.G6_ISS_MNAME,N'') IS NOT NULL THEN B.G6_ISS_MNAME+N' ' ELSE N'' END)+
      ISNULL(B.G6_ISS_LNAME,N'')
  )                                 AS ACTION_BY_NAME_FML#
  ,B.G6_ISS_LNAME                   AS ACTION_BY_NAME_L
  ,B.G6_ISS_MNAME                   AS ACTION_BY_NAME_M
 --ACTION_BY_USERID# - Pull first match by name, priority to active user
  ,(  select  top 1 (p.user_name) 
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.G6_ISS_FNAME
              and p.lname=B.G6_ISS_LNAME
              and (
                NULLIF(p.mname,N'') is null AND NULLIF(B.G6_ISS_MNAME,N'') IS NULL
                  or
                p.mname=B.G6_ISS_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS ACTION_BY_USERID#
  ,D1.R3_DEPTNAME                   AS ASSIGNED_DEPT
  ,B.ASGN_FNAME                     AS ASSIGNED_NAME_F 
  --ASSIGNED_NAME_FML
  ,(  ISNULL(B.ASGN_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(B.ASGN_MNAME,N'') IS NOT NULL THEN B.ASGN_MNAME+N' ' ELSE N'' END)+
      ISNULL(B.ASGN_LNAME,N'')
  )                                 AS ASSIGNED_NAME_FML#
  ,B.ASGN_LNAME                     AS ASSIGNED_NAME_L
  ,B.ASGN_MNAME                     AS ASSIGNED_NAME_M
--ASSIGNED_USERID# - Pull first match by name, priority to active user
  ,(  select  TOP 1 (p.user_name) 
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.ASGN_FNAME
              and p.lname=B.ASGN_LNAME
              and (
                NULLIF(p.mname,N'') is null AND NULLIF(B.ASGN_MNAME,N'') IS NULL
                  or
                p.mname=B.ASGN_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS ASSIGNED_USERID#
  ,B.SD_BILLABLE                    AS BILLABLE
  ,B.SD_COMMENT                     AS COMMENTS
  ,B.G6_ASGN_DD                     AS DATE_ASSIGNED
  ,B.B1_DUE_DD                      AS DATE_DUE
  ,B.SD_ESTIMATED_DUE_DATE          AS DATE_EST_COMPLETE
  ,B.SD_APP_DD                      AS DATE_STATUS
  ,B.SD_TRACK_START_DATE            AS DATE_TRACK_START
  ,B.RESTRICT_COMMENT_FOR_ACA       AS DISPLAY_CMT_ACA
  --DISPLAY_CMT_ACA_TO#
  ,(
    CASE B.RESTRICT_ROLE    
      WHEN N'0000000000' then N'No One'
      WHEN N'1111100000' THEN N'All ACA Users, Record Creator, Licensed Professional, Contact, Owner'
      ELSE REVERSE(SUBSTRING(
        REVERSE(
        (CASE SUBSTRING(B.RESTRICT_ROLE,1,1) WHEN N'1' THEN N'All ACA Users, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,2,1) WHEN N'1' THEN N'Record Creator, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,3,1) WHEN N'1' THEN N'Licensed Professional, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,4,1) WHEN N'1' THEN N'Contact, ' ELSE N'' END) +
        (CASE SUBSTRING(B.RESTRICT_ROLE,5,1) WHEN N'1' THEN N'Owner, ' ELSE N'' END) 
        )
        ,3 
        --remove the comma and space at end ('reversed' to start of string)
        ,100
      ))
    END
  )                                 AS DISPLAY_CMT_ACA_TO#
  ,B.ASGN_EMAIL_DISPLAY_FOR_ACA     AS DISPLAY_EMAIL_ACA
  ,B.ESTIMATED_HOURS                AS ESTIMATED_HOURS
  ,B.SD_HOURS_SPENT                 AS HOURS_SPENT
  ,B.SD_IN_POSSESSION_TIME          AS IN_POSSESSION_HRS
  ,B.SD_OVERTIME                    AS OVERTIME
  ,B.PARENTTASKNAME                 AS PARENT_TASK
  ,B.R1_PROCESS_CODE                AS PROCESS_NAME
  ,B.SD_APP_DES                     AS STATUS
  ,B.SD_PRO_DES                     AS TASK
  ,B.SD_CHK_LV1                     AS TASK_IS_ACTIVE
  ,B.SD_CHK_LV2                     AS TASK_IS_COMPLETE
  ,LTRIM(RIGHT(CONVERT(CHAR(19),B.SD_START_TIME,100),7))
                                    AS TIME_START
  ,LTRIM(RIGHT(CONVERT(CHAR(19),B.SD_END_TIME,100),7))
                                    AS TIME_END
  ,A.B1_PER_ID1 AS T_ID1
  ,A.B1_PER_ID2 AS T_ID2
  ,A.B1_PER_ID3 AS T_ID3
FROM
  B1PERMIT A 
  JOIN
  GPROCESS_HISTORY B
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE 
    AND A.B1_PER_ID1 = B.B1_PER_ID1 
    AND A.B1_PER_ID2 = B.B1_PER_ID2 
    AND A.B1_PER_ID3 = B.B1_PER_ID3 
   LEFT JOIN
  G3DPTTYP D1
   --Assigned Dept
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE 
    AND B.ASGN_AGENCY_CODE = D1.R3_AGENCY_CODE 
    AND B.ASGN_BUREAU_CODE = D1.R3_BUREAU_CODE 
    AND B.ASGN_DIVISION_CODE = D1.R3_DIVISION_CODE 
    AND B.ASGN_SECTION_CODE = D1.R3_SECTION_CODE 
    AND B.ASGN_GROUP_CODE = D1.R3_GROUP_CODE 
    AND B.ASGN_OFFICE_CODE = D1.R3_OFFICE_CODE
  LEFT JOIN
  G3DPTTYP D2
    --Action Dept
    ON  B.SERV_PROV_CODE = D2.SERV_PROV_CODE 
    AND B.SD_AGENCY_CODE = D2.R3_AGENCY_CODE 
    AND B.SD_BUREAU_CODE = D2.R3_BUREAU_CODE 
    AND B.SD_DIVISION_CODE = D2.R3_DIVISION_CODE 
    AND B.SD_SECTION_CODE = D2.R3_SECTION_CODE 
    AND B.SD_GROUP_CODE = D2.R3_GROUP_CODE 
    AND B.SD_OFFICE_CODE = D2.R3_OFFICE_CODE
WHERE
  A.REC_STATUS = N'A'
--**** Exclude deleted history items
  AND B.REC_STATUS = N'A'
GO

ALTER VIEW [dbo].[V_WORKORDER_ASSET] 
AS
SELECT
		--=== Record Info
		A.SERV_PROV_CODE              AS AGENCY_ID
		,A.B1_ALT_ID                  AS RECORD_ID
		,A.B1_PER_GROUP               AS RECORD_MODULE
		,A.B1_SPECIAL_TEXT            AS RECORD_NAME
		,A.B1_FILE_DD                 AS RECORD_OPEN_DATE
		,A.B1_APPL_STATUS             AS RECORD_STATUS
		,A.B1_APPL_STATUS_DATE        AS RECORD_STATUS_DATE 
		,A.B1_APP_TYPE_ALIAS       	  AS RECORD_TYPE
		--=== Row Update Info
		,B.REC_FUL_NAM                AS UPDATED_BY
		,B.REC_DATE                   AS UPDATED_DATE
		--=== WorkOrder Asset Info
		,B.G1_ASSET_SEQ_NBR           AS ASSET_NBR
		,B.REC_STATUS                 AS STATUS
		,B.G1_WOASSET_ORDER           AS ORDER_ID
		,B.G1_WOASSET_COMPLETE        AS STATUS_COMPLETE
		,B.G1_WOASSET_COMPLETE_DATE   AS DATE_COMPLETED
		,B.G1_WOASSET_SHORT_NOTES     AS SHORT_NOTES
		,B.START_WORK_LOCATION        AS START_WORK_LOCATION
		,B.END_WORK_LOCATION          AS END_WORK_LOCATION
		,COALESCE(B.WORK_DIRECTION,N'N')		AS WORK_DIRECTION
		,A.B1_PER_ID1 AS T_ID1
		,A.B1_PER_ID2 AS T_ID2
		,A.B1_PER_ID3 AS T_ID3
FROM
	dbo.B1PERMIT A
	JOIN
	dbo.GWORK_ORDER_ASSET B
		ON  A.SERV_PROV_CODE=B.SERV_PROV_CODE
		AND A.B1_PER_ID1=B.B1_PER_ID1
		AND A.B1_PER_ID2=B.B1_PER_ID2
		AND A.B1_PER_ID3=B.B1_PER_ID3
	WHERE
	A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_LP_TEMPLATE_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + A.B1_CONTACT_TYPE + N'/'+ CONVERT(NVARCHAR, A.B1_CONTACT_NBR) AS ID,
       N'LP_TPL::' + A.B1_CONTACT_TYPE AS ENTITY,
       A.B1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.B1_ATTRIBUTE_VALUE AS VALUE
  FROM B3CONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_PEOPLE_TEMPLATE_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + A.B1_CONTACT_TYPE + N'/'+ CONVERT(NVARCHAR, A.B1_CONTACT_NBR) AS ID,
       N'PEOPLE_DAILY::' + A.B1_CONTACT_TYPE AS ENTITY,
       A.B1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.B1_ATTRIBUTE_VALUE AS VALUE
  FROM B3CONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[B6CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.B1_CON_DES B1_CON_DES_V, 
       I.B1_CON_LONG_COMMENT B1_CON_LONG_COMMENT_V, 
       I.B1_CON_COMMENT B1_CON_COMMENT_V
  FROM      B6CONDIT T 
  LEFT JOIN B6CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_CONDITION_RECORD_TPL_ATTR] 
AS
(
SELECT DISTINCT A.SERV_PROV_CODE AS AGENCY_ID,
               N'RECORD_COND_TPL::' + A.R1_CHECKBOX_CODE AS ENTITY,
                B3.B1_CON_TYP AS CONDITION_TYPE,
                B3.B1_CON_GROUP AS CONDITION_GROUP,
                A.R1_CHECKBOX_DESC AS ATTRIBUTE,
                NULL AS TYPE
  FROM B6CONDIT B3, R2CHCKBOX A
 INNER JOIN GTMPL_ATTRIBUTE B ON A.SERV_PROV_CODE = B.SERV_PROV_CODE
                             AND A.R1_CHECKBOX_CODE = B.GROUP_CODE
 WHERE (B.ENTITY_TYPE = 11)
   AND A.R1_CHECKBOX_GROUP = N'APPLICATION'
   AND A.SERV_PROV_CODE = B3.SERV_PROV_CODE
   AND A.REC_STATUS = N'A' AND B3.B1_CON_NBR = B.ENTITY_SEQ1
   AND B3.B1_PER_ID1 = B.ENTITY_KEY1 AND B3.B1_PER_ID2 = B.ENTITY_KEY2 AND B3.B1_PER_ID3 = B.ENTITY_KEY3
)
GO

ALTER VIEW [dbo].[B6CONDIT_DETAIL_VIEW_EN_US] AS 
SELECT T.*, 
       I.ADDIT_INFO_PLAIN_TEXT ADDIT_INFO_PLAIN_TEXT_V, 
       I.ADDITIONAL_INFORMATION ADDITIONAL_INFORMATION_V, 
       I.B1_CON_PUBLIC_DIS_MESSAGE B1_CON_PUBLIC_DIS_MESSAGE_V, 
       I.B1_CON_RESOLUTION_ACTION B1_CON_RESOLUTION_ACTION_V, 
       I.LANG_ID LANG_ID_V
  FROM      B6CONDIT_DETAIL T 
  LEFT JOIN B6CONDIT_DETAIL_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BACTIVITY_COMMENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.TEXT TEXT_V, 
       I.CLOBTEXT CLOBTEXT_V
  FROM      BACTIVITY_COMMENT T 
  LEFT JOIN BACTIVITY_COMMENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BALERT_MESSAGE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.ALERT_MSG_TYPE ALERT_MSG_TYPE_V, 
       I.ALERT_MSG_CONTENT ALERT_MSG_CONTENT_V
  FROM      BALERT_MESSAGE T 
  LEFT JOIN BALERT_MESSAGE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BATCH_JOB_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.BATCH_JOB_NAME BATCH_JOB_NAME_V
  FROM      BATCH_JOB T 
  LEFT JOIN BATCH_JOB_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BCUSTOMIZED_CONTENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CONTENT_TEXT CONTENT_TEXT_V, 
       I.BRIEF_DESC BRIEF_DESC_V
  FROM      BCUSTOMIZED_CONTENT T 
  LEFT JOIN BCUSTOMIZED_CONTENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BDOCUMENT_COMMENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.COMMENT_CONTENT COMMENT_CONTENT_V
  FROM      BDOCUMENT_COMMENT T 
  LEFT JOIN BDOCUMENT_COMMENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BMODEL_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.MODEL_NAME MODEL_NAME_V, 
       I.MODEL_TITLE MODEL_TITLE_V
  FROM      BMODEL T 
  LEFT JOIN BMODEL_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BMODEL_VAR_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.VARIATION_NAME VARIATION_NAME_V
  FROM      BMODEL_VAR T 
  LEFT JOIN BMODEL_VAR_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BMODEL_VAR_CHOICE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CHOICE_NAME CHOICE_NAME_V
  FROM      BMODEL_VAR_CHOICE T 
  LEFT JOIN BMODEL_VAR_CHOICE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BPERMIT_COMMENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.TEXT TEXT_V
  FROM      BPERMIT_COMMENT T 
  LEFT JOIN BPERMIT_COMMENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[BPORTLETLINKS_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.LINK_DES LINK_DES_V, 
       I.LINK_ALT LINK_ALT_V
  FROM      BPORTLETLINKS T 
  LEFT JOIN BPORTLETLINKS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[CALENDAR_VIEW_EN_US] AS 
SELECT T.*, 
       I.CALENDAR_COMMENT CALENDAR_COMMENT_V, 
       I.CALENDAR_CONTACTS CALENDAR_CONTACTS_V, 
       I.CALENDAR_NAME CALENDAR_NAME_V, 
       I.CALENDAR_REASON CALENDAR_REASON_V, 
       I.LANG_ID LANG_ID_V
  FROM      CALENDAR T 
  LEFT JOIN CALENDAR_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[CALENDAR_EVENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.EVENT_COMMENT EVENT_COMMENT_V, 
       I.EVENT_NAME EVENT_NAME_V, 
       I.HEARING_BODY HEARING_BODY_V, 
       I.LANG_ID LANG_ID_V
  FROM      CALENDAR_EVENT T 
  LEFT JOIN CALENDAR_EVENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[CRYSTAL_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CRYSTAL_X_LABEL CRYSTAL_X_LABEL_V, 
       I.CRYSTAL_Y_LABEL CRYSTAL_Y_LABEL_V, 
       I.CRYSTAL_TITLE CRYSTAL_TITLE_V
  FROM      CRYSTAL T 
  LEFT JOIN CRYSTAL_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_TRUST_ACCT_TRANSACTION] 
AS
SELECT
--=== Record Info
  B.SERV_PROV_CODE                  AS AGENCY_ID
  ,B.B1_ALT_ID                      AS RECORD_ID  
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Trust Account Transaction Info    
  --AMOUNT
  ,( CASE WHEN B.TRANS_TYPE IN (N'PAYMENT', N'WITHDRAW', N'TRANSFER TO', N'DEBIT ADJUST', N'VOID REFUND') 
        THEN B.TRANS_AMOUNT * (-1)
        ELSE B.TRANS_AMOUNT 
     END
  )                                 AS AMOUNT
  ,P.AMOUNT_NOTALLOCATED            AS AMOUNT_NOT_APPLIED
  --BALANCE_RUNNING#  
  ,(  CASE 
        WHEN B.TRANS_TYPE IN (N'DEPOSIT',N'WITHDRAW') THEN B.BALANCE
        ELSE ( select sum( case when q.trans_type in (N'PAYMENT',N'WITHDRAW',N'TRANSFER TO',N'DEBIT ADJUST', N'VOID REFUND') 
                                then q.trans_amount * (-1)
                                else q.trans_amount 
                           end )
               from   f4acct_transaction q
               where  q.serv_prov_code=B.SERV_PROV_CODE
                      and q.acct_seq_nbr=B.ACCT_SEQ_NBR
                      and q.trans_seq_nbr <= B.TRANS_SEQ_NBR
        )
      END
  )                                 AS BALANCE_RUNNING#
  ,B.BATCH_TRANSACTION_NBR          AS BATCH_TRANSACT_ID
  ,COALESCE(NULLIF(P.TERMINAL_ID,N''),B.TERMINAL_ID) 
                                    AS CASH_DRAWER
  ,COALESCE(B.REC_FUL_NAM,P.CASHIER_ID) 
                                    AS CASHIER_USERID
  ,B.CLIENT_TRANS_NBR               AS CLIENT_TRANSACT_ID
  ,COALESCE(NULLIF(B.OP_COMMENT,N''),P.PAYMENT_COMMENT)  
                                    AS COMMENTS
  ,P.PAYMENT_DATE                   AS DATE_PAYMENT
  ,B.REC_DATE                       AS DATE_TRANSACTION
  ,B.DEPOSIT_FOR                    AS DEPOSIT_FOR
  ,B.OFFICE_CODE                    AS OFFICE_CODE
  ,B.PAYMENT_SEQ_NBR                AS PAYMENT_ID
  --PAYMENT_METHOD
  ,(  CASE 
        WHEN B.TRANS_TYPE IN (N'PAYMENT',N'VOID PAYMENT',N'REFUND',N'VOID REFUND')
          THEN N'Trust Account'
        WHEN B.TRANS_TYPE IN (N'DEPOSIT',N'WITHDRAW')
          THEN B.DEPOSIT_METHOD
        ELSE NULL
      END
  )                                 AS PAYMENT_METHOD
  ,COALESCE(NULLIF(B.PAYOR,N''),P.PAYEE)     
                                    AS PAYOR
  ,P.PHONE_NUMBER                   AS PHONE_NUMBER
  ,COALESCE(B.RECEIPT_NBR,P.RECEIPT_NBR)    
                                    AS RECEIPT_ID
  ,COALESCE(NULLIF(R1.RECEIPT_CUSTOMIZED_NBR,N''),R2.RECEIPT_CUSTOMIZED_NBR) 
                                    AS RECEIPT_NUMBER
  ,B.PAYMENT_RECEIVED_CHANNEL       AS RECEIVED
  ,COALESCE(NULLIF(B.PAYMENT_REF_NBR,N''),P.PAYMENT_REF_NBR) 
                                    AS REFERENCE_
  ,P.SESSION_NBR                    AS SESSION_ID
  ,B.TARGET_ACCT_ID                 AS TARGET_ACCOUNT_ID
  ,B.REC_DATE                       AS TRANSACTION_DATE
  ,B.TRANS_TYPE                     AS TRANSACTION_TYPE
  ,B.ACCT_ID                        AS TRUST_ACCOUNT_ID
  ,B.TRANS_SEQ_NBR                  AS TRUST_TRANSACT_ID
  ,COALESCE(NULLIF(B.WORKSTATION_ID,N''),P.WORKSTATION_ID)   
                                    AS WORKSTATION
  ,B.B1_PER_ID1 AS T_ID1
  ,B.B1_PER_ID2 AS T_ID2
  ,B.B1_PER_ID3 AS T_ID3
FROM
  F4ACCT_TRANSACTION B  
  LEFT JOIN 
  F4RECEIPT R1
   --DEPOSIT/WITHDRAW   
    ON  B.SERV_PROV_CODE = R1.SERV_PROV_CODE    
    AND B.RECEIPT_NBR = R1.RECEIPT_NBR  
  LEFT JOIN 
  F4PAYMENT P   
    ON  B.SERV_PROV_CODE = P.SERV_PROV_CODE 
    AND B.B1_PER_ID1 = P.B1_PER_ID1 
    AND B.B1_PER_ID2 = P.B1_PER_ID2 
    AND B.B1_PER_ID3 = P.B1_PER_ID3 
    AND B.PAYMENT_SEQ_NBR = P.PAYMENT_SEQ_NBR   
  LEFT JOIN 
  F4RECEIPT R2
   --PAYMENT/REFUND 
    ON  P.SERV_PROV_CODE = R2.SERV_PROV_CODE    
    AND P.RECEIPT_NBR = R2.RECEIPT_NBR
GO

ALTER VIEW [dbo].[V_REF_CONTACT] 
AS
SELECT
  B.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Reference Contact Info  
  ,B.G1_ADDRESS1                    AS ADDRESS_LINE1
  ,B.G1_ADDRESS2                    AS ADDRESS_LINE2
  ,B.G1_ADDRESS3                    AS ADDRESS_LINE3
  ,B.G1_CITY                        AS ADDRESS_CITY
  ,B.L1_POST_OFFICE_BOX             AS ADDRESS_PO_BOX
  ,B.G1_STATE                       AS ADDRESS_STATE
  ,B.G1_ZIP                         AS ADDRESS_ZIP
  ,B.G1_COUNTRY                     AS ADDRESS_COUNTRY
  ,B.G1_BUSINESS_NAME               AS BUSINESS_NAME  
  ,B.G1_CONTACT_NBR                 AS CONTACT_REF_ID
  ,B.G1_CONTACT_TYPE                AS CONTACT_TYPE
  ,B.G1_EMAIL                       AS EMAIL  
  ,B.G1_FAX                         AS FAX  
  ,B.G1_FAX_COUNTRY_CODE            AS FAX_COUNTRY_CODE
  ,B.G1_FEDERAL_EMPLOYER_ID_NUM     AS FEIN  
  ,B.L1_GENDER                      AS GENDER
  ,B.G1_FNAME                       AS NAME_FIRST
  ,B.G1_MNAME                       AS NAME_MIDDLE
  ,B.G1_LNAME                       AS NAME_LAST
  ,(
    ISNULL(B.G1_FNAME,N'')+N' '+
    (CASE WHEN NULLIF(B.G1_MNAME,N'') IS NOT NULL THEN B.G1_MNAME+N' ' ELSE N'' END)+
    ISNULL(B.G1_LNAME,N'')
  )                                 AS NAME_FML#
  ,B.G1_FULL_NAME                   AS NAME_FULL
  ,B.G1_PHONE1                      AS PHONE1
  ,B.G1_PHONE1_COUNTRY_CODE         AS PHONE1_COUNTRY_CODE
  ,B.G1_PHONE2                      AS PHONE2
  ,B.G1_PHONE2_COUNTRY_CODE         AS PHONE2_COUNTRY_CODE
  ,B.G1_PHONE3                      AS PHONE3
  ,B.G1_PHONE3_COUNTRY_CODE         AS PHONE3_COUNTRY_CODE
  ,(  CASE 
        WHEN B.G1_PREFERRED_CHANNEL=0 OR B.G1_PREFERRED_CHANNEL IS NULL
          THEN N''
        ELSE COALESCE(NULLIF(C1.VALUE_DESC,N''),NULLIF(C2.VALUE_DESC,N''),N'')
      END    
  )                                 AS PREFERRED_CHANNEL
  ,coalesce(B.G1_FLAG,N'N')          AS PRIMARY_
  ,B.G1_RELATION                    AS RELATIONSHIP  
  ,B.L1_SALUTATION                  AS SALUTATION
  ,B.REC_STATUS                     AS STATUS  
  ,B.G1_TITLE                       AS TITLE
  ,B.G1_TRADE_NAME                  AS TRADE_NAME  
 --=== column to support build relation with Templates.
  ,CONVERT(NVARCHAR, B.G1_CONTACT_NBR)   AS TEMPLATE_ID
  ,CONVERT(NVARCHAR, B.G1_CONTACT_NBR)   AS T_ID1
FROM
  G3CONTACT B
LEFT JOIN
  RBIZDOMAIN_VALUE C1
    ON  B.SERV_PROV_CODE=C1.SERV_PROV_CODE
    AND C1.BIZDOMAIN=N'CONTACT_PREFERRED_CHANNEL'
    AND B.G1_PREFERRED_CHANNEL=C1.BIZDOMAIN_VALUE
    AND C1.REC_STATUS=N'A'
  LEFT JOIN
  RBIZDOMAIN_VALUE C2
    ON  C2.SERV_PROV_CODE=N'STANDARDDATA'
    AND C2.BIZDOMAIN=N'CONTACT_PREFERRED_CHANNEL'
    AND B.G1_PREFERRED_CHANNEL=C2.BIZDOMAIN_VALUE
    AND C2.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_REF_LP_TEMPLATE_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       CONVERT(NVARCHAR, A.G1_CONTACT_NBR) AS ID,
       N'LP_REF_TPL::' + A.G1_CONTACT_TYPE AS ENTITY,
       A.G1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.G1_Attribute_Value AS VALUE
  FROM G3CONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_REF_PEOPLE_TEMPLATE_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       CONVERT(NVARCHAR, A.G1_CONTACT_NBR) AS ID,
       N'PEOPLE_REF::' + A.G1_CONTACT_TYPE AS ENTITY,
       A.G1_ATTRIBUTE_NAME AS ATTRIBUTE,
       A.G1_Attribute_Value AS VALUE
  FROM G3CONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_CFG_WORKFLOW] 
AS
SELECT
  B.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Workflow Configuration Info
  ,A.DISPLAY_IN_ACA                 AS STATUS_ACA_DISPLAY
  ,A.APPLICATION_STATUS             AS STATUS_APP_STATUS
  ,A.R3_MOU_CLOCK_ACTION            AS STATUS_CLOCK_ACTION
  ,(  CASE A.R3_ACT_STAT_FLG
        WHEN N'U'  THEN N'No Change'
        WHEN N'L'  THEN N'Go To Loop Task'
        WHEN N'B'  THEN N'Go To Branch Task'
        WHEN N'Y'  THEN N'Go To Next Task'
      END
  )                                 AS STATUS_FLOW_CONTROL
  ,A.R3_ACT_STAT_DES                AS STATUS_NAME 
  ,ISNULL(NULLIF(N.SD_PRO_DES,N''),N'N/A')   
                                    AS STATUS_NEXT_TASK 
--STATUS_NEXT_TASKNBR#
  ,(  CASE A.R3_ACT_STAT_FLG
        WHEN N'U'  THEN N'N/A'
        WHEN N'L'  THEN SUBSTRING(B.SD_NXT_ID1,10,3)
        WHEN N'B'  THEN SUBSTRING(B.SD_NXT_ID1,4,3)
        WHEN N'Y'  THEN SUBSTRING(B.SD_NXT_ID1,1,3)
      END
  )                                 AS STATUS_NEXT_TASKNBR#
  ,A.PARENT_STATUS                  AS STATUS_PARENT_STATUS
    --SUBPROCESS_COMPL_REQD
  ,B.DISPLAY_IN_ACA                 AS TASK_ACA_DISPLAY
  ,B.CALENDAR_ID                    AS TASK_CALENDAR_ID
  ,D1.R3_DEPTNAME                   AS TASK_DEPARTMENT
  ,B.SD_DUE_DAY                     AS TASK_DURATION_DAYS
  ,B.ESTIMATED_HOURS                AS TASK_ESTIMATED_HRS
  ,B.HOURS_SPENT_REQUIRED           AS TASK_HRS_SPENT_REQD
  ,B.SD_PRO_DES                     AS TASK_NAME
  ,SUBSTRING(B.SD_PRO_ID1,1,3)      AS TASK_NBR
  ,B.SD_NXT_ID1                     AS TASK_NEXT_NUMBER
  ,(  select  top 1 substring(q.sd_pro_id1,1,3)
      from    sprocess q
      where   q.serv_prov_code=B.SERV_PROV_CODE
              and q.r1_process_code=B.R1_PROCESS_CODE
              and substring(q.sd_pro_id1,1,3)=SUBSTRING(B.SD_PRO_ID1,1,3)
              and q.sd_stp_num <> B.SD_STP_NUM
  )                                 AS TASK_PARALLEL_NBR#
  ,B.SD_PRO_ID1                     AS TASK_PHASE_NUMBER
--TASK_STAFF_USERID# - Pull first match by name, priority to active user
  ,(  select  top 1 p.user_name
      from    puser p
      where   p.serv_prov_code=B.SERV_PROV_CODE
              and p.fname=B.ASGN_FNAME
              and p.lname=B.ASGN_LNAME
              and (
                nullif(p.mname,N'') is null AND NULLIF(B.ASGN_MNAME,N'') IS NULL
                  or
                p.mname=B.ASGN_MNAME
              )
              and p.user_name not like N'PUBLICUSER%'
      order by p.rec_status
  )                                 AS TASK_STAFF_USERID#
  ,B.ASGN_FNAME                     AS TASK_STAFFNAME_F 
  --TASK_STAFFNAME_FML#
  ,LTRIM(  ISNULL(B.ASGN_FNAME,N'')+N' '+
          (CASE WHEN NULLIF(B.ASGN_MNAME,N'') IS NOT NULL THEN B.ASGN_MNAME+N' ' ELSE N'' END)+
          ISNULL(B.ASGN_LNAME,N'')
  )                                 AS TASK_STAFFNAME_FML#
  ,B.ASGN_LNAME                     AS TASK_STAFFNAME_L  
  ,B.ASGN_MNAME                     AS TASK_STAFFNAME_M
  ,B.SD_APP_DES                     AS TASK_STATUS_INITIAL
  --TASK_SUBPROCESS# - name of subprocess attached to this task
  ,(  select  top 1 q.r1_process_code
      from    sprocess_group q
      where   q.serv_prov_code=B.SERV_PROV_CODE
              and q.sprocess_group_code=B.R1_PROCESS_CODE
              and q.sd_stp_num=B.SD_STP_NUM
  )                                 AS TASK_SUBPROCESS#
  ,B.R1_CHECKBOX_CODE               AS TASK_TSI_GROUP
  --WF_INPROCESS_ACTIV#
  ,(  select  TOP 1 (case when q.task_activation=N'A' then N'Enable' else N'Disable' end)
      from    sprocess_group q
      where   q.serv_prov_code=B.SERV_PROV_CODE
              and q.r1_process_code=B.R1_PROCESS_CODE
  )                                 AS WF_INPROCESS_ACTIV#
  --WF_IS_SUBPROCESS#
  ,(  select  (case when count(*)>0 then N'Y' else N'N' end)
      from    sprocess_group q
      where   q.serv_prov_code=B.SERV_PROV_CODE
              and q.r1_process_code=B.R1_PROCESS_CODE
              and q.sd_stp_num<>0
  )                                 AS WF_IS_SUBPROCESS#
  ,B.R1_PROCESS_CODE                AS WF_WORKFLOW_NAME
FROM
  SPROCESS B
  --Task
  LEFT JOIN
  R3STATYP A
   --Status
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE
    AND A.R3_PROCESS_CODE = B.R1_PROCESS_CODE 
    and A.R3_ACT_TYPE_DES = B.SD_PRO_DES
  LEFT JOIN
  SPROCESS N
 --Next Task
    ON  B.SERV_PROV_CODE = N.SERV_PROV_CODE
    AND B.R1_PROCESS_CODE = N.R1_PROCESS_CODE 
    AND (
      CASE A.R3_ACT_STAT_FLG
        WHEN N'U'  THEN N'N/A'
        WHEN N'L'  THEN SUBSTRING(B.SD_NXT_ID1,10,3)
        WHEN N'B'  THEN SUBSTRING(B.SD_NXT_ID1,4,3)
        WHEN N'Y'  THEN SUBSTRING(B.SD_NXT_ID1,1,3)
      END
    ) = SUBSTRING(N.SD_PRO_ID1,1,3)
  LEFT JOIN
  G3DPTTYP D1 
--Assigned Dept
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE 
    AND B.ASGN_AGENCY_CODE = D1.R3_AGENCY_CODE 
    AND B.ASGN_BUREAU_CODE = D1.R3_BUREAU_CODE 
    AND B.ASGN_DIVISION_CODE = D1.R3_DIVISION_CODE 
    AND B.ASGN_SECTION_CODE = D1.R3_SECTION_CODE 
    AND B.ASGN_GROUP_CODE = D1.R3_GROUP_CODE 
    AND B.ASGN_OFFICE_CODE = D1.R3_OFFICE_CODE
WHERE
  B.REC_STATUS=N'A'
  AND A.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[V_USER] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,A.REC_FUL_NAM                    AS UPDATED_BY
  ,A.REC_DATE                       AS UPDATED_DATE
--=== User/Staff Info  
  ,A.ACCOUNT_DISABLE_PERIOD         AS ACCOUNT_TIMEFRAME
  ,P5.PROFILE_VALUE                 AS BILLING_RATE
  ,A.DAILY_INSP_UNITS               AS DAILY_INSP_UNITS
  ,A.LAST_LOGIN_TIME                AS DATE_LAST_LOGIN
  ,A.LAST_CHANGE_PASSWORD           AS DATE_PWORD_CHANGED
  ,P3.PROFILE_VALUE                 AS DEFAULT_MODULE
  ,D1.R3_DEPTNAME                   AS DEPARTMENT
  ,B.GA_EMAIL                       AS EMAIL
  ,A.EMPLOYEE_ID                    AS EMPLOYEE_IDENT
  ,A.INTEGRATED_FLAG                AS EXTERNAL_USER
  ,B.GA_INITIAL                     AS INITIALS
  ,P23.PROFILE_VALUE                AS INITIALS_IN_ACA
  ,( CASE INSPECTOR_STATUS WHEN N'Y' THEN N'ENABLE' WHEN N'N' THEN N'DISABLE' ELSE NULL END )
                                    AS INSPECTOR_STATUS
  ,B.GA_IVR_SEQ                     AS IVR_USER_NBR
  ,A.DISTINGUISH_NAME               AS NAME_DISTINGUISHED
  ,A.FNAME                          AS NAME_FIRST
 --NAME_FML#
  ,(  ISNULL(B.GA_FNAME,N'')+N' '+
      (CASE WHEN NULLIF(B.GA_MNAME,N'') IS NOT NULL THEN B.GA_MNAME+N' ' ELSE N'' END)+
      ISNULL(B.GA_LNAME,N'')
  )                                 AS NAME_FML#
  ,A.LNAME                          AS NAME_LAST
  ,A.MNAME                          AS NAME_MIDDLE
  ,( CASE A.ALLOW_USER_CHANGE_PASSWORD WHEN N'Y' THEN N'User' WHEN N'N' THEN N'Administrator' ELSE NULL END )                                  AS PASSWORD_CHANGE_ALLOW
  ,A.LAST_CHANGE_PASSWORD           AS PASSWORD_LAST_CHANGED
  ,A.PASSWORD_EXPIRE_TIMEFRAME      AS PASSWORD_TIMEFRAME
  ,B.GA_EMPLOY_PH1                  AS PHONE
  ,( CASE WHEN A.USER_NAME LIKE N'PUBLICUSER%' THEN N'Y' ELSE N'N' END )
                                    AS PUBLIC_USER
  ,A.SECTION_508_FLAG               AS SECTION_508_SUPPORT
  ,A.STATUS                         AS STATUS
  ,B.GA_TITLE                       AS TITLE
  ,A.USER_NAME                      AS USER_ID
FROM    
  dbo.PUSER A   
  JOIN  
  dbo.G3STAFFS B    
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE   
    AND A.GA_USER_ID = B.GA_USER_ID   
  LEFT JOIN 
  dbo.G3DPTTYP D1 
  -- Dept   
    ON  B.SERV_PROV_CODE = D1.SERV_PROV_CODE    
    AND B.GA_AGENCY_CODE = D1.R3_AGENCY_CODE    
    AND B.GA_BUREAU_CODE = D1.R3_BUREAU_CODE    
    AND B.GA_DIVISION_CODE = D1.R3_DIVISION_CODE  
    AND B.GA_SECTION_CODE = D1.R3_SECTION_CODE    
    AND B.GA_GROUP_CODE = D1.R3_GROUP_CODE  
    AND B.GA_OFFICE_CODE = D1.R3_OFFICE_CODE    
  LEFT JOIN 
  dbo.PUSER_PROFILE P3 
  --Default Module 
    ON  A.SERV_PROV_CODE = P3.SERV_PROV_CODE  
    AND A.USER_NAME = P3.USER_NAME    
    AND P3.PROFILE_SEQ_NBR = 3    
  LEFT JOIN 
  dbo.PUSER_PROFILE P5 
  --Billing Rate   
    ON  A.SERV_PROV_CODE = P5.SERV_PROV_CODE  
    AND A.USER_NAME = P5.USER_NAME    
    AND P5.PROFILE_SEQ_NBR = 5    
  LEFT JOIN 
  dbo.PUSER_PROFILE P23 
  --Initials in ACA   
    ON  A.SERV_PROV_CODE = P23.SERV_PROV_CODE 
    AND A.USER_NAME = P23.USER_NAME   
    AND P23.PROFILE_SEQ_NBR = 23
GO

ALTER VIEW [dbo].[V_USER_N_GROUP] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== User and User Group Info  
  ,A.EMPLOYEE_ID                    AS EMPLOYEE_IDENT
  ,D1.R3_DEPTNAME                   AS USER_DEPARTMENT
  ,A.DISP_NAME                      AS USER_DISPLAY_NAME
  ,A.DISTINGUISH_NAME               AS USER_DISTINGUI_NAME
  ,C.DISP_TEXT                      AS USER_GROUP 
  ,C.DESC_TEXT                      AS USER_GROUP_DESC
  ,C.GROUP_SEQ_NBR                  AS USER_GROUP_ID
  ,B.MODULE_NAME                    AS USER_GROUP_MODULE
  ,C.STATUS                         AS USER_GROUP_STATUS
  ,A.USER_NAME                      AS USER_ID
  ,A.FNAME                          AS USER_NAME_F
  ,(  isnull(A.FNAME,N'')+N' '+
      (CASE WHEN NULLIF(A.MNAME,N'') IS NOT NULL THEN A.MNAME+N' ' ELSE N'' END)+
      isnull(A.LNAME,N'')
  )                                 AS USER_NAME_FML#
  ,A.LNAME                          AS USER_NAME_L
  ,A.MNAME                          AS USER_NAME_M
  ,A.STATUS                         AS USER_STATUS
  ,S.GA_TITLE                       AS USER_TITLE
FROM    
  dbo.PUSER A   
  JOIN  
  dbo.PUSER_GROUP B 
    ON  A.SERV_PROV_CODE = B.SERV_PROV_CODE     
    AND A.USER_NAME = B.USER_NAME   
  JOIN  
  dbo.PPROV_GROUP C 
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE     
    AND B.GROUP_SEQ_NBR = C.GROUP_SEQ_NBR   
  JOIN  
  dbo.G3STAFFS S    
    ON  A.SERV_PROV_CODE = S.SERV_PROV_CODE 
    AND A.GA_USER_ID = S.GA_USER_ID 
  LEFT JOIN 
  dbo.G3DPTTYP D1 
  --User Dept   
    ON  S.SERV_PROV_CODE = D1.SERV_PROV_CODE    
    AND S.GA_AGENCY_CODE = D1.R3_AGENCY_CODE    
    AND S.GA_BUREAU_CODE = D1.R3_BUREAU_CODE    
    AND S.GA_DIVISION_CODE = D1.R3_DIVISION_CODE    
    AND S.GA_SECTION_CODE = D1.R3_SECTION_CODE  
    AND S.GA_GROUP_CODE = D1.R3_GROUP_CODE  
    AND S.GA_OFFICE_CODE = D1.R3_OFFICE_CODE
GO

ALTER VIEW [dbo].[G3STAFFS_VIEW_EN_US] AS 
SELECT T.*, 
       I.GA_FNAME GA_FNAME_V, 
       I.GA_INITIAL GA_INITIAL_V, 
       I.GA_LNAME GA_LNAME_V, 
       I.GA_MNAME GA_MNAME_V, 
       I.LANG_ID LANG_ID_V
  FROM      G3STAFFS T 
  LEFT JOIN G3STAFFS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[G6COMMNT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G6_COMMENT G6_COMMENT_V
  FROM      G6COMMNT T 
  LEFT JOIN G6COMMNT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[G7VOTE_DECISION_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.VOTE_DECISION VOTE_DECISION_V
  FROM      G7VOTE_DECISION T 
  LEFT JOIN G7VOTE_DECISION_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GACTIVITY_TYPE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.ACTIVITY_TYPE ACTIVITY_TYPE_V
  FROM      GACTIVITY_TYPE T 
  LEFT JOIN GACTIVITY_TYPE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_ASSET] 
AS
SELECT
--=== Row Update Info
       C.REC_DATE AS UPDATED_DATE
       ,C.REC_FUL_NAM AS UPDATED_BY
--=== Asset Parts
       ,C.SERV_PROV_CODE AS AGENCY_ID
       ,C.G1_ASSET_SEQ_NBR AS ASSET_SEQ_NBR
       ,C.G1_ASSET_ID AS ASSET_ID
       ,C.G1_ASSET_NAME AS ASSET_NAME
       ,C.G1_ASSET_GROUP AS ASSET_GROUP
       ,C.G1_ASSET_TYPE AS ASSET_TYPE
       ,C.G1_DESCRIPTION AS DESCRIPTION
       ,C.G1_ASSET_STATUS AS ASSET_STATUS
       ,C.G1_ASSET_STATUS_DATE AS ASSET_STATUS_DATE
       ,C.G1_COMMENTS AS COMMENTS
       ,C.REC_STATUS AS STATUS
       ,C.START_VALUE AS START_VALUE
       ,C.DATE_OF_SERVICE AS  DATE_OF_SERVICE
       ,C.USEFUL_LIFE AS USEFUL_LIFE
       ,C.SALVAGE_VALUE AS SALVAGE_VALUE
       ,C.CURRENT_VALUE AS CURRENT_VALUE
       ,C.DEPRECIATION_START_DATE AS DEPRECIATION_START_DATE
       ,C.DEPRECIATION_END_DATE AS DEPRECIATION_END_DATE
       ,C.DEPRECIATION_AMOUNT AS DEPRECIATION_AMOUNT
       ,C.DEPRECIATION_VALUE AS DEPRECIATION_VALUE
       ,C.G1_CLASS_TYPE AS CLASS_TYPE
       ,C.ASSET_ID_START AS START_POINT_OF_ASSET_ID
       ,C.ASSET_ID_END AS END_POINT_OF_ASSET_ID
       ,C.G1_DEPENDENCIES_FLAG AS DEPENDENCIES_FLAG
       ,C.G1_ASSET_SIZE AS ASSET_SIZE
       ,C.G1_ASSET_SIZE_UNIT AS ASSET_UNIT_SIZE
        ,D.G1_ASSET_GROUP+CASE WHEN D.G1_ASSET_GROUP IS NULL THEN N'' ELSE N'/' END+D.G1_ASSET_TYPE+CASE WHEN D.G1_ASSET_TYPE IS NULL THEN N'' ELSE N'/' END+D.G1_ASSET_ID AS PARENT_ASSET_ID
       ,(
       SELECT SUM(E.DISTRIBUTION_COST)
       FROM DBO.GCOST_DISTRIBUTION_HISTORY E
       WHERE E.REC_STATUS=N'A'
       AND E.SERV_PROV_CODE=C.SERV_PROV_CODE
       AND E.G1_ASSET_SEQ_NBR=C.G1_ASSET_SEQ_NBR
       GROUP BY E.SERV_PROV_CODE,E.G1_ASSET_SEQ_NBR
       ) AS COST_LTD,
       -- column to support build relation with Templates.
       CAST(C.G1_ASSET_SEQ_NBR AS CHAR) AS TEMPLATE_ID
	   ,CAST(C.G1_ASSET_SEQ_NBR AS CHAR) AS T_ID1
       FROM  
    (
    SELECT A.SERV_PROV_CODE,A.G1_ASSET_SEQ_NBR,A.G1_ASSET_ID,A.G1_ASSET_GROUP,A.G1_ASSET_TYPE,A.G1_DESCRIPTION,A.G1_ASSET_STATUS,A.G1_ASSET_STATUS_DATE,
           A.G1_COMMENTS,A.REC_STATUS,A.START_VALUE,A.DATE_OF_SERVICE,A.USEFUL_LIFE,A.SALVAGE_VALUE,A.CURRENT_VALUE,A.DEPRECIATION_START_DATE,A.DEPRECIATION_END_DATE,
           A.DEPRECIATION_AMOUNT,A.DEPRECIATION_VALUE,A.G1_CLASS_TYPE,A.ASSET_ID_START,A.ASSET_ID_END,A.G1_DEPENDENCIES_FLAG,G1_ASSET_SIZE,A.G1_ASSET_SIZE_UNIT,
           A.G1_ASSET_NAME,A.REC_DATE,A.REC_FUL_NAM,B.G1_ASSET_SEQ_NBR1   
      FROM DBO.GASSET_MASTER A
      LEFT JOIN DBO.GASSET_ASSET B
      ON A.SERV_PROV_CODE=B.SERV_PROV_CODE
      AND A.G1_ASSET_SEQ_NBR=B.G1_ASSET_SEQ_NBR2 
      AND B.REC_STATUS=N'A'
      WHERE A.REC_STATUS=N'A'
    ) C
    LEFT JOIN
    DBO.GASSET_MASTER D
    ON C.SERV_PROV_CODE=D.SERV_PROV_CODE
    AND C.G1_ASSET_SEQ_NBR1=D.G1_ASSET_SEQ_NBR
    AND D.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[GASSET_ATTRIBUTE_VIEW_EN_US] AS 
SELECT T.*, 
       I.G1_ATTRIBUTE_NAME G1_ATTRIBUTE_NAME_V, 
       I.G1_ATTRIBUTE_VALUE G1_ATTRIBUTE_VALUE_V, 
       I.LANG_ID LANG_ID_V
  FROM      GASSET_ATTRIBUTE T 
  LEFT JOIN GASSET_ATTRIBUTE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_ASSET_TEMPLATE_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
                cast(A.G1_ASSET_SEQ_NBR as NVARCHAR) AS ID,
                N'ASSET_TPL' + N'::' + RT.R1_ASSET_TEMPLATE_ID AS ENTITY,
                B.G1_ATTRIBUTE_NAME AS ATTRIBUTE,
                B.G1_ATTRIBUTE_VALUE AS VALUE
  FROM RASSET_TYPE RT, GASSET_MASTER A
 INNER JOIN GASSET_ATTRIBUTE B ON A.SERV_PROV_CODE = B.SERV_PROV_CODE AND A.G1_ASSET_SEQ_NBR = B.G1_ASSET_SEQ_NBR
 WHERE A.G1_ASSET_GROUP = RT.R1_ASSET_GROUP AND A.G1_ASSET_TYPE = RT.R1_ASSET_TYPE
 AND A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[GASSET_ATTRIBUTE_TAB_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G1_ATTR_VALUE G1_ATTR_VALUE_V, 
       I.G1_ATTR_NAME G1_ATTR_NAME_V
  FROM      GASSET_ATTRIBUTE_TAB T 
  LEFT JOIN GASSET_ATTRIBUTE_TAB_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GASSET_CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G1_CON_DES G1_CON_DES_V, 
       I.G1_CON_COMMENT G1_CON_COMMENT_V, 
       I.G1_CON_LONG_COMMENT G1_CON_LONG_COMMENT_V
  FROM      GASSET_CONDIT T 
  LEFT JOIN GASSET_CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GASSET_MASTER_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G1_DESCRIPTION G1_DESCRIPTION_V, 
       I.G1_COMMENTS G1_COMMENTS_V, 
       I.G1_ASSET_NAME G1_ASSET_NAME_V
  FROM      GASSET_MASTER T 
  LEFT JOIN GASSET_MASTER_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GCALENDAR_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CAL_NAME CAL_NAME_V, 
       I.CAL_SUMMARY CAL_SUMMARY_V, 
       I.CAL_SUBJECT CAL_SUBJECT_V
  FROM      GCALENDAR T 
  LEFT JOIN GCALENDAR_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GCALENDAR_DETAIL_VIEW_EN_US] AS 
SELECT T.*, 
       I.COMMENTS COMMENTS_V, 
       I.LANG_ID LANG_ID_V, 
       I.STATUS STATUS_V
  FROM      GCALENDAR_DETAIL T 
  LEFT JOIN GCALENDAR_DETAIL_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GDATAFILTER_VIEW_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.DATAFILTER_NAME DATAFILTER_NAME_V
  FROM      GDATAFILTER_VIEW T 
  LEFT JOIN GDATAFILTER_VIEW_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GFILTER_SCREEN_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SCREEN_LABEL SCREEN_LABEL_V
  FROM      GFILTER_SCREEN T 
  LEFT JOIN GFILTER_SCREEN_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GFILTER_SCREEN_ELEMENT_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SCREEN_ELEMENT_LABEL SCREEN_ELEMENT_LABEL_V, 
       I.SCREEN_ELEMENT_MARKLABEL SCREEN_ELEMENT_MARKLABEL_V
  FROM      GFILTER_SCREEN_ELEMENT T 
  LEFT JOIN GFILTER_SCREEN_ELEMENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GFILTER_VIEW_VIEW_EN_US] AS 
SELECT T.*, 
       I.CONTENT_TEXT CONTENT_TEXT_V, 
       I.LANG_ID LANG_ID_V
  FROM      GFILTER_VIEW T 
  LEFT JOIN GFILTER_VIEW_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GFILTER_VIEW_ELEMENT_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.LABEL_ID LABEL_ID_V
  FROM      GFILTER_VIEW_ELEMENT T 
  LEFT JOIN GFILTER_VIEW_ELEMENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_GUIDESHEET_TEMPLATE_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       CONVERT(NVARCHAR, A.GUIDESHEET_SEQ_NBR) + N'/' + CONVERT(NVARCHAR, A.GUIDEITEM_SEQ_NBR) AS ID,
       N'GUIDESHEET_TPL::' + A.ASI_GRP_NAM + N'::' + A.ASI_SUBGRP_NAM AS ENTITY,
       A.ASI_NAME ATTRIBUTE,
       (CASE WHEN ISNULL(A.G1_ATTRIBUTE_VALUE,N'')<>N'' THEN A.G1_ATTRIBUTE_VALUE + N' ' + A.ASI_COMMENT 
       ELSE A.ASI_COMMENT END ) AS VALUE
  FROM GGDSHEET_ITEM_ASI A 
 --WHERE A.REC_STATUS = 'A'
)
GO

ALTER VIEW [dbo].[V_GUIDESHEET] 
AS
SELECT
  B.SERV_PROV_CODE                      AS AGENCY_ID
--=== Row Update Info  
  ,C.REC_FUL_NAM                        AS UPDATED_BY
  ,C.REC_DATE                           AS UPDATED_DATE
--=== Guidesheet and Guide Item Info
  ,B.GUIDESHEET_ID                      AS GUIDESHEET_IDENT
  ,B.GUIDE_TYPE                         AS GUIDESHEET_NAME
  ,B.G6_ACT_NUM                         AS INSPECTION_ID
  ,C.GUIDE_ITEM_COMMENT                 AS ITEM_COMMENT
  ,C.GUIDE_ITEM_DISPLAY_ORDER           AS ITEM_DISPLAY_ORDER
  ,C.GUIDE_ITEM_SEQ_NBR                 AS ITEM_ID
  ,C.MAJOR_VIOLATION                    AS ITEM_MAJOR_VIOL
  ,C.MAX_POINTS                         AS ITEM_MAX_POINTS
  ,C.GUIDE_ITEM_SCORE                   AS ITEM_SCORE
  ,C.GUIDE_ITEM_STATUS                  AS ITEM_STATUS
  ,C.GUIDE_ITEM_TEXT                    AS ITEM_TEXT
  --- column to support build relation with Templates.
  ,CONVERT(NVARCHAR, C.GUIDESHEET_SEQ_NBR) + N'/' +  CONVERT(NVARCHAR, C.GUIDE_ITEM_SEQ_NBR) AS TEMPLATE_ID
  ,CONVERT(NVARCHAR, C.GUIDESHEET_SEQ_NBR) AS T_ID1
  ,CONVERT(NVARCHAR, C.GUIDE_ITEM_SEQ_NBR) AS T_ID2
FROM
  GGUIDESHEET B
  JOIN
  GGUIDESHEET_ITEM C
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE 
    AND B.GUIDESHEET_SEQ_NBR = C.GUIDESHEET_SEQ_NBR
GO

ALTER VIEW [dbo].[GMESSAGE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.MESSAGE_TEXT MESSAGE_TEXT_V, 
       I.MESSAGE_TITLE MESSAGE_TITLE_V
  FROM      GMESSAGE T 
  LEFT JOIN GMESSAGE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GPART_TRANSACTION_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PART_BRAND PART_BRAND_V, 
       I.PART_DESCRIPTION PART_DESCRIPTION_V
  FROM      GPART_TRANSACTION T 
  LEFT JOIN GPART_TRANSACTION_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GPM_SCHEDULE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SCHEDULE_NAME SCHEDULE_NAME_V, 
       I.COMMENTS COMMENTS_V
  FROM      GPM_SCHEDULE T 
  LEFT JOIN GPM_SCHEDULE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GPORTLET_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PORTLET_DES PORTLET_DES_V
  FROM      GPORTLET T 
  LEFT JOIN GPORTLET_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GPROCESS_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SD_APP_DES SD_APP_DES_V, 
       I.SD_COMMENT SD_COMMENT_V, 
       I.SD_PRO_DES SD_PRO_DES_V
  FROM      GPROCESS T 
  LEFT JOIN GPROCESS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[GPROCESS_HISTORY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SD_APP_DES SD_APP_DES_V, 
       I.SD_COMMENT SD_COMMENT_V, 
       I.SD_PRO_DES SD_PRO_DES_V
  FROM      GPROCESS_HISTORY T 
  LEFT JOIN GPROCESS_HISTORY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_TSI_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 + N'/' + CONVERT(NVARCHAR, A.RELATION_SEQ_ID) + N'/' + CONVERT(NVARCHAR, A.SD_STP_NUM) AS ID,
       N'TSI::' + A.B1_ACT_STATUS + N'::' + A.B1_CHECKBOX_TYPE AS ENTITY,
       A.B1_CHECKBOX_DESC AS ATTRIBUTE,
       A.B1_CHECKLIST_COMMENT AS VALUE
  FROM GPROCESS_SPEC_INFO A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[GSTRUCTURE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G1_STRUCTURE_NAME G1_STRUCTURE_NAME_V
  FROM      GSTRUCTURE T 
  LEFT JOIN GSTRUCTURE_I18N I
    ON T.SOURCE_SEQ_NBR = I.SOURCE_SEQ_NBR
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_CONDITION_RECORD_TPL_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
         A.ENTITY_KEY1 + N'/' + A.ENTITY_KEY2 + N'/' + A.ENTITY_KEY3 + N'/' + CONVERT(NVARCHAR, A.ENTITY_SEQ1) AS ID,
         N'RECORD_COND_TPL::' + A.GROUP_CODE AS ENTITY,
         A.FIELD_NAME AS ATTRIBUTE,
         A.FIELD_VALUE AS VALUE
  FROM GTMPL_ATTRIBUTE A
 WHERE (A.ENTITY_TYPE = 11)
   AND A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_STD_CONDITION_TPL_ATTR] 
AS
(
SELECT DISTINCT A.SERV_PROV_CODE AS AGENCY_ID,
               N'STD_COND_TPL::' + A.R1_CHECKBOX_CODE AS ENTITY,
                R3.R3_CON_TYPE AS CONDITION_TYPE,
                R3.R3_CON_GROUP AS CONDITION_GROUP,
                A.R1_CHECKBOX_DESC AS ATTRIBUTE,
                NULL AS TYPE
  FROM R3CLEART R3, R2CHCKBOX A
 INNER JOIN GTMPL_ATTRIBUTE B ON A.SERV_PROV_CODE = B.SERV_PROV_CODE
                             AND A.R1_CHECKBOX_CODE = B.GROUP_CODE
 WHERE (B.ENTITY_TYPE = 2)
   AND A.R1_CHECKBOX_GROUP = N'APPLICATION'
   AND A.SERV_PROV_CODE = R3.SERV_PROV_CODE
   AND A.REC_STATUS = N'A' AND R3.R3_CON_NBR = B.ENTITY_SEQ1
)
GO

ALTER VIEW [dbo].[V_STD_CONDITION_TPL_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
         CONVERT(NVARCHAR, A.ENTITY_SEQ1) AS ID,
         N'STD_COND_TPL::' + A.GROUP_CODE AS ENTITY,
         A.FIELD_NAME AS ATTRIBUTE,
         A.FIELD_VALUE AS VALUE
  FROM GTMPL_ATTRIBUTE A
 WHERE (A.ENTITY_TYPE = 2)
   AND A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[GVALUATN_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G3_USE_TYP G3_USE_TYP_V, 
       I.G3_CON_TYP G3_CON_TYP_V, 
       I.G3_UNIT_TYPE G3_UNIT_TYPE_V, 
       I.VALUATN_VERSION VALUATN_VERSION_V
  FROM      GVALUATN T 
  LEFT JOIN GVALUATN_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[L1CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_CON_DES L1_CON_DES_V, 
       I.L1_CON_COMMENT L1_CON_COMMENT_V, 
       I.L1_CON_LONG_COMMENT L1_CON_LONG_COMMENT_V
  FROM      L1CONDIT T 
  LEFT JOIN L1CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[L3ADDRES_CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_CON_DES L1_CON_DES_V, 
       I.L1_CON_COMMENT L1_CON_COMMENT_V, 
       I.L1_CON_LONG_COMMENT L1_CON_LONG_COMMENT_V
  FROM      L3ADDRES_CONDIT T 
  LEFT JOIN L3ADDRES_CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[L3CAE_CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_CON_DES L1_CON_DES_V, 
       I.L1_CON_COMMENT L1_CON_COMMENT_V, 
       I.L1_CON_LONG_COMMENT L1_CON_LONG_COMMENT_V
  FROM      L3CAE_CONDIT T 
  LEFT JOIN L3CAE_CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[L3COMMON_CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_CON_COMMENT L1_CON_COMMENT_V, 
       I.L1_CON_DES L1_CON_DES_V, 
       I.L1_CON_LONG_COMMENT L1_CON_LONG_COMMENT_V
  FROM      L3COMMON_CONDIT T 
  LEFT JOIN L3COMMON_CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[L3OWNER_CONDIT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_CON_DES L1_CON_DES_V, 
       I.L1_CON_COMMENT L1_CON_COMMENT_V, 
       I.L1_CON_LONG_COMMENT L1_CON_LONG_COMMENT_V
  FROM      L3OWNER_CONDIT T 
  LEFT JOIN L3OWNER_CONDIT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_REF_PARCEL] 
AS
SELECT
  A.SERV_PROV_CODE              AS AGENCY_ID
--=== Row Update Info  
  ,B.REC_FUL_NAM                AS UPDATED_BY
  ,B.REC_DATE                   AS UPDATED_DATE  
--=== Ref Pracel Info  
  ,B.L1_PARCEL_NBR              AS APN
  ,B.L1_GIS_SEQ_NBR             AS GIS_SEQ_NBR
  ,B.L1_BOOK                    AS BOOK
  ,B.L1_PAGE                    AS PAGE
  ,B.L1_PARCEL                  AS PARCEL
  ,B.L1_LOT                     AS LOT
  ,B.L1_BLOCK                   AS BLOCK
  ,B.L1_LEGAL_DESC              AS LEGAL_DESCRIPTION
  ,B.L1_MAP_NBR                 AS MAP_GRID
  ,B.L1_MAP_REF                 AS MAP_REFERENCE
  ,B.L1_PARCEL_AREA             AS AREA_PARCEL
  ,B.L1_PLAN_AREA               AS AREA_PLAN
  ,B.L1_CENSUS_TRACT            AS CENSUS_TRACT
  ,B.L1_COUNCIL_DISTRICT        AS DISTRICT_COUNCIL
  ,B.L1_INSPECTION_DISTRICT     AS DISTRICT_INSPECTION
  ,B.L1_SUPERVISOR_DISTRICT     AS DISTRICT_SUPERVISOR
  ,B.L1_PARCEL_NBR              AS PARCEL_REF_ID
  ,COALESCE(B.L1_PRIMARY_PAR_FLG,N'N')
                                AS PRIMARY_
  ,B.L1_RANGE                   AS RANGE_
  ,B.L1_SECTION                 AS SECTION_
  ,B.L1_SUBDIVISION             AS SUBDIVISION
  ,B.L1_TOWNSHIP                AS TOWNSHIP
  ,B.L1_TRACT                   AS TRACT
  ,B.L1_EXEMPT_VALUE            AS VALUE_EXEMPT
  ,B.L1_IMPROVED_VALUE          AS VALUE_IMPROVED
  ,B.L1_LAND_VALUE              AS VALUE_LAND
---- column to support build relation with Templates.  
  ,CONVERT(NVARCHAR, B.L1_PARCEL_NBR)   AS TEMPLATE_ID
  ,CONVERT(NVARCHAR, B.L1_PARCEL_NBR)   AS T_ID1
FROM
  L3PARCEL B
INNER JOIN RSERV_PROV A ON A.APO_SRC_SEQ_NBR = B.SOURCE_SEQ_NBR
WHERE
  B.L1_PARCEL_STATUS=N'A'
GO

ALTER VIEW [dbo].[L3STRU_ESTA_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_NAME L1_NAME_V, 
       I.L1_DESCRIPTION L1_DESCRIPTION_V
  FROM      L3STRU_ESTA T 
  LEFT JOIN L3STRU_ESTA_I18N I
    ON T.SOURCE_SEQ_NBR = I.SOURCE_SEQ_NBR
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[L3STRU_ESTA_TYPE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_TYPE R1_TYPE_V, 
       I.R1_STRU_ESTA_DESC R1_STRU_ESTA_DESC_V
  FROM      L3STRU_ESTA_TYPE T 
  LEFT JOIN L3STRU_ESTA_TYPE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[LSTRU_ESTA_ATTRIBUTE_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.L1_ATTRIBUTE_VALUE L1_ATTRIBUTE_VALUE_V
  FROM      LSTRU_ESTA_ATTRIBUTE T 
  LEFT JOIN LSTRU_ESTA_ATTRIBUTE_I18N I
    ON T.SOURCE_SEQ_NBR = I.SOURCE_SEQ_NBR
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_USER_GROUP_FID] 
AS
SELECT
--=== Record Info
  A.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,X.REC_FUL_NAM                    AS UPDATED_BY
  ,X.REC_DATE                       AS UPDATED_DATE
--=== User Group and FID Info  
  ,X.EDIT_STAT                      AS ACCESS_FULL
  ,(CASE WHEN X.EDIT_STAT=N'N' AND X.READ_STAT=N'Y' THEN N'Y' ELSE N'N' END)
                                    AS ACCESS_READ_ONLY
  ,C.MENUITEM_CODE                  AS FID
  ,C.FUNCTION_CATEGORY              AS FUNCTION_CATEGORY
  ,C.FUNCTION_GROUP                 AS FUNCTION_GROUP
  ,C.FUNCTION_NAME                  AS FUNCTION_NAME
  ,C.FUNCTION_SUBTYPE               AS FUNCTION_SUBTYPE
  ,C.FUNCTION_TYPE                  AS FUNCTION_TYPE
  ,C.FUNCTION_VERSION               AS FUNCTION_VERSION
  ,A.DISP_TEXT                      AS USER_GROUP 
  ,A.DESC_TEXT                      AS USER_GROUP_DESC
  ,A.GROUP_SEQ_NBR                  AS USER_GROUP_ID
  ,A.MODULE_NAME                    AS USER_GROUP_MODULE  
  ,A.STATUS                         AS USER_GROUP_STATUS
FROM    
  dbo.PPROV_GROUP A     
  JOIN  
  dbo.XGROUP_MENUITEM_MODULE X  
    ON  A.SERV_PROV_CODE = X.SERV_PROV_CODE     
    AND A.GROUP_SEQ_NBR = X.GROUP_SEQ_NBR   
  JOIN  
  dbo.RMENUITEM C   
    ON  X.MENUITEM_CODE = C.MENUITEM_CODE   
WHERE   
  X.READ_STAT=N'Y' 
  --If group has Full or Read-Only access, READ_STAT='Y'
GO

ALTER VIEW [dbo].[R1_EXPIRATION_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.EXPIRATION_CODE EXPIRATION_CODE_V
  FROM      R1_EXPIRATION T 
  LEFT JOIN R1_EXPIRATION_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R1_TIME_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.TIME_GROUP_NAME TIME_GROUP_NAME_V
  FROM      R1_TIME_GROUP T 
  LEFT JOIN R1_TIME_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R1_TIME_TYPES_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.TIME_TYPE_NAME TIME_TYPE_NAME_V
  FROM      R1_TIME_TYPES T 
  LEFT JOIN R1_TIME_TYPES_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R2CHCKBOX_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTRIBUTE_VALUE R1_ATTRIBUTE_VALUE_V, 
       I.R1_CHECKBOX_DESC R1_CHECKBOX_DESC_V, 
       I.R1_CHECKBOX_DESC_ALIAS R1_CHECKBOX_DESC_ALIAS_V, 
       I.R1_CHECKBOX_DESC_ALT R1_CHECKBOX_DESC_ALT_V, 
       I.R1_CHECKBOX_TYPE R1_CHECKBOX_TYPE_V
  FROM      R2CHCKBOX T 
  LEFT JOIN R2CHCKBOX_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_ASI_ATTR] 
AS
(
SELECT DISTINCT A.SERV_PROV_CODE AS AGENCY_ID,
                N'ASI::' + A.R1_CHECKBOX_CODE  + N'::' + A.R1_CHECKBOX_TYPE AS ENTITY,
                A.R1_CHECKBOX_DESC AS ATTRIBUTE,
                R3.R1_PER_GROUP +N'/'+R3.R1_PER_TYPE+N'/'+R3.R1_PER_SUB_TYPE+N'/'+R3.R1_PER_CATEGORY AS RECORD_TYPE, 
                --AA TYPE
                R3.R1_APP_TYPE_ALIAS AS RECORD_ALIAS,
                NULL AS TYPE
  FROM R2CHCKBOX A,R3APPTYP R3  WHERE
   A.R1_CHECKBOX_GROUP = N'APPLICATION' AND R3.R1_CHCKBOX_CODE = A.R1_CHECKBOX_CODE
   AND A.SERV_PROV_CODE=R3.SERV_PROV_CODE
  -- AND A.REC_STATUS = 'A'   
    --combine ASIT Attribute
   UNION ALL
   SELECT DISTINCT ASIT.SERV_PROV_CODE AS AGENCY_ID,
                N'ASIT::'+ ASIT.R1_CHECKBOX_CODE  + N'::' + ASIT.R1_CHECKBOX_TYPE AS ENTITY,
                ASIT.R1_CHECKBOX_DESC AS ATTRIBUTE,
                 R3.R1_PER_GROUP +N'/'+R3.R1_PER_TYPE+N'/'+R3.R1_PER_SUB_TYPE+N'/'+R3.R1_PER_CATEGORY AS RECORD_TYPE,
                R3.R1_APP_TYPE_ALIAS AS RECORD_ALIAS,
                NULL AS TYPE
  FROM R3APPTYP R3, R2CHCKBOX ASIT  
 INNER JOIN R2CHCKBOX ASI ON ASIT.R1_CHECKBOX_CODE = ASI.R1_TABLE_GROUP_NAME
                       AND ASI.R1_CHECKBOX_GROUP = N'APPLICATION'
					   AND ASIT.SERV_PROV_CODE = ASI.SERV_PROV_CODE
 WHERE ASIT.R1_CHECKBOX_GROUP = N'FEEATTACHEDTABLE' AND R3.R1_CHCKBOX_CODE = ASI.R1_CHECKBOX_CODE
  AND R3.SERV_PROV_CODE=ASIT.SERV_PROV_CODE
  AND ASIT.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_GUIDESHEET_TEMPLATE_ATTR] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       N'GUIDESHEET_TPL::' + A.R1_CHECKBOX_CODE + N'::' + A.R1_CHECKBOX_TYPE AS ENTITY,
       B.GUIDE_TYPE AS GUIDESHEET_TYPE,
       B.GUIDE_ITEM_TEXT AS GUIDESHEET_ITEM_TEXT,
       R1_CHECKBOX_DESC AS ATTRIBUTE,
       NULL AS TYPE
 FROM R2CHCKBOX A, RGUIDESHEET_ITEM B
 WHERE A.R1_CHECKBOX_GROUP = N'APPLICATION'
 AND A.SERV_PROV_CODE = B.SERV_PROV_CODE
 AND A.R1_CHECKBOX_CODE = B.ASI_GRP_NAM
 --AND A.REC_STATUS = 'A'
)
GO

ALTER VIEW [dbo].[V_TSI_ATTR] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       N'TSI::' + A.R1_CHECKBOX_CODE + N'::' + A.R1_CHECKBOX_TYPE  AS ENTITY,
        R3.R1_PER_GROUP +N'/'+R3.R1_PER_TYPE+N'/'+R3.R1_PER_SUB_TYPE+N'/'+R3.R1_PER_CATEGORY AS RECORD_TYPE,
        R3.R1_APP_TYPE_ALIAS AS RECORD_ALIAS,
       S.R1_PROCESS_CODE AS PROCESS_CODE,
       S.SD_PRO_DES AS TASK_NAME,
       R1_CHECKBOX_DESC AS ATTRIBUTE,
       NULL AS TYPE
  FROM R2CHCKBOX A INNER JOIN SPROCESS S ON A.SERV_PROV_CODE = S.SERV_PROV_CODE
           AND A.R1_CHECKBOX_CODE = S.R1_CHECKBOX_CODE LEFT JOIN SPROCESS_GROUP SG ON S.R1_PROCESS_CODE = SG.R1_PROCESS_CODE 
		   AND S.SERV_PROV_CODE = SG.SERV_PROV_CODE
  LEFT JOIN R3APPTYP R3 ON SG.SPROCESS_GROUP_CODE = R3.R1_PROCESS_CODE
   AND R3.SERV_PROV_CODE = SG.SERV_PROV_CODE
 WHERE A.R1_CHECKBOX_GROUP = N'WORKFLOW TASK' AND A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[R2CHCKBOX_VALUE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_CHECKBOX_VALUE R1_CHECKBOX_VALUE_V
  FROM      R2CHCKBOX_VALUE T 
  LEFT JOIN R2CHCKBOX_VALUE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R2GUIDESHEET_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.GUIDE_TYPE GUIDE_TYPE_V
  FROM      R2GUIDESHEET T 
  LEFT JOIN R2GUIDESHEET_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3AGENCY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R3_AGENCY_CODE R3_AGENCY_CODE_V
  FROM      R3AGENCY T 
  LEFT JOIN R3AGENCY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3APPTYP_VIEW_EN_US] AS 
SELECT T.*, 
       I.APPTYP_HTML_INSTRUCTION APPTYP_HTML_INSTRUCTION_V, 
       I.APPTYP_PLAIN_INSTRUCTION APPTYP_PLAIN_INSTRUCTION_V, 
       I.LANG_ID LANG_ID_V, 
       I.R1_APP_TYPE_ALIAS R1_APP_TYPE_ALIAS_V, 
       I.R1_PER_CATEGORY R1_PER_CATEGORY_V, 
       I.R1_PER_GROUP R1_PER_GROUP_V, 
       I.R1_PER_SUB_TYPE R1_PER_SUB_TYPE_V, 
       I.R1_PER_TYPE R1_PER_TYPE_V
  FROM      R3APPTYP T 
  LEFT JOIN R3APPTYP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3APPTYP_FILTER_VIEW_EN_US] AS 
SELECT T.*, 
       I.FILTER_NAME FILTER_NAME_V, 
       I.LANG_ID LANG_ID_V
  FROM      R3APPTYP_FILTER T 
  LEFT JOIN R3APPTYP_FILTER_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3BUREAU_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R3_BUREAU_CODE R3_BUREAU_CODE_V
  FROM      R3BUREAU T 
  LEFT JOIN R3BUREAU_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_STANDARD_CONDITION] 
AS
SELECT
  B.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE
--=== Standard Condition Info  
  ,B.R3_CON_LONG_COMMENT            AS COMMENTS_LONG
  ,B.R3_CON_COMMENT                 AS COMMENTS_SHORT
  ,B.R3_CON_DES                     AS CONDITION_NAME
  ,B.COND_APRV_FLAG                 AS CONDITION_OF_APPROV
  ,B.R3_CON_NBR   AS CONDITION_REF_ID
  ,B.R3_CON_INC_CON_NAME            AS DISPLAY_COND_NAME
  ,B.R3_CON_DIS_CON_NOTICE          AS DISPLAY_NOTICE_AA
  ,B.R3_CON_DIS_NOTICE_ACA          AS DISPLAY_NOTICE_ACA
  ,B.R3_CON_DIS_NOTICE_ACA_FEE      AS DISPLAY_NOTICE_ACA_FEE
  ,B.R3_CON_INC_SHORT_DESC          AS DISPLAY_SHORT_DESC
  ,C.R3_CON_PUBLIC_DIS_MESSAGE      AS DISPLAYED_MESSAGE
  ,B.R3_CON_GROUP                   AS GROUP_
  ,B.R3_CON_INHERITABLE             AS INHERITABLE
  ,C.PRIORITY                       AS PRIORITY
  ,C.R3_CON_RESOLUTION_ACTION       AS RESOLUTION_ACTION
  ,B.R3_CON_IMPACT_CODE             AS SEVERITY
  ,B.R3_CON_TYPE                    AS TYPE_
--=== column to support build relation with Templates.
  ,CONVERT(NVARCHAR, B.R3_CON_NBR)   AS TEMPLATE_ID
  ,CONVERT(NVARCHAR, B.R3_CON_NBR)   AS T_ID1
FROM
  R3CLEART B
  LEFT JOIN     
  RCOA_DETAIL C 
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE     
    AND B.R3_CON_NBR = C.R3_CON_NBR 
WHERE   
  B.REC_STATUS=N'A'
GO

ALTER VIEW [dbo].[R3DIVISN_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R3_DIVISION_CODE R3_DIVISION_CODE_V
  FROM      R3DIVISN T 
  LEFT JOIN R3DIVISN_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3OFFICE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R3_OFFICE_CODE R3_OFFICE_CODE_V
  FROM      R3OFFICE T 
  LEFT JOIN R3OFFICE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3STATYP_VIEW_EN_US] AS 
SELECT T.*, 
       I.APPLICATION_STATUS APPLICATION_STATUS_V, 
       I.LANG_ID LANG_ID_V, 
       I.R3_ACT_STAT_DES R3_ACT_STAT_DES_V
  FROM      R3STATYP T 
  LEFT JOIN R3STATYP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

--Name: 9.0.0_3_create_views.sql
--description: This file contains the SQL statements to create Accela Automation schema views in release 9.0.0
--schema owner: executed by dbo schema with sysadmin role
--Initial Date: 2016-10-25

------------------------------------------------
-- create view part (begin)
------------------------------------------------
ALTER VIEW [dbo].[R3WGROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R3_GROUP_CODE R3_GROUP_CODE_V
  FROM      R3WGROUP T 
  LEFT JOIN R3WGROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[R3WSECTN_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R3_SECTION_CODE R3_SECTION_CODE_V
  FROM      R3WSECTN T 
  LEFT JOIN R3WSECTN_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RACCOUNT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.ACCT_DESC ACCT_DESC_V
  FROM      RACCOUNT T 
  LEFT JOIN RACCOUNT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RAPO_ATTRIBUTE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTRIBUTE_LABEL R1_ATTRIBUTE_LABEL_V
  FROM      RAPO_ATTRIBUTE T 
  LEFT JOIN RAPO_ATTRIBUTE_I18N I
    ON T.SOURCE_SEQ_NBR = I.SOURCE_SEQ_NBR
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_APO_ADDRESS_ATTR] 
AS
(
SELECT DISTINCT B.SERV_PROV_CODE AS AGENCY_ID,
                N'ADDRESS_TEMPLATE'  ENTITY,
                A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
                NULL AS TYPE
  FROM RAPO_ATTRIBUTE A
 INNER JOIN RSERV_PROV B ON A.SOURCE_SEQ_NBR = B.APO_SRC_SEQ_NBR
 WHERE A.REC_STATUS = N'A' AND A.R1_ATTRIBUTE_TYPE=N'ADDRESS'
)
GO

ALTER VIEW [dbo].[V_APO_OWNER_ATTR] 
AS 
(
SELECT DISTINCT B.SERV_PROV_CODE AS AGENCY_ID,
                N'OWNER_TEMPLATE' AS ENTITY,
                A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
                NULL AS TYPE
  FROM RAPO_ATTRIBUTE A
 INNER JOIN RSERV_PROV B ON A.SOURCE_SEQ_NBR = B.APO_SRC_SEQ_NBR
 WHERE A.REC_STATUS = N'A' AND A.R1_ATTRIBUTE_TYPE=N'OWNER'
)
GO

ALTER VIEW [dbo].[V_APO_PARCEL_ATTR] 
AS 
(
SELECT DISTINCT B.SERV_PROV_CODE AS AGENCY_ID,
                N'PARCEL_TEMPLATE' AS ENTITY,
                A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
                NULL AS TYPE 
  FROM RAPO_ATTRIBUTE A
 INNER JOIN RSERV_PROV B ON A.SOURCE_SEQ_NBR = B.APO_SRC_SEQ_NBR
 WHERE A.REC_STATUS = N'A' AND A.R1_ATTRIBUTE_TYPE=N'PARCEL'
)
GO

ALTER VIEW [dbo].[V_REF_PARCEL_TEMPLATE_ATTR] 
AS 
SELECT DISTINCT B.SERV_PROV_CODE AS AGENCY_ID,
                N'PARCEL_REF_TEMPLATE' AS ENTITY,
                A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
                NULL AS TYPE 
  FROM RAPO_ATTRIBUTE A
 INNER JOIN RSERV_PROV B ON A.SOURCE_SEQ_NBR = B.APO_SRC_SEQ_NBR
 WHERE A.REC_STATUS = N'A' 
   AND A.R1_ATTRIBUTE_TYPE=N'PARCEL'
GO

ALTER VIEW [dbo].[RAPO_ATTRIBUTE_VALUE_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTRIBUTE_VALUE R1_ATTRIBUTE_VALUE_V
  FROM      RAPO_ATTRIBUTE_VALUE T 
  LEFT JOIN RAPO_ATTRIBUTE_VALUE_I18N I
    ON T.SOURCE_SEQ_NBR = I.SOURCE_SEQ_NBR
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RASSET_ATTRIBUTE_VIEW_EN_US] AS 
SELECT T.*,
       I.LANG_ID LANG_ID_V,
       I.R1_ATTRIBUTE_VALUE R1_ATTRIBUTE_VALUE_V,
       I.R1_ATTRIBUTE_LABEL R1_ATTRIBUTE_LABEL_V
  FROM      RASSET_ATTRIBUTE T
  LEFT JOIN RASSET_ATTRIBUTE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_ASSET_TEMPLATE_ATTR] 
AS
(
SELECT DISTINCT A.SERV_PROV_CODE AS AGENCY_ID,
                N'ASSET_TPL' + N'::' + A.R1_ASSET_TEMPLATE_ID AS ENTITY,
                R.R1_ASSET_GROUP AS ASSET_GROUP,
                R.R1_ASSET_TYPE AS ASSET_TYPE,
                B.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
                NULL AS TYPE 
  FROM RASSET_TYPE R, RASSET_TEMPLATE_ATTRIBUTE A 
 INNER JOIN RASSET_ATTRIBUTE B ON A.SERV_PROV_CODE = B.SERV_PROV_CODE
                              AND A.R1_ATTRIBUTE_NAME = B.R1_ATTRIBUTE_NAME 
  WHERE A.REC_STATUS = N'A' 
 AND A.SERV_PROV_CODE = R.SERV_PROV_CODE
 AND R.R1_ASSET_TEMPLATE_ID = A.R1_ASSET_TEMPLATE_ID
)
GO

ALTER VIEW [dbo].[RASSET_ATTRIBUTE_VALUE_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTRIBUTE_VALUE R1_ATTRIBUTE_VALUE_V
  FROM      RASSET_ATTRIBUTE_VALUE T 
  LEFT JOIN RASSET_ATTRIBUTE_VALUE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RASSET_CA_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_CONDITION_ASSESSMENT R1_CONDITION_ASSESSMENT_V
  FROM      RASSET_CA T 
  LEFT JOIN RASSET_CA_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RASSET_TYPE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ASSET_ICON R1_ASSET_ICON_V, 
       I.R1_ASSET_TYPE R1_ASSET_TYPE_V
  FROM      RASSET_TYPE T 
  LEFT JOIN RASSET_TYPE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RATTRIBUTE_TAB_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTR_TAB_NAME R1_ATTR_TAB_NAME_V
  FROM      RATTRIBUTE_TAB T 
  LEFT JOIN RATTRIBUTE_TAB_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_STANDARD_CHOICE] 
AS
SELECT
  B.SERV_PROV_CODE                      AS AGENCY_ID
--=== Row Update Info  
  ,C.REC_FUL_NAM                        AS UPDATED_BY
  ,C.REC_DATE                           AS UPDATED_DATE
--=== EMSE script controls
  ,(  CASE 
        WHEN C.VALUE_DESC LIKE N'%^%^%' 
          THEN ltrim(LEFT(
            --Action portion of script control
            substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc))
            --Position of ^ within Action portion of script control, less 1
            ,PATINDEX(N'%^%',substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc)))-1
          ))
        WHEN C.VALUE_DESC LIKE N'%^%'
          THEN LTRIM(right(C.VALUE_DESC, LEN(C.value_desc)-PATINDEX(N'%^%',C.VALUE_DESC)))
        ELSE N''
      END    
  )                                     AS EMSE_ACTION_TRUE#
  ,(  CASE
        WHEN C.VALUE_DESC LIKE N'%^%^%' THEN
          LTRIM(RIGHT(
            --Action portion of script control
            substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc))
            --Length of Action portion of script control, less position of ^ in the same string
            ,LEN(substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc))) 
             - PATINDEX(N'%^%',substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc))) 
          ))
        ELSE N''
      END  
  )                                      AS EMSE_ACTION_FALSE#  
  ,(  CASE 
        WHEN LTRIM(substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc))) LIKE N'BRANCH%(%)%'
        THEN RTRIM(LTRIM(
          replace(
            REPLACE(
              substring(C.value_desc, PATINDEX(N'%^%',C.VALUE_DESC)+1,len(C.value_desc))
              ,N'BRANCH'
              ,N''
            )
          ,N';'
          ,N''
          )))
        ELSE N''
      END
  )                                     AS EMSE_BRANCH_TO#
  ,(  CASE WHEN C.VALUE_DESC LIKE N'%^%'
        THEN RTRIM(LEFT(C.VALUE_DESC,PATINDEX(N'%^%', C.VALUE_DESC)-1))
        ELSE N''
      END
  )                                     AS EMSE_CRITERIA#
  ,(  CASE WHEN C.VALUE_DESC LIKE N'%^%'
        THEN C.BIZDOMAIN_VALUE
        ELSE N''
      END
  )                                     AS EMSE_STEP                                      
--=== Standard Choices Info
  ,B.DESCRIPTION                        AS ITEM_DESCRIPTION  
  ,C.BIZDOMAIN                          AS ITEM_NAME
  ,B.REC_STATUS                         AS ITEM_STATUS
  ,B.STD_CHOICE_TYPE                    AS ITEM_TYPE  
  ,C.BIZDOMAIN_VALUE                    AS VALUE_
  ,C.REC_STATUS                         AS VALUE_ACTIVE  
  ,C.VALUE_DESC                         AS VALUE_DESC
FROM
  RBIZDOMAIN B
  JOIN
  RBIZDOMAIN_VALUE C
    ON  B.SERV_PROV_CODE = C.SERV_PROV_CODE     
    AND B.BIZDOMAIN = C.BIZDOMAIN
GO

ALTER VIEW [dbo].[RBIZDOMAIN_VALUE_VIEW_EN_US] AS 
SELECT T.*, 
       I.BIZDOMAIN_VALUE BIZDOMAIN_VALUE_V, 
       I.LANG_ID LANG_ID_V, 
       I.VALUE_DESC VALUE_DESC_V
  FROM      RBIZDOMAIN_VALUE T 
  LEFT JOIN RBIZDOMAIN_VALUE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RCALENDAR_EVENT_TYPE_V_EN_US] AS 
SELECT T.*, 
       I.EVENT_TYPE EVENT_TYPE_V, 
       I.LANG_ID LANG_ID_V
  FROM      RCALENDAR_EVENT_TYPE T 
  LEFT JOIN RCALENDAR_EVENT_TYPE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RCOA_DETAIL_VIEW_EN_US] AS 
SELECT T.*, 
       I.ADDIT_INFO_PLAIN_TEXT ADDIT_INFO_PLAIN_TEXT_V, 
       I.ADDITIONAL_INFORMATION ADDITIONAL_INFORMATION_V, 
       I.LANG_ID LANG_ID_V, 
       I.R3_CON_PUBLIC_DIS_MESSAGE R3_CON_PUBLIC_DIS_MESSAGE_V, 
       I.R3_CON_RESOLUTION_ACTION R3_CON_RESOLUTION_ACTION_V
  FROM      RCOA_DETAIL T 
  LEFT JOIN RCOA_DETAIL_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RCONTACT_ATTRIBUTE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTRIBUTE_LABEL R1_ATTRIBUTE_LABEL_V
  FROM      RCONTACT_ATTRIBUTE T 
  LEFT JOIN RCONTACT_ATTRIBUTE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[V_LP_TEMPLATE_ATTR] 
AS 
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       N'LP_TPL::' + A.R1_ATTRIBUTE_TYPE AS ENTITY,
       A.R1_ATTRIBUTE_TYPE AS LICENCE_TYPE,
       A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
       NULL AS TYPE
  FROM RCONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_PEOPLE_TEMPLATE_ATTR] 
AS 
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       N'PEOPLE_DAILY::' + A.R1_ATTRIBUTE_TYPE AS ENTITY,
       A.R1_ATTRIBUTE_TYPE AS CONTACT_TYPE,
       A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
       NULL AS TYPE
  FROM RCONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_REF_LP_TEMPLATE_ATTR] 
AS 
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       N'LP_REF_TPL::' + A.R1_ATTRIBUTE_TYPE AS ENTITY,
       A.R1_ATTRIBUTE_TYPE AS LICENCE_TYPE,
       A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
       NULL AS TYPE
  FROM RCONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[V_REF_PEOPLE_TEMPLATE_ATTR] 
AS 
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       N'PEOPLE_REF::' + A.R1_ATTRIBUTE_TYPE AS ENTITY,
       A.R1_ATTRIBUTE_TYPE AS CONTACT_TYPE,
       A.R1_ATTRIBUTE_NAME AS ATTRIBUTE,
       NULL AS TYPE
  FROM RCONTACT_ATTRIBUTE A
 WHERE A.REC_STATUS = N'A'
)
GO

ALTER VIEW [dbo].[RCONTACT_ATTRIBUTE_VAL_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_ATTRIBUTE_VALUE R1_ATTRIBUTE_VALUE_V
  FROM      RCONTACT_ATTRIBUTE_VALUE T 
  LEFT JOIN RCONTACT_ATTRIBUTE_VALUE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RCOST_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_GROUP_NAME R1_GROUP_NAME_V
  FROM      RCOST_GROUP T 
  LEFT JOIN RCOST_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RDOCUMENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.DOC_CODE DOC_CODE_V, 
       I.DOC_TYPE DOC_TYPE_V, 
       I.LANG_ID LANG_ID_V
  FROM      RDOCUMENT T 
  LEFT JOIN RDOCUMENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[REMAIL_TEMPLATE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.TITLE TITLE_V, 
       I.CONTENT CONTENT_V
  FROM      REMAIL_TEMPLATE T 
  LEFT JOIN REMAIL_TEMPLATE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[REXAM_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.EXAM_NAME EXAM_NAME_V
  FROM      REXAM T 
  LEFT JOIN REXAM_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[REXPRESSION_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SCRIPT_TEXT SCRIPT_TEXT_V
  FROM      REXPRESSION T 
  LEFT JOIN REXPRESSION_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[REXPRESSION_CALCULATIO_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CALCULATE_EXP CALCULATE_EXP_V
  FROM      REXPRESSION_CALCULATION T 
  LEFT JOIN REXPRESSION_CALCULATION_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[REXPRESSION_CRITERIA_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CRITERIA_VALUE CRITERIA_VALUE_V
  FROM      REXPRESSION_CRITERIA T 
  LEFT JOIN REXPRESSION_CRITERIA_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[REXPRESSION_PARAMETER_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PARAMETER_VALUE PARAMETER_VALUE_V
  FROM      REXPRESSION_PARAMETER T 
  LEFT JOIN REXPRESSION_PARAMETER_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RFEE_SCHEDULE_VIEW_EN_US] AS 
SELECT T.*, 
       I.FEE_SCHEDULE_ALIAS FEE_SCHEDULE_ALIAS_V, 
       I.FEE_SCHEDULE_COMMENT FEE_SCHEDULE_COMMENT_V, 
       I.FEE_SCHEDULE_NAME FEE_SCHEDULE_NAME_V, 
       I.FEE_SCHEDULE_VERSION FEE_SCHEDULE_VERSION_V, 
       I.LANG_ID LANG_ID_V
  FROM      RFEE_SCHEDULE T 
  LEFT JOIN RFEE_SCHEDULE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RFEEITEM_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_GF_COD R1_GF_COD_V, 
       I.R1_GF_DES R1_GF_DES_V, 
       I.R1_SUB_GROUP R1_SUB_GROUP_V
  FROM      RFEEITEM T 
  LEFT JOIN RFEEITEM_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RFEEITEM_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.GROUP_NAME GROUP_NAME_V
  FROM      RFEEITEM_GROUP T 
  LEFT JOIN RFEEITEM_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RGUIDE_ITEM_STATUS_GRO_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.GUIDE_ITEM_STATUS GUIDE_ITEM_STATUS_V
  FROM      RGUIDE_ITEM_STATUS_GROUP T 
  LEFT JOIN RGUIDE_ITEM_STATUS_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RGUIDESHEET_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.GUIDE_GROUP GUIDE_GROUP_V
  FROM      RGUIDESHEET_GROUP T 
  LEFT JOIN RGUIDESHEET_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RGUIDESHEET_ITEM_VIEW_EN_US] AS 
SELECT T.*, 
       I.GUIDE_ITEM_COMMENT GUIDE_ITEM_COMMENT_V, 
       I.GUIDE_ITEM_STATUS GUIDE_ITEM_STATUS_V, 
       I.GUIDE_ITEM_TEXT GUIDE_ITEM_TEXT_V, 
       I.GUIDE_TYPE GUIDE_TYPE_V, 
       I.LANG_ID LANG_ID_V
  FROM      RGUIDESHEET_ITEM T 
  LEFT JOIN RGUIDESHEET_ITEM_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RINSP_RESULT_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.INSP_RESULT INSP_RESULT_V
  FROM      RINSP_RESULT_GROUP T 
  LEFT JOIN RINSP_RESULT_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RINSPTYP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.INSP_TYPE INSP_TYPE_V, 
       I.INSP_CODE INSP_CODE_V, 
       I.INSP_GROUP_NAME INSP_GROUP_NAME_V
  FROM      RINSPTYP T 
  LEFT JOIN RINSPTYP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RLOOKUP_TABLE_VALUE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.LOOKUP_COLUMN_VALUE LOOKUP_COLUMN_VALUE_V
  FROM      RLOOKUP_TABLE_VALUE T 
  LEFT JOIN RLOOKUP_TABLE_VALUE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RNOTIFICATION_TEMPLATE_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.DESCRIPTION DESCRIPTION_V
  FROM      RNOTIFICATION_TEMPLATE T 
  LEFT JOIN RNOTIFICATION_TEMPLATE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPART_CONTACT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.BUSINESS_NAME BUSINESS_NAME_V, 
       I.CONTACT_TITLE CONTACT_TITLE_V, 
       I.CONTACT_FNAME CONTACT_FNAME_V, 
       I.CONTACT_MNAME CONTACT_MNAME_V, 
       I.CONTACT_LNAME CONTACT_LNAME_V, 
       I.ADDRESS1 ADDRESS1_V, 
       I.ADDRESS2 ADDRESS2_V, 
       I.CONTACT_CITY CONTACT_CITY_V, 
       I.CONTACT_TERMS CONTACT_TERMS_V
  FROM      RPART_CONTACT T 
  LEFT JOIN RPART_CONTACT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPART_INVENTORY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PART_BRAND PART_BRAND_V, 
       I.PART_DESCRIPTION PART_DESCRIPTION_V
  FROM      RPART_INVENTORY T 
  LEFT JOIN RPART_INVENTORY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPART_LOCATION_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.LOCATION_NAME LOCATION_NAME_V
  FROM      RPART_LOCATION T 
  LEFT JOIN RPART_LOCATION_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPAYMENT_PERIOD_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.GF_FEE_PERIOD GF_FEE_PERIOD_V, 
       I.PAY_PERIOD_GROUP PAY_PERIOD_GROUP_V
  FROM      RPAYMENT_PERIOD T 
  LEFT JOIN RPAYMENT_PERIOD_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPF_COMPONENT_VIEW_EN_US] AS 
SELECT T.*, 
       I.COMPONENT_INSTRUCTION COMPONENT_INSTRUCTION_V, 
       I.CUSTOM_HEADING CUSTOM_HEADING_V, 
       I.LANG_ID LANG_ID_V, 
       I.PORTLET_RANGE2 PORTLET_RANGE2_V
  FROM      RPF_COMPONENT T 
  LEFT JOIN RPF_COMPONENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPF_PAGE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PAGE_NAME PAGE_NAME_V, 
       I.INSTRUCTION INSTRUCTION_V
  FROM      RPF_PAGE T 
  LEFT JOIN RPF_PAGE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPF_STEP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.STEP_NAME STEP_NAME_V
  FROM      RPF_STEP T 
  LEFT JOIN RPF_STEP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPT_CATEGORY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CATEGORY_NAME CATEGORY_NAME_V
  FROM      RPT_CATEGORY T 
  LEFT JOIN RPT_CATEGORY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPT_DETAIL_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.REPORT_LINK REPORT_LINK_V, 
       I.REPORT_NAME REPORT_NAME_V
  FROM      RPT_DETAIL T 
  LEFT JOIN RPT_DETAIL_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RPT_PARAMETER_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PARAMETER_NAME PARAMETER_NAME_V
  FROM      RPT_PARAMETER T 
  LEFT JOIN RPT_PARAMETER_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

ALTER VIEW [dbo].[RRATING_CONDITION_CRIT_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CRITERIA_VALUE CRITERIA_VALUE_V
  FROM      RRATING_CONDITION_CRITERIA T 
  LEFT JOIN RRATING_CONDITION_CRITERI_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RRATING_EXPRESSION_CRI_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CRITERIA_VALUE CRITERIA_VALUE_V
  FROM      RRATING_EXPRESSION_CRITERIA T 
  LEFT JOIN RRATING_EXPRESSION_CRITER_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RRATING_TYPE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.RATING_TYPE RATING_TYPE_V, 
       I.SCRIPT_TEXT SCRIPT_TEXT_V
  FROM      RRATING_TYPE T 
  LEFT JOIN RRATING_TYPE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO

EXECUTE sp_refreshsqlmodule N'[dbo].[V_AGENCY_INFO]';


GO


ALTER VIEW [dbo].[RSERVICE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SERVICE_NAME SERVICE_NAME_V
  FROM      RSERVICE T 
  LEFT JOIN RSERVICE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RSERVICE_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SERVICE_GROUP_CODE SERVICE_GROUP_CODE_V
  FROM      RSERVICE_GROUP T 
  LEFT JOIN RSERVICE_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RSET_TYPE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SET_TYPE_NAME SET_TYPE_NAME_V
  FROM      RSET_TYPE T 
  LEFT JOIN RSET_TYPE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RSHARED_DDLIST_VALUES_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.LIST_VALUE LIST_VALUE_V
  FROM      RSHARED_DDLIST_VALUES T 
  LEFT JOIN RSHARED_DDLIST_VALUES_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RSMS_TEMPLATE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CONTENT CONTENT_V
  FROM      RSMS_TEMPLATE T 
  LEFT JOIN RSMS_TEMPLATE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[V_REF_PROFESSIONAL]
AS
SELECT
  B.SERV_PROV_CODE                  AS AGENCY_ID
--=== Row Update Info  
  ,B.REC_FUL_NAM                    AS UPDATED_BY
  ,B.REC_DATE                       AS UPDATED_DATE  
--=== Professional Info  
  ,B.CITY                           AS ADDRESS_CITY
  ,B.COUNTRY                        AS ADDRESS_COUNTRY
  ,B.ADDRESS1                       AS ADDRESS_LINE1
  ,B.ADDRESS2                       AS ADDRESS_LINE2
  ,B.ADDRESS3                       AS ADDRESS_LINE3
  ,B.L1_POST_OFFICE_BOX             AS ADDRESS_PO_BOX
  ,B."STATE"                        AS ADDRESS_STATE
  ,B.ZIP                            AS ADDRESS_ZIP
  ,B.BUS_LIC                        AS BUSINESS_LIC_NBR
  ,B.BUS_NAME                       AS BUSINESS_NAME
  ,B.BUS_NAME2                      AS BUSINESS_NAME2
  ,B.LIC_COMMENT                    AS COMMENTS
  ,B.L1_BIRTH_DATE                  AS DATE_BIRTH
  ,B.BUS_LIC_EXP_DT                 AS DATE_BIZ_LIC_EXPIRE
  ,B.INS_EXP_DT                     AS DATE_INSUR_EXPIRE
  ,B.LIC_EXPIR_DD                   AS DATE_LIC_EXPIRE
  ,B.LAST_UPDATE_DD                 AS DATE_LIC_ISSUED
  ,B.LAST_RENEWAL_DD                AS DATE_LIC_RENEWED
  ,B.WC_EXP_DT                      AS DATE_WC_EXPIRE
  ,B.ACA_PERMISSION                 AS DISPLAY_IN_ACA
  ,B.EMAIL                          AS EMAIL
  ,B.FAX                            AS FAX
  ,B.FAX_COUNTRY_CODE               AS FAX_COUNTRY_CODE
  ,B.LIC_FEDERAL_EMPLOYER_ID_NBR    AS FEIN
  ,B.L1_GENDER                      AS GENDER
  ,B.INS_AMMOUNT                    AS INSUR_AMOUNT
  ,B.INS_CO_NAME                    AS INSUR_COMPANY
  ,B.INS_EXP_DT                     AS INSUR_EXPIRE_DATE
  ,B.INS_POLICY_NO                  AS INSUR_POLICY_NBR
  ,B.LIC_BOARD                      AS LICENSE_BOARD
  ,B.LIC_NBR                        AS LICENSE_NBR
  ,B.LIC_SEQ_NBR                    AS LICENSE_REF_ID  
  ,B.LIC_STATE                      AS LICENSE_STATE
  ,B.LIC_TYPE                       AS LICENSE_TYPE
  ,B.CAE_FNAME                      AS NAME_FIRST
  ,B.CAE_LNAME                      AS NAME_LAST
  ,B.CAE_MNAME                      AS NAME_MIDDLE
  ,(  
    ISNULL(B.CAE_FNAME,N'') +
    (CASE WHEN NULLIF(B.CAE_MNAME,N'') IS NULL THEN N'' ELSE N' '+B.CAE_MNAME END) +
    N' '+ISNULL(B.CAE_LNAME,N'')
  )                                 AS NAME_FML#
  ,B.PHONE1                         AS PHONE1
  ,B.PHONE1_COUNTRY_CODE            AS PHONE1_COUNTRY_CODE
  ,B.PHONE2                         AS PHONE2
  ,B.PHONE2_COUNTRY_CODE            AS PHONE2_COUNTRY_CODE
  ,B.PHONE3                         AS PHONE3
  ,B.PHONE3_COUNTRY_CODE            AS PHONE3_COUNTRY_CODE
  ,B.L1_SALUTATION                  AS SALUTATION
  ,B.LIC_SOCIAL_SECURITY_NBR        AS SSN
  ,B.REC_STATUS                     AS STATUS
  ,B.L1_TITLE                       AS TITLE
  ,B.WC_INS_CO_CODE                 AS WC_COMPANY    
  ,B.WC_EXEMPT                      AS WC_EXEMPT
  ,B.WC_EXP_DT                      AS WC_EXPIRE_DATE
  ,B.WC_POLICY_NO                   AS WC_POLICY_NBR
   --=== column to support build relation with Templates.
  ,CONVERT(NVARCHAR, B.LIC_SEQ_NBR)   AS TEMPLATE_ID
  ,CONVERT(NVARCHAR, B.LIC_SEQ_NBR)   AS T_ID1
FROM
  RSTATE_LIC B
GO


ALTER VIEW [dbo].[RSTRUCTURE_TYPE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_STRUCTURE_TYPE R1_STRUCTURE_TYPE_V
  FROM      RSTRUCTURE_TYPE T 
  LEFT JOIN RSTRUCTURE_TYPE_I18N I
    ON T.SOURCE_SEQ_NBR = I.SOURCE_SEQ_NBR
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RTEMPLATE_LAYOUT_CONFI_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.INSTRUCTION INSTRUCTION_V, 
       I.WATER_MARK WATER_MARK_V, 
       I.ALTERNATIVE_LABEL ALTERNATIVE_LABEL_V, 
       I.BUTTON_ADD_LABEL BUTTON_ADD_LABEL_V, 
       I.BUTTON_EDIT_LABEL BUTTON_EDIT_LABEL_V, 
       I.BUTTON_DELETE_LABEL BUTTON_DELETE_LABEL_V, 
       I.BUTTON_ADD_MORE_LABEL BUTTON_ADD_MORE_LABEL_V
  FROM      RTEMPLATE_LAYOUT_CONFIG T 
  LEFT JOIN RTEMPLATE_LAYOUT_CONFIG_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RWO_COSTING_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_COST_ITEM R1_COST_ITEM_V
  FROM      RWO_COSTING T 
  LEFT JOIN RWO_COSTING_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RWO_TASK_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_TASK_CODE R1_TASK_CODE_V, 
       I.R1_TASK_DESCRIPTION R1_TASK_DESCRIPTION_V, 
       I.R1_DEFAULT_TASK_SOP R1_DEFAULT_TASK_SOP_V
  FROM      RWO_TASK T 
  LEFT JOIN RWO_TASK_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RWO_TEMPLATE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.WO_TEMPLATE_NAME WO_TEMPLATE_NAME_V, 
       I.WO_DESCRIPTION WO_DESCRIPTION_V
  FROM      RWO_TEMPLATE T 
  LEFT JOIN RWO_TEMPLATE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[RWO_TEMPLATE_TASK_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_DESCRIPTION R1_DESCRIPTION_V, 
       I.R1_TASK_SOP R1_TASK_SOP_V, 
       I.R1_COMMENTS R1_COMMENTS_V
  FROM      RWO_TEMPLATE_TASK T 
  LEFT JOIN RWO_TEMPLATE_TASK_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[SETHEADER_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SET_TITLE SET_TITLE_V
  FROM      SETHEADER T 
  LEFT JOIN SETHEADER_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[SNOTE_CONTENTS_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.CONTENTS_SUBJECT CONTENTS_SUBJECT_V, 
       I.CONTENTS_BODY CONTENTS_BODY_V
  FROM      SNOTE_CONTENTS T 
  LEFT JOIN SNOTE_CONTENTS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[SPROCESS_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R1_PROCESS_CODE R1_PROCESS_CODE_V, 
       I.SD_PRO_DES SD_PRO_DES_V
  FROM      SPROCESS T 
  LEFT JOIN SPROCESS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[SPROCESS_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SPROCESS_GROUP_CODE SPROCESS_GROUP_CODE_V
  FROM      SPROCESS_GROUP T 
  LEFT JOIN SPROCESS_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[STCOMMNT_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G6_COM_TYP G6_COM_TYP_V, 
       I.G6_DOC_ID G6_DOC_ID_V, 
       I.G6_COMMENT G6_COMMENT_V, 
       I.G6_NAME G6_NAME_V
  FROM      STCOMMNT T 
  LEFT JOIN STCOMMNT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[STCOMMNT_GROUP_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.G6_GROUP_NAME G6_GROUP_NAME_V
  FROM      STCOMMNT_GROUP T 
  LEFT JOIN STCOMMNT_GROUP_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[XCOMMENTS_ENTITY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.R6_COMMENT R6_COMMENT_V
  FROM      XCOMMENTS_ENTITY T 
  LEFT JOIN XCOMMENTS_ENTITY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[XDISPALERT_RECIPIENT_V_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.ALERT_MSG_CONTENT ALERT_MSG_CONTENT_V
  FROM      XDISPALERT_RECIPIENT T 
  LEFT JOIN XDISPALERT_RECIPIENT_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[XPOLICY_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.DATA2 DATA2_V
  FROM      XPOLICY T 
  LEFT JOIN XPOLICY_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[XPORTLET_SERVPROV_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.PORTLET_COMMENTS PORTLET_COMMENTS_V, 
       I.PORTLET_DESC PORTLET_DESC_V, 
       I.PORTLET_NAME PORTLET_NAME_V
  FROM      XPORTLET_SERVPROV T 
  LEFT JOIN XPORTLET_SERVPROV_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[XSET_TYPE_ATTRIBUTE_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.DISPLAY_VALUE DISPLAY_VALUE_V
  FROM      XSET_TYPE_ATTRIBUTE T 
  LEFT JOIN XSET_TYPE_ATTRIBUTE_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[XSET_TYPE_STATUS_VIEW_EN_US] AS 
SELECT T.*, 
       I.LANG_ID LANG_ID_V, 
       I.SET_STATUS_NAME SET_STATUS_NAME_V
  FROM      XSET_TYPE_STATUS T 
  LEFT JOIN XSET_TYPE_STATUS_I18N I
    ON T.SERV_PROV_CODE = I.SERV_PROV_CODE
   AND T.RES_ID = I.RES_ID 
   AND I.LANG_ID = N'en_US'
GO


ALTER VIEW [dbo].[G3DPTTYP_VIEW_EN_US]
AS
SELECT T.*,
       L.LANG_ID LANG_ID_V,
       --V1-V6 is from views of agency levels,L is resource table of T(G3DPTTYP)
       V2.R3_BUREAU_CODE_V,
       V3.R3_DIVISION_CODE_V,
       V4.R3_SECTION_CODE_V,
       V5.R3_GROUP_CODE_V,
       V1.R3_AGENCY_CODE_V,
       V6.R3_OFFICE_CODE_V,
       L.R3_DEPTNAME R3_DEPTNAME_V,
       L.R3_DEPT_KEY R3_DEPT_KEY_V
  FROM G3DPTTYP T
  LEFT JOIN G3DPTTYP_I18N L ON T.SERV_PROV_CODE = L.SERV_PROV_CODE
                           AND T.RES_ID = L.RES_ID
                           AND L.LANG_ID = N'en_US'
  LEFT JOIN R3AGENCY_VIEW_EN_US V1 ON T.R3_AGENCY_CODE = V1.R3_AGENCY_CODE
                                  AND T.SERV_PROV_CODE = V1.SERV_PROV_CODE
  LEFT JOIN R3BUREAU_VIEW_EN_US V2 ON T.R3_BUREAU_CODE = V2.R3_BUREAU_CODE
                                  AND T.SERV_PROV_CODE = V2.SERV_PROV_CODE
                                  AND V1.R3_AGENCY_CODE = V2.R3_AGENCY_CODE
  LEFT JOIN R3DIVISN_VIEW_EN_US V3 ON T.R3_DIVISION_CODE = V3.R3_DIVISION_CODE
                                  AND T.SERV_PROV_CODE = V3.SERV_PROV_CODE
                                  AND V1.R3_AGENCY_CODE = V3.R3_AGENCY_CODE
  LEFT JOIN R3WSECTN_VIEW_EN_US V4 ON T.R3_SECTION_CODE = V4.R3_SECTION_CODE
                                  AND T.SERV_PROV_CODE = V4.SERV_PROV_CODE
                                  AND V1.R3_AGENCY_CODE = V4.R3_AGENCY_CODE
  LEFT JOIN R3WGROUP_VIEW_EN_US V5 ON T.R3_GROUP_CODE = V5.R3_GROUP_CODE
                                  AND T.SERV_PROV_CODE = V5.SERV_PROV_CODE
                                  AND V1.R3_AGENCY_CODE = V5.R3_AGENCY_CODE
  LEFT JOIN R3OFFICE_VIEW_EN_US V6 ON T.R3_OFFICE_CODE = V6.R3_OFFICE_CODE
                                  AND T.SERV_PROV_CODE = V6.SERV_PROV_CODE
                                  AND V1.R3_AGENCY_CODE = V6.R3_AGENCY_CODE
GO


ALTER VIEW [dbo].[R3CLEART_VIEW_EN_US] AS
SELECT T.*,
       L.LANG_ID LANG_ID_V,
       L.R3_CON_COMMENT R3_CON_COMMENT_V,
       L.R3_CON_DES R3_CON_DES_V,
       L.R3_CON_LONG_COMMENT R3_CON_LONG_COMMENT_V,
       V.BIZDOMAIN_VALUE_V R3_CON_TYPE_V
  FROM R3CLEART T
  LEFT JOIN R3CLEART_I18N L ON T.SERV_PROV_CODE = L.SERV_PROV_CODE
                           AND T.RES_ID = L.RES_ID
                           AND L.LANG_ID = N'en_US'
  LEFT JOIN RBIZDOMAIN_VALUE_VIEW_EN_US V ON UPPER(V.BIZDOMAIN) = N'CONDITION TYPE'
                                         AND T.SERV_PROV_CODE = V.SERV_PROV_CODE
                                         AND T.R3_CON_TYPE = V.BIZDOMAIN_VALUE
GO


ALTER FUNCTION [dbo].[FN_GET_ADDRESS_INFO](
                                        @CLIENTID NVARCHAR(15),
                                        @PID1  NVARCHAR(5),
                                        @PID2  NVARCHAR(5),
                                        @PID3  NVARCHAR(5),
                                        @PrimaryAddrFlag NVARCHAR(1),
                                        @Get_Field NVARCHAR(30)
                                        )RETURNS NVARCHAR(500) AS  
/*  Author           : Sandy Yin
    Create Date      : 04/22/2005
    Version          : AA6.0 MSSQL
    Detail           : RETURNS: Address information, as follows: If {PrimaryAddrFlag} is 'Y', uses primary address; if {PrimaryAddrFlag} is 'B', uses primary address if available or first address; if {PrimaryAddrFlag} is '', uses first address. Returns field value as specified by {Get_Field}. 
                       ARGUMENTS: ClientID, 
                       		  PrimaryTrackingID1, 
                       		  PrimaryTrackingID2, 
                       		  PrimaryTrackingID3, 
                       		  PrimaryAddrFlag (Options: 'Y','B',''), 
                       		  Get_Field(Options: 'FullAddr_Line' (default), 'PartAddr_Line', 'FullAddr_Block', 'HouseNBRStart', 'HouseNBREnd', 'HouseFractionNBRStart', 'HouseFractionNBREnd', 'UnitType', 'UnitStart', 'UnitEnd', 'StreetDirection', 'StreetName', 'StreetNameSuffix', 'SitusCity', 'SitusState', 'SitusZip', 'CityStateZip', 'County').
    Revision History : Sandy Yin  04/22/2005  Initial Design
                       Lorry  06/06/2005  Get full address in line format is not include '#' 
                       Martin  08/06/2005  Get full address in block format is not include '#' 
                       Lydia Lim  08/22/2005  Correct field widths in DECLARE block
                       Cece Wang  08/23/2005  Added another condition for input parameter @Get_Field (IF UPPER(@Get_Field) = 'PARTADDR_LINE_2')
                       Glory Wang  09/08/2005  If {PrimaryAddrFlag} is 'Y', returns primary address; if {PrimaryAddrFlag} is 'B', returns primary address if available or first address.
                       Lydia Lim  10/21/2005  Fix problem caused by null B1_HSE_NBR_END (05SSP-00432.R51017); If B1_HSE_NBR_END  is 0, don't show for PARTADDR_LINE, FULLADDR_BLOCK, FULLADDR_LINE.
                       Lydia Lim  10/27/2005  Add code to drop function before creating it
                       Ava Wu  03/24/2006  Add Get_Field option 'County' to pull situs county from reference data.
                       Roy Zhou 08/21/2006 Add Get_Field option 'PARTADDR_LINE_3'.
                       Cece Wang 09/13/2006  Add Get_Field option 'STREETINFO'.
                       Sandy Yin   12/11/2006  Add Get_field  option 'ADDR_NO_CSZ'
                       Angel Feng  12/27/2006  Add Get_field='LINEADDR5' for 06SSP-00269 field D "street number, direction, unit, street name and street type"
                       Angel Feng  01/03/2007  Add Get_field='STREETADDR4_LINE' for 06SSP-00271 field G "street number, direction, street name and street type"
                       Lucky Song 05/10/2007  To change character length for parameter @Get_Field from 20 to 30.                         
                       Lucky Song 06/11/2007 Added Get_Field = 'STRNUMCITY' for 07SSP-00170 to get  B1_HSE_NBR_START space B1_STR_PREFIX space B1_STR_NAME space B1_STR_SUFFIX comma B1_SITUS_CITY. Converted from Oracle version.
                       Lydia Lim 8/17/2007  Add Get_Field option 'UNIT_STREETINFO' (07-078.C70720)
                       Shawn Huang 06/17/2008 Add Get_field = 'STREET_NBR_NAM_TYP_SUF_DIR' for 08SSP-00002 to get "B1_HSE_NBR_START space B1_STR_NAME space B1_STR_SUFFIX space B1_STR_DIR"
*/                   
BEGIN 
DECLARE 
@VSTR NVARCHAR(500),
@B1_HSE_NBR_START NVARCHAR(9),
@B1_HSE_NBR_END NVARCHAR(9),
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
@B1_SITUS_ZIP NVARCHAR(10),
@L1_SITUS_COUNTY NVARCHAR(30),
@B1_STR_PREFIX NVARCHAR(6); 
BEGIN
 SET @VSTR = N'';
END
IF UPPER(@Get_Field) <> N'COUNTY' AND (UPPER(@PrimaryAddrFlag)=N'Y' OR UPPER(@PrimaryAddrFlag)=N'B')
  BEGIN
        SELECT  TOP 1
                @B1_HSE_NBR_START = isnull(B1_HSE_NBR_START,NULL),    
                @B1_HSE_NBR_END = isnull(B1_HSE_NBR_END,NULL),
                @B1_HSE_FRAC_NBR_START = isnull(B1_HSE_FRAC_NBR_START,N''),
                @B1_HSE_FRAC_NBR_END = isnull(B1_HSE_FRAC_NBR_END,N'') ,
                @B1_STR_DIR = isnull(B1_STR_DIR,N'') ,   
                @B1_STR_NAME = isnull(B1_STR_NAME ,N''),
                @B1_STR_SUFFIX = isnull(B1_STR_SUFFIX,N''),
                @B1_UNIT_TYPE = isnull(B1_UNIT_TYPE,N''), 
                @B1_UNIT_START = isnull(B1_UNIT_START,N''),  
                @B1_UNIT_END = isnull(B1_UNIT_END,N''),
                @B1_SITUS_CITY = isnull(B1_SITUS_CITY,N''), 
                @B1_SITUS_STATE = isnull(B1_SITUS_STATE,N''), 
                @B1_SITUS_ZIP = isnull(B1_SITUS_ZIP,N''), 
                @B1_STR_PREFIX = isnull(B1_STR_PREFIX, N'')
        FROM   
                B3ADDRES
        WHERE 
                SERV_PROV_CODE = @CLIENTID
                AND B1_PER_ID1 = @PID1
                AND B1_PER_ID2 = @PID2
                AND B1_PER_ID3 = @PID3
                AND REC_STATUS = N'A'
                AND UPPER(B1_ADDR_SOURCE_FLG) = N'ADR'        
                AND B1_PRIMARY_ADDR_FLG = N'Y'
  IF @@ROWCOUNT = 0 AND UPPER(@PrimaryAddrFlag)=N'B'
        SELECT  TOP 1
                @B1_HSE_NBR_START = isnull(B1_HSE_NBR_START,NULL),    
                @B1_HSE_NBR_END = isnull(B1_HSE_NBR_END,NULL),
                @B1_HSE_FRAC_NBR_START = isnull(B1_HSE_FRAC_NBR_START,N''),
                @B1_HSE_FRAC_NBR_END = isnull(B1_HSE_FRAC_NBR_END,N'') ,
                @B1_STR_DIR = isnull(B1_STR_DIR,N'') ,   
                @B1_STR_NAME = isnull(B1_STR_NAME ,N''),
                @B1_STR_SUFFIX = isnull(B1_STR_SUFFIX,N''),
                @B1_UNIT_TYPE = isnull(B1_UNIT_TYPE,N''), 
                @B1_UNIT_START = isnull(B1_UNIT_START,N''),  
                @B1_UNIT_END = isnull(B1_UNIT_END,N''),
                @B1_SITUS_CITY = isnull(B1_SITUS_CITY,N''), 
                @B1_SITUS_STATE = isnull(B1_SITUS_STATE,N''), 
                @B1_SITUS_ZIP = isnull(B1_SITUS_ZIP,N''), 
                @B1_STR_PREFIX = isnull(B1_STR_PREFIX,N'')
        FROM   
                B3ADDRES
        WHERE 
                SERV_PROV_CODE = @CLIENTID
                AND B1_PER_ID1 = @PID1
                AND B1_PER_ID2 = @PID2
                AND B1_PER_ID3 = @PID3
                AND REC_STATUS = N'A'
                AND UPPER(B1_ADDR_SOURCE_FLG) = N'ADR'
  END
/* Get County from Admin Address information */
ELSE IF UPPER(@Get_Field) = N'COUNTY' AND UPPER(@PrimaryAddrFlag)=N'B'
   BEGIN
        SELECT  TOP 1
                @L1_SITUS_COUNTY = isnull(L1_SITUS_COUNTY,N'')
        FROM   
                L3ADDRES    L,
                RSERV_PROV  R,
                B3ADDRES    B
        WHERE 
                L.SOURCE_SEQ_NBR = R.APO_SRC_SEQ_NBR
                AND L.L1_ADDRESS_NBR = B.L1_ADDRESS_NBR 
                AND R.SERV_PROV_CODE=@CLIENTID
                AND R.REC_STATUS = N'A'
                AND B.SERV_PROV_CODE = @CLIENTID
                AND B.B1_PER_ID1 = @PID1
                AND B.B1_PER_ID2 = @PID2
                AND B.B1_PER_ID3 = @PID3
                AND B.REC_STATUS = N'A'
                AND UPPER(B.B1_ADDR_SOURCE_FLG) = N'ADR'  
                AND L.REC_STATUS = N'A' 
                AND L.L1_ADDR_STATUS = N'A'
                ORDER BY B1_PRIMARY_ADDR_FLG DESC
   END
ELSE
  BEGIN
        SELECT  TOP 1
                @B1_HSE_NBR_START = isnull(B1_HSE_NBR_START,NULL),    
                @B1_HSE_NBR_END = isnull(B1_HSE_NBR_END,NULL),
                @B1_HSE_FRAC_NBR_START = isnull(B1_HSE_FRAC_NBR_START,N''),
                @B1_HSE_FRAC_NBR_END = isnull(B1_HSE_FRAC_NBR_END,N'') ,
                @B1_STR_DIR = isnull(B1_STR_DIR,N'') ,   
                @B1_STR_NAME = isnull(B1_STR_NAME ,N''),
                @B1_STR_SUFFIX = isnull(B1_STR_SUFFIX,N''),
                @B1_UNIT_TYPE = isnull(B1_UNIT_TYPE,N''), 
                @B1_UNIT_START = isnull(B1_UNIT_START,N''),  
                @B1_UNIT_END = isnull(B1_UNIT_END,N''),
                @B1_SITUS_CITY = isnull(B1_SITUS_CITY,N''), 
                @B1_SITUS_STATE = isnull(B1_SITUS_STATE,N''), 
                @B1_SITUS_ZIP = isnull(B1_SITUS_ZIP,N''), 
                @B1_STR_PREFIX = isnull(B1_STR_PREFIX, N'')
        FROM   
                B3ADDRES
        WHERE 
                SERV_PROV_CODE = @CLIENTID
                AND B1_PER_ID1 = @PID1
                AND B1_PER_ID2 = @PID2
                AND B1_PER_ID3 = @PID3
                AND REC_STATUS = N'A'
                AND UPPER(B1_ADDR_SOURCE_FLG) = N'ADR'
  END
IF UPPER(@Get_Field) = N'COUNTY'
  SET @VSTR = @L1_SITUS_COUNTY
ELSE IF UPPER(@Get_Field) = N'HOUSENBRSTART'
  SET @VSTR = @B1_HSE_NBR_START
ELSE IF UPPER(@Get_Field) = N'HOUSENBREND'
  SET @VSTR = @B1_HSE_NBR_END
ELSE IF UPPER(@Get_Field) = N'HOUSEFRACTIONNBRSTART'
  SET @VSTR = @B1_HSE_FRAC_NBR_START
ELSE IF UPPER(@Get_Field) = N'HOUSEFRACTIONNBREND'
  SET @VSTR = @B1_HSE_FRAC_NBR_END
ELSE IF UPPER(@Get_Field) = N'STREETDIRECTION'
  SET @VSTR = @B1_STR_DIR
ELSE IF UPPER(@Get_Field) = N'STREETNAME'
  SET @VSTR = @B1_STR_NAME
ELSE IF UPPER(@Get_Field) = N'STREETNAMESUFFIX'
  SET @VSTR = @B1_STR_SUFFIX
ELSE IF UPPER(@Get_Field) = N'UNITTYPE'
  SET @VSTR = @B1_UNIT_TYPE
ELSE IF UPPER(@Get_Field) = N'UNITSTART'
  SET @VSTR = @B1_UNIT_START
ELSE IF UPPER(@Get_Field) = N'UNITEND'
  SET @VSTR = @B1_UNIT_END
ELSE IF UPPER(@Get_Field) = N'SITUSCITY'
  SET @VSTR = @B1_SITUS_CITY
ELSE IF UPPER(@Get_Field) = N'SITUSSTATE'
  SET @VSTR = @B1_SITUS_STATE
ELSE IF UPPER(@Get_Field) = N'SITUSZIP'
  SET @VSTR = @B1_SITUS_ZIP
/* Get All Address, Exclude City, State and ZIP, in line format */
ELSE IF UPPER(@Get_Field) = N'PARTADDR_LINE'
  BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL 
        SET @VSTR = @B1_HSE_NBR_START 
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START;
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START;
      END
    IF (@VSTR <> N'') AND ((@B1_HSE_NBR_END IS NOT NULL AND @B1_HSE_NBR_END<>N'0') OR @B1_HSE_FRAC_NBR_END <> N'') 
        SET @VSTR = @VSTR + N' -';
    IF @B1_HSE_NBR_END IS NOT NULL AND @B1_HSE_NBR_END<>N'0'
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_NBR_END
      END
    IF @B1_HSE_FRAC_NBR_END <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_END
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N', ' + @B1_UNIT_TYPE + N'#'
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE + N'#'
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_UNIT_START <> N'' AND  @B1_UNIT_END <> N'' 
        SET @VSTR = @VSTR + N' -'
    IF @B1_UNIT_END <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
        ELSE
                SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
      END
  END
/* Get All Address, Exclude B1_HSE_NBR_END,B1_HSE_FRAC_NBR_END,B1_UNIT_END, City, State and ZIP, in line format */
ELSE IF UPPER(@Get_Field) = N'PARTADDR_LINE_2'
  BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL 
        SET @VSTR = @B1_HSE_NBR_START 
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START;
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START;
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N', ' + @B1_UNIT_TYPE + N'#'
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE + N'#'
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
  END
/* Get All Address, Exclude B1_HSE_NBR_END,B1_HSE_FRAC_NBR_END,B1_UNIT_END, City, State and ZIP, in line format (Street Number, Fraction, Street Direction, Unit type, Unit #, Street Name, and Street Suffix)*/
ELSE IF UPPER(@Get_Field) = N'PARTADDR_LINE_3'
  BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL 
        SET @VSTR = @B1_HSE_NBR_START 
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START;
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START;
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_TYPE + N'#'
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE + N'#'
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N', ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
  END
/*  Get Unit #, Street#, Street Name, Street Suffix and Street Direction, with space as delimiter */
ELSE IF UPPER(@Get_Field) = N'STREETINFO'
  BEGIN
    IF @B1_UNIT_START <> N''
        SET @VSTR = @B1_UNIT_START
    IF @B1_HSE_NBR_START <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_NBR_START
          ELSE
                SET @VSTR = @B1_HSE_NBR_START
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
  END
/* Get Street#, Street Direction, Unit #, Street Name, and street type (@B1_STR_SUFFIX), with space as delimiter */
ELSE IF UPPER(@Get_Field) = N'LINEADDR5'
  BEGIN
    IF @B1_HSE_NBR_START <> N''
        SET @VSTR = @B1_HSE_NBR_START
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_UNIT_START <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
          ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
  END
/* Get Street#, Street Direction, Street Name, and street type (@B1_STR_SUFFIX), with space as delimiter */
ELSE IF UPPER(@Get_Field) = N'STREETADDR4_LINE'
  BEGIN
    IF @B1_HSE_NBR_START <> N''
        SET @VSTR = @B1_HSE_NBR_START
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
  END
/* Get only City, State and ZIP */
ELSE IF UPPER(@Get_Field) = N'CITYSTATEZIP'
  BEGIN
    IF @B1_SITUS_CITY <> N'' 
        SET @VSTR = @B1_SITUS_CITY
    IF @B1_SITUS_STATE <>N''
      BEGIN
        IF @VSTR <>N'' 
                SET @VSTR = @VSTR + N', ' + @B1_SITUS_STATE
        ELSE    
                SET @VSTR = @B1_SITUS_STATE
      END
    IF @B1_SITUS_ZIP <>N'' 
        SET  @VSTR = @VSTR +N' '+ @B1_SITUS_ZIP
  END
/*Get full address in line format is not include '#' */
ELSE IF UPPER(@Get_Field) = N'NO#INUNITTYPE'
   BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL 
        SET @VSTR = @B1_HSE_NBR_START
    IF @B1_HSE_NBR_END IS NOT NULL 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N'-' + @B1_HSE_NBR_END;
          ELSE
                SET @VSTR = @B1_HSE_NBR_END;
      END
    IF (@VSTR <> N'') AND (@B1_HSE_FRAC_NBR_START <> N'' OR @B1_HSE_FRAC_NBR_END <> N'') 
        SET @VSTR = @VSTR + N',';
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR<>N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START
      END
    IF @B1_HSE_FRAC_NBR_END <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N'-' + @B1_HSE_FRAC_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_END
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N', ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N', ' + @B1_UNIT_TYPE + N'#'
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE + N'#'
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_SITUS_CITY <> N'' 
        BEGIN
        IF @VSTR <>N'' 
                SET @VSTR = @VSTR + N', ' + @B1_SITUS_CITY
        ELSE    
                SET @VSTR = @B1_SITUS_CITY
      END
    IF @B1_SITUS_STATE <>N''
      BEGIN
        IF @VSTR <>N'' 
                SET @VSTR = @VSTR + N', ' + @B1_SITUS_STATE
        ELSE    
                SET @VSTR = @B1_SITUS_STATE
      END
    IF @B1_SITUS_ZIP <>N'' 
        SET  @VSTR = @VSTR +N' '+ @B1_SITUS_ZIP
  END
/* Get Full address in block format, excludes '#'  */
ELSE IF UPPER(@Get_Field) = N'FULLADDR_BLOCK'
  BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL 
        SET @VSTR = @B1_HSE_NBR_START 
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START;
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START;
      END
    IF (@VSTR <> N'') AND ((@B1_HSE_NBR_END IS NOT NULL AND @B1_HSE_NBR_END<>N'0') OR @B1_HSE_FRAC_NBR_END <> N'') 
        SET @VSTR = @VSTR + N' -';
    IF @B1_HSE_NBR_END IS NOT NULL AND @B1_HSE_NBR_END<>N'0'
      BEGIN
          IF @VSTR<>N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_NBR_END
      END
    IF @B1_HSE_FRAC_NBR_END <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_END
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N', ' + @B1_UNIT_TYPE
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_UNIT_END <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR=@VSTR + N' ' + @B1_UNIT_END
        ELSE
                SET @VSTR=@B1_UNIT_END
      END
    IF @B1_SITUS_CITY <> N'' 
      BEGIN
        IF @VSTR<> N''
                SET @VSTR =@VSTR + CHAR(10) + @B1_SITUS_CITY
        ELSE
                SET @VSTR =@B1_SITUS_CITY
      END
    IF @B1_SITUS_STATE <>N''
      BEGIN
        IF @VSTR <>N'' 
                SET @VSTR = @VSTR +  N', ' + @B1_SITUS_STATE
        ELSE    
                SET @VSTR = @B1_SITUS_STATE
      END
    SET  @VSTR = @VSTR +N' '+ @B1_SITUS_ZIP
  END
 ELSE IF UPPER(@Get_Field) = N'ADDR_NO_CSZ'
  BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL
        SET @VSTR = @B1_HSE_NBR_START 
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START;
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START;
      END
    IF (@VSTR <> N'') AND ((@B1_HSE_NBR_END IS NOT NULL AND 
@B1_HSE_NBR_END<>N'0') OR @B1_HSE_FRAC_NBR_END <> N'') 
        SET @VSTR = @VSTR + N' -';
    IF @B1_HSE_NBR_END IS NOT NULL AND @B1_HSE_NBR_END<>N'0'
      BEGIN
          IF @VSTR<>N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_NBR_END
      END
    IF @B1_HSE_FRAC_NBR_END <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_END
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N', ' + @B1_UNIT_TYPE + N'#'
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE + N'#'
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_UNIT_START <> N'' AND  @B1_UNIT_END <> N'' 
        SET @VSTR = @VSTR + N' -'
    IF @B1_UNIT_END <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
        ELSE
                SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
      END
 END
/* B1_HSE_NBR_START space B1_STR_PREFIX space B1_STR_NAME space B1_STR_SUFFIX comma B1_SITUS_CITY */ 
ELSE IF UPPER(@Get_Field) = N'STRNUMCITY'
BEGIN 
 IF @B1_HSE_NBR_START <>N''  
        SET @VSTR = @B1_HSE_NBR_START 
    ELSE
    	SET @VSTR = N'';     
    IF @B1_STR_PREFIX <> N'' 
      BEGIN 
        IF @VSTR <> N'' 
            SET @VSTR = @VSTR + N' ' + @B1_STR_PREFIX 
        ELSE
            SET @VSTR = @B1_STR_PREFIX 
       END 
    ELSE 
	    SET @VSTR = @VSTR;  
    IF @B1_STR_NAME <> N'' 
    BEGIN 
	      IF @VSTR <>N'' 
	            SET @VSTR = @VSTR + N' ' + @B1_STR_NAME;
	      ELSE
	            SET @VSTR = @B1_STR_NAME  
    END;  	            
     IF @B1_STR_SUFFIX <>N'' 
       BEGIN       
         IF @VSTR <> N''  
            SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX;
         ELSE
            SET @VSTR = @B1_STR_SUFFIX 
        END 
	 ELSE 
	    SET @VSTR = @VSTR; 
    IF @B1_SITUS_CITY <>N'' 
    BEGIN     
        IF @VSTR <>N'' 
          SET @VSTR = @VSTR + N', ' + @B1_SITUS_CITY;
        ELSE
          SET @VSTR = @B1_SITUS_CITY;
    END   
END 
/* UNIT_STREETINFO:  get Unit #, Street Number, Street Direction, Street Name and Street Suffix */
ELSE IF UPPER(@Get_Field) = N'UNIT_STREETINFO' 
  BEGIN
    IF @B1_UNIT_START<>N''
      SET @VSTR = @B1_UNIT_START
    IF @B1_HSE_NBR_START IS NOT NULL
	  BEGIN
        IF @VSTR <>N''
          SET @VSTR = @VSTR + N' ' + @B1_HSE_NBR_START
        ELSE
          SET @VSTR = @B1_HSE_NBR_START
      END
    IF @B1_STR_DIR<>N''
      BEGIN
        IF @VSTR<>N''
          SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
        ELSE
          SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME<>N''
      BEGIN
        IF @VSTR<>N''
          SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
        ELSE
          SET @VSTR = @B1_STR_NAME
      END
    IF @B1_STR_SUFFIX<>N''
	  BEGIN
        IF @VSTR<>N''
          SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
        ELSE
          SET @VSTR = @B1_STR_SUFFIX
      END
  END
/* B1_HSE_NBR_START space B1_STR_NAME space B1_STR_SUFFIX space B1_STR_DIR */
ELSE IF UPPER(@Get_Field) = N'STREET_NBR_NAM_TYP_SUF_DIR'
   BEGIN
      IF @B1_HSE_NBR_START IS NOT NULL
         SET @VSTR = @B1_HSE_NBR_START
      IF @B1_STR_NAME<>N''
         BEGIN
            IF @VSTR<>N''
               SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
            ELSE
               SET @VSTR = @B1_STR_NAME
         END
      IF @B1_STR_SUFFIX<>N''
         BEGIN
            IF @VSTR<>N''
               SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
            ELSE
               SET @VSTR = @B1_STR_SUFFIX
         END
      IF @B1_STR_DIR<>N''
         BEGIN
            IF @VSTR<>N''
               SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
            ELSE
               SET @VSTR = @B1_STR_DIR
         END
   END
/* DEFAULT: Get Full address, in line format */
ELSE
  BEGIN
    IF @B1_HSE_NBR_START IS NOT NULL
        SET @VSTR = @B1_HSE_NBR_START 
    IF @B1_HSE_FRAC_NBR_START <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_START;
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_START;
      END
    IF (@VSTR <> N'') AND ((@B1_HSE_NBR_END IS NOT NULL AND 
@B1_HSE_NBR_END<>N'0') OR @B1_HSE_FRAC_NBR_END <> N'') 
        SET @VSTR = @VSTR + N' -';
    IF @B1_HSE_NBR_END IS NOT NULL AND @B1_HSE_NBR_END<>N'0'
      BEGIN
          IF @VSTR<>N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_NBR_END
      END
    IF @B1_HSE_FRAC_NBR_END <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_HSE_FRAC_NBR_END
          ELSE
                SET @VSTR = @B1_HSE_FRAC_NBR_END
      END
    IF @B1_STR_DIR <> N''
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_DIR
          ELSE
                SET @VSTR = @B1_STR_DIR
      END
    IF @B1_STR_NAME <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_NAME
          ELSE
                SET @VSTR = @B1_STR_NAME 
      END
    IF @B1_STR_SUFFIX <> N'' 
      BEGIN
          IF @VSTR <> N''
                SET @VSTR = @VSTR + N' ' + @B1_STR_SUFFIX
          ELSE
                SET @VSTR = @B1_STR_SUFFIX
      END
    IF @B1_UNIT_TYPE <> N''
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N', ' + @B1_UNIT_TYPE + N'#'
        ELSE 
                SET @VSTR = @B1_UNIT_TYPE + N'#'
      END
    IF @B1_UNIT_START <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR = @VSTR + N' ' + @B1_UNIT_START
        ELSE
                SET @VSTR = @B1_UNIT_START
      END
    IF @B1_UNIT_START <> N'' AND  @B1_UNIT_END <> N'' 
        SET @VSTR = @VSTR + N' -'
    IF @B1_UNIT_END <> N'' 
      BEGIN
        IF @VSTR<> N'' 
                SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
        ELSE
                SET @VSTR=@VSTR +N' '+ @B1_UNIT_END
      END
    IF @B1_SITUS_CITY <> N'' 
      BEGIN
        IF @VSTR<> N''
                SET @VSTR =@VSTR + N', ' + @B1_SITUS_CITY
        ELSE
                SET @VSTR =@B1_SITUS_CITY
      END
    IF @B1_SITUS_STATE <>N''
      BEGIN
        IF @VSTR <>N'' 
                SET @VSTR = @VSTR + N', ' + @B1_SITUS_STATE
        ELSE    
                SET @VSTR = @B1_SITUS_STATE
      END
    IF @B1_SITUS_ZIP <>N'' 
        SET  @VSTR = @VSTR +N' '+ @B1_SITUS_ZIP
  END
  RETURN( @VSTR)
END
GO

------------------------- Create Views -------------------------
ALTER VIEW [dbo].[V_ASI_DATA] 
AS
(
SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 AS ID,
       N'ASI::' + A.B1_ACT_STATUS + N'::' + A.B1_CHECKBOX_TYPE AS ENTITY,
       A.B1_CHECKBOX_DESC AS ATTRIBUTE,
       A.B1_CHECKLIST_COMMENT AS VALUE,
	   NULL AS ROW_INDEX
  FROM BCHCKBOX A
 --WHERE A.REC_STATUS = 'A' 
 -- Combine the ASIT Data
  UNION ALL 
 SELECT A.SERV_PROV_CODE AS AGENCY_ID,
       A.B1_PER_ID1 + N'/' + A.B1_PER_ID2 + N'/' + A.B1_PER_ID3 AS ID,
       N'ASIT::' + A.GROUP_NAME + N'::' + A.TABLE_NAME AS ENTITY,
       A.COLUMN_NAME AS ATTRIBUTE,
       A.ATTRIBUTE_VALUE AS VALUE,
       A.ROW_INDEX AS ROW_INDEX
  FROM BAPPSPECTABLE_VALUE A
 WHERE A.REC_STATUS = N'A' 
)
GO
