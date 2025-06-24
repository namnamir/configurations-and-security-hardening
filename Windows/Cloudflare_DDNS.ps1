<#
.SYNOPSIS
    Updates Cloudflare A and AAAA DNS records with the current public IPv4 and IPv6 addresses.

.DESCRIPTION
    This script connects to the Cloudflare API to:
    1. Verify the provided API token.
    2. Retrieve the Cloudflare Zone ID for the specified domain.
    3. Determine the current public IPv4 and IPv6 addresses of the machine running the script.
    4. Fetch existing A and AAAA DNS records for the specified hostname (e.g., sub.example.com).
    5. Compare the current public IPs with the DNS records.
    6. Update existing DNS records or create new ones if the IP addresses have changed
       or if the records don't exist yet.

.PARAMETER Email
    The email address associated with your Cloudflare account. Will prompt if not provided.

.PARAMETER Token
    Your Cloudflare API Token. This token must have permissions to:
    - Zone.Zone:Read
    - Zone.DNS:Edit
    - User.Tokens:Read (for verification)
    Will prompt if not provided.

.PARAMETER Domain
    The root domain (zone name) managed by Cloudflare (e.g., "example.com").
    Will dynamically list and prompt for selection if not provided.
    IMPORTANT: This should be your root domain (e.g., "example.com"), not a subdomain (e.g., "sub.example.com").

.PARAMETER Record
    The specific DNS record hostname to update (e.g., "home" for home.example.com, or "@" for the root domain).
    Will dynamically list and prompt for selection/creation if not provided.
    IMPORTANT: This should be the hostname part of the record (e.g., "sub1", "sub2", or "@" for the root), NOT the record type (e.g., "A").

.PARAMETER LogFilePath
    Optional. The full path to a file where verbose logs will be written.
    If not provided, logs will only be displayed in the console.

.NOTES
    Ensure you have created a Cloudflare API Token with the necessary permissions.
    Avoid using your Global API Key for security reasons.
#>

