# High-Speed RDP Tunneling via Debian Bastion

This guide outlines how to establish a low-latency, high-resolution Remote Desktop (RDP) connection from a local Windows laptop to a remote Windows VPS located inside a private network/VPN. By tunneling traffic over an optimized SSH connection via a Debian bastion host, you completely bypass graphical rendering lag on the intermediary system while keeping native, end-to-end clipboard sync.

## Architecture Overview

```
[Windows Laptop] ----(SSH Tunnel)----> [Debian Bastion + VPN] ----(RDP Traffic)----> [Windows VPS]
```

---

## Part 1: Preparing the Debian Intermediary Bastion

Execute these steps as `root` or using `sudo` on the Debian server.

### 1. Enable IP Routing and Network Optimization
Modern Debian versions manage system parameters in the `/etc/sysctl.d/` directory. Create a persistent configuration file to turn on packet forwarding and enable Google's high-speed **BBR** congestion control algorithm.

1. Create and open the file:
   ```bash
   sudo nano /etc/sysctl.d/99-bastion-tunnel.conf
   ```
2. Paste the following configuration blocks:
   ```ini
   # Enable IP packet forwarding for the VPN interface
   net.ipv4.ip_forward=1

   # Optimize TCP window scaling and buffer performance
   net.ipv4.tcp_window_scaling=1

   # Switch network traffic congestion algorithm to Google BBR (cuts down WAN/VPN latency)
   net.core.default_qdisc=fq
   net.ipv4.tcp_congestion_control=bbr
   ```
3. Apply the configuration across the system immediately:
   ```bash
   sudo sysctl --system
   ```
4. *(Optional)* Verify that IP forwarding and BBR is active; it should output `1` and `bbr`:
   ```bash
   sysctl net.ipv4.ip_forward
   sysctl net.ipv4.tcp_congestion_control
   ```

### 2. Configure the SSH Daemon & Change Port
To secure your bastion and keep the persistent RDP tunnel from freezing or dropping during idle states, optimize your SSH server rules.

1. Open the primary SSH configuration file:
   ```bash
   sudo nano /etc/ssh/sshd_config
   ```
2. Update or append the following values (adjust the port number as desired):
   ```ini
   Port 2222
   AllowTcpForwarding yes
   GatewayPorts yes
   TCPKeepAlive yes
   ClientAliveInterval 60
   ClientAliveCountMax 3
   ```
3. If your Debian system utilizes systemd socket-based activation for SSH, you must also override the socket layout:
   ```bash
   sudo systemctl edit ssh.socket
   ```
   Paste the following lines into the editor:
   ```ini
   [Socket]
   ListenStream=
   ListenStream=2222
   ```
4. Reload systemd daemons and restart the SSH services:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart sshd
   sudo systemctl restart ssh.socket
   ```

### 3. Adjust the Firewall (UFW)
Ensure your custom SSH port is open and that the firewall allows system traffic forwarding.
```bash
sudo ufw allow 2222/tcp
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw
sudo ufw reload
```

### 4. Test the Routing to Your VPS
Before trying to connect from your `Windows laptop`, make sure the `Bastion machine` itself can talk to the target VPS through its active VPN interface.

Run a ping -`Bastion machine` (Debian)- to your destination Windows VPS's private IP:

```bash
ping -c 4 [Windows VPS]
```

---

## Part 2: Establishing the Connection from Windows

### 1. Open the Tunnel
From your local Windows laptop, initiate the connection bridge. 
```cmd
ssh -p 2222 -N -L 33389:192.168.0.100:3389 bastion_user@bastion_ip
```
* **`192.168.0.100`**: The internal, private network IP of the destination `Windows VPS`.

> **Note:** Once you provide your SSH credentials, **the terminal window will go completely blank and pause**. This indicates the tunnel is running successfully in the background. Keep this window minimized.

### 2. Connect via Native Windows RDP (`mstsc`)
1. Press `Win + R`, type `mstsc`, and hit **Enter**.
2. In the **Computer** field, enter: `127.0.0.1:33389`
3. Click **Show Options** in the bottom-left corner and adjust these options:
   * **Local Resources Tab:** Ensure the **Clipboard** box is checked under *Local devices and resources*.
   * **Display Tab:** Adjust resolution to **Full Screen** and set color depth to **32-bit**.
   * **Experience Tab:** Change the performance profile to **High-speed WAN** (uncheck *Desktop background* if optimizing for absolute raw throughput).

### 3. Provide Domain Credentials
When prompted for your credentials to access the remote VPS, use one of these domain formats:
* **Option A (Down-Level):** `YOURDOMAIN\username`
* **Option B (UPN format):** `username@yourdomain.local`

Click **Connect** and bypass the localhost certificate warning. You are now natively working directly on the remote VPS.
