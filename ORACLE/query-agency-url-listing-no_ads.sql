/*

1. ACA_CONFIGS - accela.rbizdomain_value WHERE bizdomain = 'ACA_CONFIGS' AND bizdomain_value = 'ACA_SITE' AND rec_status = 'A'
2. EDMS - accela.rbizdomain_value WHERE bizdomain = 'EDMS' AND rec_status = 'A' AND LOWER(value_desc) LIKE '%http%'
2.5 ADHOC_REPORT_SETTINGS - accela.rbizdomain_value WHERE bizdomain = 'ADHOC_REPORT_SETTINGS' 
3. LASERFICHE - accela.rbizdomain_value WHERE bizdomain='EDMS' AND rec_status='A' AND serv_prov_code='???' AND value_desc LIKE '%?.?.?.?%'
4. RBIZDOMAIN_VALUE_OTHERS - accela.rbizdomain_value WHERE bizdomain NOT IN ('EDMS','ACA_CONFIGS','ADHOC_REPORT_SETTINGS') AND rec_status = 'A' AND LOWER(value_desc) LIKE '%http%'
5. #EDOC_INDEX - ads.edoc_index
6. #RDOC_CONFIG_PROV_PROFILE - ads.rdoc_config_prov_profile WHERE profile_name = 'FileRepository-FileDatabase'
7. BPORTLETLINKS - accela.bportletlinks WHERE LOWER(link_url) LIKE '%http%'
8. ADHOC_URLS - accela.xpolicy WHERE policy_name = 'ReportService' AND level_data IN ('url','reportNameURL') AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)='ADHOC')
9. CRYSTAL_URLS - accela.xpolicy WHERE policy_name = 'ReportService' AND level_data IN ('url','reportNameURL') AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)='CRYSTAL')
10. XPOLICY_OTHER - 
  accela.xpolicy WHERE policy_name != 'ReportService' AND LOWER(data1) LIKE '%http%'
  accela.xpolicy WHERE policy_name != 'ReportService' AND LOWER(data2) LIKE '%http%'
  accela.xpolicy WHERE policy_name != 'ReportService' AND LOWER(data3) LIKE '%http%'
11. GIS_SERVICE_URL - accela.agis_service WHERE LOWER(gis_service_url) LIKE '%http%'
12. GIS_JAVASCRIPT_API_URL - accela.agis_service WHERE LOWER(gis_javascript_api_url) LIKE '%http%'
13. GPORTLET - accela.gportlet WHERE LOWER(portlet_url) LIKE '%http%'
14. REVT_AGENCY_SCRIPT - accela.revt_agency_script WHERE LOWER(script_text) LIKE '%http%' AND LENGTH(REGEXP_SUBSTR(script_text,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')) > 8
15. AGIS_APPSERVERURL - agisuser.configuration ('wireless/GovXMLServlet' entries, table may be named jsagis.configuration)
16. AMO_APP_SERVER - amo.agency.app_server
17. ACCELAGISSERVER - amo.agency WHERE LOWER(accelagisserver) LIKE 'http%' 
*/

