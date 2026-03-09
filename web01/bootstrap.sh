#!/bin/bash

set -e

echo "[*] Starting WEB01 provisioning..."

# Update and install build tools
echo "[*] Installing dependencies..."
apt-get update
apt-get install -y build-essential wget curl net-tools python3 python3-pip

# Download and compile Apache 2.4.49 (vulnerable to CVE-2021-41773)
echo "[*] Downloading Apache 2.4.49..."
cd /tmp
wget -q https://archive.apache.org/dist/httpd/httpd-2.4.49.tar.gz
tar xzf httpd-2.4.49.tar.gz
cd httpd-2.4.49

echo "[*] Configuring Apache..."
./configure --enable-cgi --enable-modules=most --prefix=/usr/local/apache2

echo "[*] Compiling Apache (this may take a few minutes)..."
make -j$(nproc)
make install

# Install our custom httpd.conf
echo "[*] Installing custom configuration..."
cp /vagrant/web01/files/httpd.conf /usr/local/apache2/conf/httpd.conf

# Create CGI script
echo "[*] Setting up CGI script..."
mkdir -p /usr/local/apache2/cgi-bin
cp /vagrant/web01/files/test.cgi /usr/local/apache2/cgi-bin/test.cgi
chmod +x /usr/local/apache2/cgi-bin/test.cgi

# Start Apache
echo "[*] Starting Apache..."
/usr/local/apache2/bin/apachectl start

# Create world-writable backup script and cron job (privilege escalation vector)
echo "[*] Creating privilege escalation vector..."
touch /usr/local/bin/backup.sh
chmod 666 /usr/local/bin/backup.sh
cat > /usr/local/bin/backup.sh << 'EOF'
#!/bin/bash
cp -r /var/www /tmp/backup
EOF

# Add cron job that runs as root every minute
echo "* * * * * root /usr/local/bin/backup.sh" >> /etc/crontab

# Store credentials for lateral movement
echo "[*] Storing domain credentials..."
echo "corp\\web_admin:P@ssw0rd" > /root/creds.txt
chmod 600 /root/creds.txt

# Create flag after root escalation
echo "[*] Creating root flag..."
echo "FLAG{WEB01_ROOT_ESCA1ATED}" > /root/flag_root.txt
chmod 600 /root/flag_root.txt

# Enable IP forwarding (optional for pivoting)
echo "[*] Enabling IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Install Python HTTP server for tool transfer
echo "[*] Setting up Python HTTP server helper..."
cat > /usr/local/bin/serve-tools << 'EOF'
#!/bin/bash
cd /vagrant/tools
python3 -m http.server 8080
EOF
chmod +x /usr/local/bin/serve-tools

# Ensure network interfaces are up
echo "[*] Configuring network interfaces..."
ip addr add 10.0.20.10/24 dev eth1 2>/dev/null || true
ip link set eth1 up

# Add helpful message
echo "[*] WEB01 provisioning complete!"
echo "    External IP: 192.168.1.10"
echo "    Internal IP: 10.0.20.10"
echo "    Apache running on port 80"
echo "    Cron job: /usr/local/bin/backup.sh (world-writable)"
echo "    Credentials: /root/creds.txt"
echo "    Flag: /root/flag_root.txt"