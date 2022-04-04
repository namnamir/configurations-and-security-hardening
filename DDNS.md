# Best Dynamic DNS (DDNS) Services
I have looked up mublitple DDNS services. Including the following ones:
- [No-IP](https://my.noip.com/)
- [FreeDNS](https://freedns.afraid.org/)
- [Duck DNS](https://www.duckdns.org/)
- [ClouDNS](https://www.cloudns.net/dynamic-dns/)
- And many others.


All will provide you with a subdomain and let you set your IP on it *dynamically*. The problem is with the security of the IP. All might reveal the IP to the public. Therefore, finding a solution helping with the security is crucial.

I realized using Cloudflare Edit Zone API is a solution. Fortunately, there are scripts like [Cloudflare DDNS (Python 3)](https://github.com/timothymiller/cloudflare-ddns) that makes it easy; a PowerShell solution is provided [here](https://adamtheautomator.com/cloudflare-dynamic-dns/) as well.

# Cloudflare
There is a possibility to frequently update DNS records (A and/or AAAA) of a domain on Clouldflare via API.
To do so, there is a need to get the an API token:
1. Go to the [My Account -> API Tokens](https://dash.cloudflare.com/profile/api-tokens).
2. Create an API with the template "Edit Zone DNS".
3. Select the zone (domain name).

### Use the API on Linux
1. Save the following script in a file, e.g. `cloudflare.sh`.
2. Make it executable by `chmod +x /path/to/cloudflare.sh`.
3. Run `crontab -e` and add a line like `@weekly /path/to/cloudflare.sh` to the end of the file to run the script periodically. Use tools like [Crontab Guru](https://crontab.guru/) to define the frequency properly.
```bash
#!/bin/bash
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# initial data; they need to be filled by the user
## API token; e.g. FErsdfklw3er59dUlDce44-3D43dsfs3sddsFoD3
api_token=<YOUR_API_TOKEN>
## the email address associated with the Cloudflare account; e.g. email@gmail.com
email=<YOUR_EMAIL>
## the zone (domain) should be modified; e.g. example.com
zone_name=<YOUR_DOMAIN>
## the dns record (sub-domain) should be modified; e.g. sub.example.com
dns_record=<YOUR_SUB_DOMAIN>

# Check jq installed
check_jq=$(which jq)
if [ -z "${check_jq}" ]; then
  	echo -e "\033[0;31m [-] jq not installed. jq must be created first!"
  	exit
fi

# Check DNS Records Exists
check_record_ipv4=$(dig -t a +short ${dns_record} | tail -n1)
check_record_ipv6=$(dig -t aaaa +short ${dns_record} | tail -n1)

# get the basic data
ipv4=$(curl -s -X GET -4 https://ifconfig.co)
ipv6=$(curl -s -X GET -6 https://ifconfig.co)
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
               -H "Authorization: Bearer $api_token" \
               -H "Content-Type:application/json" \
          | jq -r '{"result"}[] | .id'
         )

# write down IPv4 and/or IPv6
if [ $ipv4 ]; then echo -e "\033[0;32m [+] Your public IPv4 address: $ipv4"; else echo -e "\033[0;33m [!] Unable to get any public IPv4 address."; fi
if [ $ipv6 ]; then echo -e "\033[0;32m [+] Your public IPv6 address: $ipv6"; else echo -e "\033[0;33m [!] Unable to get any public IPv6 address."; fi

# check if the user API is valid and the email is correct
if [ $user_id ]
then
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $email" \
                   -H "Authorization: Bearer $api_token" \
              | jq -r '{"result"}[] | .[0] | .id'
             )
    # check if the zone ID is avilable
    if [ $zone_id ]
    then
        # check if there is any IP version 4
        if [ $ipv4 ]
        then
        	# Check A Record exists
        	if [ -z "${check_record_ipv4}" ]; then
  			  	echo -e "\033[0;31m [-] No A Record called ${dns_record}. This must be created first!"
  				  exit
			    fi
            dns_record_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$dns_record"  \
                                   -H "Content-Type: application/json" \
                                   -H "X-Auth-Email: $email" \
                                   -H "Authorization: Bearer $api_token"
                             )
            # if the IPv4 exist
            dns_record_a_ip=$(echo $dns_record_a_id |  jq -r '{"result"}[] | .[0] | .content')
            if [ $dns_record_a_ip != $ipv4 ]
            then
                # change the A record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_a_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] The IPv4 is successfully set on Cloudflare as the A Record with the value of:    $dns_record_a_ip"
            else
                echo -e "\033[0;37m [~] The current IPv4 and  the existing on on Cloudflare are the same; there is no need to apply it."
            fi
        fi
            
        # check if there is any IP version 6
        if [ $ipv6 ]
        then
        	# Check A Record exists
          	if [ -z "${check_record_ipv6}" ]; then
  			    	echo -e "\033[0;31m [-] No AAAA Record called ${dns_record}. This must be created first!"
  				    exit
			      fi
            dns_record_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$dns_record"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $email" \
                                      -H "Authorization: Bearer $api_token"
                                )
            # if the IPv6 exist
            dns_record_aaaa_ip=$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .content')
            if [ $dns_record_aaaa_ip != $ipv6 ]
            then
                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$dns_record\",\"content\":\"$ipv6\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] The IPv6 is successfully set on Cloudflare as the AAAA Record with the value of: $dns_record_aaaa_ip"
            else
                echo -e "\033[0;37m [~] The current IPv6 address and the existing on on Cloudflare are the same; there is no need to apply it."
            fi
        fi  
    else
        echo -e "\033[0;31m [-] There is a problem with getting the Zone ID (subdomain) or the email address (username). Check them and try again."
    fi
else
    echo -e "\033[0;31m [-] There is a problem with either the API token. Check it and try again."
fi
```

### Use the API on Windows
Use [this article](https://adamtheautomator.com/cloudflare-dynamic-dns/) to set it up on Windows.

