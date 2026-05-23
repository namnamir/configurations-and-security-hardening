#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Proxmox VM  -  Master Optimization, Hardening & Deployment Script

.DESCRIPTION
    Applies performance tweaks, security hardening, and UX improvements tailored
    for Windows 11 running as a KVM/Proxmox virtual machine.
    Supports full backup of original settings and a one-command revert.

.PARAMETER Mode
    Apply   -  apply all tweaks (default)
    Revert  -  restore original settings from a previous backup

.PARAMETER BackupFile
    Path to a specific backup JSON for Revert mode.
    If omitted, the most recent backup in $BackupDir is used.

.PARAMETER SkipEdge
    Skip the Microsoft Edge hardening section.

.PARAMETER SkipBloat
    Skip the Appx/UWP bloatware removal section.

.PARAMETER SkipOffice
    Skip the Microsoft Office installation section.

.EXAMPLE
    .\Tweak-Windows.ps1
    .\Tweak-Windows.ps1 -Mode Revert
    .\Tweak-Windows.ps1 -SkipEdge -SkipBloat -SkipOffice
    .\Tweak-Windows.ps1 -Mode Revert -BackupFile "C:\ProgramData\TweakWindows\backup_20260522-1430.json"

.NOTES
    Version : 2.1  (2026-05-23)
    Author  : Niko Ual
    License : MIT

    Credits & inspiration:
      - Sophia Script by farag2          https://github.com/farag2/Sophia-Script-for-Windows
      - Win11Debloat by Raphire          https://github.com/Raphire/Win11Debloat
      - HardeningKitty by scipag         https://github.com/scipag/HardeningKitty
      - PrivacyGuides.org                https://www.privacyguides.org
      - Windows hardening community      r/sysadmin, r/netsec, various gists

    Requires : PowerShell 5.1 or later, Administrator rights, internet access for winget
#>

param(
    [ValidateSet("Apply", "Revert")]
    [string]$Mode = "Apply",

    [string]$BackupFile = "",

    [switch]$SkipEdge,
    [switch]$SkipBloat,
    [switch]$SkipOffice
)

Set-StrictMode -Version Latest

# =====================================================================
# CONFIGURATION  -  edit these before running
# =====================================================================

$ScriptVersion = "2.1"
$BackupDir     = "C:\ProgramData\TweakWindows"
$LogDir        = "C:\ProgramData\TweakWindows\Logs"

# DNS: Cloudflare for Families (malware + phishing blocking, fastest globally)
#   + Quad9 (independent org, different threat feed, DNSSEC validation)
# Using different providers means no single vendor is a single point of failure.
$DNS1 = "1.1.1.2"   # Cloudflare for Families
$DNS2 = "9.9.9.9"   # Quad9

# DNS-over-HTTPS templates paired to each resolver above
$DohServers = @(
    @{ Addr = $DNS1; Tpl = "https://security.cloudflare-dns.com/dns-query" },
    @{ Addr = $DNS2; Tpl = "https://dns.quad9.net/dns-query" }
)

# Keyboard layouts
$PrimaryLang      = "en-US"
$PrimaryLangTip   = "0409:00000409"   # English (US)
$SecondaryLang    = "fa-IR"
$SecondaryLangTip = "0429:00050429"   # Persian (Standard)

# NTP
$NtpServer              = "time.cloudflare.com"   # Stratum 1, anycast, highly reliable
$NtpPollIntervalSeconds = 3600                    # Sync every hour (Windows default is 7 days)

# Power / storage
$HighPerfGUID   = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"   # High Performance power plan
$PagefileSizeMB = 4096                                      # Fixed pagefile size in MB

# Scheduler / responsiveness
$Win32PrioritySeparation = 38   # Max foreground boost (0x26); short quanta, 3-level boost

# TCP tuning
$TcpTimedWaitDelay = 30      # Seconds before a TIME_WAIT port is freed (default 240)
$TcpMaxUserPort    = 65534   # Maximum ephemeral port number (default 5000 on older builds)

# Edge
$EdgeSleepingTabsTimeout = 300   # Seconds before an inactive tab is put to sleep (5 min)

# Scheduled maintenance
$WingetUpgradeDay  = "Sunday"   # Day of the week for the auto-upgrade task (Sunday..Saturday)
$WingetUpgradeTime = "09:00"    # Time for the auto-upgrade task (24-hour HH:mm)

# Services to disable (reason shown in the log)
$ServicesToDisable = @(
    @{ Name = "SysMain";          Reason = "not useful with a fast virtual disk (Superfetch)" },
    @{ Name = "WSearch";          Reason = "heavy disk I/O, optional on a VM (Search indexer)" },
    @{ Name = "DiagTrack";        Reason = "sends usage data to Microsoft (Telemetry collector)" },
    @{ Name = "dmwappushservice"; Reason = "telemetry-related helper service (WAP Push routing)" }
)

# Startup Run-key entries to remove
$BloatStartup = @("OneDrive", "Teams", "Spotify", "MicrosoftEdgeAutoLaunch", "OneDriveSetup")

# Winget package IDs to install
$AppsToInstall = @(
    @{ Id = "Microsoft.WindowsTerminal.Preview";      Override = "" },
    @{ Id = "Microsoft.VisualStudioCode";             Override = "/GA /VERYSILENT /MERGETASKS=!runcode" },
    @{ Id = "OpenJS.NodeJS.LTS";                      Override = "" },   # required for Gemini CLI (npm)
    @{ Id = "SidebarDiagnostics.SidebarDiagnostics";  Override = "" },
    @{ Id = "Beeper.Beeper";                          Override = "" },
    @{ Id = "Git.Git";                                Override = "" }
)

# Winget package IDs to remove
$AppsToRemove = @(
    "Microsoft.WindowsTerminal",   # Replaced by Preview (removed after reboot if running inside it)
    "Microsoft.OneDrive"           # Win32; winget is the cleanest removal path
)

# Appx/UWP packages to purge from all user profiles and the provisioned image.
# Wildcards are supported; safe-list below prevents accidental removal of system packages.
$AppxBloat = @(
    "*BingNews*",              # Bing News feed
    "*BingWeather*",           # Weather
    "*BingSearch*",            # Bing Search taskbar integration
    "*SolitaireCollection*",   # Solitaire
    "*communicationsapps*",    # Mail & Calendar (legacy)
    "*OutlookForWindows*",     # New Outlook (store app)
    "*FeedbackHub*",           # Feedback Hub
    "*Xbox*",                  # Xbox Console Companion, Identity Provider, Speech…
    "*GamingApp*",             # New Xbox / Gaming app (package name does NOT contain "Xbox")
    "*MicrosoftStickyNotes*",  # Sticky Notes
    "*PowerAutomateDesktop*",  # Power Automate Desktop
    "*MicrosoftTeams*",        # Teams classic
    "*MSTeams*",               # Teams new (Windows 11 integrated, different package ID)
    "*Todos*",                 # Microsoft To Do
    "*549981C3F5F10*",         # Cortana
    "*Copilot*",               # Windows Copilot
    "*YourPhone*",             # Phone Link
    "*Clipchamp*",             # Clipchamp video editor
    "*WebExperience*",         # Widgets engine (belt-and-suspenders alongside winget removal)
    "*WindowsMaps*",           # Maps
    "*GetHelp*",               # Get Help / Support
    "*ZuneMusic*",             # Groove Music / legacy Media Player
    "*ZuneVideo*"              # Movies & TV
)

# These packages must never be removed  -  doing so can break Windows.
# The pattern is matched against package names with -notmatch (case-insensitive regex).
$AppxSafeList = "^(Microsoft\.UI\.|Microsoft\.VCLibs|Microsoft\.NET\." +
                "|Microsoft\.WindowsAppRuntime|Microsoft\.DesktopAppInstaller" +
                "|Microsoft\.StorePurchaseApp|Microsoft\.MicrosoftEdge" +
                "|Microsoft\.WindowsStore|ShellExperienceHost" +
                "|StartMenuExperienceHost|Microsoft\.Windows\.Cortana" +
                "|Microsoft\.XboxGameCallableUI)"

# Edge extensions to force-install via policy (users cannot remove these).
# Format: <extension-id>;<update-url>
$EdgeExtensions = @(
    "bfogiafebfohielmmehodmfbbebbbpei;https://clients2.google.com/service/update2/crx",  # Keeper Password Manager
    "cjpalhdlnbpafiamejdnhcphjbkeiagm;https://clients2.google.com/service/update2/crx",  # uBlock Origin
    "mnjggcdmjocbbbhaepdhchncahnbgone;https://clients2.google.com/service/update2/crx",  # SponsorBlock for YouTube
    "kkeakohpadmbldjaiggikmnldlfkdfog;https://clients2.google.com/service/update2/crx",  # FastStream Video Player
    "jhnleheckmknfcgijgkadoemagpecfol;https://clients2.google.com/service/update2/crx"   # Auto Tab Discard
)

# =====================================================================
# OUTPUT HELPERS
# =====================================================================

# Box-drawing characters — defined via [char] so the source stays ASCII-clean.
$BoxH  = [string][char]0x2550   # ═
$BoxV  = [string][char]0x2551   # ║
$BoxTL = [string][char]0x2554   # ╔
$BoxTR = [string][char]0x2557   # ╗
$BoxBL = [string][char]0x255A   # ╚
$BoxBR = [string][char]0x255D   # ╝

# Status symbols — all single-column width so every line aligns perfectly.
$SymOK      = [string][char]0x2713   # ✓  success
$SymFail    = [string][char]0x2717   # ✗  error
$SymWarn    = [string][char]0x25B2   # ▲  warning
$SymStep    = [string][char]0x203A   # ›  in progress / action
$SymSkipped = [string][char]0x00B7   # ·  no change needed
$SymInfo    = [string][char]0x25B8   # ▸  informational

