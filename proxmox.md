
# Proxmox Virtual Machine Best Practices (Linux & Windows)

When creating Virtual Machines in Proxmox, the default settings are prioritized for maximum compatibility with legacy operating systems, not for performance. To achieve near bare-metal speed, especially for desktop environments and coding, you must use paravirtualized hardware (VirtIO).

## 1. Hardware Settings (Applies to both Linux & Windows)

For maximum performance, configure your VM hardware as follows:

* **SCSI Controller:** `VirtIO SCSI single`
* **Hard Disk Bus/Device:** `SCSI`
    * *Important:* Check the **Discard** box to enable TRIM (automatically reclaims deleted file space on thin-provisioned storage).
    * *Important:* Check the **IO thread** box to separate disk tasks from the main VM processes for better throughput.
* **Network Device:** Model `VirtIO (paravirtualized)`
* **Display:** `VirtIO-GPU` (or `SPICE / qxl`). 
    * *Note:* The "Default" (Standard VGA) display driver causes graphical deadlocks and system freezes when using desktop environments over RDP.
* **Processors:** Set Sockets to `1` and change the CPU **Type** to `host`. Using `host` passes your raw processor features (like AES acceleration) directly to the VM. Allocate cores based on host capacity, but avoid over-provisioning to prevent CPU Steal Time.

## 2. Proxmox Options Tab

* **QEMU Guest Agent:** Set to **Enabled**. (You must also install the agent inside the guest OS).
* **Boot Order:** Ensure your main `scsi0` disk is checked and at the top of the list. Uncheck `net0` to prevent slow PXE boot attempts.

## 3. Windows-Specific Setup (VirtIO Drivers)

Windows does not have built-in drivers for VirtIO hardware. If you do not install them, Windows will not recognize your hard drive or network adapter.

1. Create the VM with two CD/DVD drives: mount the Windows ISO to the first drive and the **VirtIO Drivers ISO** (`virtio-win.iso`) to the second.
2. Start the Windows installation. When the drive list shows up empty, click **Load Driver** -> **Browse** -> navigate to the `vioscsi` folder on the VirtIO CD to find your storage drive.
3. After Windows finishes installing and boots up, run `virtio-win-guest-tools.exe` directly from the VirtIO CD drive to automatically install the network, display, and QEMU Guest Agent drivers.


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
