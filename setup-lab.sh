#!/bin/bash

set -e

echo "=========================================="
echo "  Red-Team Lab Setup Script"
echo "=========================================="
echo

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for Vagrant
if ! command -v vagrant &> /dev/null; then
    echo "[ERROR] Vagrant is not installed."
    echo "Please install Vagrant from https://www.vagrantup.com/downloads"
    echo "Also install VirtualBox from https://www.virtualbox.org/wiki/Downloads"
    exit 1
fi

# Check for VirtualBox
if ! command -v VBoxManage &> /dev/null; then
    echo "[WARNING] VirtualBox command-line tools not found."
    echo "Ensure VirtualBox is installed and 'VBoxManage' is in your PATH."
    echo "Continue anyway? (y/N)"
    read -r choice
    if [[ ! $choice =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Vagrant version
vagrant_version=$(vagrant --version | awk '{print $2}')
echo "[*] Found Vagrant version $vagrant_version"

# Download tools
echo
echo "[*] Downloading required tools (Chisel, Mimikatz)..."
cd "$LAB_DIR/tools"
if [ -f "download-tools.sh" ]; then
    bash download-tools.sh
else
    echo "[ERROR] download-tools.sh not found in tools/ directory."
    exit 1
fi

# Check if boxes are already present
echo
echo "[*] Checking for Vagrant boxes..."
boxes=("ubuntu/focal64" "StefanScherer/windows_2019" "StefanScherer/windows_10")
for box in "${boxes[@]}"; do
    if vagrant box list | grep -q "$box"; then
        echo "  ✓ $box"
    else
        echo "  ✗ $box (will be downloaded on 'vagrant up')"
    fi
done

# Network configuration info
echo
echo "[*] Network Configuration"
echo "  External network: 192.168.1.0/24 (host‑only)"
echo "  Internal network: 10.0.20.0/24 (internal)"
echo
echo "  The lab expects your attacker machine to be on the same host‑only"
echo "  network as WEB01's external interface (192.168.1.0/24)."
echo
echo "  If you need to configure the host‑only network in VirtualBox:"
echo "  1. Open VirtualBox → File → Host Network Manager"
echo "  2. Create a host‑only network with:"
echo "     • IPv4 Address: 192.168.1.1"
echo "     • IPv4 Network Mask: 255.255.255.0"
echo "     • DHCP server disabled"
echo "  3. Set your host's IP to 192.168.1.100 (or any free address)."
echo

# Ask if user wants to start the lab now
echo
echo "Setup complete. You can now start the lab with:"
echo "  cd '$LAB_DIR'"
echo "  vagrant up"
echo
echo "Do you want to start the lab now? (y/N)"
read -r start_choice
if [[ $start_choice =~ ^[Yy]$ ]]; then
    echo "[*] Starting Vagrant (this will download boxes and may take a while)..."
    vagrant up
else
    echo "[*] To start later, run:"
    echo "    cd '$LAB_DIR' && vagrant up"
fi

echo
echo "=========================================="
echo "  Lab setup complete!"
echo "=========================================="
echo "  Documentation:"
echo "    README.md           - Overview and quick start"
echo "    CHALLENGE.md        - Challenge scenario and hints"
echo "    docs/Attack-Walkthrough.md - Full solution"
echo "  Verification:"
echo "    ./verify.sh         - Check lab connectivity"
echo "=========================================="