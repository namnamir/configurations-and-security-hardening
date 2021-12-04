# Create the key pair (public and private)
By running the following command, it will create the key pair in `~/.ssh`.
```bash
ssh-keygen -t rsa
```

# Copy the public key on the remote server
The following command will copy the public key on the remote server.
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub <USER>@<HOST>
```

# Login to the remote server with the key pair
The following command will present the way to loging to the remote server with the key pair.
```bash
# # if the key pair is stored in ~/.ssh
ssh <USER>@<HOST>

# if the key pair is not stored in ~/.ssh
ssh -i PATH/TO/FILE/id_rsa.pub <USER>@<HOST>
```
