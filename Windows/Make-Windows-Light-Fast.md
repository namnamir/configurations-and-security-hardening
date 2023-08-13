# Make Windows 10 or Windows 11 Lighter and Faster
### 1. Change the power and screen settings <sup><sub>([More Info](https://ss64.com/nt/powercfg.html))</sub></sup>
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
The following PowerShell script will do it.
```PowerShell
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0

# it works just on Windows 10
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
```
#### # Do it Manually
If you would prefer to do it manually, follow the following steps and change the settings:
-  `Settings -> System -> Notifications -> Additional settings` 
-  `Settings -> System -> Notifications -> Notifications from apps and other senders`.

### 4. Debloat Windows (Uninstall Unnecessary Programs)
Firstly, there there is a need to check installed applications in "Add & Remove Programs" and uninstall unwanted ones.

Use the following script to see bloatware.
```PowerShell
# get the list of bloatware
DISM /Online /Get-ProvisionedAppxPackages | Select-String Packagename;

# remove them one by one
DISM /Online /Remove-ProvisionedAppxPackage /PackageName:<PACKAGE_NAME>
```
#### 4.1. Use Chris Titus Tech's Windows Utility <sup><sub>([Github](https://github.com/ChrisTitusTech/winutil))</sub></sup>
Run the following command and select desired settings.
```powershell
iwr -useb https://christitus.com/win | iex
```
#### 4.2. Use Chris Titus Tech's Windows Utility <sup><sub>([Github](https://github.com/Sycnex/Windows10Debloater))</sub></sup>
After enabling PowerShell execution by `Set-ExecutionPolicy Unrestricted -Force`, use [this](https://github.com/Sycnex/Windows10Debloater) script to remove default Windows apps and bloatware.

### 5. Turn off search indexing <sup><sub>([More Info](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service))</sub></sup>
Go to *Services* (`services.msc`) and find *Windows Search*. The following PowerShell script will do it.
```PowerShell
Stop-Service -Name WSearch;
Set-Service  -Name WSearch -StartupType Disabled;
```

### 6. Change the Visual Settings
#### 6.1. Disable **Shadows, Animations, and Visual Effects**.
```PowerShell
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2
```
#### 6.2. Disable **Transparency Effects**
```PowerShell
Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -Value 0
```
#### 6.3. Remove Backgrounds
#### # Do them Manually
If you would prefer to do it manually, follow the following steps and change the settings:
-  `Advanced System Settings (sysdm.cpl) -> Performance -> Settings -> Adjust for best performance`
-  `Settings -> Accessibility -> Transparency effects   OR   Settings -> Personalization -> Colors -> Transparency effects`
-  `Settings -> Accessibility -> Animation effects`
-  `Settings -> Personalization -> Lock screen -> Lock screen status -> None`
-  `Settings -> Personalization -> Lock screen -> Show the lock screen background picture on the sign-in screen`
-  `Settings -> Personalization -> Lock screen -> Personalize your lock screen -> Picture`
-  `Settings -> Personalization -> Lock screen -> Personalize your lock screen -> Get the fun facts, tips, tricks, and more on your lock screen`

### 7. Repair Windows (if needed) without reinstallation
```PowerShell
# Deployment Image Service and Management Tool (DISM)
DISM /Online /Cleanup-image /Restorehealth

# System File Checker (SFC)
sfc /scannow
```

### 9. Others
#### 9.1. Disable DiagTracK
To stop and disable the User Experiences and Telemetry (Diagnostics Tracking or DiagTracK) run following commands.
```PowerShell
stop-service diagtrack
set-service diagtrack -startuptype disabled
```
#### 9.2. Disable Auto Updates for Maps
- `Settings -> Apps -> Offline maps -> Map updates`
#### 9.3. Disable AutoPlay Feature for Devices
- `Settings -> Bluetooth & devices -> AutoPlay`


---
**Resources:**
- https://support.microsoft.com/en-us/windows/tips-to-improve-pc-performance-in-windows-b3b3ef5b-5953-fb6a-2528-4bbed82fba96
- https://admx.help/HKCU/Software/Policies/Microsoft/Windows/Explorer
- https://gist.github.com/ilyaigpetrov/03506150e0a3a4104a24f7e519d42078
