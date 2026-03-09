#!/bin/bash
# Restore PRoot Ubuntu XFCE setup on a new phone
# Run: bash restore-on-new-phone.sh [step]
# Steps: 1=termux-pkgs 2=ubuntu-install 3=ubuntu-pkgs 4=user 5=restore 6=proot-compat 7=shortcuts
# Without argument, runs all steps. Each step is safe to re-run.

STEP="${1:-all}"
ROOTFS="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

run_step() { [ "$STEP" = "all" ] || [ "$STEP" = "$1" ]; }

# --- Step 1: Termux packages ---
if run_step 1; then
    echo "[1/7] Installing Termux packages..."
    pkg update -y
    pkg install -y x11-repo
    pkg install -y proot-distro pulseaudio virglrenderer-android termux-x11-nightly \
        termux-am git openssh zenity
    echo "[1/7] Done."
fi

# --- Step 2: Install Ubuntu in PRoot ---
if run_step 2; then
    echo "[2/7] Installing Ubuntu PRoot distribution..."
    if proot-distro list 2>/dev/null | grep -q "ubuntu.*installed"; then
        echo "  Ubuntu already installed, skipping."
    else
        proot-distro install ubuntu
    fi
    echo "[2/7] Done."
fi

# --- Step 3: Install Ubuntu packages inside PRoot ---
if run_step 3; then
    echo "[3/7] Installing Ubuntu packages (this will take a while)..."
    proot-distro login ubuntu -- bash -c '
        dpkg --configure -a 2>/dev/null
        apt-get -f install -y 2>/dev/null
        apt update
        DEBIAN_FRONTEND=noninteractive apt install -y \
            xubuntu-desktop \
            build-essential git vim tmux curl wget \
            dropbear \
            nodejs npm \
            ripgrep htop net-tools traceroute telnet \
            chromium-browser firefox remmina \
            locales sudo \
            php php-gd apache2
        locale-gen en_US.UTF-8
    '
    echo "[3/7] Done."
fi

# --- Step 4: Create user ---
if run_step 4; then
    echo "[4/7] Setting up user akulov..."
    proot-distro login ubuntu -- bash -c '
        if ! id akulov 2>/dev/null; then
            useradd -m -s /bin/bash -G sudo akulov
            echo "akulov ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/akulov
        else
            echo "User akulov already exists."
        fi
        echo "Set password for akulov:"
        passwd akulov
    '
    echo "[4/7] Done."
fi

# --- Step 5: Restore backup ---
if run_step 5; then
    BACKUP_FILE="/storage/self/primary/Download/proot-home-backup.tar.gz"
    [ -f "$BACKUP_FILE" ] || BACKUP_FILE="$HOME/storage/downloads/proot-home-backup.tar.gz"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "ERROR: proot-home-backup.tar.gz not found in Downloads!"
        exit 1
    fi
    echo "[5/7] Restoring home directory and configs from backup..."
    tar xzf "$BACKUP_FILE" -C "$ROOTFS"
    echo "  Restored: home/akulov/, etc/dropbear/, usr/local/bin/tmux"
    echo "[5/7] Done."
fi

# --- Step 6: Build and install proot-compat ---
if run_step 6; then
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
    echo "[6/7] Done."
fi

# --- Step 7: Install Termux shortcuts ---
if run_step 7; then
    echo "[7/7] Installing Termux shortcuts..."
    mkdir -p ~/.shortcuts
    if [ -f "$ROOTFS/home/akulov/proot-compat/uX11" ]; then
        cp "$ROOTFS/home/akulov/proot-compat/uX11" ~/.shortcuts/uX11
        chmod +x ~/.shortcuts/uX11
        echo "  Installed uX11 shortcut"
    fi
    echo "[7/7] Done."
fi

echo ""
echo "=== Done ==="
echo "Remaining manual steps:"
echo "  1. Install Rust: proot-distro login ubuntu --user akulov"
echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
echo "  2. Rebuild projects: cd ~/DCFW_editor && cargo build"
echo "  3. Run uX11: bash ~/.shortcuts/uX11"
