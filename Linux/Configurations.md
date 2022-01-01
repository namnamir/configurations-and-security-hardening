# Power Management
## Lid
Uncomment and set desired settings in the following file and restart your session.
```bash
# edit the file
sudo nano /etc/systemd/logind.conf

# reset the session
systemctl restart systemd-logind.service
```
The following values are the possible value <sup>([documentation](https://www.freedesktop.org/software/systemd/man/logind.conf.html))</sup>: `ignore`, `poweroff`, `reboot`, `halt`, `kexec`, `suspend`, `hibernate`, `hybrid-sleep`, `suspend-then-hibernate`, `lock`, and `factory-reset`.
