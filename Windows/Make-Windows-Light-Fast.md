# Make Windows 11 Lightweight and Fast for VMs

Windows 11 is heavily bloated with background telemetry, consumer applications, and services designed for slow physical hardware. When running inside a Virtual Machine for development, this bloat wastes CPU cycles, RAM, and Disk I/O. 

Follow these steps to debloat the OS and optimize it for coding.

## 1. The Ultimate Debloat Tool (Chris Titus Tech Utility)
The fastest and safest way to strip Windows 11 down to its bare essentials is by using the open-source CTT Windows Utility.

1. Right-click the Start Button and open **Terminal (Admin)** or **PowerShell (Admin)**.
2. Run the following command:
    ```powershell
    irm [christitus.com/win](https://christitus.com/win) | iex
    ```
3. In the graphical window that appears, navigate to the **Tweaks** tab.
4. Click the **Desktop** profile button (this selects the safest recommended tweaks for a daily-use machine).
5. Click **Run Tweaks**.

## 2. Granular Windows Speed-up Script

Run this script inside **PowerShell (Admin)** or **Terminal (Admin)** to make Windows 10/11 faster.

```powershell
# =====================================================================
# WINDOWS 11 VM PERFORMANCE OPTIMIZATION SCRIPT
# Run as Administrator
# =====================================================================

Write-Host "Starting Windows optimization optimization..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# 2. Disable VM-Killing Services
# ---------------------------------------------------------------------
Write-Host "Disabling SysMain and Windows Search services..." -ForegroundColor Yellow
$Services = @("SysMain", "WSearch")
foreach ($Service in $Services) {
    if (Get-Service -Name $Service -ErrorAction SilentlyContinue) {
        Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $Service -StartupType Disabled
    }
}

# ---------------------------------------------------------------------
# 3. Disable Xbox Game Bar
# ---------------------------------------------------------------------
Write-Host "Disabling Xbox Game Bar and Game DVR..." -ForegroundColor Yellow
$GameDVRPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
if (!(Test-Path $GameDVRPath)) { New-Item -Path $GameDVRPath -Force | Out-Null }
Set-ItemProperty -Path $GameDVRPath -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force

$GameConfigPath = "HKCU:\System\GameConfigStore"
if (!(Test-Path $GameConfigPath)) { New-Item -Path $GameConfigPath -Force | Out-Null }
Set-ItemProperty -Path $GameConfigPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

# ---------------------------------------------------------------------
# 4. Optimize Visuals and Power
# ---------------------------------------------------------------------
Write-Host "Optimizing visual effects and power plan..." -ForegroundColor Yellow

# Disable transparency effects
$ThemesPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (!(Test-Path $ThemesPath)) { New-Item -Path $ThemesPath -Force | Out-Null }
Set-ItemProperty -Path $ThemePath -Name "EnableTransparency" -Value 0 -Type DWord -Force

# Set system options to "Adjust for best performance"
$VisualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
if (!(Test-Path $VisualFxPath)) { New-Item -Path $VisualFxPath -Force | Out-Null }
Set-ItemProperty -Path $VisualFxPath -Name "VisualFXSetting" -Value 2 -Type DWord -Force

# Turn off window animations
$DesktopPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $DesktopPath -Name "WindowMetrics" -Value 0 -ErrorAction SilentlyContinue | Out-Null
$WindowMetricsPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
Set-ItemProperty -Path $WindowMetricsPath -Name "MinAnimate" -Value "0" -Type String -Force

# Keep font smoothing ON so code text remains perfectly readable
Set-ItemProperty -Path $DesktopPath -Name "FontSmoothing" -Value "2" -Type String -Force
Set-ItemProperty -Path $DesktopPath -Name "FontSmoothingType" -Value 2 -Type DWord -Force

# Set Power Plan to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# ---------------------------------------------------------------------
# 5. Clean Up Startup Apps
# ---------------------------------------------------------------------
Write-Host "Removing common consumer startup bloat..." -ForegroundColor Yellow
$BloatStartup = @("OneDrive", "Teams", "Spotify", "MicrosoftEdgeAutoLaunch", "OneDriveSetup")
$RunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
foreach ($Item in $BloatStartup) {
    if (Get-ItemProperty -Path $RunPath -Name $Item -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $RunPath -Name $Item -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------
# 6. Disable VM-Killing Services
# ---------------------------------------------------------------------
Stop-Service -Name "SysMain", "WSearch" -Force -ErrorAction SilentlyContinue
Set-Service -Name "SysMain", "WSearch" -StartupType Disabled

# ---------------------------------------------------------------------
# 7. Disable Xbox Game Bar
# ---------------------------------------------------------------------
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Force

# ---------------------------------------------------------------------
# 8. Disable Animations & Set High-Performance Power
# ---------------------------------------------------------------------
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# =====================================================================
Write-Host "Optimization Complete! Please restart your VM to apply changes." -ForegroundColor Green
```