# Section header — draws a compact box around the title.
function Write-Header {
    param([string]$Text)
    $Rule = $BoxH * ($Text.Length + 2)
    Write-Host ""
    Write-Host "  $BoxTL$Rule$BoxTR" -ForegroundColor Cyan
    Write-Host "  $BoxV $Text $BoxV" -ForegroundColor Cyan
    Write-Host "  $BoxBL$Rule$BoxBR" -ForegroundColor Cyan
}

# Banner box — accepts one or more lines; auto-pads to the longest one.
function Write-Box {
    param([string[]]$Lines, [string]$Color = "Cyan", [int]$Padding = 5)
    $MaxLen = ($Lines | Measure-Object -Property Length -Maximum).Maximum
    $Inner  = $Padding + $MaxLen + $Padding
    $Rule   = $BoxH * $Inner
    $Pad    = " " * $Padding
    Write-Host "  $BoxTL$Rule$BoxTR" -ForegroundColor $Color
    foreach ($Line in $Lines) {
        Write-Host "  $BoxV$Pad$($Line.PadRight($MaxLen))$Pad$BoxV" -ForegroundColor $Color
    }
    Write-Host "  $BoxBL$Rule$BoxBR" -ForegroundColor $Color
}

function Write-Step    { param([string]$T) Write-Host "   $SymStep  $T" -ForegroundColor DarkGray }
function Write-OK      { param([string]$T) Write-Host "   $SymOK  $T"   -ForegroundColor Green }
function Write-Warn    { param([string]$T) Write-Host "   $SymWarn  $T" -ForegroundColor Yellow }
function Write-Fail    { param([string]$T) Write-Host "   $SymFail  $T" -ForegroundColor Red }
function Write-Skipped { param([string]$T) Write-Host "   $SymSkipped  $T" -ForegroundColor DarkGray }
function Write-Info    { param([string]$T) Write-Host "   $SymInfo  $T" -ForegroundColor DarkCyan }

# =====================================================================
# REGISTRY HELPERS
# =====================================================================

# Creates a registry key path if it does not already exist. Logs when a new key is made.
function Ensure-RegPath {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-Step "Created registry key: $(($Path -split '\\')[-1])"
    }
}

# Snapshots a registry value for backup/revert. Returns the current value (or $null if absent).
function Save-RegValue {
    param([string]$Path, [string]$Name)
    $currentValue = $null
    try {
        if (Test-Path $Path) {
            $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($null -ne $prop) {
                $kind = (Get-Item -Path $Path -ErrorAction SilentlyContinue).GetValueKind($Name)
                $currentValue = $prop.$Name
                $script:Backup.Registry += [PSCustomObject]@{
                    Path  = $Path
                    Name  = $Name
                    Value = $currentValue
                    Kind  = $kind.ToString()
                }
            } else {
                $script:Backup.Registry += [PSCustomObject]@{
                    Path  = $Path; Name = $Name; Value = $null; Kind = "NotPresent"
                }
            }
        }
    } catch {
        Write-Warn "Could not snapshot '$Name' at '$Path'"
    }
    return $currentValue
}

# Snapshots then sets a registry value. Skips if already at the target value.
# Shows before -> after for every change so the user can see exactly what moved.
function Set-RegSafe {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    $before = Save-RegValue -Path $Path -Name $Name
    if ($null -ne $before -and "$before" -eq "$Value") {
        Write-Skipped "$Name = $Value  (no change)"
        return
    }
    try {
        Ensure-RegPath $Path
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        if ($null -eq $before) {
            Write-OK "$Name = $Value  (new entry)"
        } else {
            Write-OK "$Name  $before -> $Value"
        }
    } catch {
        Write-Fail "$Name - $_"
    }
}

# =====================================================================
# BACKUP STRUCTURE (populated during Apply, serialized at the end)
# =====================================================================

$Backup = [PSCustomObject]@{
    ScriptVersion        = $ScriptVersion
    Timestamp            = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    ComputerName         = $env:COMPUTERNAME
    RdpPort              = 0
    DNS                  = [System.Collections.Generic.List[object]]::new()
    Registry             = [System.Collections.Generic.List[object]]::new()
    Services             = [System.Collections.Generic.List[object]]::new()
    FirewallRules        = [System.Collections.Generic.List[string]]::new()   # rules we created; removed on revert
    StartupEntries       = [System.Collections.Generic.List[object]]::new()   # startup entries we removed
    TaskbarXml           = [System.Collections.Generic.List[object]]::new()   # original XML files (path + content)
    # Non-registry state captured before each change; $null means "not touched by this run"
    Hibernation          = $null   # $true = was enabled, $false = was already off
    MemoryCompression    = $null   # $true = was enabled
    SystemRestoreEnabled = $null   # $true = was enabled
    SMB1Enabled          = $null   # original EnableSMB1Protocol value
    SMBSigningRequired   = $null   # original RequireSecuritySignature value
    NtpServer            = $null   # original w32tm peer list string
    BootUxValue          = $null   # "NotSet" or the original bcdedit bootux value
    DefragTaskState      = $null   # original scheduled task state string
    PowerPlan            = $null   # active power scheme GUID before this script
    Pagefile             = $null   # original CIM pagefile configuration
    LanguageList         = $null   # serialized language list: "tag|tip1,tip2;tag|tip" format
    RdpFirewallState     = $null   # $true if "Remote Desktop" firewall group was already enabled
    OfficeInstalled      = $null   # $true = was already installed; $false = installed by this script
}

# Write current $Backup snapshot to disk — called both mid-run and at finalize
$BackupPath = $null
function Save-Backup {
    if (-not $script:BackupPath) {
        $script:BackupPath = "$BackupDir\backup_$(Get-Date -Format 'yyyyMMdd-HHmm').json"
    }
    try {
        $script:Backup | ConvertTo-Json -Depth 4 | Out-File -FilePath $script:BackupPath -Encoding utf8 -Force
    } catch {
        Write-Warn "Could not write backup to disk: $_"
    }
}

# =====================================================================
# REVERT MODE
# =====================================================================

if ($Mode -eq "Revert") {
    # Find backup file  -  use the newest one if no path was specified
    if ([string]::IsNullOrWhiteSpace($BackupFile)) {
        $BackupFile = Get-ChildItem -Path $BackupDir -Filter "backup_*.json" -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $BackupFile -or !(Test-Path $BackupFile)) {
        Write-Fail "No backup file found  —  run in Apply mode first to create one."
        exit 1
    }

    $RevertLog = "$LogDir\revert-$(Get-Date -Format 'yyyyMMdd-HHmm').log"
    if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory -Force | Out-Null }
    Start-Transcript -Path $RevertLog -Append | Out-Null

    Write-Host ""
    Write-Info "Reverting from: $BackupFile"

    $Saved = Get-Content $BackupFile -Raw | ConvertFrom-Json

    # Restore registry values
    foreach ($entry in $Saved.Registry) {
        try {
            if ($entry.Name -eq "__KeyAbsent__") {
                # The entire key was absent before this script; remove it entirely on revert
                Remove-Item -Path $entry.Path -Recurse -Force -ErrorAction SilentlyContinue
                Write-OK "Removed registry key (was absent originally): $($entry.Path)"
            } elseif ($entry.Kind -eq "NotPresent") {
                Remove-ItemProperty -Path $entry.Path -Name $entry.Name -Force -ErrorAction SilentlyContinue
                Write-OK "Removed '$($entry.Name)' (was not present originally)"
            } else {
                Ensure-RegPath $entry.Path
                Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -Type $entry.Kind -Force
                Write-OK "Restored '$($entry.Name)' = $($entry.Value)"
            }
        } catch {
            Write-Fail "Could not restore '$($entry.Name)' at '$($entry.Path)'  -  $_"
        }
    }

    # Restore services
    foreach ($svc in $Saved.Services) {
        try {
            Set-Service -Name $svc.Name -StartupType $svc.StartupType -ErrorAction SilentlyContinue
            Write-OK "Restored service '$($svc.Name)' startup type to $($svc.StartupType)"
        } catch {
            Write-Fail "Could not restore service '$($svc.Name)'"
        }
    }

    # Restore DNS per adapter
    foreach ($adapter in $Saved.DNS) {
        try {
            if ($adapter.Servers -and $adapter.Servers.Count -gt 0) {
                Set-DnsClientServerAddress -InterfaceAlias $adapter.Alias -ServerAddresses $adapter.Servers
            } else {
                Set-DnsClientServerAddress -InterfaceAlias $adapter.Alias -ResetServerAddresses
            }
            Write-OK "Restored DNS on '$($adapter.Alias)'"
        } catch {
            Write-Fail "Could not restore DNS on '$($adapter.Alias)'  -  $_"
        }
    }

    # Restore computer name
    if ($Saved.ComputerName -and $Saved.ComputerName -ne $env:COMPUTERNAME) {
        try {
            Rename-Computer -NewName $Saved.ComputerName -Force -ErrorAction Stop
            Write-OK "Computer name will revert to '$($Saved.ComputerName)' after restart"
        } catch {
            Write-Fail "Could not revert computer name  -  $_"
        }
    }

    # Remove scheduled tasks created by this script
    foreach ($TaskName in @("Winget Weekly Upgrade", "TweakWindows-RemoveTerminalStable")) {
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
            Write-OK "Removed scheduled task '$TaskName'"
        }
    }

    # -- Hibernation ------------------------------------------------
    if ($null -ne $Saved.Hibernation) {
        if ($Saved.Hibernation) {
            powercfg /h on 2>&1 | Out-Null
            Write-OK "Hibernation re-enabled (was on before this script)"
        } else {
            Write-Skipped "Hibernation was already off before - keeping it off"
        }
    }

    # -- Memory compression -----------------------------------------
    if ($null -ne $Saved.MemoryCompression) {
        if ($Saved.MemoryCompression) {
            Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
            Write-OK "Memory compression re-enabled"
        } else {
            Write-Skipped "Memory compression was already off before - keeping it off"
        }
    }

    # -- System Restore ---------------------------------------------
    if ($null -ne $Saved.SystemRestoreEnabled) {
        if ($Saved.SystemRestoreEnabled) {
            try {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
                Write-OK "System Restore re-enabled"
            } catch { Write-Fail "Could not re-enable System Restore  -  $_" }
        } else {
            Write-Skipped "System Restore was already disabled before - keeping it off"
        }
    }

    # -- SMB --------------------------------------------------------
    if ($null -ne $Saved.SMB1Enabled) {
        try {
            Set-SmbServerConfiguration -EnableSMB1Protocol $Saved.SMB1Enabled -Force -ErrorAction Stop
            Write-OK "SMBv1 restored to: $($Saved.SMB1Enabled)"
        } catch { Write-Fail "Could not restore SMBv1  -  $_" }
    }
    if ($null -ne $Saved.SMBSigningRequired) {
        try {
            Set-SmbServerConfiguration -RequireSecuritySignature $Saved.SMBSigningRequired -Force -ErrorAction Stop
            Write-OK "SMB signing restored to: $($Saved.SMBSigningRequired)"
        } catch { Write-Fail "Could not restore SMB signing  -  $_" }
    }

    # -- NTP --------------------------------------------------------
    if ($Saved.NtpServer) {
        try {
            w32tm /config /manualpeerlist:"$($Saved.NtpServer)" /update 2>&1 | Out-Null
            Restart-Service W32Time -ErrorAction SilentlyContinue
            Write-OK "NTP server restored to: $($Saved.NtpServer)"
        } catch { Write-Fail "Could not restore NTP server  -  $_" }
    }

    # -- Boot animation (bootux) ------------------------------------
    if ($Saved.BootUxValue -eq "NotSet") {
        bcdedit /deletevalue bootux 2>&1 | Out-Null
        Write-OK "bootux BCD entry removed (was absent before this script)"
    } elseif ($Saved.BootUxValue) {
        bcdedit /set bootux $Saved.BootUxValue 2>&1 | Out-Null
        Write-OK "bootux restored to: $($Saved.BootUxValue)"
    }

