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

# SSH Keys
## Install SSH client
```bash
# install OpenSSH
sudo apt install openssh-client

# check the version
ssh -v localhost
```

## Create the key pair (public and private)
By running the following command, it will create the key pair in `~/.ssh`.
```bash
sudo ssh-keygen -t rsa
```

## Copy the public key on the remote server
The following command will copy the public key on the remote server.
```bash
# # if the key pair is stored in ~/.ssh
sudo ssh-copy-id <USER>@<HOST>

# if the key pair is not stored in ~/.ssh
sudo ssh-copy-id -i ~/.ssh/id_rsa.pub <USER>@<HOST>
```

## Login to the remote server with the key pair
The following command will present the way to loging to the remote server with the key pair.
```bash
# # if the key pair is stored in ~/.ssh
ssh <USER>@<HOST>

# if the key pair is not stored in ~/.ssh
ssh -i PATH/TO/FILE/id_rsa.pub <USER>@<HOST>
```
