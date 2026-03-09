# Red‑Team Lab: Multi‑Network Domain Compromise

A fully automated, Vagrant‑based lab that simulates a realistic attack path from external web exploitation to complete Active Directory takeover.

## Lab Overview

### Scenario
You are a red‑team operator tasked with penetrating a corporate network. The only exposed asset is a web server (WEB01) running a vulnerable version of Apache. Your goal is to:
1. Gain initial access via CVE‑2021‑41773 (Apache path traversal).
2. Escalate privileges on WEB01.
3. Pivot into the internal network (`10.0.20.0/24`).
4. Move laterally to a Windows 10 workstation.
5. Dump credentials, crack a Domain Admin hash, and compromise the Domain Controller.

### Network Topology
```
External Network (192.168.1.0/24)
├── Attacker (your Kali/host machine) – 192.168.1.100 (not provisioned)
└── WEB01 (Ubuntu 20.04) – 192.168.1.10 (eth0)

Internal Network (10.0.20.0/24)
├── WEB01 – 10.0.20.10 (eth1)
├── DC (Windows Server 2019) – 10.0.20.5
└── WORKSTATION (Windows 10) – 10.0.20.20
```

**Connectivity rules:**
- Attacker can only reach WEB01’s external interface (`192.168.1.10`).
- WEB01 can talk to both networks.
- Internal machines cannot initiate connections to the external network.
- All internal machines can communicate with each other.

## Setup

### Automated Setup Script
The lab includes a setup script that checks dependencies and downloads required tools.

```bash
chmod +x setup-lab.sh
./setup-lab.sh
```

The script will:
- Verify Vagrant and VirtualBox are installed.
- Download Chisel and Mimikatz binaries into the `tools/` directory.
- Provide guidance on network configuration.
- Optionally start the lab for you.

### Manual Setup

