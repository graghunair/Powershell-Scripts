cls

#Variable Declarations and Initiations
    [string]$varSQL_Server_1 = "<SQL-Server-1>"
    [string]$varSQL_Server_2 = "<SQL-Server-2>"
    [string]$varDatabase_Name = "master"    

#T-SQL Queries
    $varGetDatabases_Query =
@"
    SET NOCOUNT ON
    GO
    SELECT [name] 
    FROM   [sys].[databases] 
    WHERE  [database_id] > 4
    GO
"@

$varSQL_Server_1_Database_List = Invoke-Sqlcmd -ServerInstance $varSQL_Server_1 -Database $varDatabase_Name -Query $varGetDatabases_Query
$varSQL_Server_2_Database_List = Invoke-Sqlcmd -ServerInstance $varSQL_Server_2 -Database $varDatabase_Name -Query $varGetDatabases_Query

Write-Host '------------------------------------------------------'
Write-Host 'Comparing: "' $varSQL_Server_1 '" and "' $varSQL_Server_2 '"'
Write-Host '------------------------------------------------------'
Compare-Object -ReferenceObject $varSQL_Server_1_Database_List.Name -DifferenceObject $varSQL_Server_2_Database_List.Name #-IncludeEqual
