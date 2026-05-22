
# Proxmox Virtual Machine Best Practices (Linux & Windows)

When creating Virtual Machines in Proxmox, the default settings are prioritized for maximum compatibility with legacy operating systems, not for performance. To achieve near bare-metal speed, especially for desktop environments and coding, you must use paravirtualized hardware (VirtIO).

## 1. Hardware Settings (Applies to both Linux & Windows)

For maximum performance, configure your VM hardware as follows:

* **SCSI Controller:** `VirtIO SCSI single`
* **Hard Disk Bus/Device:** `SCSI`
    * *Important:* Check the **Discard** box to enable TRIM (automatically reclaims deleted file space on thin-provisioned storage).
    * *Important:* Check the **IO thread** box to separate disk tasks from the main VM processes for better throughput.
    * *Important:* Check the **SSD emulation** box so the guest OS optimizes its storage pipelines natively for flash memory.
* **Network Device:** Model `VirtIO (paravirtualized)`
* **Display:** `VirtIO-GPU` (or `SPICE / qxl`). 
    * *Note:* The "Default" (Standard VGA) display driver causes graphical deadlocks and system freezes over RDP.
    * *Crucial VDI Tweak:* Once RDP is active, go to the VM's Hardware tab and **Remove the USB Tablet** device (`usb-tablet`). This stops massive idle CPU drain and context-switching caused by the virtual pointer.
* **Processors:** Set Sockets to `1` and change the CPU **Type** to `host`. Using `host` passes your raw processor features (like AES acceleration) directly to the VM, reducing software latency. Avoid over-provisioning cores to prevent high CPU Steal Time.

## 2. Proxmox Options Tab

* **QEMU Guest Agent:** Set to **Enabled**. (You must also install the agent inside the guest OS).
* **Boot Order:** Ensure your main `scsi0` disk is checked and at the top of the list. Uncheck `net0` to prevent slow PXE boot attempts.

## 3. Windows VDI Setup & Optimization

Windows requires strict hardening to respect the KVM hypervisor and prevent it from destroying host NVMe IOPS or network bandwidth. 

### Phase 1: VirtIO Installation
Windows does not have built-in drivers for paravirtualized hardware.
1. Create the VM with two CD/DVD drives: mount the Windows ISO to the first drive and the **VirtIO Drivers ISO** (`virtio-win.iso`) to the second.
2. During Windows installation, when the drive list is empty, click **Load Driver -> Browse** and navigate to the `vioscsi` folder on the VirtIO CD to reveal your storage drive.
3. After booting into Windows, run `virtio-win-guest-tools.exe` from the CD to automatically install network, display, and QEMU Guest Agent drivers.

### Phase 2: OS & Hypervisor Harmony
Physical PC optimizations can crash virtual machines. To achieve bare-metal speed over RDP, you must apply specific VDI (Virtual Desktop Infrastructure) tweaks:
* **Disable Virtualization-Based Security (VBS):** Turn off *Core Isolation / Memory Integrity* in Windows Security. Leaving this on forces nested virtualization, crippling CPU and disk I/O by up to 30%.
* **Disable Fast Startup & Hibernation:** Run `powercfg /h off` to instantly delete the massive `hiberfil.sys` and stop Windows from fighting the hypervisor during reboots.
* **Disable P2P Updates (WUDO):** Windows acts as a peer-to-peer node by default. Disable *Delivery Optimization* to stop it from uploading updates and shredding your Proxmox network bridge.
* **Static Pagefile:** Manually set a static pagefile (e.g., 4096MB Min/Max) to prevent the VM from freezing during dynamic virtual disk expansions.
* **RDP UI Adjustments:** Disable all DWM/UI animations but keep *Font Smoothing* and *Thumbnails* enabled. RDP streams pixel differentials; animations force heavy video encoding, causing lag.

### Phase 3: Master Deployment Script
To automate all of the above, alongside bloatware removal, DNS configuration, and browser optimization, run the automated deployment script located in this repository: [Windows Tweak Script](/Windows/Tweak-Windows.ps1)

## 4. Linux-Specific Setup

Linux kernels natively support VirtIO hardware, so no extra driver CDs are required. 

**Post-Installation Step:**
Install the QEMU Guest Agent to allow Proxmox to issue graceful shutdown commands and view the VM's IP address:
```bash
sudo apt update && sudo apt install qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

If using XFCE via Remote Desktop (`xrdp`), remove `light-locker` to prevent the session from permanently freezing when the display goes to sleep:

```bash
sudo apt remove light-locker
```

**Fixing XRDP Clipboard Crashes (XFCE):**
The desktop clipboard manager often fights with XRDP, breaking copy/paste between the host and VM mid-session.
1. Go to **Session and Startup -> Application Autostart** and uncheck `xfce4-clipman`.
2. If the clipboard stops working, run this inside the VM terminal to instantly restart the sync process:
```bash
killall xrdp-chansrv ; xrdp-chansrv &
```