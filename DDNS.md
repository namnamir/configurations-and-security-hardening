# Best Dynamic DNS (DDNS) Services and Cloudflare Integration

When choosing a Dynamic DNS (DDNS) service, one critical consideration is the security and privacy of your IP address. Many traditional DDNS providers, while offering a subdomain and dynamic IP updates, may publicly expose your home or server's IP address. This can be a significant security concern. Anyhow, I have looked up multiple DDNS services. Including the following ones:
- [No-IP](https://my.noip.com/)
- [FreeDNS](https://freedns.afraid.org/)
- [Duck DNS](https://www.duckdns.org/)
- [ClouDNS](https://www.cloudns.net/dynamic-dns/)
- And many others.

## Cloudflare: A Secure DDNS Solution

Use of Cloudflare's DNS management and proxying features is a strong way to keep track of dynamic IP addresses safely. As a reverse proxy, Cloudflare sits between your server and the internet. When you enable "Proxy status" (often represented by an orange cloud icon) for your DNS records, Cloudflare's IP addresses are revealed to the public, not your server's actual IP. This provides a layer of security, DDoS protection, and performance benefits.

You should regularly update your Cloudflare DNS records (A records for IPv4 and/or AAAA records for IPv6) with your current public IP address. You can do this through their API.

### Getting Your Cloudflare API Token

To use the Cloudflare API, you need an API token with specific permissions:

1.  Go to your Cloudflare account's [API Tokens page](https://dash.cloudflare.com/profile/api-tokens).
2.  Click "Create Token."
3.  For simplicity, you can use the "Edit Zone DNS" template.
4.  When configuring the token, ensure it has permissions for:
    * **Zone:** `Zone` - `Read`
    * **Zone:** `DNS` - `Edit`
    * **User:** `Tokens` - `Read` (for script's token verification)
5.  Select the specific Zone(s) (domain names) that you want this token to manage.
6.  **Important:** The token is displayed only once. Copy and save it securely.

### Using the API on Linux

1.  **Download the script:** Obtain the script from the [Cloudflare DDNS  Bash Script](https://github.com/namnamir/configurations-and-security-hardening/blob/main/Linux/Cloudflare_DDNS.sh).
2.  **Make it executable:** Open your terminal and run `chmod +x /path/to/Cloudflare_DDNS.sh`.
3.  **Schedule with Cron:** Use `crontab -e` to edit your cron jobs and add a line to the end of the file to run the script periodically. For example, to run weekly:
    ```bash
    @weekly /path/to/Cloudflare_DDNS.sh
    ```
    You can define the frequency precisely using tools like [Crontab Guru](https://crontab.guru/). Remember to configure the script with your API token, email, domain, and record details.

### Using the API on Windows

I made a strong PowerShell script for Windows that can handle dynamic input, multiple records, and detailed logging.

**1. Save the Script:** Download the [Cloudflare DDNS PowerShell Script for Windows]([https://adamtheautomator.com/cloudflare-dynamic-dns/](https://github.com/namnamir/configurations-and-security-hardening/blob/main/Windows/Cloudflare_DDNS.ps1)).

**2. Execute the Script:**

* **Interactive Mode:**
    Open PowerShell and navigate to the script's directory:
    ```powershell
    .\Cloudflare_DDNS.ps1
    ```
    The script will then interactively prompt you for your Email, API Token, and allow you to select your domain and the specific DNS record(s) to update from lists fetched directly from Cloudflare.

* **Manual Mode (Non-Interactive, with parameters):**
    You can pass all necessary information as arguments directly:
    ```powershell
    C:\CloudflareDDNS\Cloudflare_DDNS.ps1 -Email "your_cloudflare_email@example.com" -Token "YOUR_CLOUDFLARE_API_TOKEN" -Domain "domain.com" -Record "sub.domain.com" -LogFilePath "C:\CloudflareDDNS\CloudflareDdns.log"
    ```

**3. Schedule with Task Scheduler (for Automated Runs):**

To run the script periodically (e.g., weekly) for one or multiple subdomains, use Windows Task Scheduler.

* **Open Task Scheduler:** Search for "Task Scheduler" in the Start Menu, or press `Win + R` and type `taskschd.msc`.
* **Create a New Task:** In the right-hand "Actions" pane, click **"Create Task..."**.

    * **Triggers Tab:**
        * Click **"New..."**.
        * **"Begin the task:"**: Select `On a schedule`.
        * **Settings:** Choose `Weekly`. Set a start date/time and select the specific day(s) of the week. Click **"OK"**.
    * **Actions Tab:**
        * Click **"New..."**.
        * **"Action:"**: `Start a program`.
        * **"Program/script:"**: `powershell.exe`
        * **"Add arguments (optional):"**: This is where you'll put the command to run your script without user interaction.
            ```powershell
            -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\CloudflareDDNS\Cloudflare_DDNS.ps1" -Email "your_cloudflare_email@example.com" -Token "YOUR_CLOUDFLARE_API_TOKEN" -Domain "yourdomain.com" -Record "subdomain" -LogFilePath "C:\CloudflareDDNS\CloudflareDdns.log"
            ```

**Scheduling for Multiple Subdomains:**

For each subdomain you want to update (e.g., `sub1.domain.com`, `sub2.domain.com`, or `sub.domain2.com), **create a separate action**.

---
Resources:
- [Cloudflare DDNS (Python 3)](https://github.com/timothymiller/cloudflare-ddns)
- [PowerShell Solution](https://adamtheautomator.com/cloudflare-dynamic-dns/)
