# Setup SSH Server
Install SSH Server
```bash
# become sudo
su -

# install OpenSSH
apt install openssh-server

# check the status of the server
service ssh status

# check the connectivity
ssh localhost
```

If during the connection, there is an error like `Permission denied, please try again.`, then open `/etc/ssh/sshd_config` and change following lines based on your needs.
```bash
# enable password authentication
PasswordAuthentication yes

# enable root login
PermitRootLogin yes

# enable SSH key login
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```
Then reset the SSH Server by running `service ssh restart`.
