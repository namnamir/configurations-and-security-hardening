# Get the Public IP Address of a Linux Machine
Use one of the following commands to get either IPv4, IPv6 or both.
```bash
# built-in commands
# it works only if a public IP is assigned to the NIC
ip addr 
ip -6 addr # version 6

# 3rd party tools
curl checkip.amazonaws.com
curl ifconfig.me
curl icanhazip.com
curl ipecho.net/plain
curl ifconfig.co

curl -6 https://ifconfig.co
curl -6 https://ipv6.icanhazip.com 

# get it through SSH or Talent
ssh -6 sshmyip.com
telnet -6 ipv6.telnetmyip.com 
```
