#!/bin/bash
# READ ME: https://github.com/namnamir/configurations-and-security-hardening/blob/main/DDNS.md
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# Initial data; needs to be filled in by the user
## API token; e.g. FErsdfklw3er59dUlDce44-3D43dsfs3sddsFoD3
api_token="YOUR_API_TOKEN"
## The email address associated with the Cloudflare account; e.g. email@gmail.com
email="YOUR_EMAIL"
## the zone (domain) should be modified; e.g. example.com
zone_name="YOUR_DOMAIN"
## The DNS record (sub-domain) that needs to be modified; e.g. sub.example.com
dns_record="YOUR_SUB_DOMAIN"

# Check if the script is already running
if ps ax | grep "$0" | grep -v "$$" | grep bash | grep -v grep > /dev/null; then
    echo -e "\033[0;31m [-] The script is already running."
    exit 1
fi

# Check if jq and dig are installed
if [ -z "$(which dig)" ] || [ -z "$(which grep)" ] || [ -z "$(which jq)" ]; then
    echo -e "\033[0;31m [-] Either 'jq', 'dig', or 'grep' is not installed. Install them by 'sudo apt install jq dnsutils grep'."
    exit 1
fi

# Check the subdomain
# Check if the dns_record field (subdomain) contains a dot
if [[ $dns_record == *.* ]]; then
    # If the zone_name field (domain) is not in the dns_record
    if [[ $dns_record != *.$zone_name ]]; then
        echo -e "\033[0;31m [-] The Zone in DNS Record does not match the defined Zone; check it and try again."
        exit 1
    fi
# If the dns_record (subdomain) is not complete and contains invalid characters
elif ! [[ $dns_record =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo -e "\033[0;31m [-] The DNS Record contains illegal charecters, i.e., @, %, *, _, etc.; fix it and run the script again."
    exit 1
# If the dns_record (subdomain) is not complete, complete it
else
    dns_record="$dns_record.$zone_name"
fi

# Check if DNS records exist
check_record_ipv4=$(dig -t a +short ${dns_record} | tail -n1)
check_record_ipv6=$(dig -t aaaa +short ${dns_record} | tail -n1)

# Get the basic data
ipv4=$(curl -s -X GET -4 https://ifconfig.co)
ipv6=$(curl -s -X GET -6 https://ifconfig.co)

# If the current dynamic IPs match what's already in DNS, exit the script; read more: https://github.com/namnamir/configurations-and-security-hardening/issues/9
if [ $check_record_ipv4 == $ipv4 ]; then
        echo -e "\033[0;37m [~] No change: The current IPv4 address ${ipv4} matches the existing DNS records ${check_record_ipv4}."
        exit 0
fi
if [ $check_record_ipv6 == $ipv6 ]; then
        echo -e "\033[0;37m [~] No change: The current IPv6 address ${ipv6} matches the existing DNS records ${check_record_ipv6}."
        exit 0
fi

# Get the user ID
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
               -H "Authorization: Bearer $api_token" \
               -H "Content-Type:application/json" \
          | jq -r '{"result"}[] | .id'
         )

# write down IPv4 and/or IPv6
if [ $ipv4 ]; then echo -e "\033[0;32m [+] Your public IPv4 address: $ipv4"; else echo -e "\033[0;33m [!] Unable to get any public IPv4 address."; fi
if [ $ipv6 ]; then echo -e "\033[0;32m [+] Your public IPv6 address: $ipv6"; else echo -e "\033[0;33m [!] Unable to get any public IPv6 address."; fi

# check if the user API is valid, and the email is correct
if [ $user_id ]; then
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $email" \
                   -H "Authorization: Bearer $api_token" \
              | jq -r '{"result"}[] | .[0] | .id'
             )
    # check if the zone ID is available
    if [ $zone_id ]; then
        # check if there is any IP version 4
        if [ $ipv4 ]; then
            # Check if any A record exists
            if [ -z "${check_record_ipv4}" ]; then
                echo -e "\033[0;31m [-] No A Record is set for ${dns_record}. This should be created first!"
                exit 1
            fi
            dns_record_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$dns_record"  \
                                   -H "Content-Type: application/json" \
                                   -H "X-Auth-Email: $email" \
                                   -H "Authorization: Bearer $api_token"
                             )
            dns_record_a_ip=$(echo $dns_record_a_id |  jq -r '{"result"}[] | .[0] | .content')
            # if a new IPv4 exist; current IPv4 is different with the actual IPv4
            if [ $dns_record_a_ip != $ipv4 ]; then
                # change the A record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_a_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] Updated: The IPv4 is successfully set on Cloudflare as the A Record with the value of $ipv4."
                exit 0
            fi
        fi

        # check if there is any IP version 6
        if [ $ipv6 ]
        then
            # Check if any A record exists
            if [ -z "${check_record_ipv6}" ]; then
                echo -e "\033[0;31m [-] No AAAA Record called ${dns_record}. This must be created first!"
                exit 1
            fi
            dns_record_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$dns_record"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $email" \
                                      -H "Authorization: Bearer $api_token"
                                )
            dns_record_aaaa_ip=$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .content')
            # if a new IPv6 exist; current IPv6 is different with the actual IPv6
            if [ $dns_record_aaaa_ip != $ipv6 ]; then
                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$dns_record\",\"content\":\"$ipv6\",\"ttl\":1,\"proxied\":false}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] Updated: The IPv6 is successfully set on Cloudflare as the AAAA Record with the value of $ipv6."
                exit 0
            fi
        fi
    else
        echo -e "\033[0;31m [-] There is a problem with getting the Zone ID (sub-domain) or the email address (username). Check them and try again."
        exit 1
    fi
else
    echo -e "\033[0;31m [-] There is a problem with either the API token. Check it and try again."
    exit 1
fi
