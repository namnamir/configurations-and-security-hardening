# Change Local Password Policy
To do it manually, after opening the *Group Policy* window by `gpedit.msc`, go to `Computer Configuration > Windows Settings > Security Settings > Account Policies > Password Policy` to be able to change parameters. The followin script help to do it too.
```PowerShell
$SecPolFile = "$($env:USERPROFILE)\Downloads\SecPol.cfg"

SecEdit /export /cfg $SecPolFile

(Get-Content $SecPolFile) | Foreach-Object {
  $_  -replace "PasswordComplexity = 0",    "PasswordComplexity = 1" `
      -replace "ClearTextPassword = 1",     "ClearTextPassword = 0" `
      -replace "EnableAdminAccount = 1",    "EnableAdminAccount = 0" `
      -replace "EnableGuestAccount = 1",    "EnableGuestAccount = 0" `
      -replace "MinimumPasswordLength = 0", "MinimumPasswordLength = 8" `
      -replace "LockoutBadCount = 0",       "LockoutBadCount = 5"
} | Set-Content $SecPolFile

SecEdit /configure /db "$Env:WinDir\security\local.sdb" /cfg $SecPolFile /areas SECURITYPOLICY

rm -Force $SecPolFile -Confirm:$False
```
# Add MFA to the (RDP) Login with DUO
[DUO](https://duo.com/editions-and-pricing) provides Windows (RDP) MFA login for free (up to 10 users). It will act against any external attack on Windows systems specially when they are publically available.

Follow the provided [instruction](https://duo.com/docs/rdp) and easily set it up on each device, if there is no Active Directory (AD). Then, setup users on DUO, enrole them (send the invitation to setup their devices), and it should work.
