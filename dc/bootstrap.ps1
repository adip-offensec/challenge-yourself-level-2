# DC Bootstrap Script
Write-Host "[*] Starting Domain Controller provisioning..." -ForegroundColor Green

# Set execution policy for this session
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install AD-DS Role
Write-Host "[*] Installing Active Directory Domain Services..." -ForegroundColor Yellow
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to Domain Controller
Write-Host "[*] Promoting to Domain Controller (corp.local)..." -ForegroundColor Yellow
$domainName = "corp.local"
$safeModePassword = ConvertTo-SecureString "DSRMP@ssw0rd" -AsPlainText -Force

$params = @{
    DomainName = $domainName
    SafeModeAdministratorPassword = $safeModePassword
    InstallDns = $true
    Force = $true
    NoRebootOnCompletion = $true
}
Install-ADDSForest @params

# Wait a moment for AD to settle
Start-Sleep -Seconds 30

# Create domain users
Write-Host "[*] Creating domain users..." -ForegroundColor Yellow

# Regular user
$bobPassword = ConvertTo-SecureString "Summer2024!" -AsPlainText -Force
New-ADUser -Name "bob" -GivenName "Bob" -Surname "User" -SamAccountName "bob" -UserPrincipalName "bob@corp.local" -AccountPassword $bobPassword -Enabled $true -PasswordNeverExpires $true

# Service account / target user (Domain Admin)
$backupAdminPassword = ConvertTo-SecureString "Winter2024!" -AsPlainText -Force
New-ADUser -Name "backup_admin" -GivenName "Backup" -Surname "Admin" -SamAccountName "backup_admin" -UserPrincipalName "backup_admin@corp.local" -AccountPassword $backupAdminPassword -Enabled $true -PasswordNeverExpires $true
Add-ADGroupMember -Identity "Domain Admins" -Members "backup_admin"

# Lateral movement user (regular domain user)
$webAdminPassword = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
New-ADUser -Name "web_admin" -GivenName "Web" -Surname "Admin" -SamAccountName "web_admin" -UserPrincipalName "web_admin@corp.local" -AccountPassword $webAdminPassword -Enabled $true -PasswordNeverExpires $true

Write-Host "[*] Users created:" -ForegroundColor Green
Write-Host "    bob : Summer2024!" -ForegroundColor Cyan
Write-Host "    backup_admin (Domain Admin) : Winter2024!" -ForegroundColor Cyan
Write-Host "    web_admin : P@ssw0rd" -ForegroundColor Cyan

# Configure Windows Firewall (allow internal traffic)
Write-Host "[*] Configuring firewall..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Allow Internal ICMP" -Direction Inbound -Protocol ICMPv4 -LocalAddress 10.0.20.5 -Action Allow
New-NetFirewallRule -DisplayName "Allow Internal SMB" -Direction Inbound -Protocol TCP -LocalPort 445 -LocalAddress 10.0.20.5 -Action Allow
New-NetFirewallRule -DisplayName "Allow Internal WinRM" -Direction Inbound -Protocol TCP -LocalPort 5985 -LocalAddress 10.0.20.5 -Action Allow

# Disable Windows Defender (for lab simplicity)
Write-Host "[*] Disabling Windows Defender..." -ForegroundColor Yellow
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue

# Create final flag on desktop
Write-Host "[*] Creating domain flag..." -ForegroundColor Yellow
$flagPath = "C:\Users\Administrator\Desktop\flag_domain.txt"
"FLAG{DOMAIN_COMPROMISED_FULL_CONTROL}" | Out-File -FilePath $flagPath -Encoding ASCII

# Add helpful message
Write-Host "[*] Domain Controller provisioning complete!" -ForegroundColor Green
Write-Host "    IP: 10.0.20.5" -ForegroundColor Cyan
Write-Host "    Domain: corp.local" -ForegroundColor Cyan
Write-Host "    Flag: C:\Users\Administrator\Desktop\flag_domain.txt" -ForegroundColor Cyan
Write-Host "    Users: bob, backup_admin (Domain Admin), web_admin" -ForegroundColor Cyan