# -- Scheduled defrag -------------------------------------------
    if ($Saved.DefragTaskState -and $Saved.DefragTaskState -ne "Disabled") {
        Enable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" `
            -ErrorAction SilentlyContinue | Out-Null
        Write-OK "Scheduled defrag restored to: $($Saved.DefragTaskState)"
    } elseif ($Saved.DefragTaskState -eq "Disabled") {
        Write-Skipped "Scheduled defrag was already disabled before - keeping it off"
    }

    # -- Power plan -------------------------------------------------
    if ($Saved.PowerPlan) {
        $restorePlan = powercfg /setactive $Saved.PowerPlan 2>&1
        if ($LASTEXITCODE -eq 0) { Write-OK "Power plan restored to: $($Saved.PowerPlan)" }
        else { Write-Warn "Could not restore power plan  -  $restorePlan" }
    }

    # -- Pagefile ---------------------------------------------------
    if ($null -ne $Saved.Pagefile) {
        try {
            $CS = Get-CimInstance -ClassName Win32_ComputerSystem
            $CS | Set-CimInstance -Property @{ AutomaticManagedPagefile = [bool]$Saved.Pagefile.AutoManaged }
            if ($null -ne $Saved.Pagefile.InitialSize) {
                $PF = Get-CimInstance -ClassName Win32_PageFileSetting |
                      Where-Object { $_.Name -eq 'C:\pagefile.sys' }
                if ($PF) {
                    $PF | Set-CimInstance -Property @{
                        InitialSize = [UInt32]$Saved.Pagefile.InitialSize
                        MaximumSize = [UInt32]$Saved.Pagefile.MaximumSize
                    }
                }
            }
            Write-OK "Pagefile settings restored"
        } catch { Write-Fail "Could not restore pagefile settings  -  $_" }
    }

    # -- Language list ----------------------------------------------
    if ($Saved.LanguageList) {
        try {
            $restored = New-Object System.Collections.Generic.List[object]
            foreach ($entry in ($Saved.LanguageList -split ';')) {
                $parts = $entry -split '\|'
                $lang = New-WinUserLanguageList $parts[0]
                $lang[0].InputMethodTips.Clear()
                if ($parts.Count -gt 1 -and $parts[1]) {
                    foreach ($tip in ($parts[1] -split ',')) { $lang[0].InputMethodTips.Add($tip) }
                }
                $restored.Add($lang[0])
            }
            Set-WinUserLanguageList $restored -Force -ErrorAction Stop
            Write-OK "Language list restored"
        } catch { Write-Fail "Could not restore language list  -  $_" }
    }

    # -- Office ----------------------------------------------------
    if ($Saved.OfficeInstalled -eq $false) {
        $OdtSetup  = "$BackupDir\ODT\setup.exe"
        $RemoveCfg = "$BackupDir\ODT\office-remove.xml"
        if (Test-Path $OdtSetup) {
            Set-Content -Path $RemoveCfg -Encoding UTF8 -Value @"
<Configuration>
  <Remove All="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@
            Write-Step "Removing Office (installed by this script)"
            $removeProc = Start-Process -FilePath $OdtSetup `
                -ArgumentList ('/configure "' + $RemoveCfg + '"') `
                -Wait -PassThru -ErrorAction SilentlyContinue
            if ($removeProc -and $removeProc.ExitCode -eq 0) { Write-OK "Office removed" }
            else { Write-Warn "Office removal may have failed  -  check $LogDir for details" }
        } else {
            Write-Warn "ODT setup.exe not found at $OdtSetup  -  remove Office manually if needed"
        }
    }

    # -- Custom RDP firewall rules ----------------------------------
    if ($Saved.FirewallRules -and $Saved.FirewallRules.Count -gt 0) {
        foreach ($RuleName in $Saved.FirewallRules) {
            Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
            Write-OK "Removed firewall rule: $RuleName"
        }
    }

    # -- RDP firewall group state -----------------------------------
    if ($null -ne $Saved.RdpFirewallState -and -not $Saved.RdpFirewallState) {
        Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
        Write-OK "Remote Desktop firewall rules disabled (were disabled before this script)"
    }

    # -- Startup entries --------------------------------------------
    if ($Saved.StartupEntries -and $Saved.StartupEntries.Count -gt 0) {
        foreach ($entry in $Saved.StartupEntries) {
            try {
                $runPath = $entry.Path
                Ensure-RegPath $runPath
                Set-ItemProperty -Path $runPath -Name $entry.Name -Value $entry.Value -Type String -Force
                Write-OK "Restored startup entry: $($entry.Name)"
            } catch { Write-Fail "Could not restore startup entry '$($entry.Name)'  -  $_" }
        }
    }

    # -- Taskbar XML ------------------------------------------------
    if ($Saved.TaskbarXml -and $Saved.TaskbarXml.Count -gt 0) {
        foreach ($xmlEntry in $Saved.TaskbarXml) {
            try {
                if ($xmlEntry.Content -eq "NotPresent") {
                    Remove-Item -Path $xmlEntry.Path -Force -ErrorAction SilentlyContinue
                    Write-OK "Removed taskbar XML: $($xmlEntry.Path)"
                } else {
                    Set-Content -Path $xmlEntry.Path -Value $xmlEntry.Content -Encoding UTF8 -Force
                    Write-OK "Restored taskbar XML: $($xmlEntry.Path)"
                }
            } catch { Write-Fail "Could not restore taskbar XML '$($xmlEntry.Path)'  -  $_" }
        }
    }

    Stop-Transcript | Out-Null
    Write-Host ""
    Write-Box "Revert complete  —  restart to finish." "Green"
    exit 0
}

# =====================================================================
# APPLY MODE  -  set up logging and directories
# =====================================================================

foreach ($Dir in @($BackupDir, $LogDir)) {
    if (!(Test-Path $Dir)) { New-Item -Path $Dir -ItemType Directory -Force | Out-Null }
}

$LogFile = "$LogDir\tweak-$(Get-Date -Format 'yyyyMMdd-HHmm').log"

# Clear the screen before the transcript starts so control codes don't corrupt the log
Clear-Host

Start-Transcript -Path $LogFile -Append | Out-Null

Write-Host ""
Write-Box @(
      "Windows 11 VM - Optimization & Hardening  v.$ScriptVersion",
      "Author: Ali N  |  Github: https://github.com/namnamir"
  ) "Cyan"
Write-Info "Log: $LogFile"
Write-Host ""

# =====================================================================
# 0. Target User Resolution
#    All HKCU tweaks write directly to the target user's registry hive
#    so they apply regardless of which account ran this script as admin.
# =====================================================================

Write-Header "Resolving Target User Account"

# @() forces an array so .Count is always available, even when only one user matches
$Candidates = @(Get-LocalUser | Where-Object {
    $_.Enabled -and $_.Name -notmatch '^(Administrator|Guest|DefaultAccount|WDAGUtilityAccount|WDAGUtility)$'
})

