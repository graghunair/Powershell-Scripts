<#
        Purpose     :     To gather cluster nodes and SQL Server Instances on each node.
        Date        :     11th June, 2026
        Version     :     1.0
#>

cls

$Cluster_Name = (Get-Cluster).Name
$Nodes = Get-ClusterNode -Cluster $Cluster_Name

    $GetSQL_Server_Details =
@"
    SET NOCOUNT ON
    GO
    SELECT	SERVERPROPERTY('ServerName') AS [SQL_Server_Name], 
		    SERVERPROPERTY('Edition') AS [Edition], 
		    SERVERPROPERTY('IsClustered') AS [Is_Clustered],
		    SERVERPROPERTY('IsHadrEnabled') AS [Is_HADR_Enabled], 
		    SERVERPROPERTY('ProductVersion') AS [SQL_Server_Build],
		    GETDATE() AS [Date_Captured]
    GO
"@

$Cluster_Nodes = ForEach ($Node in $Nodes) 
    {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Node.Name -ErrorAction SilentlyContinue

        $SQL_Instances = Get-Service -ComputerName $Node | Where-Object {$_.Name -eq 'MSSQLSERVER' -or $_.Name -like 'MSSQL$*'}
        
        ForEach ($SQL_Instance in $SQL_Instances)
                            {
                                if ($SQL_Instance.Name -eq 'MSSQLSERVER') 
                                    {
                                        # Default instance
                                        $SQL_Server_Instance = $Node
                                    }
                                else 
                                    {
                                        # Named instance
                                        $Instance_Name = ($SQL_Instance.Name -split '\$')[1]
                                        $SQL_Server_Instance = "$Node\$Instance_Name"
                                    }

                                $SQL_Server_Details = Invoke-Sqlcmd -ServerInstance $SQL_Server_Instance -Query $GetSQL_Server_Details

                                [PSCustomObject]@{
                                    Cluster_Name = $Cluster_Name
                                    Node_Name    = $Node.Name
                                    State       = $Node.State
                                    OS          = $OS.Caption
                                    SQL_Server_Instance  = $SQL_Server_Instance
                                    SQL_Server_Edition = $SQL_Server_Details.Edition
                                    SQL_Server_Is_Clustered = $SQL_Server_Details.Is_Clustered
                                    SQL_Server_Is_HADR_Enabled = $SQL_Server_Details.Is_HADR_Enabled
                                    SQL_Server_Build = $SQL_Server_Details.SQL_Server_Build
                                    Date_Captured = $SQL_Server_Details.Date_Captured
                                    }
                            }
    }

# Output
$Cluster_Nodes | Format-Table -AutoSize

    

