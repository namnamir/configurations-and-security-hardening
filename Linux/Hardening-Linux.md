# Turn off SSH password authentication
This method helps when the key pair authentication is in use. It prevents the brute-force attacks.
```bash
# open the SSH configuration file
sudo nano /etc/ssh/sshd_config

# search in the file and set the password authentication off
PasswordAuthentication no

# earch in the file and enable the public key authentication
PubkeyAuthentication yes

# restart the SSH service
sudo systemctl restart sshd
```
