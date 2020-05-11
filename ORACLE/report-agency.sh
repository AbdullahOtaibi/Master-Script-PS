#!/bin/bash
# Usage: PSA.ps1 -DS _ds_ -SSH -Nohup -File report-agency.sh -Params "<ORACLE_SID> <ORACLE_HOME> <REMOTE_DIR> _spc_ $(PSA.ps1 -Base64 ' ') _email_" -RemoteDir _remote_dir_
 
export ORACLE_SID=$1
export ORACLE_HOME=$2
REMOTE_DIR=$3
SPC=$4
TICKET_DESC=$(echo -n $5 | base64 -d)
EMAIL=$6

echo Start $0
echo $(date)

echo ${ORACLE_SID}
echo ${ORACLE_HOME}
echo ${SPC}

if [ "${TICKET_DESC}" != " " ]; then
  echo ""
  echo "${TICKET_DESC}"
fi

cd ${REMOTE_DIR}
${ORACLE_HOME}/bin/sqlplus -s "/ as sysdba" <<EOF

SET FEEDBACK OFF
EXEC accela.count_spc('${SPC}');
SET FEEDBACK ON

SET TAB OFF
SET LINES 500
SET PAGESIZE 50000

SET FEEDBACK OFF
COLUMN "Agency Name" FORMAT A30
COLUMN "Agency Name2" FORMAT A30
SELECT apo_src_seq_nbr "Agency SRC",
       name "Agency Name",
       name2 "Agency Name2"
  FROM accela.rserv_prov 
 WHERE serv_prov_code='${SPC}';

SET FEEDBACK ON
BREAK ON REPORT
COMPUTE SUM LABEL "Agency Totals" OF "Row Count" ON REPORT
COMPUTE SUM OF "AA_SYS_SEQ" ON REPORT
COMPUTE SUM OF "AA_SEQ" ON REPORT
COLUMN "Agency Table" FORMAT A50
COLUMN "Row Count" FORMAT FM999,999,990
COLUMN "Type" FORMAT A4
SELECT target.table_name "Agency Table",
       target.row_count "Row Count",
       (SELECT CASE WHEN aaobj.tran_flag = 'Y' THEN 'TRN'
                    WHEN aaobj.agency_config = 'Y' THEN 'CFG'
                    ELSE NULL
               END AS source_type
          FROM accela.aa_objects aaobj
         WHERE aaobj.object_name = target.table_name
           AND aaobj.owner = 'ACCELA'
           AND aaobj.object_type = 'TABLE'
       ) "Type",
       (SELECT COUNT(1) 
          FROM accela.aa_sys_seq ass
         WHERE SUBSTR(ass.sequence_desc,1,INSTR(ass.sequence_desc,'.')-1) = target.table_name
       ) "AA_SYS_SEQ",
       CASE WHEN target.table_name IN ('F4INVOICE','B1PERMIT','F4RECEIPT') THEN
         1
       ELSE
         0
       END AS "AA_SEQ"
  FROM accela.aa_tab_count target
 WHERE target.serv_prov_code='${SPC}'
 ORDER BY 
       target.table_name;

SET FEEDBACK OFF
COLUMN "BDDoc Count" FORMAT FM999,999,990
SELECT COUNT(1) "BDDoc Count",
       ROUND(SUM(file_size)/1024/1024/1024) "BDDoc Size(GB)" 
  FROM accela.bdocument
 WHERE serv_prov_code='${SPC}';

VAR GROUP_BY_SPC VARCHAR2(3);
EXEC :GROUP_BY_SPC := 'YES';
VAR SHOW_ENTIRE_URL VARCHAR2(3);
EXEC :SHOW_ENTIRE_URL := 'YES';
VAR SERV_PROV_CODE VARCHAR2(200);
EXEC :SERV_PROV_CODE := '${SPC}';

SET FEEDBACK ON
COLUMN "URL Count" FORMAT 9999
COLUMN "Agency SPC" FORMAT A15
COLUMN "URL" FORMAT A100
COLUMN "Update Stmt" FORMAT A450
COLUMN "Entire URL" FORMAT A300
@query-agency-url-listing-no_ads.sql

COLUMN "Agency Module" FORMAT A45
SELECT DISTINCT 
       aam.module_name "Agency Module",
       aam.aa_version_nbr "Version"
  FROM accela.pprov_menuitem_module pmm,
       accela.aaversion_module aam
 WHERE pmm.serv_prov_code='${SPC}'
   AND pmm.status='ENABLE'
   AND aam.module_name = pmm.module_name
 ORDER BY 
       aam.module_name;

EXIT;
EOF

if [ ${EMAIL} ]
then
  echo "" | mailx -s "$(hostname):${ORACLE_SID} ${0} for ${SPC} has completed" ${EMAIL}
fi

echo $(date)
echo Finish $0

exit;
