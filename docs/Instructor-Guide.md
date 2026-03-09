# Instructor Guide – Setup & Troubleshooting

This guide provides detailed information for instructors or lab administrators who need to set up, verify, or troubleshoot the lab.

## Lab Architecture Overview

### Virtual Machines
| VM | OS | IPs | Roles |
|----|----|-----|-------|
| **web01** | Ubuntu 20.04 | 192.168.1.10 (eth0)<br>10.0.20.10 (eth1) | Vulnerable Apache server, pivot host |
| **dc** | Windows Server 2019 | 10.0.20.5 | Domain Controller (`corp.local`) |
| **workstation** | Windows 10 | 10.0.20.20 | Domain‑joined workstation with misconfigured scheduled task |

### Network Configuration
- **External network:** `vboxnet1` (192.168.1.0/24) – host‑only.
- **Internal network:** `vboxnet2` (10.0.20.0/24) – host‑only.
- **Attacker:** Not provisioned; user supplies own machine (Kali/host) on `192.168.1.0/24`.

### Credentials
| User | Password | Role |
|------|----------|------|
| `bob` | `Summer2024!` | Regular domain user |
| `backup_admin` | `Winter2024!` | Domain Admin (target) |
| `web_admin` | `P@ssw0rd` | Domain user (for lateral movement) |
| `Administrator` (DC) | `DSRMP@ssw0rd` | DSRM password (not used) |

## Setup Verification

### 1. Pre‑flight Checks
- VirtualBox ≥ 6.1 and Vagrant ≥ 2.2.10 installed.
- At least 9 GB RAM free (2+4+3 GB for VMs).
- ~10 GB free disk space for base boxes + provisioned disks.
- Host‑only networks `vboxnet1` and `vboxnet2` exist (Vagrant will create them).

### 2. Build the Lab
```bash
cd /path/to/lab
vagrant up
```
**Expected timeline:**
- Download base boxes (≈8 GB): 30–60 minutes depending on bandwidth.
- Provisioning:
  - `web01`: 5–10 minutes (compiles Apache).
  - `dc`: 10–15 minutes (AD promotion).
  - `workstation`: 5–10 minutes (domain join, scheduled task).

### 3. Verify Each VM

#### web01
```bash
vagrant ssh web01
sudo /usr/local/apache2/bin/apachectl status  # Should show Apache running
curl -I http://localhost  # Should return 200 OK
ls -la /usr/local/bin/backup.sh  # Should be -rw-rw-rw-
cat /etc/crontab | grep backup.sh  # Should show cron entry
cat /root/creds.txt  # Should show corp\web_admin:P@ssw0rd
```

#### dc
- Log in via RDP (VirtualBox GUI) or WinRM.
- Open Active Directory Users and Computers, verify `bob`, `backup_admin`, `web_admin` exist.
- Check `C:\Users\Administrator\Desktop\flag_domain.txt` exists.

#### workstation
- Log in via RDP or WinRM.
- Verify `C:\ProgramData\Tasks\backup.bat` exists and folder is writable.
- Check scheduled task:
  ```powershell
  Get-ScheduledTask -TaskName BackupTask
  ```
- Verify `C:\Windows\System32\flag_system.txt` exists.

### 4. Network Connectivity
From the **attacker** (host machine):
```bash
ping 192.168.1.10  # Should succeed
```

From **web01**:
```bash
ping 10.0.20.5     # Should succeed
ping 10.0.20.20    # Should succeed
```

From **workstation**:
```powershell
Test-NetConnection 10.0.20.5 -Port 445  # Should succeed
```

## Common Issues & Solutions

### Vagrant Timeouts During Windows Provisioning
**Symptom:** Vagrant hangs at “Waiting for machine to boot…”  
**Cause:** WinRM not ready, slow Windows boot.  
**Fix:**
1. Increase timeout in Vagrantfile (add `config.vm.boot_timeout = 600`).
2. Manually boot the VM via VirtualBox GUI, wait for login screen, then retry `vagrant up`.
3. Use `vagrant reload` after initial boot.

### Apache Compilation Fails on web01
**Symptom:** `make` error due to missing dependencies.  
**Fix:** Ensure `build‑essential` is installed. Edit `web01/bootstrap.sh` to include:
```bash
apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
```

### Domain Join Fails (workstation)
**Symptom:** “The network path was not found” or similar.  
**Cause:** DC not fully ready, DNS misconfiguration.  
**Fix:**
1. Verify DC is fully provisioned (AD DS installed, DNS running).
2. On workstation, set DNS server to `10.0.20.5` before joining.
3. Add a sleep in `workstation/bootstrap.ps1` before `Add‑Computer`.

### Chisel/Mimikatz Not Available in `/vagrant/tools`
**Symptom:** Tools directory empty.  
**Fix:** Run the download script:
```bash
cd tools
./download-tools.sh
```
If offline, manually download binaries from:
- Chisel: https://github.com/jpillora/chisel/releases
- Mimikatz: https://github.com/gentilkiwi/mimikatz/releases

Place them in `tools/` with correct names.

### Internal Network Not Reachable from web01
**Symptom:** `ping 10.0.20.5` fails.  
**Cause:** Second NIC not configured or firewall.  
**Fix:**
```bash
vagrant ssh web01
sudo ip addr add 10.0.20.10/24 dev eth1
sudo ip link set eth1 up
```

### Windows Defender Blocks Mimikatz
**Symptom:** Mimikatz is quarantined.  
**Fix:** Disable Windows Defender (already done in bootstrap) or add exclusion:
```powershell
Add-MpPreference -ExclusionPath "C:\vagrant\tools"
```

## Customizing the Lab

### Changing IP Addresses
Edit the Vagrantfile’s `private_network` IPs and update:
- `web01/bootstrap.sh` (internal IP assignment).
- `workstation/bootstrap.ps1` (domain join assumes DC at `10.0.20.5`).

### Adding More Challenges
- **Extra web vulnerability:** Add a second vulnerable service (e.g., ProFTPD, Samba) on web01.
- **Additional lateral movement:** Place another Windows server with different misconfiguration (e.g., unquoted service path).
- **Defense evasion:** Enable Windows Defender/AMSI and require bypass techniques.

### Adjusting Difficulty
- **Easier:** Provide explicit hints in `CHALLENGE.md`.
- **Harder:** Remove stored credentials (`/root/creds.txt`) and require attackers to dump them from memory (e.g., with `linpeas`).

## Lab Reset
To return to a fresh state:
```bash
vagrant destroy -f
vagrant up
```
This will delete all VMs and rebuild them from scratch.

## Monitoring Student Progress
- Flags are placed at key milestones (see `CHALLENGE.md`).
- Students can submit flags as proof of completion.
- For a CTF, use a scoring platform (CTFd, FBCTF) and assign points per flag.

## Safety & Ethics Reminder
- This lab is for authorized training only.
- Ensure students understand that techniques shown must not be used against unauthorized systems.
- Consider running the lab on isolated hardware or a dedicated VLAN.

## Support
If issues persist, check:
- Vagrant logs: `vagrant up --debug`
- VirtualBox network settings (Host Network Manager).
- Windows event logs (DC, workstation).

For further assistance, refer to the original blueprint document (`../lab.blueprint`).