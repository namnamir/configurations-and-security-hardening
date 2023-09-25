# Create a New User
```PowerShell
# set a password
$Password = Read-Host -AsSecureString

# create a new user
New-LocalUser <NEW_USERNAME> -Password $Password

# add to a group
Add-LocalGroupMember -Group "Administrators" -Member <NEW_USERNAME>
```

# Rename Local Username
```PowerShell
Rename-LocalUser -Name <CURRENT_USERNAME> -NewName <NEW_USERNAME>
```

# Change Computer Name
```PowerShell
Rename-Computer -ComputerName $env:COMPUTERNAME -NewName <NEW_COMPUTERNAME>
```

# Detect Services, e.g., Sysmon
```PowerShell
Get-CimInstance win32_service -Filter "Description = 'System Monitor service'"

# or

Get-Service | where-object {$_.DisplayName -like "*sysm*"}
```

# Other Useful Commands
11