#### 1. Prerequisites
- [VirtualBox](https://www.virtualbox.org/) (≥ 6.1)
- [Vagrant](https://www.vagrantup.com/) (≥ 2.2.10)
- At least **10 GB free disk space** and **9 GB RAM** (WEB01: 2GB, DC: 4GB, WORKSTATION: 3GB)
- A separate attacker machine (Kali Linux, host machine, or another VM) on the `192.168.1.0/24` network.

#### 2. Download Required Tools
Before starting the lab, download the necessary penetration‑testing tools:

```bash
cd tools
./download-tools.sh
```

This downloads:
- **Chisel** (Linux & Windows) – SOCKS proxy for pivoting.
- **Mimikatz** (Windows) – Credential‑dumping tool.

#### 3. Network Configuration
The lab creates two isolated networks:

| Network | Subnet | Type | Purpose |
|---------|--------|------|---------|
| External | `192.168.1.0/24` | Host‑only (Vagrant managed) | Attacker ↔ WEB01 |
| Internal | `10.0.20.0/24` | Internal network (isolated) | Internal communication |

**Attacker setup:**
Your attacker machine must be on the same host‑only network as WEB01’s external interface.

**Option A (recommended):** Use your host machine as the attacker.
1. Open VirtualBox → **File** → **Host Network Manager**.
2. Create a host‑only network with:
   - IPv4 Address: `192.168.1.1`
   - IPv4 Network Mask: `255.255.255.0`
   - DHCP server **disabled**.
3. Configure your host’s network adapter (on the host‑only network) with a static IP, e.g., `192.168.1.100`.

**Option B:** Use a separate Kali VM.
- Attach the Kali VM’s NIC to the same host‑only network (Vagrant will create one named `vboxnet1`).
- Set Kali’s IP to `192.168.1.100` (or any free address in `192.168.1.0/24`).

## Quick Start

1. **Clone/download** this lab to your host.
2. **Open a terminal** in the lab directory.
3. **Run the setup script** (or follow manual steps above).
4. **Start the lab:**
   ```bash
   vagrant up
   ```
   This downloads the base boxes (≈8 GB) and provisions all three VMs. The first run may take **30–60 minutes** depending on your internet speed.

5. **Verify** the VMs are running:
   ```bash
   vagrant status
   ```

6. **Test connectivity** from your attacker machine:
   ```bash
   ping 192.168.1.10
   ```

## Lab Components

### WEB01 (Ubuntu 20.04)
- **External IP:** 192.168.1.10
- **Internal IP:** 10.0.20.10
- **Services:** Apache 2.4.49 (vulnerable to CVE‑2021‑41773)
- **Misconfigurations:**
  - World‑writable cron script (`/usr/local/bin/backup.sh`) running as root.
  - Credentials stored in `/root/creds.txt`.

### DC (Windows Server 2019)
- **IP:** 10.0.20.5
- **Domain:** `corp.local`
- **Users:**
  - `bob` – regular user, password `Summer2024!`
  - `backup_admin` – Domain Admin, password `Winter2024!`
  - `web_admin` – domain user, password `P@ssw0rd`
- **Firewall:** Allows SMB (445) and WinRM (5985) from internal network.

### WORKSTATION (Windows 10)
- **IP:** 10.0.20.20
- **Domain‑joined:** `corp.local`
- **Misconfigurations:**
  - Writable scheduled‑task folder (`C:\ProgramData\Tasks`).
  - Scheduled task runs `backup.bat` as SYSTEM every minute.
  - Domain Admin credentials (`backup_admin`) kept in memory for dumping.

## Objectives & Flags
Detailed objectives and flag locations are in [CHALLENGE.md](./CHALLENGE.md).

### Milestone Flags
1. **WEB01‑root** – After obtaining root on WEB01.
2. **WORKSTATION‑system** – After achieving SYSTEM on the Windows 10 workstation.
3. **DC‑domain** – After compromising the Domain Controller.

## Tools Provided
The `tools/` directory contains pre‑compiled binaries for convenience:
- `chisel_linux_amd64` – SOCKS proxy (Linux).
- `chisel_windows_amd64.exe` – SOCKS proxy (Windows).
- `mimikatz_trunk.zip` – Credential‑dumping tool.

These are synced to `/vagrant/tools` (Linux) and `C:\vagrant\tools` (Windows) inside each VM.

## Documentation
- [CHALLENGE.md](./CHALLENGE.md) – Red‑team scenario, hints, flag locations.
- [Attack‑Walkthrough.md](./docs/Attack-Walkthrough.md) – Step‑by‑step solution.
- [Instructor‑Guide.md](./docs/Instructor-Guide.md) – Setup notes, troubleshooting.

## Verification Script
After provisioning, you can run a quick connectivity check:

```bash
./verify.sh
```

This script verifies that each VM is reachable and flags are present.

## Troubleshooting

### Vagrant times out during Windows provisioning
Increase the `winrm` timeout or check that the Windows boxes are downloaded correctly. You can also run provisioning in stages:

```bash
vagrant up web01
vagrant up dc
vagrant up workstation
```

### Apache exploit fails
Ensure Apache is running on WEB01:

```bash
vagrant ssh web01
sudo /usr/local/apache2/bin/apachectl status
```

### Internal network unreachable
Verify that WEB01’s second NIC is up and has IP `10.0.20.10`:

```bash
vagrant ssh web01
ip addr show eth1
```

### Windows Defender blocks Mimikatz
Windows Defender is disabled in the provisioning scripts. If it re‑enables, add an exclusion for `C:\vagrant\tools` or disable real‑time protection manually.

### Domain join fails (WORKSTATION)
Ensure the DC is fully provisioned before starting the workstation. If needed, run `vagrant provision dc` and then `vagrant provision workstation`.

## Cleaning Up
To stop all VMs:
```bash
vagrant halt
```

To destroy them (delete all disks):
```bash
vagrant destroy -f
```

## License & Disclaimer
This lab is for educational and authorized penetration‑testing practice only. Do not use the techniques or code against systems you do not own or have explicit permission to test.