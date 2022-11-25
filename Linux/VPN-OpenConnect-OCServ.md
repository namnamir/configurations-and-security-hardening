# Install and Configure Open Connect
## Install the Open VPN Package
```bash
# update and install OCServ
sudo apt update && sudo apt install ocserv

# confirm the installation by getting the version
ocserv --version
# or by getting the status
systemctl status ocserv
```

## Get the Certificate
You need to get a certificate, the easiest way is getting Let's Encrypt certificate that is explained [here](/Linux/Certbot_Lets-Encrypt.md).

## Configure Open Connect (OCServ)
Modify the configuration file.
```bash
# get the backup of the existing config file
sudo mv /etc/ocserv/ocserv.conf /etc/ocserv/ocserv.conf.bakup

# open the config file
sudo nano /etc/ocserv/ocserv.conf
```

Paste the following lines into the config file. Remember to check the certificate address and the domain.
```ini

# Authentication method
#auth = "pam"
#auth = "pam[gid-min=1000]"
auth = "plain[passwd=/etc/ocserv/ocpasswd]"
#auth = "certificate"
#auth = "radius[config=/etc/radiusclient/radiusclient.conf,groupconfig=true]"

# TCP and UDP port number
tcp-port = 443
udp-port = 443

# The user the worker processes will be run as
run-as-user = nobody
run-as-group = daemon

# socket file used for server IPC (worker-main)
socket-file = /run/ocserv.socket

# The key and the certificates of the server
server-cert = /etc/letsencrypt/live/example.com/fullchain.pem
server-key = /etc/letsencrypt/live/example.com/privkey.pem

# The Certificate Authority
ca-cert = /etc/ssl/certs/ssl-cert-snakeoil.pem

# Whether to enable seccomp/Linux namespaces worker isolation
isolate-workers = true

# A banner to be displayed on clients
banner = "Wel Der"

# Limit the number of clients
max-clients = 128

# Limit the number of identical clients
max-same-clients = 2

# When the server receives connections from a proxy
listen-proxy-proto = true

# Stats reset time
server-stats-reset-time = 604800

# Keepalive in seconds
keepalive = 300

# Dead peer detection in seconds
dpd = 60

# Dead peer detection for mobile clients
mobile-dpd = 300

# If using DTLS, and no UDP traffic is received
switch-to-tcp-timeout = 25

# MTU discovery (DPD must be enabled)
try-mtu-discovery = true

# Certificate OID
cert-user-oid = 0.9.2342.19200300.100.1.1

# Uncomment this to enable compression negotiation (LZS, LZ4).
compression = true

# Set the minimum size under which a packet will not be compressed
no-compress-limit = 256

# GnuTLS priority string
tls-priorities = "NORMAL:%SERVER_PRECEDENCE:%COMPAT:-RSA:-VERS-SSL3.0:-ARCFOUR-128"

# The time (in seconds) that a client is allowed to stay connected prior to authentication
auth-timeout = 240

# The time (in seconds) that a client is allowed to stay idle (no traffic) before being disconnected. Unset to disable.
idle-timeout = 1200

# The time (in seconds) that a mobile client is allowed to stay idle (no traffic) before being disconnected. Unset to disable.
mobile-idle-timeout = 1800

# The time (in seconds) that a client is not allowed to reconnect after a failed authentication attempt.
min-reauth-time = 300

# Banning clients in ocserv works with a point system
max-ban-score = 80

# The time (in seconds) that all score kept for a client is reset
ban-reset-time = 300

# Cookie timeout (in seconds)
cookie-timeout = 300

# Whether roaming is allowed
deny-roaming = false

# ReKey time (in seconds)
rekey-time = 172800

# ReKey method
rekey-method = ssl

# Whether to enable support for the occtl tool
use-occtl = true

# PID file
pid-file = /run/ocserv.pid

# The name to use for the tun device
device = vpns

# Whether the generated IPs will be predictable
predictable-ips = true

# The default domain to be advertised
default-domain = derafsh.example.com

# The pool of addresses
ipv4-network = 192.168.1.0
ipv4-netmask = 255.255.255.0

ipv6-network = fda9:4efe:7e3b:03ea::/48
ipv6-subnet-prefix = 64

tunnel-all-dns = true

# The advertized DNS server
dns = 8.8.8.8
dns = 1.1.1.1

# Prior to leasing any IP from the pool ping it to verify that it is not in use by another (unrelated to this server) host.
ping-leases = false

# This option will enable the pre-draft-DTLS version of DTLS
cisco-client-compat = true

# This option allows to disable the legacy DTLS negotiation
dtls-legacy = true
```

## Network Configuration
### Enable Port Forwarding
```bash
# create a systemctl file and write into it
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/60-custom.conf

# apply changes
sudo sysctl -p /etc/sysctl.d/60-custom.conf
```
### Configure the Firewall
```bash
# install Ubuntu Firewall
sudo apt install ufw

# allow certain ports (open the port defined for OCServ)
sudo ufw allow 22/tcp
sudo ufw allow 443/tcp
sudo ufw allow 443/udp

# enable the firewall
sudo ufw enable
```
#### Configure IP Masquerading
Open the firewall file.
```bash
sudo nano /etc/ufw/before.rules
```
Add the NAT table rules to the **end** of the file. The interface name is gotten from `ip addr`. 
Change `<INTERFACE_NAME>` to the interface name, i.e. `ens160`.
 ```rules
 # NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 192.168.1.0/24 -o <INTERFACE_NAME> -j MASQUERADE

# End each table with the 'COMMIT' line or these rules won't be processed
COMMIT
 ```
 Then find the section `# ok icmp code for FORWARD` and add the following lines after it and before `# allow dhcp client to work`.
 ```rules
 # allow forwarding for trusted network
-A ufw-before-forward -s 192.168.1.0/24 -j ACCEPT
-A ufw-before-forward -d 192.168.1.0/24 -j ACCEPT
 ```
 Then restart the firewall to apply changes.
 ```bash
 sudo systemctl restart ufw
 ```

## Create Users
Use the following command to create a user as `USERNAME`.
```bash
sudo ocpasswd -c /etc/ocserv/ocpasswd USERNAME
```