[cmdletbinding(DefaultParameterSetName='Default', SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param (
    [string]$Email,
    [string]$Token,
    [string]$Domain,
    [string]$Record,
    [string]$LogFilePath = "$PSScriptRoot\CloudflareDdns.log" # Default log file path in script directory
)

# --- Configuration ---
# API endpoint for getting public IPv4 and IPv6 addresses
$IPv4ApiUrl = 'https://api.ipify.org'
$IPv6ApiUrl = 'https://api6.ipify.org' # Directly returns IPv6 without JSON for simpler parsing

# --- Global Variables ---
$CloudflareApiBaseUrl = "https://api.cloudflare.com/client/v4"
$zone_id = $null # Will be set dynamically

# Build the request headers once. These headers will be used throughout the script.
$headers = @{
    "Content-Type"  = "application/json"
}

# --- Logging Function ---
function Write-Log {
    param (
        [parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "INFO", # INFO, WARN, ERROR, VERBOSE
        [ConsoleColor]$ForegroundColor = "White" # Default to white for console
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console
    Write-Host $Message -ForegroundColor $ForegroundColor

    # Write to log file if path is specified
    if (-not [string]::IsNullOrEmpty($script:LogFilePath)) {
        try {
            Add-Content -Path $script:LogFilePath -Value $logEntry -ErrorAction Stop
        }
        catch {
            # Catch file write errors, but don't stop the main script
            Write-Host "Error writing to log file '$($script:LogFilePath)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Ensure initial log file state (clear or create)
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('LogFilePath')) {
    # If LogFilePath was explicitly provided, ensure the directory exists
    $logDir = Split-Path $LogFilePath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Write-Host "Log file initialized at: $($LogFilePath)" -ForegroundColor Green
} else {
    # If using default, ensure script:LogFilePath is set for the log function
    $script:LogFilePath = "$PSScriptRoot\CloudflareDdns.log"
    $logDir = Split-Path $script:LogFilePath
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Write-Host "Log file initialized at: $($script:LogFilePath) (default path)" -ForegroundColor Green
}


# --- Function for consistent API calls and error handling ---
function Invoke-CloudflareApi {
    param (
        [parameter(Mandatory=$true)]
        [string]$Method,
        [parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Body = $null,
        [switch]$SkipAuthEmailHeader # Use this for requests that don't need X-Auth-Email (e.g., /user/tokens/verify)
    )
    $uri = "$($CloudflareApiBaseUrl)$($Path)"
    Write-Log "Calling API: $($Method) $($uri)" "VERBOSE" Cyan

    # Clone headers and add X-Auth-Email if needed
    $currentHeaders = $headers.Clone()
    if (-not $SkipAuthEmailHeader) {
        $currentHeaders["X-Auth-Email"] = $script:Email # Use script-level $Email
    }
    $currentHeaders["Authorization"] = "Bearer $($script:Token)" # Use script-level $Token

    # Define common parameters for Invoke-RestMethod
    $invokeRestMethodParams = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $currentHeaders
        ErrorAction = 'Stop'
    }

    # Conditionally add -Body parameter based on Method and Body content
    # PowerShell 5.1 can throw "Cannot send a content-body with this verb-type" for GET if -Body is present, even if $null
    if ($Body -ne $null -and $Method -ne 'GET') {
        $invokeRestMethodParams.Add('Body', $Body)
    }

    try {
        $response = Invoke-RestMethod @invokeRestMethodParams
        if (-not $response.success) {
            $errorMessage = "Cloudflare API call failed for $($Method) $($Path). Errors: "
            foreach ($error in $response.errors) {
                $errorMessage += "$($error.message) "
            }
            Write-Log $errorMessage "ERROR" Red
            return $null
        }
        return $response
    }
    catch {
        Write-Log "An error occurred during API call to $($Path): $($_.Exception.Message)" "ERROR" Red
        return $null
    }
}

# --- Input Prompting and Validation ---
if ([string]::IsNullOrEmpty($Email)) {
    $Email = Read-Host "Enter your Cloudflare email address" -ForegroundColor Green
}
if ([string]::IsNullOrEmpty($Token)) {
    $Token = Read-Host "Enter your Cloudflare API Token" -ForegroundColor Green
}

# Ensure Email and Token are accessible globally within the script's scope
$script:Email = $Email
$script:Token = $Token

# --- Region: Token Test ---
Write-Log "--- Verifying API Token ($Record) ---" "INFO" DarkGray
# Note: Token verification endpoint does not require X-Auth-Email header
$auth_result = Invoke-CloudflareApi -Method GET -Path "/user/tokens/verify" -SkipAuthEmailHeader
if (-not $auth_result) {
    Write-Log "API token validation failed. Terminating script." "ERROR" Red
    return
}
Write-Log "API token validation [$script:Token] success. $($auth_result.messages.message)." "INFO" Green

# --- Region: Get Zone ID (Dynamic Selection) ---
Write-Log "--- Getting Zone ID ---" "INFO" DarkGray

if ([string]::IsNullOrEmpty($Domain)) {
    $zones = Invoke-CloudflareApi -Method GET -Path "/zones"
    if (-not $zones -or $zones.result.Count -eq 0) {
        Write-Log "Could not retrieve any Cloudflare zones. Ensure your API token has Zone:Read permissions. Terminating script." "ERROR" Red
        return
    }

    Write-Log "Available Cloudflare Domains (Zones):" "INFO" Blue
    for ($i = 0; $i -lt $zones.result.Count; $i++) {
        Write-Log "$($i + 1). $($zones.result[$i].name)" "INFO" Cyan
    }

    $selection = Read-Host "Enter the number of the domain you want to update (e.g., 1, 2, etc.):" -ForegroundColor Green
    if ($selection -notmatch '^\d+$' -or $selection -lt 1 -or $selection -gt $zones.result.Count) {
        Write-Log "Invalid selection. Terminating script." "ERROR" Red
        return
    }
    $selectedZone = $zones.result[$selection - 1]
    $script:Domain = $selectedZone.name
    $script:zone_id = $selectedZone.id
} else {
    # If Domain was provided as a parameter, fetch its zone ID
    $zone_check_path = "/zones?name=$($Domain)"
    $ZoneCheck = Invoke-CloudflareApi -Method GET -Path $zone_check_path
    if (-not $ZoneCheck -or $ZoneCheck.result.Count -eq 0) {
        Write-Log "The provided Domain '$Domain' is not recognized as a Cloudflare zone. Please ensure you are providing the root domain (e.g., 'nikooee.us' instead of 'a.nikooee.us'). Terminating script." "ERROR" Red
        return
    }
    $script:zone_id = $ZoneCheck.result[0].id
    $script:Domain = $Domain # Ensure script-level variable is set
}

Write-Log "Selected Domain [$script:Domain]: ID=$script:zone_id" "INFO" Green

# --- Region: Get Current Public IP Addresses ---
Write-Log "--- Getting Current Public IP Addresses ---" "INFO" DarkGray
$new_ipv4 = $null
$new_ipv6 = $null

try {
    $ipv4_response = Invoke-RestMethod -Uri $IPv4ApiUrl -ErrorAction Stop
    $new_ipv4 = $ipv4_response.Trim()
    if ($new_ipv4 -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
        Write-Log "Could not parse IPv4 address from '$IPv4ApiUrl'. Response: '$ipv4_response'." "WARN" Yellow
        $new_ipv4 = $null
    }
}
catch {
    Write-Log "Failed to get public IPv4 address from '$IPv4ApiUrl': $($_.Exception.Message)" "WARN" Yellow
}

try {
    $ipv6_response = Invoke-RestMethod -Uri $IPv6ApiUrl -ErrorAction Stop
    $new_ipv6 = $ipv6_response.Trim()

    if ($new_ipv6 -notmatch '^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$') { # Basic IPv6 regex
        Write-Log "Could not parse IPv6 address from '$IPv6ApiUrl'. Response: '$new_ipv6'." "WARN" Yellow
        $new_ipv6 = $null
    }
}
catch {
    Write-Log "Failed to get public IPv6 address from '$IPv6ApiUrl': $($_.Exception.Message)" "WARN" Yellow
}

if (-not $new_ipv4 -and -not $new_ipv6) {
    Write-Log "Could not retrieve any public IP addresses (IPv4 or IPv6). Terminating script." "ERROR" Red
    return
}

if ($new_ipv4) { Write-Log "Current Public IPv4 Address: $($new_ipv4)" "INFO" Green }
if ($new_ipv6) { Write-Log "Current Public IPv6 Address: $($new_ipv6)" "INFO" Green }

# --- Region: Get DNS Record (Dynamic Selection/Creation) ---
Write-Log "--- Selecting DNS Record ---" "INFO" DarkGray

# Fetch ALL A and AAAA records for the zone to accurately determine existing records
$allDnsRecordsPath = "/zones/$($script:zone_id)/dns_records?per_page=100&type=A,AAAA"
$allDnsRecords = Invoke-CloudflareApi -Method GET -Path $allDnsRecordsPath
if (-not $allDnsRecords) {
    Write-Log "Failed to retrieve all DNS records for $($script:Domain). Terminating script." "ERROR" Red
    return
}

# Create a map from simplified hostname (for user selection) to the full Cloudflare record object
$recordMap = @{}
$uniqueRecordNames = New-Object System.Collections.ArrayList
foreach ($rec in $allDnsRecords.result) {
    $hostname = $rec.name -replace "\.$($script:Domain)$", "" # Remove domain suffix
    if ($hostname -eq $script:Domain) { $hostname = "@" } # Root domain record

    # Store the actual record object with the simplified hostname as key
    # If multiple records (A/AAAA) share the same hostname, just store one for display purposes
    if (-not $recordMap.ContainsKey($hostname)) {
        $recordMap[$hostname] = $rec
        $uniqueRecordNames.Add($hostname) | Out-Null
    }
}
$uniqueRecordNames.Sort() # Sort for consistent display

$script:fullRecordName = $Record # Initialize with parameter if provided

if ([string]::IsNullOrEmpty($Record)) {
    if ($uniqueRecordNames.Count -gt 0) {
        Write-Log "Existing A/AAAA Records in $($script:Domain):" "INFO" Blue
        for ($i = 0; $i -lt $uniqueRecordNames.Count; $i++) {
            Write-Log "$($i + 1). $($uniqueRecordNames[$i])" "INFO" Cyan
        }
        Write-Log "$($uniqueRecordNames.Count + 1). Create new record" "INFO" DarkCyan
        $recordSelection = Read-Host "Enter the number of the record to update, or select 'Create new record' (e.g., 1, 2, or $($uniqueRecordNames.Count + 1)):" -ForegroundColor Green

        if ($recordSelection -match '^\d+$' -and $recordSelection -ge 1 -and $recordSelection -le $uniqueRecordNames.Count) {
            $selectedSimplifiedName = $uniqueRecordNames[$recordSelection - 1]
            $script:fullRecordName = $recordMap[$selectedSimplifiedName].name # Get the exact full name from the stored object
            Write-Log "Selected existing record: $($script:fullRecordName)" "INFO" Green
        } elseif ($recordSelection -match '^\d+$' -and $recordSelection -eq ($uniqueRecordNames.Count + 1)) {
            $newRecordName = Read-Host "Enter the new record name (e.g., 'home' for home.$($script:Domain), or '@' for the root domain):" -ForegroundColor Green
            if ([string]::IsNullOrEmpty($newRecordName)) {
                Write-Log "Record name cannot be empty. Terminating script." "ERROR" Red
                return
            }
            if ($newRecordName -eq "@") {
                $script:fullRecordName = $script:Domain
            } else {
                $script:fullRecordName = "$($newRecordName).$($script:Domain)"
            }
            Write-Log "Will create/update new record: $($script:fullRecordName)" "INFO" Green
        } else {
            Write-Log "Invalid record selection. Terminating script." "ERROR" Red
            return
        }
    } else {
        Write-Log "No existing A/AAAA records found for $($script:Domain). You must create a new record." "WARN" Yellow
        $newRecordName = Read-Host "Enter the new record name (e.g., 'home' for home.$($script:Domain), or '@' for the root domain):" -ForegroundColor Green
        if ([string]::IsNullOrEmpty($newRecordName)) {
            Write-Log "Record name cannot be empty. Terminating script." "ERROR" Red
            return
        }
        if ($newRecordName -eq "@") {
            $script:fullRecordName = $script:Domain
        } else {
            $script:fullRecordName = "$($newRecordName).$($script:Domain)"
        }
        Write-Log "Will create new record: $($script:fullRecordName)" "INFO" Green
    }
} else {
    # If Record was provided as a parameter, construct full name
    if ($Record -eq "@") {
        $script:fullRecordName = $script:Domain
    } elseif ($Record -notlike "*.*") {
        # Try to find the exact full name from the existing records map
        if ($recordMap.ContainsKey($Record.ToLower())) {
             $script:fullRecordName = $recordMap[$Record.ToLower()].name
        } else {
            $script:fullRecordName = "$($Record).$($script:Domain)"
        }
    } elseif ($Record -notlike "*.$($script:Domain)" -and $Record -ne $script:Domain) {
        Write-Log "The provided DNS record '$Record' does not belong to the domain '$($script:Domain)'. Terminating script." "ERROR" Red
        return
    }
    Write-Log "Using record: $($script:fullRecordName)" "INFO" Green
}

# --- Region: Get Existing DNS Records and Update/Create ---
Write-Log "--- Checking and Updating DNS Records for $($script:fullRecordName) ---" "INFO" DarkGray

# Filter the previously fetched allDnsRecords to find the specific A and AAAA records for fullRecordName
$existing_a_record = $allDnsRecords.result | Where-Object { $_.name -eq $script:fullRecordName -and $_.type -eq "A" } | Select-Object -First 1
$existing_aaaa_record = $allDnsRecords.result | Where-Object { $_.name -eq $script:fullRecordName -and $_.type -eq "AAAA" } | Select-Object -First 1

if ($existing_a_record) {
    Write-Log "Found existing A record: Name=`"$($existing_a_record.name)`", Content=`"$($existing_a_record.content)`", Proxied=`"$($existing_a_record.proxied)`", TTL=`"$($existing_a_record.ttl)`"" "INFO" Cyan
}
if ($existing_aaaa_record) {
    Write-Log "Found existing AAAA record: Name=`"$($existing_aaaa_record.name)`", Content=`"$($existing_aaaa_record.content)`", Proxied=`"$($existing_aaaa_record.proxied)`", TTL=`"$($existing_aaaa_record.ttl)`"" "INFO" Cyan
}


# --- Handle A Record (IPv4) ---
if ($new_ipv4) {
    if ($existing_a_record) {
        if ($existing_a_record.content -ne $new_ipv4) {
            Write-Log "IPv4 change detected! OLD=$($existing_a_record.content), NEW=$($new_ipv4)" "WARN" Yellow
            $body = @{
                type    = "A"
                name    = $script:fullRecordName
                content = $new_ipv4
                ttl     = $existing_a_record.ttl    # Preserve existing TTL
                proxied = $existing_a_record.proxied # Preserve existing proxied status
            } | ConvertTo-Json

            $update_result = Invoke-CloudflareApi -Method PUT -Path "/zones/$($script:zone_id)/dns_records/$($existing_a_record.id)" -Body $body
            if ($update_result) {
                Write-Log "Successfully updated A record for $($script:fullRecordName) to $($new_ipv4)." "INFO" Green
            } else {
                Write-Log "Failed to update A record for $($script:fullRecordName)." "ERROR" Red
            }
        } else {
            Write-Log "IPv4 address ($($new_ipv4)) is already up to date for A record $($script:fullRecordName)." "INFO" White
        }
    } else {
        Write-Log "No existing A record found for $($script:fullRecordName). Creating new A record." "WARN" Yellow
        $body = @{
            type    = "A"
            name    = $script:fullRecordName
            content = $new_ipv4
            ttl     = 1     # Automatic TTL
            proxied = $false # Not proxied by default
        } | ConvertTo-Json

        $create_result = Invoke-CloudflareApi -Method POST -Path "/zones/$($script:zone_id)/dns_records" -Body $body
        if ($create_result) {
            Write-Log "Successfully created A record for $($script:fullRecordName) with IP $($new_ipv4)." "INFO" Green
        } else {
            Write-Log "Failed to create A record for $($script:fullRecordName)." "ERROR" Red
        }
    }
} else {
    Write-Log "No public IPv4 address found to update A record." "WARN" Yellow
}


# --- Handle AAAA Record (IPv6) ---
if ($new_ipv6) {
    if ($existing_aaaa_record) {
        if ($existing_aaaa_record.content -ne $new_ipv6) {
            Write-Log "IPv6 change detected! OLD=$($existing_aaaa_record.content), NEW=$($new_ipv6)" "WARN" Yellow
            $body = @{
                type    = "AAAA"
                name    = $script:fullRecordName
                content = $new_ipv6
                ttl     = $existing_aaaa_record.ttl    # Preserve existing TTL
                proxied = $existing_aaaa_record.proxied # Preserve existing proxied status
            } | ConvertTo-Json

            $update_result = Invoke-CloudflareApi -Method PUT -Path "/zones/$($script:zone_id)/dns_records/$($existing_aaaa_record.id)" -Body $body
            if ($update_result) {
                Write-Log "Successfully updated AAAA record for $($script:fullRecordName) to $($new_ipv6)." "INFO" Green
            } else {
                Write-Log "Failed to update AAAA record for $($script:fullRecordName)." "ERROR" Red
            }
        } else {
            Write-Log "IPv6 address ($($new_ipv6)) is already up to date for AAAA record $($script:fullRecordName)." "INFO" White
        }
    } else {
        Write-Log "No existing AAAA record found for $($script:fullRecordName). Creating new AAAA record." "WARN" Yellow
        $body = @{
            type    = "AAAA"
            name    = $script:fullRecordName
            content = $new_ipv6
            ttl     = 1     # Automatic TTL
            proxied = $false # Not proxied by default
        } | ConvertTo-Json

        $create_result = Invoke-CloudflareApi -Method POST -Path "/zones/$($script:zone_id)/dns_records" -Body $body
        if ($create_result) {
            Write-Log "Successfully created AAAA record for $($script:fullRecordName) with IP $($new_ipv6)." "INFO" Green
        } else {
            Write-Log "Failed to create AAAA record for $($script:fullRecordName)." "ERROR" Red
        }
    }
} else {
    Write-Log "No public IPv6 address found to update AAAA record." "WARN" Yellow
}

Write-Log "--- Cloudflare DDNS Update Script Finished ---`n`n" "INFO" DarkGray
