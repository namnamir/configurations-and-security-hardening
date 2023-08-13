# Install MTProto on Ubuntu
*MTPRoto* is a proxy designed by Telegram and can be setup with a script written by [Behnam](https://github.com/HirbodBehnam/MTProtoProxyInstaller).
Run the following command to download and install the script. Just follow the prompts.
```bash
curl -o MTProtoProxyInstall.sh -L https://git.io/fjo34 && bash MTProtoProxyInstall.sh
```

## Some Useful Commands
```bash
# access the admin menu
bash ~/MTProtoProxyInstall.sh

# access the configuration file
nano /opt/mtprotoproxy/config.py

# see the logs
journalctl -u mtprotoproxy | cat

```