$TargetUser = $env:USERNAME   # safe fallback — overwritten below if a better match is found
if ($Candidates.Count -eq 0) {
    Write-Warn "No eligible local user accounts found  -  HKCU tweaks will target the current session."
    $TargetUser = $env:USERNAME
} elseif ($Candidates.Count -eq 1) {
    $TargetUser = $Candidates[0].Name
    Write-OK "Target user auto-detected: $TargetUser"
} else {
    Write-Info "Multiple accounts found  —  choose the daily-use account:"
    $idx = 1
    foreach ($u in $Candidates) {
        Write-Host "       $idx)  $($u.Name)" -ForegroundColor White
        $idx++
    }
    do {
        $Pick = Read-Host "    Enter number"
    } while ($Pick -notmatch '^\d+$' -or [int]$Pick -lt 1 -or [int]$Pick -gt $Candidates.Count)
    $TargetUser = $Candidates[[int]$Pick - 1].Name
    Write-OK "Target user selected: $TargetUser"
}

# Resolve SID and load the user's hive if they are not currently logged in
$TargetSID  = $null
$HiveLoaded = $false
try {
    $TargetSID = (New-Object System.Security.Principal.NTAccount($env:COMPUTERNAME, $TargetUser)).Translate(
        [System.Security.Principal.SecurityIdentifier]).Value

    if (!(Test-Path "Registry::HKU\$TargetSID")) {
        $ProfileRoot = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$TargetSID" `
                            -ErrorAction Stop).ProfileImagePath
        $LoadResult = reg load "HKU\$TargetSID" "$ProfileRoot\NTUSER.DAT" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $HiveLoaded = $true
            Write-OK "Loaded hive from $ProfileRoot\NTUSER.DAT"
        } else {
            Write-Warn "Could not load hive: $LoadResult  -  HKCU tweaks may not reach $TargetUser"
        }
    }
} catch {
    Write-Warn "SID resolution failed: $_  -  HKCU tweaks will target the current session."
}

# All HKCU-equivalent writes go through this variable
$HKCU = if ($TargetSID) { "Registry::HKU\$TargetSID" } else { "HKCU:" }

# =====================================================================
# 1. Gather User Inputs
# =====================================================================