-- 1. ACA_CONFIGS
SELECT COUNT(1) "URL Count",
       'ACA_CONFIGS' "Context",
       'accela.rbizdomain_value.value_desc' "Table Column",
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS "Agency SPC",
       value_desc "URL",
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain=''ACA_CONFIGS'' AND bizdomain_value=''ACA_SITE'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';' 
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain=''ACA_CONFIGS'' AND bizdomain_value=''ACA_SITE'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';' 
       END AS "Update Stmt",
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END AS "Entire URL"
  FROM accela.rbizdomain_value
 WHERE bizdomain = 'ACA_CONFIGS' AND bizdomain_value = 'ACA_SITE' AND rec_status = 'A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       value_desc,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain=''ACA_CONFIGS'' AND bizdomain_value=''ACA_SITE'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';' 
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain=''ACA_CONFIGS'' AND bizdomain_value=''ACA_SITE'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';' 
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
 -- 2. EDMS
 SELECT COUNT(1) counter,
       'EDMS' setting,
       'accela.rbizdomain_value.value_desc' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain = ''EDMS'' AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'';'
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain = ''EDMS'' AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.rbizdomain_value
 WHERE bizdomain = 'EDMS' AND rec_status = 'A' AND LOWER(value_desc) LIKE '%http%'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?'),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain = ''EDMS'' AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'';'
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain = ''EDMS'' AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 2.5 ADHOC_REPORT_SETTINGS
SELECT COUNT(1) counter,
       'ADHOC_REPORT_SETTINGS' setting,
       'accela.rbizdomain_value.value_desc' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       value_desc url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain = ''ADHOC_REPORT_SETTINGS'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';'
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain = ''ADHOC_REPORT_SETTINGS'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.rbizdomain_value
 WHERE bizdomain = 'ADHOC_REPORT_SETTINGS' AND rec_status = 'A' AND LOWER(value_desc) LIKE '%http%'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       value_desc,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain = ''ADHOC_REPORT_SETTINGS'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';'
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain = ''ADHOC_REPORT_SETTINGS'' AND rec_status = ''A'' AND value_desc = '''||value_desc||''';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 3. LASERFICHE
SELECT COUNT(1) counter,
       'LASERFICHE' setting,
       'accela.rbizdomain_value.value_desc' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       value_desc url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code=''???'' AND bizdomain=''EDMS'' AND rec_status=''A'' AND serv_prov_code = ''OR_MHODS'' AND value_desc LIKE ''%.%.%.%'';' --IP address
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain=''EDMS'' AND rec_status=''A'' AND serv_prov_code = ''OR_MHODS'' AND value_desc LIKE ''%.%.%.%'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.rbizdomain_value 
 WHERE bizdomain='EDMS' AND rec_status='A' AND serv_prov_code = 'OR_MHODS' AND value_desc LIKE '%.%.%.%'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       value_desc,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code=''???'' AND bizdomain=''EDMS'' AND rec_status=''A'' AND serv_prov_code = ''OR_MHODS'' AND value_desc LIKE ''%.%.%.%'';' --IP address
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         value_desc||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain=''EDMS'' AND rec_status=''A'' serv_prov_code = ''OR_MHODS'' AND value_desc LIKE ''%.%.%.%'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 4. RBIZDOMAIN_VALUE_OTHERS
SELECT COUNT(1) counter,
       'RBIZDOMAIN_VALUE_OTHERS' setting,
       'accela.rbizdomain_value.value_desc' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?') url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain NOT IN (''EDMS'',''ACA_CONFIGS'',''ADHOC_REPORT_SETTINGS'') AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||'%'';'
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain NOT IN (''EDMS'',''ACA_CONFIGS'',''ADHOC_REPORT_SETTINGS'') AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||'%'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.rbizdomain_value
 WHERE bizdomain NOT IN ('EDMS','ACA_CONFIGS','ADHOC_REPORT_SETTINGS') AND rec_status = 'A' AND LOWER(value_desc) LIKE '%http%'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?'),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND bizdomain NOT IN (''EDMS'',''ACA_CONFIGS'',''ADHOC_REPORT_SETTINGS'') AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||'%'';'
       ELSE
         'UPDATE ACCELA.RBIZDOMAIN_VALUE SET value_desc = REPLACE(value_desc,'''||
         REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE bizdomain NOT IN (''EDMS'',''ACA_CONFIGS'',''ADHOC_REPORT_SETTINGS'') AND rec_status = ''A'' AND value_desc LIKE ''%'||REGEXP_SUBSTR(value_desc,'http[sS]*://([a-zA-Z0-9_-{}]+\.?){3,5}/?')||'%'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         value_desc 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
