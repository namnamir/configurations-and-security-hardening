# V2ray Proxy
V2Ray supports multiple protocols but doesn't provide any user managemnt panel. However, some scripts like `x-ui` or `multi-v2ray` provides this feature.

- [X-UI](https://github.com/vaxilu/x-ui)
- [X-UI (Fork)](https://github.com/FranzKafkaYu/x-ui)
- [Multi-V2ray](https://github.com/Jrohy/multi-v2ray)

## Preperation of the Server
Run the following commands.
```bash
# Update and upgrade the server
apt update && apt upgrade -y

# set the timezone
timedatectl set-timezone Europe/Berlin
```

## X-UI
### Installation of X-UI
Run *one* of the following commands to start the installation. During the install it asks 3 questions for the Username, Password, and Port. These will be used later
```bash
# Install the original version of X-UI
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)


# Install the forked version of X-UI with more features
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)

# Or the English version
bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install_en.sh)
```

### Configuration
#### SSL Certificate Generation
Run the command `x-ui` and select the item `16` to setup an SSL certificate either through Cloudflare or standalone. To generate an SSL certificate, 
having a domain is neccessary. When it is finished, it provides a path to the SSL certificate and the key.
```bash
    [Sun Nov  6 11:10:54 AM CET 2022] Installing cert to: /root/cert/DOMAIN_NAME.cer
    [Sun Nov  6 11:10:54 AM CET 2022] Installing CA to: /root/cert/ca.cer
    [Sun Nov  6 11:10:54 AM CET 2022] Installing key to: /root/cert/DOMAIN_NAME.key
    [Sun Nov  6 11:10:54 AM CET 2022] Installing full chain to: /root/cert/fullchain.cer
```
#### Complete the configuration
After the installation, visit `http://IP_ADDRESS:PORT` (the port you defined during the installation) to login to the panel. 
Then, go to the seettings (left-side) to set the certificate and the key.

#### Exclude IPs or Domains from Proxy
It should be done through the `xray` configuration file which can be accessed through the panel -> settings or directly via `/usr/local/x-ui/bin/config.json`.
For instance, adding the following lines to the key `routing` as a `rule` should exclude `google.com` from being proxied.
```
    {
        "type":"field",
        "outboundTag":"direct",
        "domain":[
            "google.com"
        ]
    },
```

The way to configure it is explained [here](https://xtls.github.io/en/config/routing.html#routingobject).

Note: [Here](https://github.com/SamadiPour/iran-hosted-domains/releases/) is the list of the Iranian domains that can filtered out from the proxy.

### Some Useful Commands
- `x-ui`: run the admin menu
- `x-ui status`: show the status of `x-ui` as well as `xray`
- `x-ui log`: show the log

### Some Useful Paths
- `/etc/x-ui/`: user database
- `/usr/local/x-ui/bin/`: xray configuration files including `geoip.dat` and `geosite.dat`
