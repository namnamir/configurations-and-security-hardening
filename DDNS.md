# Best Dynamic DNS (DDNS) Services
I have looked up mublitple DDNS services. Including the following ones:
- [No-IP](https://my.noip.com/)
- [FreeDNS](https://freedns.afraid.org/)
- [Duck DNS](https://www.duckdns.org/)
- [ClouDNS](https://www.cloudns.net/dynamic-dns/)
- And many others.
All will provide you with a subdomain and let you set your IP on it *dynamically*. The problem is with the security of the IP. All might reveal the IP to the public. Therefore, finding a solution helping with the security is crucial.

I realized using Cloudflare Edit Zone API is a solution. Fortunately, there are scripts like [Cloudflare DDNS (Python 3)](https://github.com/timothymiller/cloudflare-ddns) that makes it easy; a PowerShell solution is provided [here](https://adamtheautomator.com/cloudflare-dynamic-dns/) as well.