try {   # try/finally ensures backup is always written even if a section throws

Write-Header "Configuration"

Write-Info "Current computer name: $($env:COMPUTERNAME)"
$NewComputerName = Read-Host "    New computer name (Enter to keep current)"

$RdpPath = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$CurrentRdpPort = try { (Get-ItemProperty -Path $RdpPath -Name "PortNumber" -ErrorAction Stop).PortNumber } catch { 0 }
if (-not $CurrentRdpPort) { $CurrentRdpPort = 3389 }
$Backup.RdpPort = $CurrentRdpPort

Write-Info "Current RDP port: $CurrentRdpPort"
$RdpPortInput = Read-Host "    New RDP port 1024-65535 (Enter to keep $CurrentRdpPort)"

$NewRdpPort = $CurrentRdpPort
if (![string]::IsNullOrWhiteSpace($RdpPortInput)) {
    if ($RdpPortInput -match '^\d+$' -and [int]$RdpPortInput -ge 1024 -and [int]$RdpPortInput -le 65535) {
        $NewRdpPort = [int]$RdpPortInput
    } else {
        Write-Warn "Invalid port '$RdpPortInput'  -  must be 1024-65535. Keeping $CurrentRdpPort."
    }
}

$ChangeDNS = (Read-Host "    Set DNS to $DNS1 + $DNS2 with DoH? (Y/N)") -match "^[Yy]$"

Write-Host ""
Write-Step "Applying all tweaks  —  this may take a few minutes..."

# =====================================================================
# 2. Computer Identity
# =====================================================================

Write-Header "Computer Identity"

if (![string]::IsNullOrWhiteSpace($NewComputerName)) {
    $Backup.ComputerName = $env:COMPUTERNAME
    try {
        Rename-Computer -NewName $NewComputerName -Force -ErrorAction Stop
        Write-OK "Will rename to '$NewComputerName' after restart"
    } catch {
        Write-Fail "Rename failed  -  $_"
    }
} else {
    Write-Skipped "Computer name"
}

# =====================================================================
# 3. Network  -  RDP, DNS, DoH, LLMNR
# =====================================================================

Write-Header "Network, Remote Desktop & DNS"

# PortNumber is snapshotted here separately because we only call Set-RegSafe for it
# if the user actually changed the port  -  without this the original port has no backup entry.
$null = Save-RegValue -Path $RdpPath -Name "PortNumber"

# Enable Remote Desktop
Set-RegSafe -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
$rdpRules = Get-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
$Backup.RdpFirewallState = ($rdpRules | Where-Object Enabled -eq "True" | Measure-Object).Count -gt 0
Write-Step "Remote Desktop firewall before: $(if ($Backup.RdpFirewallState) { 'already enabled' } else { 'disabled' })"
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Write-OK "Remote Desktop enabled"

# Require Network Level Authentication  -  users must authenticate before a session is created,
# which blocks unauthenticated brute-force attempts against the login screen.
Set-RegSafe -Path $RdpPath -Name "UserAuthentication" -Value 1
Write-OK "NLA (Network Level Authentication) enforced"

# Custom RDP port
if ($NewRdpPort -ne $CurrentRdpPort) {
    Set-RegSafe -Path $RdpPath -Name "PortNumber" -Value $NewRdpPort -Type "DWord"
    # Both TCP and UDP are used by RDP  -  both need firewall rules
    foreach ($Proto in @("TCP", "UDP")) {
        $ruleName = "RDP-Custom-$Proto-$NewRdpPort"
        $rule = New-NetFirewallRule -DisplayName $ruleName -Direction Inbound `
            -Protocol $Proto -LocalPort $NewRdpPort -Action Allow -Profile Any -ErrorAction SilentlyContinue
        if ($rule) {
            $Backup.FirewallRules.Add($ruleName)
            Write-OK "Firewall rule added: $ruleName (Inbound $Proto port $NewRdpPort)"
        } else {
            Write-Warn "Could not create firewall rule for $Proto $NewRdpPort"
        }
    }
    Write-OK "RDP port changed: $CurrentRdpPort -> $NewRdpPort"
}

# Disable LLMNR  -  prevents link-local multicast name resolution, which can be abused
# for name poisoning attacks (Responder/MITM) on the local network segment.
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0
Write-OK "LLMNR disabled"

if ($ChangeDNS) {
    $ActiveAdapters = Get-NetAdapter | Where-Object Status -eq "Up"
    foreach ($Adapter in $ActiveAdapters) {
        $CurrentServers = (Get-DnsClientServerAddress -InterfaceAlias $Adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses
        $Backup.DNS.Add([PSCustomObject]@{ Alias = $Adapter.Name; Servers = $CurrentServers })
        $oldDns = if ($CurrentServers) { $CurrentServers -join ", " } else { "none" }
        try {
            Set-DnsClientServerAddress -InterfaceAlias $Adapter.Name -ServerAddresses $DNS1, $DNS2 -ErrorAction Stop
            Write-OK "$($Adapter.Name): DNS  $oldDns  ->  $DNS1, $DNS2"
        } catch { Write-Fail "$($Adapter.Name): could not set DNS  —  $_" }
    }
    # Register both resolvers for DNS-over-HTTPS (native Windows 11 feature).
    # Set- only modifies existing entries; Add- creates them. 1.1.1.2 is not in Windows's
    # built-in DoH list so we must Add- first; fall back to Set- if it already exists.
    foreach ($s in $DohServers) {
        try {
            $existing = Get-DnsClientDohServerAddress -ServerAddress $s.Addr -ErrorAction SilentlyContinue
            if ($existing) {
                Set-DnsClientDohServerAddress -ServerAddress $s.Addr -DohTemplate $s.Tpl `
                    -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop | Out-Null
            } else {
                Add-DnsClientDohServerAddress -ServerAddress $s.Addr -DohTemplate $s.Tpl `
                    -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction Stop | Out-Null
            }
            Write-OK "DoH registered: $($s.Addr) -> $($s.Tpl)"
        } catch { Write-Warn "DoH registration failed for $($s.Addr): $_" }
    }
}

# TCP stack tuning  -  reduces latency for RDP sessions and local dev servers.
# TcpAckFrequency = 1  disables delayed ACK (sends ACK immediately instead of waiting 200 ms).
# TCPNoDelay      = 1  disables Nagle's algorithm (sends small packets immediately).
# These are set per network adapter interface since Windows stores them per-GUID.
$TcpInterfacesPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
Get-ChildItem -Path $TcpInterfacesPath -ErrorAction SilentlyContinue | ForEach-Object {
    Set-RegSafe -Path $_.PSPath -Name "TcpAckFrequency" -Value 1
    Set-RegSafe -Path $_.PSPath -Name "TCPNoDelay"      -Value 1
}

$TcpGlobalPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
# Reduce TIME_WAIT so ports are freed faster under heavy localhost API traffic.
Set-RegSafe -Path $TcpGlobalPath -Name "TcpTimedWaitDelay" -Value $TcpTimedWaitDelay
# Expand the ephemeral port range to the OS maximum (default ceiling is 5000 on older builds).
Set-RegSafe -Path $TcpGlobalPath -Name "MaxUserPort"       -Value $TcpMaxUserPort

Write-OK "TCP stack tuned (no-delay ACK, Nagle off, TIME_WAIT 30 s, 65534 ephemeral ports)"

# =====================================================================
# 4. Package Management (winget)
# =====================================================================

Write-Header "Package Management"

$TerminalStableSkipped = $false
foreach ($App in $AppsToRemove) {
    # Windows Terminal hosts the current session - removing it mid-script kills the process.
    # $env:WT_SESSION is a GUID set by Windows Terminal for every shell it spawns.
    if ($App -eq "Microsoft.WindowsTerminal" -and $env:WT_SESSION) {
        $TerminalStableSkipped = $true
        Write-Warn "Skipping Terminal stable removal  -  script is running inside it. A one-shot task will remove it at next logon."
        continue
    }

    Write-Step "Removing $App"
    winget uninstall --id "$App" --accept-source-agreements --silent 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-OK "Removed $App" }
    else { Write-Warn "$App was not installed or could not be removed" }
}

# Register a one-shot logon task to remove Terminal stable on next sign-in.
# It runs once then deletes itself. Safe to skip if Terminal Preview wasn't installed.
if ($TerminalStableSkipped) {
    try {
        # Wrap in PowerShell so the task unregisters itself after running (true one-shot).
        # Use -EncodedCommand so the -Argument value needs no nested or backtick-escaped quotes.
        $taskName = "TweakWindows-RemoveTerminalStable"
        $innerCmd = 'winget uninstall --id Microsoft.WindowsTerminal --accept-source-agreements --silent; ' +
                    "Unregister-ScheduledTask -TaskName $taskName -Confirm:" + '$false'
        $bytes    = [System.Text.Encoding]::Unicode.GetBytes($innerCmd)
        $encoded  = [Convert]::ToBase64String($bytes)
        $act = New-ScheduledTaskAction -Execute 'powershell.exe' `
                   -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -EncodedCommand $encoded"
        $trg = New-ScheduledTaskTrigger -AtLogOn
        $cfg = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
                   -StartWhenAvailable
        $pri = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
        Register-ScheduledTask -TaskName $taskName `
            -Action $act -Trigger $trg -Settings $cfg -Principal $pri `
            -Description "One-shot: removes Terminal stable on first logon, then deletes itself." `
            -Force -ErrorAction Stop | Out-Null
        Write-OK "Scheduled Terminal stable removal at next logon (self-deleting)"
    } catch { Write-Warn "Could not register Terminal removal task: $_" }
}

foreach ($App in $AppsToInstall) {
    Write-Step "Installing $($App.Id)"
    # Pre-check: ask winget if the package is already installed (avoids fragile exit-code guessing)
    $listOut = winget list --id $App.Id --exact --accept-source-agreements 2>&1
    if ($listOut | Where-Object { $_ -match [regex]::Escape($App.Id) }) {
        Write-Skipped "$($App.Id)  (already installed)"
        continue
    }
    if (![string]::IsNullOrEmpty($App.Override)) {
        winget install --id $App.Id --exact --accept-source-agreements `
            --accept-package-agreements --override "$($App.Override)" 2>&1 | Out-Null
    } else {
        winget install --id $App.Id --exact --accept-source-agreements `
            --accept-package-agreements --silent 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010 -or $LASTEXITCODE -eq 1641) {
        Write-OK "Installed $($App.Id)"
    } else {
        Write-Warn "Install may have failed for $($App.Id)  -  check the log for details"
    }
}

Write-Step "Upgrading all installed packages"
$upgradeProc = Start-Process winget -ArgumentList "upgrade --all --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru
if ($upgradeProc.ExitCode -eq 0) { Write-OK "All packages up to date" }
else { Write-Warn "Some packages may not have upgraded (exit $($upgradeProc.ExitCode))  -  check the log" }

# Register a weekly scheduled task to keep packages updated automatically
Write-Step "Registering weekly winget auto-upgrade task"
try {
    $WingetPath = (Get-Command winget -ErrorAction Stop).Source
    $Action   = New-ScheduledTaskAction -Execute $WingetPath `
                    -Argument "upgrade --all --silent --accept-package-agreements --accept-source-agreements"
    $Trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $WingetUpgradeDay -At $WingetUpgradeTime
    $Settings = New-ScheduledTaskSettingsSet `
                    -ExecutionTimeLimit  (New-TimeSpan -Hours 1) `
                    -RunOnlyIfNetworkAvailable `
                    -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName "Winget Weekly Upgrade" `
        -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal `
        -Description "Upgrades all winget packages silently every Sunday at 9 AM." `
        -Force -ErrorAction Stop | Out-Null
    Write-OK "Scheduled task registered: 'Winget Weekly Upgrade' ($WingetUpgradeDay ${WingetUpgradeTime}, SYSTEM)"
} catch {
    Write-Warn "Could not register scheduled task: $_"
}

# Gemini CLI has no winget package  -  install via npm once Node.js is in PATH.
# Install to a machine-wide prefix so the CLI is available to all users, not just the
# elevated admin session that runs this script.
Write-Step "Installing Gemini CLI via npm"
$NpmCmd = Get-Command npm -ErrorAction SilentlyContinue
if (-not $NpmCmd) {
    # Node was just installed by winget; refresh PATH before trying npm
    $env:PATH = [System.Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    $NpmCmd = Get-Command npm -ErrorAction SilentlyContinue
}
if ($NpmCmd) {
    $NpmGlobal = "$env:ProgramData\npm-global"
    if (!(Test-Path $NpmGlobal)) { New-Item -Path $NpmGlobal -ItemType Directory -Force | Out-Null }

    # Set the machine-wide npm global prefix so every user's "npm install -g" lands here,
    # not in the elevated admin session's per-user %APPDATA%\npm.
    npm config set prefix "$NpmGlobal" --global 2>&1 | Out-Null

    # Ensure PATH covers the prefix root (where npm puts .cmd wrappers on Windows)
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    if ($machinePath -notlike "*$NpmGlobal*") {
        [Environment]::SetEnvironmentVariable('PATH', "$machinePath;$NpmGlobal", 'Machine')
        $env:PATH = $env:PATH + ";$NpmGlobal"
    }

    npm install -g "@google/gemini-cli" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Gemini CLI installed to $NpmGlobal (open a new terminal to use it)"
    } else {
        Write-Warn "npm install for Gemini CLI may have failed  -  check the log"
    }
} else {
    Write-Warn "npm not found  -  Gemini CLI skipped. After reboot run: npm install -g @google/gemini-cli"
}


# =====================================================================
# 5. Microsoft Office  -  Word, Excel, PowerPoint via ODT
# =====================================================================

if (-not $SkipOffice) {
    Write-Header "Microsoft Office"

    $OdtDir    = "$BackupDir\ODT"
    $OdtSetup  = "$OdtDir\setup.exe"
    $OfficeCfg = "$OdtDir\office-config.xml"
    if (!(Test-Path $OdtDir)) { New-Item -Path $OdtDir -ItemType Directory -Force | Out-Null }

    # Click-to-Run configuration key is present on any modern Office / M365 install
    $Backup.OfficeInstalled = Test-Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

    if ($Backup.OfficeInstalled) {
        Write-Skipped "Office already installed  -  nothing to do"
    } else {
        Write-Step "Extracting Office Deployment Tool"
        winget install --id Microsoft.OfficeDeploymentTool --exact `
            --accept-source-agreements --accept-package-agreements `
            --override ('/quiet /extract:"' + $OdtDir + '"') 2>&1 | Out-Null

        if (!(Test-Path $OdtSetup)) {
            Write-Warn "ODT setup.exe not found at $OdtSetup  -  Office install skipped"
        } else {
            # Minimal config: only Word, Excel, PowerPoint; everything else excluded.
            # Product ID O365ProPlusRetail covers personal M365, business M365, and retail M365 Apps.
            # Change the Language ID if a different locale is needed.
            Set-Content -Path $OfficeCfg -Encoding UTF8 -Value @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Display Level="None" AcceptEULA="TRUE" />
  <Updates Enabled="TRUE" Channel="Current" />
  <Logging Level="Standard" Path="$LogDir" />
</Configuration>
"@
            Write-Step "Installing Office  -  downloads ~1 GB, allow 5-15 minutes"
            $officeProc = Start-Process -FilePath $OdtSetup `
                -ArgumentList ('/configure "' + $OfficeCfg + '"') `
                -Wait -PassThru -ErrorAction Stop
            if ($officeProc.ExitCode -eq 0) {
                Write-OK "Office installed  -  Word, Excel, PowerPoint"
            } else {
                Write-Warn "Office install may have failed (exit $($officeProc.ExitCode))  -  check $LogDir for details"
            }
        }
    }
} else {
    Write-Skipped "Microsoft Office install  (-SkipOffice flag set)"
}

# =====================================================================
# 6. Taskbar Pins
#    LayoutModification.xml is the Microsoft-supported method for
#    pinning apps to the taskbar. It takes effect on the next sign-in,
#    which happens automatically after the reboot at the end of the script.
# =====================================================================

Write-Header "Taskbar Pins"

# Resolve the target user's profile path from the registry
$TargetProfile = (Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$TargetSID" `
    -ErrorAction SilentlyContinue).ProfileImagePath

if ($TargetProfile) {
    # %APPDATA% in this XML expands correctly to the signing-in user's roaming profile
    $PinXml = @'
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Append">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk" />
        <taskbar:UWA AppUserModelID="Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe!App" />
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
'@

    # Write to the target user's Shell folder
    $UserShellDir = "$TargetProfile\AppData\Local\Microsoft\Windows\Shell"
    $UserXmlPath  = "$UserShellDir\LayoutModification.xml"
    if (!(Test-Path $UserShellDir)) { New-Item -Path $UserShellDir -ItemType Directory -Force | Out-Null }
    $Backup.TaskbarXml.Add([PSCustomObject]@{
        Path    = $UserXmlPath
        Content = if (Test-Path $UserXmlPath) { Get-Content $UserXmlPath -Raw } else { "NotPresent" }
    })
    Set-Content -Path $UserXmlPath -Value $PinXml -Encoding UTF8 -Force
    Write-OK "Pins queued for $TargetUser - VSCode + Terminal Preview will appear after sign-in"

    # Write to the Default profile so any future new users get the same pins
    $DefaultShellDir = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell"
    $DefaultXmlPath  = "$DefaultShellDir\LayoutModification.xml"
    if (!(Test-Path $DefaultShellDir)) { New-Item -Path $DefaultShellDir -ItemType Directory -Force | Out-Null }
    $Backup.TaskbarXml.Add([PSCustomObject]@{
        Path    = $DefaultXmlPath
        Content = if (Test-Path $DefaultXmlPath) { Get-Content $DefaultXmlPath -Raw } else { "NotPresent" }
    })
    Set-Content -Path $DefaultXmlPath -Value $PinXml -Encoding UTF8 -Force
    Write-OK "Pins also applied to Default profile (affects all future users)"
} else {
    Write-Warn "Could not resolve profile path for $TargetUser - taskbar pins skipped"
}

# =====================================================================
# 7. Appx/UWP Bloatware Removal
# =====================================================================

if (-not $SkipBloat) {
    Write-Header "UWP Bloatware Removal"
    foreach ($Pattern in $AppxBloat) {
        Write-Step "Purging: $Pattern"

        # Remove from all existing user profiles
        Get-AppxPackage -AllUsers $Pattern -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch $AppxSafeList } |
            ForEach-Object {
                $pkg = $_   # capture before entering the catch scope where $_ becomes the exception
                try {
                    Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                    Write-OK "  Removed $($pkg.Name)"
                } catch { Write-Warn "  Could not remove $($pkg.Name) - $_" }
            }

        # Remove from the provisioned image so it won't reinstall for new profiles
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $Pattern -and $_.DisplayName -notmatch $AppxSafeList } |
            ForEach-Object {
                $pkg = $_
                try {
                    Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
                    Write-OK "  De-provisioned $($pkg.DisplayName)"
                } catch { Write-Warn "  Could not de-provision $($pkg.DisplayName) - $_" }
            }
    }
} else {
    Write-Skipped "Appx bloatware removal  (-SkipBloat flag set)"
}

