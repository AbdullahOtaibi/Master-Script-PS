# function Get-UpgradeScripts {
param(
    [Parameter(Mandatory=$true)] 
    [ValidateSet("ORACLE", "MSSQL")] 
    [string] $RDBMS,
    [Parameter(Mandatory=$true)] 
    [ValidateSet("INSERT", "UPDATE")] 
    [string] $TypeName
)
    # TODO: put PLSQL and TSQL code in an external JSON config file
    # NOTE: placeholders will be replaced by input variables values

<# -------------------------------------------------- #>
function Get-PLSQLVersion {
param (
    [Parameter(Mandatory=$true)] 
    [ValidateSet("INSERT", "UPDATE")] 
    [string] $TypeName
)
    [string] $sqlCmd = 
    switch ($TypeName) {
        "INSERT" { "--add one record for current script applied status
SET DEFINE OFF

INSERT INTO UPGRADE_SCRIPTS (SCRIPT_SEQ,SCRIPT_NAME,RELEASE_VERSION,SCRIPT_APPLIED,REC_DATE,REC_FUL_NAM,REC_STATUS)
VALUES (<SCRIPT_SEQUENCE>, '<RELEASE_SCRIPT>', '<MASTER_SCRIPT_VERSION>', 'N', SYSDATE, 'ADMIN', 'A');" 
        }
        "UPDATE" { "--indicate the current script is applied successfully
UPDATE UPGRADE_SCRIPTS SET SCRIPT_APPLIED = 'Y', REC_DATE = SYSDATE WHERE SCRIPT_SEQ=<SCRIPT_SEQUENCE> AND RELEASE_VERSION = '<MASTER_SCRIPT_VERSION>';"
        }
    }
    return $sqlCmd
}

<# -------------------------------------------------- #>
function Get-TSQLVersion {
param (
    [Parameter(Mandatory=$true)] 
    [ValidateSet("INSERT", "UPDATE")] 
    [string] $TypeName
)
    [string] $sqlCmd =
    switch ($TypeName) {
        "INSERT" { "--add one record for current script applied status
INSERT INTO UPGRADE_SCRIPTS (SCRIPT_SEQ,SCRIPT_NAME,RELEASE_VERSION,SCRIPT_APPLIED,REC_DATE,REC_FUL_NAM,REC_STATUS)
VALUES (<SCRIPT_SEQUENCE>, '<RELEASE_SCRIPT>', '<MASTER_SCRIPT_VERSION>', 'N', CURRENT_TIMESTAMP, 'ADMIN', 'A')
GO"
        }
        "UPDATE" { "--indicate the current script is applied successfully
UPDATE UPGRADE_SCRIPTS SET SCRIPT_APPLIED = 'Y', REC_DATE = CURRENT_TIMESTAMP WHERE SCRIPT_SEQ=<SCRIPT_SEQUENCE> AND RELEASE_VERSION = '<MASTER_SCRIPT_VERSION>'
GO"     }
    }
    return $sqlCmd
}

<# -------------------------------------------------- #>
    [string] $sqlCmd = 
    switch ($RDBMS) {
        "ORACLE"    { $(Get-PLSQLVersion -TypeName $TypeName) }
        "MSSQL"     { $(Get-TSQLVersion -TypeName $TypeName) }
    }
    return $sqlCmd
# }

