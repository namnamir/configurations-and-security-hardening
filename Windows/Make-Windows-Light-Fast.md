# Make Windows 11 Lightweight and Fast for VMs

Windows 11 is heavily bloated with background telemetry, consumer applications, and services designed for slow physical hardware. When running inside a Virtual Machine for development, this bloat wastes CPU cycles, RAM, and Disk I/O. 

Follow these steps to debloat the OS and optimize it for coding.

## 1. The Ultimate Debloat Tool (Chris Titus Tech Utility)
The fastest and safest way to strip Windows 11 down to its bare essentials is by using the open-source CTT Windows Utility.

1. Right-click the Start Button and open **Terminal (Admin)** or **PowerShell (Admin)**.
2. Run the following command:
    ```powershell
    irm [christitus.com/win](https://christitus.com/win) | iex
    ```
3. In the graphical window that appears, navigate to the **Tweaks** tab.
4. Click the **Desktop** profile button (this selects the safest recommended tweaks for a daily-use machine).
5. Click **Run Tweaks**.

## 2. Disable VM-Killing Services

Windows runs optimization services that are helpful for old physical hard drives but actually hurt the performance of fast, SSD-backed Virtual Machines.

1. Press `Win + R`, type `services.msc`, and press Enter.
2. Disable **SysMain** (formerly Superfetch):
* *Reason:* It constantly pre-loads apps into RAM, wasting CPU and virtual disk I/O.
* *Action:* Right-click -> Properties -> Startup type: **Disabled** -> Stop -> OK.

3. Disable **Windows Search**:
* *Reason:* It constantly indexes the hard drive for slightly faster Start Menu searches, causing severe virtual disk thrashing.
* *Action:* Right-click -> Properties -> Startup type: **Disabled** -> Stop -> OK.


## 3. Disable Xbox Game Bar

Windows constantly runs gaming services in the background waiting to record gameplay.

1. Open **Settings** -> **Gaming** -> **Xbox Game Bar**.
2. Toggle the service **Off**.

## 4. Optimize Visuals and Power

UI animations in Windows 11 require GPU acceleration. In a VM, these look choppy and consume unnecessary resources.

1. **Disable Animations:** Press the `Windows Key`, search for **Visual Effects**, and turn off **Transparency effects** and **Animation effects**.
2. **Performance Settings:** Press the `Windows Key`, search for **Advanced System Settings**. Under the *Performance* section, click **Settings**. Choose **Adjust for best performance** (Tip: leave "Smooth edges of screen fonts" checked so your code remains legible).
3. **Power Plan:** Search for **Choose a power plan** and set it to **High Performance**. This prevents Windows from attempting to put your virtual CPU cores to sleep.

## 5. Clean Up Startup Apps

Every application that launches at startup silently consumes RAM.

1. Press `Ctrl + Shift + Esc` to open **Task Manager**.
2. Go to the **Startup apps** tab (speedometer icon).
3. Right-click and **Disable** anything not strictly necessary for the OS to run (e.g., OneDrive, Edge, Spotify, Microsoft Teams).

## 6. Enable Native Remote Desktop (RDP)

For the best daily coding experience, do not use the Proxmox Web Console (noVNC). The web console lacks dual-monitor support, restricts resolution, and makes clipboard sharing difficult.

1. Inside the Windows VM, go to **Settings** -> **System** -> **Remote Desktop**.
2. Toggle Remote Desktop **On**.
3. Use the native "Remote Desktop Connection" app from your host machine to connect to the VM's IP address. This provides a native, full-screen, high-refresh-rate experience.