# =====================================================================
# 8. Microsoft Edge Hardening
# =====================================================================

if (-not $SkipEdge) {
    Write-Header "Microsoft Edge"

    $EP = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    Ensure-RegPath $EP

    # Default search engine
    Set-RegSafe -Path $EP -Name "DefaultSearchProviderEnabled"    -Value 1
    Set-RegSafe -Path $EP -Name "DefaultSearchProviderName"       -Value "Google"                                       -Type "String"
    Set-RegSafe -Path $EP -Name "DefaultSearchProviderSearchURL"  -Value "https://www.google.com/search?q={searchTerms}" -Type "String"

    # Disable Edge's built-in password manager and autofill (using Keeper instead)
    Set-RegSafe -Path $EP -Name "PasswordManagerEnabled"     -Value 0
    Set-RegSafe -Path $EP -Name "AutofillAddressEnabled"     -Value 0
    Set-RegSafe -Path $EP -Name "AutofillCreditCardEnabled"  -Value 0

    # Performance  -  these features keep Edge running even when no windows are open,
    # which wastes VM resources with no user benefit.
    Set-RegSafe -Path $EP -Name "StartupBoostEnabled"   -Value 0
    Set-RegSafe -Path $EP -Name "BackgroundModeEnabled" -Value 0

    # Sleep inactive tabs after $EdgeSleepingTabsTimeout seconds to free memory
    Set-RegSafe -Path $EP -Name "SleepingTabsEnabled" -Value 1
    Set-RegSafe -Path $EP -Name "SleepingTabsTimeout" -Value $EdgeSleepingTabsTimeout

    # Disable DNS prefetch, TCP preconnect, and prerendering  -  reduces idle network noise
    Set-RegSafe -Path $EP -Name "NetworkPredictionOptions" -Value 2

    # Bloat and telemetry
    Set-RegSafe -Path $EP -Name "NewTabPageContentEnabled"     -Value 0
    Set-RegSafe -Path $EP -Name "HubsSidebarEnabled"           -Value 0
    Set-RegSafe -Path $EP -Name "EdgeShoppingAssistantEnabled" -Value 0
    Set-RegSafe -Path $EP -Name "MetricsReportingEnabled"      -Value 0

    # Force-install extensions via policy (applied at browser startup, user cannot remove).
    # Each entry is backed up automatically because Set-RegSafe snapshots before writing.
    $ExtPath = "$EP\ExtensionInstallForcelist"
    Ensure-RegPath $ExtPath
    $i = 1
    foreach ($Ext in $EdgeExtensions) {
        Set-RegSafe -Path $ExtPath -Name "$i" -Value $Ext -Type String
        $i++
    }

    # Edge reads group policy only at startup. Background processes survive after the window
    # is closed, so a new window inherits the old policy session. Kill all Edge processes now
    # so the very next launch reads the updated ExtensionInstallForcelist and auto-installs.
    Get-Process -Name msedge, msedgewebview2 -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Write-OK "Edge hardened  -  $($EdgeExtensions.Count) extensions queued"
    Write-Info "Extensions install automatically on the next Edge launch"
    Write-Info "If they do not appear within ~60 s, visit edge://policy to verify the entries"
} else {
    Write-Skipped "Edge hardening  (-SkipEdge flag set)"
}

# =====================================================================
# 9. SMB Hardening
# =====================================================================

Write-Header "SMB Hardening"

# Snapshot current SMB config before touching anything so revert can restore exact original state
$smbBefore = Get-SmbServerConfiguration -ErrorAction SilentlyContinue
if ($smbBefore) {
    $Backup.SMB1Enabled       = $smbBefore.EnableSMB1Protocol
    $Backup.SMBSigningRequired = $smbBefore.RequireSecuritySignature
    Write-Step "SMB before  -  SMBv1: $($smbBefore.EnableSMB1Protocol)  |  signing required: $($smbBefore.RequireSecuritySignature)"
}

# SMBv1 is the protocol behind WannaCry and NotPetya  -  there is no reason to have it enabled.
try {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction Stop
    Write-OK "SMBv1 disabled"
} catch { Write-Warn "Could not disable SMBv1  -  $_" }

# Require SMB signing on all connections to prevent relay/MITM attacks
try {
    Set-SmbServerConfiguration -RequireSecuritySignature $true -Force -ErrorAction Stop
    Write-OK "SMB signing required"
} catch { Write-Warn "Could not enforce SMB signing  -  $_" }

# =====================================================================
# 10. Hypervisor & Storage Optimization
# =====================================================================

Write-Header "KVM / Proxmox Optimization"

# Hibernation wastes disk space equal to the VM's RAM size and serves no purpose in a VM
$hibReg = try { (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -ErrorAction Stop).HibernateEnabled } catch { $null }
$Backup.Hibernation = ($hibReg -ne 0)   # $true = was enabled
Write-Step "Hibernation before: $(if ($Backup.Hibernation) { 'enabled' } else { 'already off' })"
$pfcfgResult = powercfg /h off 2>&1
if ($LASTEXITCODE -eq 0) { Write-OK "Hibernation disabled" }
else { Write-Warn "Could not disable hibernation  —  $pfcfgResult" }

# Fast Startup uses the hibernation subsystem under the hood. Leaving it enabled can corrupt
# the VM disk state across Proxmox snapshots and live migrations.
Set-RegSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0
Write-OK "Fast Startup disabled"

# High Performance power plan  -  the hypervisor manages real power; the guest should not throttle
$activeSchemeLine = powercfg /getactivescheme 2>&1 | Out-String
if ($activeSchemeLine -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
    $Backup.PowerPlan = $Matches[1]
    Write-Step "Power plan before: $($Backup.PowerPlan)"
}
$PlanList = powercfg /list 2>&1 | Out-String
if ($PlanList -match $HighPerfGUID) {
    powercfg /setactive $HighPerfGUID 2>&1 | Out-Null
    Write-OK "Power plan set to High Performance"
} else {
    Write-Warn "High Performance plan GUID $HighPerfGUID not found  -  power plan unchanged"
}

# Memory compression adds CPU overhead inside the VM for a task the hypervisor already handles
$Backup.MemoryCompression = (Get-MMAgent -ErrorAction SilentlyContinue).MemoryCompression
Write-Step "Memory compression before: $(if ($Backup.MemoryCompression) { 'enabled' } else { 'already off' })"
if ($Backup.MemoryCompression) {
    try {
        Disable-MMAgent -MemoryCompression -ErrorAction Stop
        Write-OK "Memory compression disabled"
    } catch { Write-Warn "Could not disable memory compression  —  $_" }
} else {
    Write-Skipped "Memory compression already off"
}

# Disable NTFS last-access timestamp updates  -  reduces write I/O on every file read.
# Backed up automatically via Set-RegSafe so revert restores the exact original value.
Set-RegSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Value 1
Write-OK "NTFS last-access timestamps disabled"

# System Restore is redundant when Proxmox handles snapshots at the hypervisor level
$srDisabled = try { (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" `
    -Name "DisableSR" -ErrorAction Stop).DisableSR } catch { $null }
$Backup.SystemRestoreEnabled = ($srDisabled -ne 1)   # $true = was enabled before this run
Write-Step "System Restore before: $(if ($Backup.SystemRestoreEnabled) { 'enabled' } else { 'already disabled' })"
try {
    Disable-ComputerRestore -Drive "C:\" -ErrorAction Stop
    Write-OK "System Restore disabled (use Proxmox snapshots instead)"
} catch { Write-Warn "Could not disable System Restore  -  $_" }