/*
-- 5. EDOC_INDEX
SELECT COUNT(1) counter,
       'EDOC_INDEX' setting,
       'ads.edoc_index.repository_file_database' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       repository_file_database url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ADS.EDOC_INDEX SET repository_file_database = REPLACE(repository_file_database,'''||
         repository_file_database||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND repository_file_database='''||repository_file_database||''' AND rec_status = ''A'';' 
       ELSE
         'UPDATE ADS.EDOC_INDEX SET repository_file_database = REPLACE(repository_file_database,'''||
         repository_file_database||
         ''','''||CHR(38)||'1'') '||
         'WHERE repository_file_database='''||repository_file_database||''' AND rec_status = ''A'';' 
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         repository_file_database 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM ads.edoc_index 
 WHERE rec_status = 'A'
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       repository_file_database,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ADS.EDOC_INDEX SET repository_file_database = REPLACE(repository_file_database,'''||
         repository_file_database||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND repository_file_database='''||repository_file_database||''' AND rec_status = ''A'';' 
       ELSE
         'UPDATE ADS.EDOC_INDEX SET repository_file_database = REPLACE(repository_file_database,'''||
         repository_file_database||
         ''','''||CHR(38)||'1'') '||
         'WHERE repository_file_database='''||repository_file_database||''' AND rec_status = ''A'';' 
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         repository_file_database 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 6. RDOC_CONFIG_PROV_PROFILE
SELECT COUNT(1) counter,
       'RDOC_CONFIG_PROV_PROFILE' setting,
       'ads.rdoc_config_prov_profile' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       profile_value url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ADS.RDOC_CONFIG_PROV_PROFILE SET profile_value = REPLACE(profile_value,'''||
         profile_value||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND profile_name=''FileRepository-FileDatabase'' AND rec_status = ''A'';' 
       ELSE
         'UPDATE ADS.RDOC_CONFIG_PROV_PROFILE SET profile_value = REPLACE(profile_value,'''||
         profile_value||
         ''','''||CHR(38)||'1'') '||
         'WHERE profile_name=''FileRepository-FileDatabase'' AND rec_status = ''A'';' 
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         profile_value 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM ads.rdoc_config_prov_profile
 WHERE profile_name = 'FileRepository-FileDatabase'
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       profile_value,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ADS.RDOC_CONFIG_PROV_PROFILE SET profile_value = REPLACE(profile_value,'''||
         profile_value||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND profile_name=''FileRepository-FileDatabase'' AND rec_status = ''A'';' 
       ELSE
         'UPDATE ADS.RDOC_CONFIG_PROV_PROFILE SET profile_value = REPLACE(profile_value,'''||
         profile_value||
         ''','''||CHR(38)||'1'') '||
         'WHERE profile_name=''FileRepository-FileDatabase'' AND rec_status = ''A'';' 
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         profile_value 
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
*/
-- 7. BPORTLETLINKS
SELECT COUNT(1) counter,
       'BPORTLETLINKS' setting,
       'accela.bportletlinks.link_url' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.BPORTLETLINKS SET link_url = REPLACE(link_url,'''||
         REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND LOWER(link_url) LIKE ''%'||REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.BPORTLETLINKS SET link_url = REPLACE(link_url,'''||
         REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE LOWER(link_url) LIKE ''%'||REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         link_url 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.bportletlinks
 WHERE LOWER(link_url) LIKE '%http%' AND rec_status = 'A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?'),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.BPORTLETLINKS SET link_url = REPLACE(link_url,'''||
         REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND LOWER(link_url) LIKE ''%'||REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.BPORTLETLINKS SET link_url = REPLACE(link_url,'''||
         REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE LOWER(link_url) LIKE ''%'||REGEXP_SUBSTR(link_url,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         link_url
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 8. ADHOC_URLS
SELECT COUNT(1) counter,
       'ADHOC_URLS' setting,
       'accela.xpolicy.data1' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       data1 url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name ='''||policy_name||''' AND level_data='''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''ADHOC'') AND data1='''||data1||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name = '''||policy_name||''' AND level_data='''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''ADHOC'') AND data1='''||data1||''' AND rec_status=''A'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data1
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.xpolicy
 WHERE policy_name = 'ReportService' AND level_data IN ('url','reportNameURL') AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)='ADHOC') AND rec_status='A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       data1,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name ='''||policy_name||''' AND level_data='''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''ADHOC'') AND data1='''||data1||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name = '''||policy_name||''' AND level_data='''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''ADHOC'') AND data1='''||data1||''' AND rec_status=''A'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data1
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 9. CRYSTAL_URLS
SELECT COUNT(1) counter,
       'CRYSTAL_URLS' setting,
       'accela.xpolicy.data1' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       data1 url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name = '''||policy_name||''' AND level_data = '''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''CRYSTAL'') AND data1='''||data1||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name = '''||policy_name||''' AND level_data = '''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''CRYSTAL'') AND data1='''||data1||''' AND rec_status=''A'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data1 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.xpolicy
 WHERE policy_name = 'ReportService' AND level_data IN ('url','reportNameURL') AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)='CRYSTAL') AND rec_status='A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       data1,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name = '''||policy_name||''' AND level_data = '''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''CRYSTAL'') AND data1='''||data1||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         data1||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name = '''||policy_name||''' AND level_data = '''||level_data||''' AND level_type IN (SELECT level_Type FROM accela.xpolicy WHERE UPPER(data1)=''CRYSTAL'') AND data1='''||data1||''' AND rec_status=''A'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data1
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 10. XPOLICY_OTHER
SELECT COUNT(1) counter,
       'XPOLICY_OTHER' setting,
       'accela.xpolicy.data1' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name != ''ReportService'' AND data1 LIKE ''%'||REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name != ''ReportService'' AND data1 LIKE ''%'||REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data1 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.xpolicy
 WHERE policy_name != 'ReportService' AND LOWER(data1) LIKE '%http%' AND rec_status='A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?'),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name != ''ReportService'' AND data1 LIKE ''%'||REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.XPOLICY SET data1 = REPLACE(data1,'''||
         REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name != ''ReportService'' AND data1 LIKE ''%'||REGEXP_SUBSTR(data1,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data1
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
SELECT COUNT(1) counter,
       'XPOLICY_OTHER' setting,
       'accela.xpolicy.data2' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data2 = REPLACE(data2,'''||
         REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name != ''ReportService'' AND data2 LIKE ''%'||REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.XPOLICY SET data2 = REPLACE(data2,'''||
         REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name != ''ReportService'' AND data2 LIKE ''%'||REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data2 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.xpolicy
 WHERE policy_name != 'ReportService' AND LOWER(data2) LIKE '%http%' AND rec_status='A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?'),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data2 = REPLACE(data2,'''||
         REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name != ''ReportService'' AND data2 LIKE ''%'||REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.XPOLICY SET data2 = REPLACE(data2,'''||
         REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name != ''ReportService'' AND data2 LIKE ''%'||REGEXP_SUBSTR(data2,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data2
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
SELECT COUNT(1) counter,
       'XPOLICY_OTHER' setting,
       'accela.xpolicy.data3' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data3 = REPLACE(data3,'''||
         REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name != ''ReportService'' AND data3 LIKE ''%'||REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.XPOLICY SET data3 = REPLACE(data3,'''||
         REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name != ''ReportService'' AND data3 LIKE ''%'||REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data3 
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.xpolicy
 WHERE policy_name != 'ReportService' AND LOWER(data3) LIKE '%http%' AND rec_status='A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?'),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.XPOLICY SET data3 = REPLACE(data3,'''||
         REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND policy_name != ''ReportService'' AND data3 LIKE ''%'||REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.XPOLICY SET data3 = REPLACE(data3,'''||
         REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE policy_name != ''ReportService'' AND data3 LIKE ''%'||REGEXP_SUBSTR(data3,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         data3
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 11. GIS_SERVICE_URL
SELECT COUNT(1) count,
       'GIS_SERVICE_URL' setting,
       'accela.agis_service.gis_service_url' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         r.serv_prov_code
       ELSE
         'Group by all'
       END,
       a.gis_service_url url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.AGIS_SERVICE SET gis_service_url = REPLACE(gis_service_url,'''||
         gis_service_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE agency='''||r.apo_src_seq_nbr||''' AND gis_service_url = '''||gis_service_url||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.AGIS_SERVICE SET gis_service_url = REPLACE(gis_service_url,'''||
         gis_service_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE gis_service_url = '''||gis_service_url||''' AND rec_status=''A'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         a.gis_service_url
       ELSE
         TO_CHAR(NULL) 
       END AS url_entire
  FROM accela.rserv_prov r,
       accela.agis_service a
 WHERE r.serv_prov_code = NVL(:SERV_PROV_CODE,r.serv_prov_code)
   AND a.agency = r.apo_src_seq_nbr
   AND LOWER(a.gis_service_url) LIKE '%http%' AND a.rec_status='A'
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         r.serv_prov_code
       ELSE
         'Group by all'
       END,
       a.gis_service_url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.AGIS_SERVICE SET gis_service_url = REPLACE(gis_service_url,'''||
         gis_service_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE agency='''||r.apo_src_seq_nbr||''' AND gis_service_url = '''||gis_service_url||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.AGIS_SERVICE SET gis_service_url = REPLACE(gis_service_url,'''||
         gis_service_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE gis_service_url = '''||gis_service_url||''' AND rec_status=''A'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         a.gis_service_url
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
-- 12. GIS_JAVASCRIPT_API_URL
SELECT COUNT(1) count,
       'GIS_JAVASCRIPT_API_URL' setting,
       'accela.agis_service.gis_javascript_api_url' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         r.serv_prov_code
       ELSE
         'Group by all'
       END,
       a.gis_javascript_api_url url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.AGIS_SERVICE SET gis_javascript_api_url = REPLACE(gis_javascript_api_url,'''||
         a.gis_javascript_api_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE agency='''||r.apo_src_seq_nbr||''' and gis_javascript_api_url = '''||a.gis_javascript_api_url||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.AGIS_SERVICE SET gis_javascript_api_url = REPLACE(gis_javascript_api_url,'''||
         a.gis_javascript_api_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE gis_javascript_api_url = '''||a.gis_javascript_api_url||''' AND rec_status=''A'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         a.gis_javascript_api_url
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.rserv_prov r,
       accela.agis_service a
 WHERE r.serv_prov_code = NVL(:SERV_PROV_CODE,r.serv_prov_code)
   AND a.agency = r.apo_src_seq_nbr
   AND LOWER(a.gis_javascript_api_url) LIKE '%http%' AND a.rec_status='A'
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         r.serv_prov_code
       ELSE
         'Group by all'
       END,
       a.gis_javascript_api_url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.AGIS_SERVICE SET gis_javascript_api_url = REPLACE(gis_javascript_api_url,'''||
         a.gis_javascript_api_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE agency='''||r.apo_src_seq_nbr||''' and gis_javascript_api_url = '''||a.gis_javascript_api_url||''' AND rec_status=''A'';'
       ELSE
         'UPDATE ACCELA.AGIS_SERVICE SET gis_javascript_api_url = REPLACE(gis_javascript_api_url,'''||
         a.gis_javascript_api_url||
         ''','''||CHR(38)||'1'') '||
         'WHERE gis_javascript_api_url = '''||a.gis_javascript_api_url||''' AND rec_status=''A'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         a.gis_javascript_api_url
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
 --13. GPORTLET
 SELECT COUNT(1) count,
       'GPORTLET' setting,
       'accela.gportlet.portlet_url' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       portlet_url url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.GPORTLET SET portlet_url = REPLACE(portlet_url,'''||portlet_url||''','''||CHR(38)||'1'') '||
          'WHERE serv_prov_code='''||serv_prov_code||''' AND portlet_url = '''||portlet_url||''' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.GPORTLET SET portlet_url = REPLACE(portlet_url,'''||portlet_url||''','''||CHR(38)||'1'') '||
          'WHERE portlet_url = '''||portlet_url||''' AND rec_status=''A'';'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         portlet_url
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.gportlet
 WHERE LOWER(portlet_url) LIKE '%http%' AND rec_status='A'
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       portlet_url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.GPORTLET SET portlet_url = REPLACE(portlet_url,'''||portlet_url||''','''||CHR(38)||'1'') '||
          'WHERE serv_prov_code='''||serv_prov_code||''' AND portlet_url = '''||portlet_url||''' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.GPORTLET SET portlet_url = REPLACE(portlet_url,'''||portlet_url||''','''||CHR(38)||'1'') '||
          'WHERE portlet_url = '''||portlet_url||''' AND rec_status=''A'';'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         portlet_url
       ELSE
         TO_CHAR(NULL) 
       END
 UNION ALL
--14. REVT_AGENCY_SCRIPT
 SELECT COUNT(1) count,
       'REVT_AGENCY_SCRIPT' setting,
       'accela.revt_agency_script.script_text' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END AS serv_prov_code,
       CAST(REGEXP_SUBSTR(script_text,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') AS VARCHAR2(4000)) url,
       TO_CHAR(NULL) update_stmt,
       /* Throwing ORA-06502: PL/SQL: numeric or value error: character string buffer too small in SV4 TSTDBSV4
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.REVT_AGENCY_SCRIPT SET script_text = REPLACE(script_text,'''||
         REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND script_text LIKE ''%'||REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.REVT_AGENCY_SCRIPT SET script_text = REPLACE(script_text,'''||
         REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE script_text LIKE ''%'||REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END AS update_stmt,
       */
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(NULL)
         --DBMS_LOB.SUBSTR(script_text,4000,1)
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM accela.revt_agency_script
 WHERE LOWER(script_text) LIKE '%http%' AND rec_status='A'
   AND LENGTH(REGEXP_SUBSTR(script_text,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')) > 8
   AND serv_prov_code = NVL(:SERV_PROV_CODE,serv_prov_code)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         serv_prov_code
       ELSE
         'Group by all'
       END,
       CAST(REGEXP_SUBSTR(script_text,'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?') AS VARCHAR2(4000)),
       /*
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE ACCELA.REVT_AGENCY_SCRIPT SET script_text = REPLACE(script_text,'''||
         REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE serv_prov_code='''||serv_prov_code||''' AND script_text LIKE ''%'||REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';' 
       ELSE
         'UPDATE ACCELA.REVT_AGENCY_SCRIPT SET script_text = REPLACE(script_text,'''||
         REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||
         ''','''||CHR(38)||'1'') '||
         'WHERE script_text LIKE ''%'||REGEXP_SUBSTR(DBMS_LOB.SUBSTR(script_text,4000,1),'http[sS]*://([a-zA-Z0-9_-]+\.?){3,5}/?')||'%'' AND rec_status=''A'';'  
       END,
       */
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(NULL)
         --DBMS_LOB.SUBSTR(script_text,4000,1)
       ELSE
         TO_CHAR(NULL) 
       END
--15. AGIS_APPSERVERURL
UNION ALL
SELECT COUNT(1) count,
       'AGIS_APPSERVERURL' setting,
       'agisuser.configuration.appserverurl' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         TO_CHAR(agency)
       ELSE
         'Group by all'
       END AS serv_prov_code,
       TO_CHAR(appserverurl) url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE agisuser.configuration SET appserverurl = REPLACE(appserverurl,'''||TO_CHAR(appserverurl)||''','''||CHR(38)||'1'') '||
         'WHERE agency='''||TO_CHAR(agency)||''';' 
       ELSE
         'UPDATE agisuser.configuration SET appserverurl = REPLACE(appserverurl,'''||TO_CHAR(appserverurl)||''','''||CHR(38)||'1'');'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(appserverurl)
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM agisuser.configuration
 WHERE agency = NVL(TO_NCHAR(:SERV_PROV_CODE),agency)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         TO_CHAR(agency)
       ELSE
         'Group by all'
       END,
       TO_CHAR(appserverurl),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE agisuser.configuration SET appserverurl = REPLACE(appserverurl,'''||TO_CHAR(appserverurl)||''','''||CHR(38)||'1'') '||
         'WHERE agency='''||TO_CHAR(agency)||''';' 
       ELSE
         'UPDATE agisuser.configuration SET appserverurl = REPLACE(appserverurl,'''||TO_CHAR(appserverurl)||''','''||CHR(38)||'1'');'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(appserverurl)
       ELSE
         TO_CHAR(NULL) 
       END
--16. AMO_APP_SERVER
UNION ALL
SELECT COUNT(1) count,
       'AMO_APP_SERVER' setting,
       'amo.agency.app_server' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         TO_CHAR(provider_code)
       ELSE
         'Group by all'
       END AS serv_prov_code,
       TO_CHAR(app_server) url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE amo.agency SET app_server = REPLACE(app_server,'''||TO_CHAR(app_server)||''','''||CHR(38)||'1'') '||
         'WHERE provider_code='''||TO_CHAR(provider_code)||''';' 
       ELSE
         'UPDATE amo.agency SET app_server = REPLACE(app_server,'''||TO_CHAR(app_server)||''','''||CHR(38)||'1'');'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(app_server)
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM amo.agency
 WHERE provider_code = NVL(:SERV_PROV_CODE,provider_code)
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         TO_CHAR(provider_code)
       ELSE
         'Group by all'
       END,
       TO_CHAR(app_server),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE amo.agency SET app_server = REPLACE(app_server,'''||TO_CHAR(app_server)||''','''||CHR(38)||'1'') '||
         'WHERE provider_code='''||TO_CHAR(provider_code)||''';' 
       ELSE
         'UPDATE amo.agency SET app_server = REPLACE(app_server,'''||TO_CHAR(app_server)||''','''||CHR(38)||'1'');'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(app_server)
       ELSE
         TO_CHAR(NULL) 
       END
--17. ACCELAGISSERVER
UNION ALL
SELECT COUNT(1) count,
       'ACCELAGISSERVER' setting,
       'amo.agency.accelagisserver' table_column,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         TO_CHAR(provider_code)
       ELSE
         'Group by all'
       END AS serv_prov_code,
       TO_CHAR(accelagisserver) url,
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE amo.agency SET accelagisserver = REPLACE(accelagisserver,'''||TO_CHAR(accelagisserver)||''','''||CHR(38)||'1'') '||
         'WHERE provider_code='''||TO_CHAR(provider_code)||''';' 
       ELSE
         'UPDATE amo.agency SET accelagisserver = REPLACE(accelagisserver,'''||TO_CHAR(accelagisserver)||''','''||CHR(38)||'1'');'
       END AS update_stmt,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(accelagisserver)
       ELSE
         TO_CHAR(NULL) 
       END url_entire
  FROM amo.agency
 WHERE provider_code = NVL(:SERV_PROV_CODE,provider_code)
   AND LOWER(accelagisserver) LIKE 'http%'
 GROUP BY 
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         TO_CHAR(provider_code)
       ELSE
         'Group by all'
       END,
       TO_CHAR(accelagisserver),
       CASE WHEN :GROUP_BY_SPC = 'YES' THEN
         'UPDATE amo.agency SET accelagisserver = REPLACE(accelagisserver,'''||TO_CHAR(accelagisserver)||''','''||CHR(38)||'1'') '||
         'WHERE provider_code='''||TO_CHAR(provider_code)||''';' 
       ELSE
         'UPDATE amo.agency SET accelagisserver = REPLACE(accelagisserver,'''||TO_CHAR(accelagisserver)||''','''||CHR(38)||'1'');'
       END,
       CASE WHEN :SHOW_ENTIRE_URL = 'YES' THEN
         TO_CHAR(accelagisserver)
       ELSE
         TO_CHAR(NULL) 
       END
 ORDER BY 2,3,4,5;