# Setting up RDP
## Enable RDP
```PowerShell
# Enable the Remote Desktop protocol
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0

# Enable Remote Desktop through the Windows Firewall (for all profiles)
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

## Get the Current RDP Port Number
```PowerShell
# Retrieve the RDP listening port number
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber"
```

## Change the RDP Port Number (Optional for security)
```PowerShell
# Set a custom RDP port (example: 3390)
$portvalue = 3390

# Change the port number
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "PortNumber" -Value $portvalue
```

## Allow the RDP Port in Windows Firewall (TCP and UDP)
```PowerShell
# Get the current RDP port value
$portvalue = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').PortNumber

# Add firewall rules to allow inbound TCP and UDP on the RDP port for all profiles
New-NetFirewallRule -DisplayName "RDP_PORT_TCP_IN" -Direction Inbound -Protocol TCP -LocalPort $portvalue -Action Allow -Profile Any
New-NetFirewallRule -DisplayName "RDP_PORT_UDP_IN" -Direction Inbound -Protocol UDP -LocalPort $portvalue -Action Allow -Profile Any
```

## Microsoft Account Sign-In for RDP
When using a Microsoft account to sign into the remote session, you may need to activate it for RDP usage by running:
```PowerShell
# Activate Microsoft account sign-in
# Replace <MICROSOFT_ACCOUNT> with your real account email prefix
# Microsoft account is like: username@example.com
runas /u:MicrosoftAccount\<MICROSOFT_ACCOUNT> winver
```

## Customize `.rdp` Connection File Settings
The GUI doesn’t expose all RDP settings, so edit the `.rdp` file in a text editor or IDE. Important settings include:

### Display & Multi-monitor
```rdp
; Full-screen mode or windowed (2 = full-screen, 1 = windowed)
screen mode id:i:2

; Enable multi-monitor support
use multimon:i:1

; Optional: specify monitor IDs (comma-separated)
selectedmonitors:s:0,1
```

### Multi-monitor Span (Optional)

```rdp
; Disable spanning across monitors (use independent monitors)
span monitors:i:0
```

### Session Color Depth and Performance Settings

```rdp
; Color depth - try 16 for better font rendering or 32 for full color
session bpp:i:16

; Compression enabled for better bandwidth use
compression:i:1

; Allow font smoothing for better font readability
allow font smoothing:i:1

; Enable desktop composition for Aero effects - can improve rendering
allow desktop composition:i:1

; Persistent bitmap caching - try toggling if display glitches occur
bitmapcachepersistenable:i:1

; Disable wallpaper & themes for better performance (optional)
disable wallpaper:i:0
disable themes:i:0
```

### Network and Reconnection

```rdp
; Connection type (5 = broadband)
connection type:i:5

; Enable automatic reconnection on network loss
autoreconnection enabled:i:1

; Enable network autodetect (set to 1 to enable)
networkautodetect:i:1
bandwidthautodetect:i:1
```

### Keep-Alive and UDP (Improve stability)

Add these lines to enhance session stability by keeping the connection alive and disabling unstable UDP transport if needed:

```rdp
; Keep-alive interval in seconds
keepaliveinterval:i:30

; Disable UDP transport to avoid disconnect issues on some Windows 11 setups
enableudp:i:0
```

### Username and Password Handling

```rdp
; Set the username for the RDP session
username:s:account@outlook.com

; Domain for Microsoft Account login
domain:s:MicrosoftAccount

; Control prompting for credentials:
; 0 = do not prompt (uses cached or saved credentials)
; 1 = always prompts for password
prompt for credentials:i:1

; Prompt once per session (for reconnection)
promptcredentialonce:i:0
```

- Passwords are not stored in `.rdp` files for security.
- Use Windows Credential Manager to securely save and manage passwords.
- To prompt for password on every connection, set `prompt for credentials:i:1`.

## Authentication Settings

```rdp
; Require Network Level Authentication (NLA) for better security
authentication level:i:2

; Enable negotiation of security protocol during connection
negotiate security layer:i:1

; Enable Credential Security Support Provider protocol (CredSSP)
enablecredsspsupport:i:1
```

## Device and Resource Redirection

```rdp
; Redirect printers, clipboard, smartcards, COM ports, drives, cameras, etc.
redirectprinters:i:1
redirectclipboard:i:1
redirectsmartcards:i:1
redirectcomports:i:1
drivestoredirect:s:*
camerastoredirect:s:*
devicestoredirect:s:*
```

## Other Useful Settings

```rdp
; Enable font smoothing for clearer fonts over RDP
allow font smoothing:i:1

; Enable desktop composition for Aero effects
allow desktop composition:i:1

; Enable auto-reconnection on network disconnects
autoreconnection enabled:i:1
```
