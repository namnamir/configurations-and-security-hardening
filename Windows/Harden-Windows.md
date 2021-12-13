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