# Disable VBS (Virtualization Based Security).
# WARNING: This turns off Credential Guard and HVCI. On a physical machine this would be a
# serious security regression. On a KVM VM the hypervisor already provides the isolation
# boundary, and VBS with nested virtualization adds significant overhead.
Set-RegSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0
Write-Warn "VBS disabled  -  Credential Guard + HVCI off (expected for KVM guest)"

# Lock pagefile at $PagefileSizeMB MB to prevent Windows from expanding it mid-workload.
# Uses CIM (modern) instead of the deprecated WMI cmdlets.
try {
    $CS = Get-CimInstance -ClassName Win32_ComputerSystem
    $pfBefore = Get-CimInstance -ClassName Win32_PageFileSetting |
                Where-Object { $_.Name -eq 'C:\pagefile.sys' }
    $Backup.Pagefile = [PSCustomObject]@{
        AutoManaged = $CS.AutomaticManagedPagefile
        InitialSize = if ($pfBefore) { $pfBefore.InitialSize } else { $null }
        MaximumSize = if ($pfBefore) { $pfBefore.MaximumSize } else { $null }
    }
    Write-Step "Pagefile before: AutoManaged=$($Backup.Pagefile.AutoManaged)  InitialSize=$($Backup.Pagefile.InitialSize)  MaximumSize=$($Backup.Pagefile.MaximumSize)"
    $CS | Set-CimInstance -Property @{ AutomaticManagedPagefile = $false }

    # Use Where-Object to avoid WQL backslash escaping issues entirely
    $PF = Get-CimInstance -ClassName Win32_PageFileSetting |
          Where-Object { $_.Name -eq 'C:\pagefile.sys' }
    $pfSize = [UInt32]$PagefileSizeMB
    if ($PF) {
        $PF | Set-CimInstance -Property @{ InitialSize = $pfSize; MaximumSize = $pfSize }
    } else {
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{
            Name = "C:\pagefile.sys"; InitialSize = $pfSize; MaximumSize = $pfSize
        } | Out-Null
    }
    Write-OK "Pagefile locked at $PagefileSizeMB MB"
} catch {
    Write-Fail "Pagefile configuration failed  -  $_"
}

# SysMain is being disabled anyway; clean up its Prefetcher registry entries too
$PrefetchPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
Set-RegSafe -Path $PrefetchPath -Name "EnablePrefetcher"  -Value 0
Set-RegSafe -Path $PrefetchPath -Name "EnableSuperfetch"  -Value 0

# Give maximum CPU time slices to the foreground application.
# Value comes from $Win32PrioritySeparation in config; automatically backed up via Set-RegSafe.
Set-RegSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
    -Name "Win32PrioritySeparation" -Value $Win32PrioritySeparation

# Capture the current bootux BCD value before overwriting it so revert can restore exactly.
# bcdedit /enum outputs "bootux    disabled" or nothing if the value was never set.
$bcdOutput = (bcdedit /enum current 2>&1 | Out-String)
if ($bcdOutput -match '(?m)^\s*bootux\s+(\S+)') {
    $Backup.BootUxValue = $Matches[1]
    Write-Step "bootux before: $($Backup.BootUxValue)"
} else {
    $Backup.BootUxValue = "NotSet"   # key was absent; revert must delete it, not set it back
    Write-Step "bootux before: not set (default)"
}
# Remove the animated boot logo  -  shaves time off every post-update reboot with no downside.
try {
    bcdedit /set bootux disabled 2>&1 | Out-Null
    Write-OK "Boot animation disabled (bootux)"
} catch {
    Write-Warn "Could not disable boot animation  -  $_"
}

# =====================================================================
# 11. NTP Time Synchronization
# =====================================================================

Write-Header "NTP Time Synchronization"

# Capture current NTP peer list before changing so revert can restore it exactly.
$ntpParamsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
$currentNtpPeer = try { (Get-ItemProperty $ntpParamsPath -Name "NtpServer" -ErrorAction Stop).NtpServer } catch { $null }
$Backup.NtpServer = if ($currentNtpPeer) { $currentNtpPeer } else { "time.windows.com,0x9" }
Write-Step "NTP server before: $($Backup.NtpServer)"

# The Windows default sync interval is 7 days, which causes noticeable clock drift in VMs.
# Sync at $NtpPollIntervalSeconds instead, using the server defined in $NtpServer.
$NtpPollPath = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient"
try {
    w32tm /config /syncfromflags:manual /manualpeerlist:"$NtpServer" /reliable:yes /update 2>&1 | Out-Null
    Set-RegSafe -Path $NtpPollPath -Name "SpecialPollInterval" -Value $NtpPollIntervalSeconds
    Restart-Service W32Time -ErrorAction SilentlyContinue
    w32tm /resync /force 2>&1 | Out-Null
    Write-OK "NTP: syncing every $NtpPollIntervalSeconds s from $NtpServer"
} catch {
    Write-Warn "NTP configuration failed  -  $_"
}

# =====================================================================
# 12. UI, Telemetry & Privacy
# =====================================================================

Write-Header "UI, Telemetry & Privacy"

# Delivery Optimization  -  disable peer-to-peer update sharing with external PCs
Set-RegSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" `
    -Name "DODownloadMode" -Value 0

# Telemetry  -  set to minimum allowed. Note: on Home/Pro editions Windows silently enforces
# a floor of level 1 (Basic); the registry key alone is not sufficient  -  the DiagTrack
# service is also disabled in Section 12 to reduce actual data collection.
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0

# Activity History (Timeline) records everything you open and can sync to Microsoft's servers
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed"    -Value 0
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0

# Advertising ID feeds targeted ads based on app usage  -  no reason to have this on a VM
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

# Lock screen adds a step on a VM with no shared-use security requirement
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1

# -- Explorer & Taskbar ---------------------------------------------

$EA = "$HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Show file extensions  -  helps spot renamed executables like "invoice.pdf.exe"
Set-RegSafe -Path $EA -Name "HideFileExt"     -Value 0

# Show hidden files and protected OS files (useful on a managed VM)
Set-RegSafe -Path $EA -Name "Hidden"          -Value 1
Set-RegSafe -Path $EA -Name "ShowSuperHidden" -Value 0   # keep protected OS files hidden (safe default)

# Start Menu  -  reduce noise and tracking
Set-RegSafe -Path $EA -Name "Start_Layout"                -Value 1   # More pins layout
Set-RegSafe -Path $EA -Name "Start_TrackDocs"             -Value 0
Set-RegSafe -Path $EA -Name "Start_TrackProgs"            -Value 0
Set-RegSafe -Path $EA -Name "Start_HideRecentJumplists"   -Value 1
Set-RegSafe -Path $EA -Name "Start_HideRecentlyAddedApps" -Value 1
Set-RegSafe -Path $EA -Name "LaunchTo"                    -Value 1   # Open Explorer to This PC

# Taskbar
# TaskbarDa is protected on Windows 11 24H2+; the HKLM policy below is the authoritative removal.
# Use inline write so we can emit Warn (not Fail) when the key is locked.
$null = Save-RegValue -Path $EA -Name "TaskbarDa"
try {
    Set-ItemProperty -Path $EA -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction Stop
    Write-OK "TaskbarDa = 0"
} catch { Write-Warn "TaskbarDa: write blocked (protected on 24H2+) — HKLM policy covers widget removal" }
Set-RegSafe -Path $EA -Name "TaskbarAnimations" -Value 0

# Belt-and-suspenders: machine-level policy disables the widgets feed regardless of HKCU.
# On Windows 11 24H2+ the HKCU key alone can be overridden by the shell.
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0

# Search box  -  hide to save space (Win key still works for search)
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "SearchboxTaskbarMode" -Value 0

# Prevent all apps from running in the background (reduces idle CPU/RAM in the VM)
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" -Name "LetAppsRunInBackground" -Value 2

# Don't relaunch apps after sign-in (cleaner, faster boot)
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\SignOutOptions" -Name "RestartApps" -Value 0

# -- Visuals --------------------------------------------------------
# Animations and transparency add GPU overhead with no practical benefit in a VM.

Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" `
    -Name "EnableTransparency" -Value 0

# VisualFXSetting belongs in VisualEffects, not Explorer\Advanced
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" `
    -Name "VisualFXSetting" -Value 3   # Custom (controlled by individual keys below)

Set-RegSafe -Path "$HKCU\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate"       -Value "0" -Type "String"
Set-RegSafe -Path "$HKCU\Control Panel\Desktop"               -Name "FontSmoothing"    -Value "2" -Type "String"
Set-RegSafe -Path "$HKCU\Control Panel\Desktop"               -Name "FontSmoothingType" -Value 2

$DWM = "$HKCU\Software\Microsoft\Windows\DWM"
Set-RegSafe -Path $DWM -Name "Animations"          -Value 0
Set-RegSafe -Path $DWM -Name "AnimationsShiftKey"  -Value 0

# -- Autoplay -------------------------------------------------------
# Disable Autoplay entirely  -  prevents auto-execution from USB drives and optical media

Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
    -Name "NoAutoplayfornonVolume" -Value 1
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" `
    -Name "DisableAutoplay" -Value 1

# -- Clipboard History (Win + V) ------------------------------------
# Policy-level allow (ensures no GPO is blocking it)
Set-RegSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Value 1
# User preference (the actual on/off toggle)
Set-RegSafe -Path "$HKCU\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 1

# -- Game DVR -------------------------------------------------------
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
Set-RegSafe -Path "$HKCU\System\GameConfigStore"                             -Name "GameDVR_Enabled"   -Value 0

# -- Developer Quality-of-Life --------------------------------------

