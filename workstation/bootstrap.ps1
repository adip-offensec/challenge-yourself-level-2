# WORKSTATION Bootstrap Script
Write-Host "[*] Starting WORKSTATION provisioning..." -ForegroundColor Green

# Set execution policy
Set-ExecutionPolicy Bypass -Scope Process -Force

# Join domain (requires DC to be ready)
Write-Host "[*] Joining domain corp.local..." -ForegroundColor Yellow
$domain = "corp.local"
$username = "corp\backup_admin"
$password = ConvertTo-SecureString "Winter2024!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

Add-Computer -DomainName $domain -Credential $credential -Force -Restart:$false

# Wait for domain join to complete
Start-Sleep -Seconds 20

# Create writable folder for scheduled task
Write-Host "[*] Creating writable scheduled-task folder..." -ForegroundColor Yellow
$taskDir = "C:\ProgramData\Tasks"
New-Item -Path $taskDir -ItemType Directory -Force
icacls $taskDir /grant "Authenticated Users:(OI)(CI)(W)" /T

# Create benign batch file
$batchPath = "$taskDir\backup.bat"
@'
@echo off
echo Backup ran at %time%
'@ | Out-File -FilePath $batchPath -Encoding ASCII

# Create scheduled task that runs as SYSTEM every minute (starts 1 minute from now)
Write-Host "[*] Creating scheduled task..." -ForegroundColor Yellow
$action = New-ScheduledTaskAction -Execute $batchPath
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 365)
$settings = New-ScheduledTaskSettingsSet
Register-ScheduledTask -TaskName "BackupTask" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -Force

# Start a process as backup_admin to keep credentials in memory (for Mimikatz)
Write-Host "[*] Planting domain admin credentials in memory..." -ForegroundColor Yellow
$backupAdminCred = New-Object System.Management.Automation.PSCredential("corp\backup_admin", (ConvertTo-SecureString "Winter2024!" -AsPlainText -Force))
Start-Process powershell -Credential $backupAdminCred -ArgumentList "-NoProfile -Command Start-Sleep -Seconds 86400" -WindowStyle Hidden

# Disable Windows Defender (for lab simplicity)
Write-Host "[*] Disabling Windows Defender..." -ForegroundColor Yellow
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# Create SYSTEM flag
Write-Host "[*] Creating SYSTEM flag..." -ForegroundColor Yellow
$flagPath = "C:\Windows\System32\flag_system.txt"
"FLAG{WORKSTATION_SYSTEM_ACCESS}" | Out-File -FilePath $flagPath -Encoding ASCII

# Add helpful message
Write-Host "[*] WORKSTATION provisioning complete!" -ForegroundColor Green
Write-Host "    IP: 10.0.20.20" -ForegroundColor Cyan
Write-Host "    Domain: corp.local" -ForegroundColor Cyan
Write-Host "    Writable folder: C:\ProgramData\Tasks\" -ForegroundColor Cyan
Write-Host "    Scheduled task: BackupTask (runs every minute as SYSTEM)" -ForegroundColor Cyan
Write-Host "    Flag: C:\Windows\System32\flag_system.txt" -ForegroundColor Cyan
Write-Host "    Domain admin process running in background." -ForegroundColor Cyan