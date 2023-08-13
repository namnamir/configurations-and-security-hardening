## Setup of Remote Development (SSH)
After creating an SSH key, there is a need to copy it to the server to be able 
to log in without asking for password (using SSH key).

### Copy SSH Key from Windows to Linux
```powershell
$USER_AT_HOST = "<USERNAME>@<HOST>"
$PUBKEYPATH = "$HOME\.ssh\id_ed25519.pub"

$pubKey=(Get-Content "$PUBKEYPATH" | Out-String); ssh "$USER_AT_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '${pubKey}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```
