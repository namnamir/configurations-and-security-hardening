# Installation through Snapd
## Install Certbot
```bash
# remove exisitng Certbot
sudo apt remove certbot

# install Snapd
apt install snapd

# Install core packages for Snap and update it
sudo snap install core; sudo snap refresh core

# install Certbot
sudo snap install --classic certbot

# create the link
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```
To verify the installation, get the version.
```bash
certbot --version
```

## Setup Certbot to use Cloudflare
### Install the Plugin
```bash
# confirm the installation of the plugin
sudo snap set certbot trust-plugin-with-root=ok

# install the CloudFlare plugin
sudo snap install certbot-dns-cloudflare
```
### Save the CloudFalre API Key and Details
```bash
# create the folder and set the permission
sudo mkdir /root/.secrets && sudo chmod 0700 /root/.secrets/

# create the setting file and set the permissions
sudo touch /root/.secrets/cloudflare.ini
sudo chmod 0400 /root/.secrets/cloudflare.ini
```
Open the `cloudfare.ini` file and paste the settings as follows:
```ini
dns_cloudflare_email = "youremail@example.com"
dns_cloudflare_api_key = "Global-API-Key"
```
And finally run the following command to get the certificate.
```bash
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 60 \
  -d example.com,*.example.com
```
