# Lab Build Complete

Your red‑team lab is ready for deployment.

## What Was Built
- **Vagrant‑based multi‑machine environment** with full automation.
- **Three VMs:** WEB01 (Ubuntu 20.04), DC (Windows Server 2019), WORKSTATION (Windows 10).
- **Dual‑network topology:** External (192.168.1.0/24) and internal (10.0.20.0/24).
- **Pre‑configured vulnerabilities:**
  1. Apache 2.4.49 with CVE‑2021‑41773 (path traversal to RCE).
  2. World‑writable cron script for privilege escalation.
  3. Stored domain credentials (`web_admin:P@ssw0rd`).
  4. Writable scheduled‑task folder on Windows 10.
  5. Domain Admin credentials kept in memory for dumping.
  6. Crackable NTLM hash (`Winter2024!`).
- **Flags** at each major milestone.
- **Complete documentation:** README, challenge guide, attack walkthrough, instructor guide.
- **Tool provision** with download script (Chisel, Mimikatz).

## Files Created
```
lab/
├── Vagrantfile                 # Multi‑VM definition
├── README.md                   # Lab overview & quick start
├── CHALLENGE.md                # Red‑team scenario & hints
├── verify.sh                   # Basic connectivity check
├── web01/
│   ├── bootstrap.sh            # Apache, cron, credentials
│   ├── files/httpd.conf        # Apache config
│   ├── files/test.cgi          # CGI script
│   └── flags/flag_root.txt
├── dc/
│   ├── bootstrap.ps1           # AD DS, users, firewall
│   └── flags/flag_domain.txt
├── workstation/
│   ├── bootstrap.ps1           # Domain join, scheduled task
│   └── flags/flag_system.txt
├── tools/
│   ├── download‑tools.sh       # Fetch Chisel & Mimikatz
│   └── (placeholder binaries)
└── docs/
    ├── Attack‑Walkthrough.md   # Step‑by‑step solution
    └── Instructor‑Guide.md     # Setup & troubleshooting
```

## Next Steps
1. **Download tools:**
   ```bash
   cd tools && ./download‑tools.sh
   ```
2. **Start the lab:**
   ```bash
   vagrant up
   ```
   (First run will download ~8 GB of base boxes.)
3. **Configure your attacker machine** (Kali/host) on `192.168.1.0/24`.
4. **Begin the challenge** using `CHALLENGE.md` as your guide.
5. **Verify** with `./verify.sh` after provisioning.

## Estimated Provisioning Time
- **Base box download:** 30–60 minutes (depending on bandwidth).
- **WEB01:** 5–10 minutes (compiles Apache).
- **DC:** 10–15 minutes (AD promotion).
- **WORKSTATION:** 5–10 minutes (domain join).

## Lab Verification Checklist
- [ ] `vagrant up` completes without errors.
- [ ] `vagrant status` shows all three VMs running.
- [ ] Attacker can ping `192.168.1.10`.
- [ ] Apache exploit yields a shell (CVE‑2021‑41773).
- [ ] Cron job escalation grants root.
- [ ] Chisel proxy allows internal network scanning.
- [ ] Scheduled‑task hijack grants SYSTEM.
- [ ] Mimikatz dumps `backup_admin` hash.
- [ ] Hash cracks to `Winter2024!`.
- [ ] WinRM to DC as `backup_admin` succeeds.
- [ ] All three flags are captured.

## Support
- Refer to `docs/Instructor‑Guide.md` for troubleshooting.
- Review the original blueprint at `../lab.blueprint`.
- For issues, check Vagrant logs: `vagrant up --debug`.

## Notes
- This lab is designed for **authorized red‑team training** only.
- Ensure the lab is run on isolated hardware or a dedicated VLAN.
- After use, destroy VMs with `vagrant destroy -f`.

Enjoy your penetration‑testing practice!