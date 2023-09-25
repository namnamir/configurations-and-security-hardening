# Enable RDP
```powershell
# Enable the remote desktop protocol
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0

# Enable remote desktop through the Windows Firewall
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

# Get the RDP port number
```powershell
# Get the RDP port
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber"
```

# Change the RDP port number
```powershell
# Define the desired port number
$portvalue = 3390

# Change the port number
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber" -Value $portvalue
```

# Let the RDP 
```powershell
# Get the RDP port number and save it in a variable
$portvalue = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').PortNumber

# Allow TCP and UDP protocols of the RDP port in the firewall
New-NetFirewallRule -DisplayName 'RDPPORTLatest-TCP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $portvalue
New-NetFirewallRule -DisplayName 'RDPPORTLatest-UDP-In' -Profile 'Public' -Direction Inbound -Action Allow -Protocol UDP -LocalPort $portvalue
```

# RDP & Microsoft Account Sign-In
```powershell
# Activate the Microsoft account for using RDP
# Microsoft account is like: username@example.com
runas /u:MicrosoftAccount\<MICROSOFT_ACCOUNT> winver
```
