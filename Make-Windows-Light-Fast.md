# Make Windows 10 or Windows 11 Lighter and Faster
### 1. Change the power and screen settings
The following PowerShell script will do it.
```powershell
# change the power plan to Balanced
powercfg.exe /s "381b4222-f694-41f0-9685-ff5bb260df2e";

# set the screen off for AC and DC to 5 mins
Powercfg /Change monitor-timeout-ac 5;
Powercfg /Change monitor-timeout-dc 5;

# set the standby for AC and DC to Never
Powercfg /Change standby-timeout-ac 0;
Powercfg /Change standby-timeout-dc 0;
```
### 2. Disable unnecessary startup programs
Press `Ctrl + Shift + Esc` to open the *Task Manager* and move to the *Startup* pane.

### 3. Turn off Windows Notifications

### 4. Uninstall unnecessary programs

### 5. Turn off search indexing <sup><sub>([More Info](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service))</sub></sup>
Go to *Services* (`services.msc`) and find *Windows Search*. The following PowerShell script will do it.
```PowerShell
Stop-Service -Name WSearch;
Set-Service  -Name WSearch -StartupType Disabled;
```

### 6. Disable shadows, animations, and visual effects
Go to *System Properties* (`sysdm.cpl`) -> *Advanced* -> *Performance* and change the setting to "Adjust to best performance". The following PowerShell script will do it.
```PowerShell
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2
```

### 7. Disable transparency effect
Go to *Personalization* -> *Colors* -> *Transparency effects* and trun it off. The following PowerShell script will do it.
```PowerShell
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -Value 0
```

### 8. Remove Windows bloatware
After enabling PowerShell execution by `Set-ExecutionPolicy Unrestricted -Force`, use [this](https://github.com/Sycnex/Windows10Debloater) script to remove default Windows apps and bloatware.

Alternatively, use the following script to see bloatware.
```PowerShell
# get the list of bloatware
DISM /Online /Get-ProvisionedAppxPackages | Select-String Packagename;

# remove them one by one
DISM /Online /Remove-ProvisionedAppxPackage /PackageName:<PACKAGE_NAME>
```

### 9. Repair Windows (if needed) without reinstallation
```PowerShell
# Deployment Image Service and Management Tool (DISM)
DISM /Online /Cleanup-image /Restorehealth

# System File Checker (SFC)
sfc /scannow
```

# Resources
- https://support.microsoft.com/en-us/windows/tips-to-improve-pc-performance-in-windows-b3b3ef5b-5953-fb6a-2528-4bbed82fba96
