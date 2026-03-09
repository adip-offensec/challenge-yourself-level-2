#!/bin/bash

set -e

echo "[*] Lab Verification Script"
echo

# Check Vagrant status
echo "[*] Checking Vagrant status..."
vagrant status | grep -E "(web01|dc|workstation)" | while read line; do
    echo "    $line"
done

echo
echo "[*] Testing WEB01..."
vagrant ssh web01 -c "curl -s -I http://localhost 2>/dev/null | head -1" || echo "    Apache not responding"

echo
echo "[*] Testing internal connectivity from WEB01..."
vagrant ssh web01 -c "ping -c 2 10.0.20.5 2>&1 | grep 'bytes from'" && echo "    DC reachable"
vagrant ssh web01 -c "ping -c 2 10.0.20.20 2>&1 | grep 'bytes from'" && echo "    WORKSTATION reachable"

echo
echo "[*] Checking flags..."
if vagrant ssh web01 -c "sudo cat /root/flag_root.txt 2>/dev/null" 2>/dev/null; then
    echo "    WEB01 flag present"
else
    echo "    WEB01 flag missing"
fi

echo
echo "[*] Verification complete."
echo "    For full testing, follow the Attack Walkthrough."
echo "    Ensure your attacker machine is on 192.168.1.0/24."