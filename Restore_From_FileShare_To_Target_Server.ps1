<#
    Author     :     Raghu Gopalakrishnan
    Date       :     25th Nov 2019
    Version    :     1.0
    Purpose    :     The script accepts 2 parameters:
                     1. Location of SQL Server Database Backup (.bak) files that needs to be restored
                     2. Name of the target SQL Server Instance

    Modification History
    --------------------
    25th Nov 2019     :     Raghu Gopalakrishnan     :     Inception
#>

#Input Arguments 
#Pass the SQL Server name as the parameter to this script
	Param 
	(  
	    [parameter(Mandatory=$false)]
	    [ValidateNotNullOrEmpty()]
	    [Alias('L')]
	    [ValidateLength(1, 255)]
	    [string]$varBackup_File_Location,

	    [parameter(Mandatory=$false)]
	    [ValidateNotNullOrEmpty()]
	    [Alias('S')]
	    [ValidateLength(1, 255)]
	    [string]$varTarget_SQL_Server_Instance_Name,

	    [parameter(Mandatory=$false)]
	    [ValidateNotNullOrEmpty()]
	    [Alias('D')]
	    [ValidateLength(1, 1)]
	    [string]$varDebug
	)  

Import-Module SQLPS

[int]$varBackup_File_Count = 0
[int]$varBackup_File_Counter = 0
[string]$varBackup_File_Name = ""
$varBackup_File_Location = "C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Backup"
$varTarget_SQL_Server_Instance_Name = ".\SQL2019"
[string]$varConnection_Database_Name = "master"

cls

$varBackup_File_Location, $varTarget_SQL_Server_Instance_Name

$varBackup_Files = Get-ChildItem -Path $varBackup_File_Location -Recurse -Filter "*.bak" | Sort-Object -Property Length
$varBackup_File_Count = $varBackup_Files.Count

"Total Backup Files Identified (*.bak): " + $varBackup_File_Count.ToString()
"-------------------------------------------"

        $varQuery = "SELECT CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS VARCHAR(255)) AS Data_Path, CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS VARCHAR(255)) AS Log_Path"
        $varInstance_Default_Path = Invoke-Sqlcmd -ServerInstance $varTarget_SQL_Server_Instance_Name -Database $varConnection_Database_Name -Query $varQuery

        ""
        "Default Data Path: " + $varInstance_Default_Path.Data_Path
        "Default Log Path:  " + $varInstance_Default_Path.Log_Path
        ""

Foreach ($varBackup_File in $varBackup_Files)
    {
        $varBackup_File_Counter  = $varBackup_File_Counter + 1
        "File (" + $varBackup_File_Counter.ToString() + "/" + $varBackup_File_Count.ToString() + ")"
        $varBackup_File_Name = $varBackup_File.Directory.ToString() + "\" + $varBackup_File.Name.ToString()
        "     File Name:         " + $varBackup_File_Name

        $varQuery = "RESTORE HEADERONLY FROM DISK = N'" + $varBackup_File_Name + "' WITH NOUNLOAD"
        $varDatabase_Name = Invoke-Sqlcmd -ServerInstance $varTarget_SQL_Server_Instance_Name -Database $varConnection_Database_Name -Query $varQuery

        $varQuery = "RESTORE FILELISTONLY FROM DISK = '" + $varBackup_File_Name + "' WITH FILE = 1"
        $varDatabase_Files = Invoke-Sqlcmd -ServerInstance $varTarget_SQL_Server_Instance_Name -Database $varConnection_Database_Name -Query $varQuery

        "     Database Name:     " + $varDatabase_Name.DatabaseName 
        "     Backup Timestamp:  " + $varDatabase_Name.BackupFinishDate

        $varQuery = "RESTORE DATABASE [" + $varDatabase_Name.DatabaseName + "] "
        $varQuery = $varQuery + "
                        FROM DISK = N'" + $varBackup_File_Name + "' "
        $varQuery = $varQuery + "
                        WITH FILE = 1, "

        Foreach ($varDatabase_File in $varDatabase_Files)
            {
                "     Logical File Name: " + $varDatabase_File.LogicalName + ", Type: " + $varDatabase_File.Type
                if ($varDatabase_File.Type -eq "D")
                    {
                                        $varQuery = $varQuery + "
                        MOVE N'" + $varDatabase_File.LogicalName + "' TO N'" + $varInstance_Default_Path.Data_Path + $varDatabase_File.LogicalName + "', "
                    }
                elseif ($varDatabase_File.Type-eq "L")
                    {
                                        $varQuery = $varQuery + "
                        MOVE N'" + $varDatabase_File.LogicalName + "' TO N'" + $varInstance_Default_Path.Log_Path + $varDatabase_File.LogicalName + "' "
                    }
            }   
        $varQuery = $varQuery + "
                        NOUNLOAD, STATS = 5"
        "     Restore Script:    " + $varQuery
        " "
    }
