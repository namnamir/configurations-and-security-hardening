# ⚡ Making Windows 11 Light, Fast, and VM-Friendly

Windows 11 is built for consumer laptops. Out of the box, it is packed with background services, widgets, peer-to-peer sharing, and heavy animations.

While modern hardware can handle this, running Windows inside a **Virtual Machine (like [Proxmox](/proxmox.md))** or using it purely for **coding and productivity** changes the rules of physics. Background tasks that seem harmless on bare-metal will aggressively consume your host's CPU, read/write cycles (IOPS), and network bandwidth.

This guide explains **what** we need to turn off, **why** it matters, and **how** to do it.

*(If you want to skip the manual work, you can run our all-in-one automated PowerShell script located here: [Windows Tweak Script](/Windows/Tweak-Windows.ps1)*

---

## 1. Core System & Hypervisor Harmony

These are the "heavy hitters." Fixing these will stop Windows from fighting your hypervisor and instantly reclaim gigabytes of SSD space.

### Disable Virtualization-Based Security (VBS)

* **What it is:** A security feature (Core Isolation / Memory Integrity) that uses hardware virtualization to isolate computer processes.
* **Why we disable it:** Inside a VM, leaving this enabled forces "nested virtualization" (a hypervisor running inside a hypervisor). This causes a massive 20-30% performance penalty on CPU and disk speeds.
* **How to do it:** * *Settings UI:* Open Windows Security -> Device Security -> Core Isolation details -> Turn off "Memory Integrity".
* *PowerShell:* Set `EnableVirtualizationBasedSecurity` to `0` in the registry.



### Kill Fast Startup & Hibernation

* **What it is:** Windows saves your kernel state to a massive hidden file (`hiberfil.sys`) so physical PCs boot faster.
* **Why we disable it:** In a VM, you rarely shut down (you use snapshots or sleep states). Fast Startup fights the Proxmox hypervisor during reboots, often causing the VM to hang forever on the "Restarting..." screen. Plus, disabling it instantly frees up 4GB-8GB of your virtual SSD.
* **How to do it:** * Open PowerShell as Admin and type: `powercfg /h off`

### Set a Static Pagefile

* **What it is:** The Pagefile is "virtual RAM" stored on your hard drive. By default, Windows dynamically grows and shrinks this file based on current RAM usage.
* **Why we change it:** When your VM suddenly runs out of RAM under heavy load, Windows panics and tries to instantly write a 2GB-4GB expansion file to your virtual SSD. This completely freezes the VM for several seconds. By setting a *static* size, the space is pre-allocated and expansion freezes never happen.
* **How to do it:** * *Settings UI:* Search for "Advanced System Settings" -> Performance Settings -> Advanced tab -> Virtual memory "Change". Uncheck automatic, select Custom size, and set both Initial and Maximum to `4096` (4GB).

---

## 2. Network & Telemetry (Stop the Phoning Home)

Windows loves to use your network in the background. Let's silence it.

### Disable Peer-to-Peer Updates (WUDO)

* **What it is:** Windows Update Delivery Optimization.
* **Why we disable it:** By default, Windows acts like a BitTorrent node. It downloads updates from Microsoft and then silently uploads them to other computers on the internet. This will completely shred your server's network bridge bandwidth.
* **How to do it:** * *Settings UI:* Settings -> Windows Update -> Advanced options -> Delivery Optimization -> Turn off "Allow downloads from other PCs".

### Stop Background UWP Apps

* **What it is:** Windows allows Microsoft Store apps (Calculator, Maps, Phone Link) to run suspended in the background so they launch 0.1 seconds faster.
* **Why we disable it:** It permanently ties up idle RAM and CPU threads.
* **How to do it:** * *Settings UI:* Settings -> Apps -> Installed Apps -> Click the `...` next to an app -> Advanced options -> Set Background apps permissions to "Never". (Our PowerShell script does this globally for all apps).

---

## 3. Visuals & UI (Snappy Remote Desktop)

If you access your VM via Remote Desktop (RDP), the visual settings are the difference between a sluggish mess and a lightning-fast native experience.

### Disable UI Animations

* **What it is:** Window minimizing animations, fading menus, and transparent glass effects.
* **Why we disable it:** RDP streams pixel changes over the network. Smooth animations force RDP to constantly encode and stream heavy video data. Disabling animations turns the stream into tiny, instantaneous static layout blocks.
* **How to do it:** * *Settings UI:* Search for "Advanced System Settings" -> Performance Settings. Choose **"Adjust for best performance"**.
* *Crucial Exception:* Make sure to check the boxes for **"Smooth edges of screen fonts"** and **"Show thumbnails instead of icons"** so your code and files remain highly legible.



### Disable the Lock Screen Transition

* **What it is:** The picture screen you have to swipe up or click before typing your password.
* **Why we disable it:** It is an unnecessary extra click when logging into a VM via Proxmox Console or RDP.
* **How to do it:** * *PowerShell / Registry:* Requires adding a `NoLockScreen` DWORD value to the Windows Personalization policies.

---

## 4. Microsoft Edge Hardening

Web browsers are the single biggest resource hogs in any OS. Even if you use Chrome or Firefox, Edge runs in the background.

### Aggressive Sleeping Tabs & Background Boost

* **What it is:** Edge's built-in memory management.
* **Why we change it:** We want to force Edge to release RAM for tabs you haven't looked at in 5 minutes, and we want to stop Edge from running a secret background instance when the browser is closed.
* **How to do it:** * *Settings UI:* Open Edge Settings -> System and performance. Turn **off** "Startup boost" and "Continue running background extensions". Turn **on** "Save resources with sleeping tabs" and set the timer to 5 minutes.

---

## 5. The "Nuke It All" Automated Script

Doing all of the above (alongside removing built-in bloatware like Xbox apps, disabling Windows Search indexing, and pinning the Windows Security tray icon) takes about 45 minutes of clicking through menus.

We have compiled all of these best practices into a single, automated PowerShell script. It will:

1. Ask you for a new Computer Name and custom RDP port.
2. Apply every hypervisor and performance tweak mentioned above.
3. Completely purge Windows 11 bloatware (Mail, Xbox, Widgets engine) via Winget.
4. Clean your Start Menu and Taskbar.

---

**🚀 Ready to optimize? Run the master script here: [Windows Tweak Script](/Windows/Tweak-Windows.ps1)**