<h1 align="center">
  <br>
  <a href="https://github.com/adip-offensec">
    <img src="https://github.com/user-attachments/assets/0671daea-0e7a-4862-8bb3-613cc5a4569a" alt="challenge-yourself-level-2" width="620">
  </a>
  <br><br>
  challenge-yourself-level-2
</h1>
<h4 align="center">
  Realistic Red Team Lab: Multi-Network Domain Compromise<br>
  Complete attack chain: CVE-2021-41773 → Root → Pivot → SYSTEM → Domain Admin
</h4>
<p align="center">
  <strong>Created by</strong><br><br>
  <a href="https://github.com/adip-offensec">adip-offensec</a>
  ×
  <a href="https://github.com/manojxshrestha">manojxshrestha</a>
</p>
<p align="center">
  <a href="https://github.com/adip-offensec/challenge-yourself-level-2/stargazers">
    <img src="https://img.shields.io/github/stars/adip-offensec/challenge-yourself-level-2?style=social" alt="GitHub stars">
  </a>
  <a href="https://github.com/adip-offensec/challenge-yourself-level-2/forks">
    <img src="https://img.shields.io/github/forks/adip-offensec/challenge-yourself-level-2?style=social" alt="GitHub forks">
  </a>
  <img src="https://img.shields.io/badge/Vagrant-✓-blue" alt="Vagrant">
  <img src="https://img.shields.io/badge/VirtualBox-✓-blue" alt="VirtualBox">
  <img src="https://img.shields.io/badge/Red%20Team%20Lab-Active%20Directory-orange" alt="Red Team Lab">
</p>
<br>

## Lab Overview

A fully automated Vagrant-based red team lab that simulates a realistic attack path from external web exploitation to complete Active Directory domain compromise.

### Scenario
You are a red team operator tasked with penetrating a corporate network. The only exposed asset is a web server (WEB01) running a vulnerable version of Apache. Your goal is to:

1. Gain initial access via **CVE-2021-41773** (Apache path traversal)
2. Escalate privileges to root on WEB01
3. Pivot into the internal network (`10.0.20.0/24`)
4. Move laterally to the Windows 10 workstation
5. Dump credentials and compromise the Domain Controller

### Network Topology
```
External Network (192.168.1.0/24)
├── Attacker (your Kali / host machine) – 192.168.1.100
└── WEB01 (Ubuntu 20.04) – 192.168.1.10 (eth0)

Internal Network (10.0.20.0/24)
├── WEB01 – 10.0.20.10 (eth1)
├── DC (Windows Server 2019) – 10.0.20.5
└── WORKSTATION (Windows 10) – 10.0.20.20
```

**Connectivity Rules:**
- Attacker can only reach WEB01 on the external interface (`192.168.1.10`)
- WEB01 can communicate with both networks (pivot point)
- Internal machines cannot reach the external network
- All internal machines can communicate freely with each other

## Quick Start

### Automated Setup (Recommended)
```bash
chmod +x setup-lab.sh
./setup-lab.sh
```

### Manual Setup
1. Clone this repository
2. Download required tools:
   ```bash
   cd tools
   ./download-tools.sh
   ```
3. Start the lab:
   ```bash
   vagrant up
   ```
   *First run will download ~8 GB of base boxes and may take 30–60 minutes.*

4. Verify setup:
   ```bash
   ./verify.sh
   ```

## Prerequisites
- VirtualBox ≥ 6.1
- Vagrant ≥ 2.2.10
- Minimum **9 GB RAM** and **10 GB** free disk space
- Attacker machine (Kali Linux recommended) on the `192.168.1.0/24` network

## Lab Components

| Machine       | OS                  | External IP     | Internal IP    | Key Features / Misconfigurations |
|---------------|---------------------|-----------------|----------------|----------------------------------|
| **WEB01**     | Ubuntu 20.04        | 192.168.1.10    | 10.0.20.10     | Apache 2.4.49 (CVE-2021-41773), world-writable root cron job |
| **DC**        | Windows Server 2019 | -               | 10.0.20.5      | Domain Controller (`corp.local`), SMB/WinRM exposed internally |
| **WORKSTATION**| Windows 10         | -               | 10.0.20.20     | Writable scheduled task running as SYSTEM, Domain Admin creds in memory |

### Domain Credentials (Discover during the lab)
- `bob` : `Summer2024!`
- `web_admin` : `P@ssw0rd`
- `backup_admin` (Domain Admin) : `Winter2024!`

## Objectives & Flags

Detailed objectives and flag locations are available in **[CHALLENGE.md](./CHALLENGE.md)**

### Milestone Flags
| Milestone             | Objective                              | Flag Location                          |
|-----------------------|----------------------------------------|----------------------------------------|
| WEB01-root            | Root on external web server            | `/root/flag.txt`                       |
| WORKSTATION-system    | SYSTEM on Windows 10 workstation       | `C:\flags\stage2.txt`                  |
| DC-domain             | Full Domain Controller compromise      | `C:\Users\Administrator\Desktop\final.txt` |

## Tools Included
The `tools/` directory contains:
- `chisel_linux_amd64` & `chisel_windows_amd64.exe` – SOCKS proxy for pivoting
- `mimikatz_trunk.zip` – Credential dumping

These tools are automatically synced to `/vagrant/tools` (Linux) and `C:\vagrant\tools` (Windows).

## Documentation
- **[CHALLENGE.md](./CHALLENGE.md)** – Full scenario, objectives & hints
- **[docs/Attack-Walkthrough.md](./docs/Attack-Walkthrough.md)** – Step-by-step solution (instructors only)
- **[docs/Instructor-Guide.md](./docs/Instructor-Guide.md)** – Advanced setup & troubleshooting

## Troubleshooting
- **Vagrant timeout on Windows machines** → Run `vagrant up dc` first, then `vagrant up workstation`
- **Cannot reach 192.168.1.10** → Configure your attacker on the same host-only network (`192.168.1.0/24`)
- **Internal network unreachable** → Check `ip addr show eth1` on WEB01
- **Mimikatz blocked** → Defender is disabled via provisioning, but you can manually exclude `C:\vagrant\tools`

Full reset:
```bash
vagrant destroy -f && vagrant up
```

## Security Warning
⚠️ **WARNING**: This lab contains intentionally vulnerable systems and real exploitation techniques. Use **only** in isolated environments for educational and authorized penetration testing purposes. Do not expose these VMs to the internet or any untrusted network.

## License
Educational Use Only — See LICENSE file for details.

---

**Happy Hacking!**  
