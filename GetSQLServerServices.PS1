Get-WmiObject Win32_Service -ComputerName <computername> | Where-Object {$_.name -like "*SQL*"} | Format-Table PSComputername, Name, StartName, StartMode | Sort-Object PSComputerName
