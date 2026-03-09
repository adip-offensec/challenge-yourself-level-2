#!/bin/bash

# Download tools needed for the lab

set -e

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[*] Downloading tools to $TOOLS_DIR..."

# Chisel (Linux amd64)
if [ ! -f "$TOOLS_DIR/chisel_linux_amd64" ]; then
    echo "[*] Downloading chisel (Linux)..."
    wget -q -O "$TOOLS_DIR/chisel_linux_amd64.gz" https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_linux_amd64.gz
    gunzip -f "$TOOLS_DIR/chisel_linux_amd64.gz"
    chmod +x "$TOOLS_DIR/chisel_linux_amd64"
fi

# Chisel (Windows amd64)
if [ ! -f "$TOOLS_DIR/chisel_windows_amd64.exe" ]; then
    echo "[*] Downloading chisel (Windows)..."
    wget -q -O "$TOOLS_DIR/chisel_windows_amd64.exe.gz" https://github.com/jpillora/chisel/releases/download/v1.10.1/chisel_1.10.1_windows_amd64.gz
    gunzip -f "$TOOLS_DIR/chisel_windows_amd64.exe.gz"
fi

# Mimikatz (trunk)
if [ ! -f "$TOOLS_DIR/mimikatz_trunk.zip" ]; then
    echo "[*] Downloading Mimikatz..."
    wget -q -O "$TOOLS_DIR/mimikatz_trunk.zip" https://github.com/gentilkiwi/mimikatz/releases/latest/download/mimikatz_trunk.zip
fi

echo "[*] Tools downloaded."
echo "    chisel_linux_amd64: SOCKS proxy (Linux)"
echo "    chisel_windows_amd64.exe: SOCKS proxy (Windows)"
echo "    mimikatz_trunk.zip: Credential dumping tool"