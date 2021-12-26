# Remote Connection (RDP)
Get and/or change the RDP port
```powershell
# To get the RDP port
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber"

# to change the RDP port
$portvalue = 3390
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber" -Value $portvalue 
New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $portvalue 
New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort $portvalue 
```

# Rename Local Username
```PowerShell
Rename-LocalUser -Name <CURRENT_USERNAME> -NewName <NEW_USERNAME>
```

# Change Computer Name
```PowerShell
Rename-Computer -ComputerName $env:COMPUTERNAME -NewName <NEW_COMPUTERNAME>
```
