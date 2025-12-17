#!/bin/bash
# Arch pre-chroot setup script with interactive options
# WARNING: This will erase the selected disk!

set -e

echo "=== Imbad's Pre-chroot Arch Script ==="

echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"

read -rp "Enter the target disk (e.g., sda): " TARGET_DISK
DISK="/dev/$TARGET_DISK"

read -rp "WARNING: All data on $DISK will be erased. Proceed? (yes/no): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && { echo "Aborted."; exit 1; }

read -rp "Do you want a swap partition? (y/n): " USE_SWAP
if [[ "$USE_SWAP" =~ ^[Yy]$ ]]; then
    read -rp "Enter swap size (e.g., 2G, 512M): " SWAP_SIZE
fi

EFI_SIZE="+1G"
ROOT_LABEL="archroot"
EFI_LABEL="EFI"
SWAP_LABEL="swap"

echo "Wiping disk $DISK..."
sgdisk --zap-all $DISK
dd if=/dev/zero of=$DISK bs=512 count=2048 2>/dev/null || true
wipefs -a $DISK

echo "Creating EFI partition..."
sgdisk -n 1:0:$EFI_SIZE -t 1:ef00 -c 1:$EFI_LABEL $DISK

# Only create swap if user wants it
if [[ "$USE_SWAP" =~ ^[Yy]$ ]]; then
    echo "Creating Swap partition..."
    sgdisk -n 2:0:+$SWAP_SIZE -t 2:8200 -c 2:$SWAP_LABEL $DISK
    ROOT_PART_NUM=3
else
    ROOT_PART_NUM=2
fi

echo "Creating Root partition (rest of disk)..."
sgdisk -n $ROOT_PART_NUM:0:0 -t 3:8300 -c $ROOT_LABEL $DISK

sgdisk -p $DISK

echo "Formatting EFI..."
mkfs.fat -F32 ${DISK}1

# Only format swap if created
if [[ "$USE_SWAP" =~ ^[Yy]$ ]]; then
    echo "Formatting Swap..."
    mkswap ${DISK}2
    swapon ${DISK}2
fi

echo "Formatting Root..."
mkfs.ext4 ${DISK}${ROOT_PART_NUM}

echo "Mounting root..."
mount ${DISK}${ROOT_PART_NUM} /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo ""
echo "=== Pacstrap options ==="

read -rp "Install minimal or full system? (minimal/full): " INSTALL_TYPE
if [[ "$INSTALL_TYPE" == "minimal" ]]; then
    BASE_PKGS="base linux linux-firmware"
else
    BASE_PKGS="base linux linux-firmware base-devel networkmanager grub efibootmgr nano"
    
    # Only ask these if full system is chosen
    read -rp "Install Nvidia drivers? (y/n): " INSTALL_NVIDIA
    if [[ "$INSTALL_NVIDIA" =~ ^[Yy]$ ]]; then
        BASE_PKGS+=" nvidia nvidia-utils"
    fi

    read -rp "Choose display server (xorg/wayland): " DISPLAY_SERVER
    if [[ "$DISPLAY_SERVER" == "xorg" ]]; then
        BASE_PKGS+=" xorg xorg-xinit"
    elif [[ "$DISPLAY_SERVER" == "wayland" ]]; then
        BASE_PKGS+=" wayland wayland-protocols"
    fi
fi

echo ""
echo "Installing packages: $BASE_PKGS"
pacstrap /mnt $BASE_PKGS

echo "Running genfstab..."
genfstab -U /mnt > /mnt/etc/fstab

sleep 2
clear

echo ""
echo "=== Pre-chroot setup complete! ==="
lsblk
