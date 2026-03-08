#!/bin/bash
# Restore PRoot Ubuntu XFCE setup on a new phone
# Run this script from Termux (NOT inside PRoot)
set -e

echo "=== PRoot Ubuntu XFCE Migration ==="
echo ""

# --- Step 1: Termux packages ---
echo "[1/7] Installing Termux packages..."
pkg update -y
pkg install -y x11-repo
pkg install -y proot-distro pulseaudio virglrenderer-android termux-x11-nightly \
    termux-am git openssh zenity

# --- Step 2: Install Ubuntu in PRoot ---
echo "[2/7] Installing Ubuntu PRoot distribution..."
proot-distro install ubuntu

# --- Step 3: Install Ubuntu packages inside PRoot ---
echo "[3/7] Installing Ubuntu packages (this will take a while)..."
proot-distro login ubuntu -- bash -c '
    apt update && apt upgrade -y
    DEBIAN_FRONTEND=noninteractive apt install -y \
        xubuntu-desktop \
        build-essential git vim tmux curl wget \
        dropbear openssh-server \
        nodejs npm \
        ripgrep htop net-tools traceroute telnet \
        chromium-browser firefox remmina \
        locales sudo \
        php php-gd apache2
    # Set locale
    locale-gen en_US.UTF-8
'

# --- Step 4: Create user ---
echo "[4/7] Setting up user akulov..."
proot-distro login ubuntu -- bash -c '
    if ! id akulov 2>/dev/null; then
        useradd -m -s /bin/bash -G sudo akulov
        echo "akulov ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/akulov
    fi
    echo "Set password for akulov:"
    passwd akulov
'

# --- Step 5: Restore backup ---
BACKUP_FILE="$HOME/storage/downloads/proot-home-backup.tar.gz"
if [ ! -f "$BACKUP_FILE" ]; then
    BACKUP_FILE="/storage/self/primary/Download/proot-home-backup.tar.gz"
fi
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: proot-home-backup.tar.gz not found in Downloads!"
    echo "Copy it to Downloads and re-run this step manually:"
    echo "  ROOTFS=\$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
    echo "  tar xzf /storage/self/primary/Download/proot-home-backup.tar.gz -C \$ROOTFS"
    exit 1
fi
echo "[5/7] Restoring home directory and configs from backup..."
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
tar xzf "$BACKUP_FILE" -C "$ROOTFS"
echo "  Restored: home/akulov/, etc/dropbear/, usr/local/bin/tmux"

# --- Step 6: Build and install proot-compat ---
echo "[6/7] Building proot-compat (fakechown.so)..."
proot-distro login ubuntu --user akulov -- bash -c '
    cd ~
    if [ ! -d proot-compat ]; then
        git clone https://github.com/andrewak54/proot-compat.git
    fi
    cd proot-compat
    make
    make install
'

# --- Step 7: Install Termux shortcuts ---
echo "[7/7] Installing Termux shortcuts..."
mkdir -p ~/.shortcuts
if [ -f "$ROOTFS/home/akulov/proot-compat/uX11" ]; then
    cp "$ROOTFS/home/akulov/proot-compat/uX11" ~/.shortcuts/uX11
    chmod +x ~/.shortcuts/uX11
    echo "  Installed uX11 shortcut"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Remaining manual steps:"
echo "  1. Install Rust:  proot-distro login ubuntu --user akulov"
echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
echo "  2. Rebuild projects: cd ~/DCFW_editor && cargo build"
echo "  3. Grant storage permission to Termux if needed"
echo "  4. Run uX11 from Termux:Widget or: bash ~/.shortcuts/uX11"
echo ""
