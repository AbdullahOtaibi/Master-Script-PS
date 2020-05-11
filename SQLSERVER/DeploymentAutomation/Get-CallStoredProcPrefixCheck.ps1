# function Get-CallStoredProcPrefixCheck {
param (
    [Parameter(Mandatory=$true)] 
    [ValidateSet("ORACLE", "MSSQL")] 
    [string] $RDBMS
    )
    # TODO: put PLSQL and TSQL code in an external JSON config file
    # NOTE: placeholders will be replaced by input variables values
    [string] $sqlCmd = 
    switch ($RDBMS) {
        "ORACLE"    {"
EXEC prefix_check (<SCRIPT_SEQUENCE>, '<MASTER_SCRIPT_VERSION>', '<RELEASE_SCRIPT>');

EXEC prefix_check (NULL, '<MASTER_SCRIPT_VERSION>', '<PREVIOUS_SCRIPT>');
"
        }
        "MSSQL"     {"
EXEC prefix_check @p_seq = <SCRIPT_SEQUENCE>, @p_rel = '<MASTER_SCRIPT_VERSION>', @p_sname = '<RELEASE_SCRIPT>';
GO

EXEC prefix_check @p_seq = NULL, @p_rel = '<MASTER_SCRIPT_VERSION>', @p_sname = '<PREVIOUS_SCRIPT>';
GO
"
        }
    }
    return $sqlCmd
# }
