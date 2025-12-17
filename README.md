# Pre-chroot Arch Script
Arch script
To install and run the script:
`curl -o script.sh https://raw.githubusercontent.com/imbadwithnamestoo/imbad-s-pre-chroot-script/refs/heads/main/run.sh`
To make the script executable: 
`chmod +x script.sh`
And to run it: 
`./script.sh`

This script will ask for the target disk and the setup you want. If you choose minimal the ONLY packages you will get are `base linux linux-firmware`.
A full installation will give the default packages of `base linux linux-firmware base-devel networkmanager grub efibootmgr nano`

The script will also give options like whether you want nvidia drivers `nvidia nvidia-utils` and your preferred display server (xorg/wayland)
