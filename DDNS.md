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
You can define a cron job by `crontab -e` to run the following Bash script frequently.
```bash
#!/bin/bash
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# initial data; they need to be filled by the user
## API token
api_token=<YOUR_API_TOKEN>
## email address associated with the Cloudflare account
email=<YOUR_EMAIL>
## the zone (domain) should be modified
zone_name=<YOUR_DOMAIN>
## the dns record (sub-domain) should be modified
dns_record=<YOUR_SUB_DOMAIN>

# get the basic data
ipv4=$(curl -s -X GET -4 https://ifconfig.co)
ipv6=$(curl -s -X GET -6 https://ifconfig.co)
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
               -H "Authorization: Bearer $api_token" \
               -H "Content-Type:application/json" \
          | jq -r '{"result"}[] | .id'
         )

echo "Your IPv4 is: $ipv4"
echo "Your IPv6 is: $ipv6"

# check if the user API is valid and the email is correct
if [ $user_id ]
then
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $email" \
                   -H "Authorization: Bearer $api_token" \
              | jq -r '{"result"}[] | .[0] | .id'
             )
    # check if the zone ID is 
    if [ $zone_id ]
    then
        # check if there is any IP version 4
        if [ $ipv4 ]
        then
            dns_record_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$dns_record"  \
                                   -H "Content-Type: application/json" \
                                   -H "X-Auth-Email: $email" \
                                   -H "Authorization: Bearer $api_token"
                             )
            # if the IPv6 exist
            dns_record_a_ip=$(echo $dns_record_a_id |  jq -r '{"result"}[] | .[0] | .content')
            echo "The set IPv4 on Cloudflare (A Record) is:    $dns_record_a_ip"
            if [ $dns_record_a_ip != $ipv4 ]
            then
                # change the A record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_a_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
            else
                echo "The current IPv4 and DNS record IPv4 are the same."
            fi
        else
            echo "Could not get your IPv4. Check if you have it; e.g. on https://ifconfig.co"
        fi
            
        # check if there is any IP version 6
        if [ $ipv6 ]
        then
            dns_record_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$dns_record"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $email" \
                                      -H "Authorization: Bearer $api_token"
                                )
            # if the IPv6 exist
            dns_record_aaaa_ip=$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .content')
            echo "The set IPv6 on Cloudflare (AAAA Record) is: $dns_record_aaaa_ip"
            if [ $dns_record_aaaa_ip != $ipv6 ]
            then
                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$dns_record\",\"content\":\"$ipv6\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
            else
                echo "The current IPv6 and DNS record IPv6 are the same."
            fi
        else
            echo "Could not get your IPv6. Check if you have it; e.g. on https://ifconfig.co"
        fi  
    else
        echo "There is a problem with getting the Zone ID. Check if the Zone Name is correct."
    fi
else
    echo "There is a problem with either the email or the password"
fi
```

### Use the API on Windows
Use [this article](https://adamtheautomator.com/cloudflare-dynamic-dns/) to set it up on Windows.