# Remove the 260-character MAX_PATH limit. Node.js, Python, and Git repos with nested
# vendor trees hit this constantly. Pure improvement, no compatibility risk on Windows 11.
Set-RegSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1

# Developer Mode unlocks sideloading, symlink creation without elevation, and some WinRT
# dev APIs. No security regression on a personal dev VM.
Set-RegSafe -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" `
    -Name "AllowDevelopmentWithoutDevLicense" -Value 1

# Keep the Windows Security shield visible in the taskbar tray (not buried in the overflow arrow)
Get-ChildItem -Path "$HKCU\Control Panel\NotifyIconSettings" -ErrorAction SilentlyContinue |
    ForEach-Object {
        $ExePath = try { (Get-ItemProperty $_.PSPath -Name ExecutablePath -ErrorAction Stop).ExecutablePath } catch { $null }
        if ($ExePath -match "SecurityHealthSystray\.exe") {
            Set-RegSafe -Path $_.PSPath -Name "IsPromoted" -Value 1
            Write-OK "Windows Security icon pinned to tray"
        }
    }

Write-OK "UI, telemetry, and privacy settings applied"

# Restart Explorer so HKCU changes (file extensions, hidden files, taskbar) take effect
# in the current session without waiting for a full reboot.
Write-Step "Restarting Explorer to apply UI settings..."
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 800
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer -ErrorAction SilentlyContinue
}
Write-OK "Explorer restarted"

# =====================================================================
# 13. Keyboard & Language
# =====================================================================

Write-Header "Keyboard & Language"

$currentLangs = Get-WinUserLanguageList -ErrorAction SilentlyContinue
if ($currentLangs) {
    $Backup.LanguageList = ($currentLangs | ForEach-Object {
        "$($_.LanguageTag)|$($_.InputMethodTips -join ',')"
    }) -join ';'
    Write-Step "Language list before: $($Backup.LanguageList)"
}

$LangList = New-WinUserLanguageList $PrimaryLang
$LangList[0].InputMethodTips.Clear()
$LangList[0].InputMethodTips.Add($PrimaryLangTip)

$Secondary = New-WinUserLanguageList $SecondaryLang
$Secondary[0].InputMethodTips.Clear()
$Secondary[0].InputMethodTips.Add($SecondaryLangTip)
$LangList += $Secondary[0]
Set-WinUserLanguageList $LangList -Force -WarningAction SilentlyContinue

# Keep local keyboard layout when connecting via RDP instead of inheriting the client's layout
Set-RegSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" `
    -Name "IgnoreRemoteKeyboardLayout" -Value 1

# Lock the Preload entries to prevent Windows from injecting ghost layouts on reconnect
foreach ($PreloadPath in @(
    "$HKCU\Keyboard Layout\Preload",
    "Registry::HKEY_USERS\.DEFAULT\Keyboard Layout\Preload"
)) {
    # Snapshot all existing numbered values before deleting the key
    if (Test-Path $PreloadPath) {
        $existingPreload = Get-ItemProperty $PreloadPath -ErrorAction SilentlyContinue
        if ($existingPreload) {
            $existingPreload.PSObject.Properties |
                Where-Object { $_.Name -match '^\d+$' } |
                ForEach-Object {
                    Save-RegValue -Path $PreloadPath -Name $_.Name | Out-Null
                }
        }
    } else {
        # Key was absent; record so revert can remove it
        $script:Backup.Registry += [PSCustomObject]@{
            Path = $PreloadPath; Name = "__KeyAbsent__"; Value = $null; Kind = "NotPresent"
        }
    }
    Remove-Item -Path $PreloadPath -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $PreloadPath -Force | Out-Null
    Set-ItemProperty -Path $PreloadPath -Name "1" -Value $($PrimaryLangTip.Split(':')[1])   -Type String -Force
    Set-ItemProperty -Path $PreloadPath -Name "2" -Value $($SecondaryLangTip.Split(':')[1]) -Type String -Force
}

# Prevent Microsoft account sync from overwriting local language settings
Set-RegSafe -Path "$HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value 0

Write-OK "Keyboard layouts locked: $PrimaryLang + $SecondaryLang"

# =====================================================================
# 14. Windows Defender Hardening
# =====================================================================

Write-Header "Windows Defender Hardening"

# Block Potentially Unwanted Applications  -  catches bundleware, adware, and fake installers
try {
    Set-MpPreference -PUAProtection 1 -ErrorAction Stop
    Write-OK "PUA protection enabled"
} catch { Write-Warn "Could not set PUA protection  -  $_" }

# Network Protection blocks connections to known malicious hosts at the kernel level
try {
    Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction Stop
    Write-OK "Network protection enabled"
} catch { Write-Warn "Could not enable network protection  -  $_" }

# Controlled Folder Access prevents unauthorized processes from modifying your files,
# which is the primary mechanism ransomware uses to encrypt documents.
try {
    Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction Stop
    Write-OK "Controlled Folder Access (ransomware protection) enabled"
} catch { Write-Warn "Could not enable Controlled Folder Access  -  $_" }

# Attack Surface Reduction rules  -  targeted behavioral blocks, not heuristics.
# IDs and what they block:
#   9e6c4e1f  -  Credential stealing from LSASS (mitigates Mimikatz / Pass-the-Hash)
#   3b576869  -  Office creating executable content (stops most macro-based malware)
#   d4f940ab  -  Office spawning child processes (covers script-based Office exploits)
$ASRIds = [string[]]@(
    "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b3",
    "3b576869-a4ec-4529-8536-b80a7769e899",
    "d4f940ab-401b-4efc-aadc-ad5f3c50688a"
)
$ASRActions = [int[]]@(1, 1, 1)   # 1 = Block
try {
    Set-MpPreference -AttackSurfaceReductionRules_Ids $ASRIds `
                     -AttackSurfaceReductionRules_Actions $ASRActions -ErrorAction Stop
    Write-OK "$($ASRIds.Count) Attack Surface Reduction rules enabled"
} catch { Write-Warn "Could not apply ASR rules  -  $_" }

# =====================================================================
# 15. Services & Startup Cleanup
# =====================================================================

Write-Header "Services & Startup Cleanup"
# $ServicesToDisable and $BloatStartup are defined in the CONFIGURATION block at the top.

foreach ($Svc in $ServicesToDisable) {
    $s = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    if ($s) {
        $oldType = $s.StartType.ToString()
        if ($oldType -eq 'Disabled') {
            Write-Skipped "$($Svc.Name): already Disabled"
            continue
        }
        $Backup.Services.Add([PSCustomObject]@{ Name = $Svc.Name; StartupType = $oldType })
        Stop-Service -Name $Svc.Name -Force    -ErrorAction SilentlyContinue
        Set-Service  -Name $Svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-OK "$($Svc.Name): $oldType -> Disabled  ($($Svc.Reason))"
    } else {
        Write-Warn "$($Svc.Name) not found on this system  -  skipped"
    }
}

# Disable the automatic defrag scheduled task.
# On a VM the host storage (NVMe) handles its own layout; guest-level defrag generates
# unnecessary I/O without improving anything.
$DefragTask = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue
if ($DefragTask) {
    $Backup.DefragTaskState = $DefragTask.State.ToString()
    Write-Step "Scheduled defrag before: $($Backup.DefragTaskState)"
    if ($DefragTask.State -ne "Disabled") {
        Disable-ScheduledTask -TaskPath "\Microsoft\Windows\Defrag\" -TaskName "ScheduledDefrag" -ErrorAction SilentlyContinue | Out-Null
        Write-OK "Scheduled defrag task disabled (was: $($Backup.DefragTaskState))"
    } else {
        Write-Skipped "Scheduled defrag already disabled"
    }
} else {
    Write-Warn "Scheduled defrag task not found  -  skipped"
}

# Remove known bloatware from the startup Run key ($BloatStartup defined in config block)
$RunPath = "$HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
foreach ($Item in $BloatStartup) {
    $prop = Get-ItemProperty -Path $RunPath -Name $Item -ErrorAction SilentlyContinue
    if ($prop) {
        $Backup.StartupEntries.Add([PSCustomObject]@{ Path = $RunPath; Name = $Item; Value = $prop.$Item })
        Remove-ItemProperty -Path $RunPath -Name $Item -Force -ErrorAction SilentlyContinue
        Write-OK "Startup entry removed: $Item"
    } else {
        Write-Skipped "Startup entry $Item (not present)"
    }
}

} finally {

# =====================================================================
# FINALIZE  -  save backup, unload hive, done
# =====================================================================

Write-Header "Saving Original Settings Backup"

Save-Backup
if ($BackupPath -and (Test-Path $BackupPath)) {
    Write-OK "Backup saved to: $BackupPath"
    Write-OK "  $($Backup.Registry.Count) registry values  |  $($Backup.Services.Count) services  |  $($Backup.DNS.Count) DNS adapters  |  $($Backup.FirewallRules.Count) firewall rules  |  $($Backup.StartupEntries.Count) startup entries  |  $($Backup.TaskbarXml.Count) XML files captured"
    Write-Info "To revert all changes: .\Tweak-Windows.ps1 -Mode Revert"
} else {
    Write-Fail "Backup could not be confirmed on disk"
}

# Release handles on the loaded hive before unloading
if ($HiveLoaded) {
    [System.GC]::Collect()
    Start-Sleep -Seconds 1
    reg unload "HKU\$TargetSID" 2>&1 | Out-Null
}

Stop-Transcript | Out-Null

Write-Host ""
Write-Box "All done!  A restart is required." "Green"
Write-Host ""

$Reboot = Read-Host "  Restart now? (Y/N)"
if ($Reboot -match "^[Yy]$") { Restart-Computer -Force }

}   # end try/finally