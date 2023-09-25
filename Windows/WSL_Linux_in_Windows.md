# How to Install Linux or WSL (Windows Subsystem for Linux) on Windows 11

## 0. Run PowerShell as Admin
```Powershell
Start-Process powershell -Verb RunAs
```

## 1. Enable Required Features
```powershell
# Enable Windows Subsystem for Linux (WSL)
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine feature
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

## 2. Install & Update Windows Subsystem for Linux (WSL)
```powershell
wsl --install
wsl --update
```

## 3. Set the Default Version of WSL
```powershell
# Check the current version
wsl -l -v

# Set the version
wsl --set-default-version 2
```

## 4. Install the
If `Ubunru` or `Debian` is selected, then the latest version of these distros will be installed
```powershell
# Use `wsl -l -o` to see the list of all avilable distros
wsl --install -d <DISTRO_NAME>
```

## Other Usefull Commands related to WSL
```powershell
# List avilable Linux distros
wsl --list --online
# or
wsl -l -o
```
