#!/usr/bin/env bash
# MasterFPSOS - gera a ISO (base Arch + kernel OGC 7.x)
# Rode em Arch Linux (PC, VM, WSL-Arch ou container) com internet:  sudo ./build.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Use: sudo ./build.sh"; exit 1; }
cd "$(dirname "$0")"

KEY=F79100EF8C802DAB81C323BB8EEA5962FE510E19
ASC=https://raw.githubusercontent.com/OpenGamingCollective/ogc-arch-packaging/main/ogc.asc

pacman -Sy --needed --noconfirm archiso curl

# Chave do repositorio OGC (assina o kernel linux-ogc)
pacman-key --init 2>/dev/null || true
pacman-key --recv-keys "$KEY" 2>/dev/null || curl -fsSL "$ASC" | pacman-key --add -
pacman-key --lsign-key "$KEY"

# Perfil base do archiso
rm -rf profile work out
cp -r /usr/share/archiso/configs/releng profile
P=profile

# Repositorio OGC no pacman do build
printf '\n[ogc]\nServer = https://pacman.opengamingcollective.org\n' >> $P/pacman.conf

# Kernel: troca "linux" por "linux-ogc"
sed -i '/^linux$/d;/^linux-headers$/d' $P/packages.x86_64
printf 'linux-ogc\nlinux-ogc-headers\nlinux-firmware\n' >> $P/packages.x86_64

# Bootloaders apontam para o kernel OGC
grep -rlE 'vmlinuz-linux|initramfs-linux' $P/grub $P/syslinux $P/efiboot 2>/dev/null | while read -r f; do
  sed -i 's/vmlinuz-linux\b/vmlinuz-linux-ogc/g; s/initramfs-linux\.img/initramfs-linux-ogc.img/g' "$f"
done

# Nome MasterFPSOS nos menus de boot da ISO (GRUB, syslinux, systemd-boot)
grep -rl 'Arch Linux' $P/grub $P/syslinux $P/efiboot 2>/dev/null | while read -r f; do
  sed -i 's/Arch Linux/MasterFPSOS/g' "$f"
done

# Marca MasterFPSOS
sed -i 's/^iso_name=.*/iso_name="masterfpsos"/' $P/profiledef.sh
sed -i 's/^iso_label=.*/iso_label="MASTERFPSOS_$(date +%Y%m)"/' $P/profiledef.sh
sed -i 's/^iso_publisher=.*/iso_publisher="MasterFPSOS"/' $P/profiledef.sh
sed -i 's/^iso_application=.*/iso_application="MasterFPSOS - Gaming Linux"/' $P/profiledef.sh
sed -i 's|^file_permissions=(|file_permissions=(\n  ["/usr/local/bin/masterfps-postinstall"]="0:0:755"|' $P/profiledef.sh

# Arquivos do MasterFPS dentro da ISO
rm -f $P/airootfs/etc/mkinitcpio.d/linux.preset
cp -r overlay/airootfs/. $P/airootfs/
cp customize_airootfs.sh $P/airootfs/root/customize_airootfs.sh
chmod +x $P/airootfs/root/customize_airootfs.sh

# Shell do root na live = bash (para o instalador abrir sozinho no login)
sed -i 's|/usr/bin/zsh$|/bin/bash|' $P/airootfs/etc/passwd

# Instalador automático da ISO
cp install/masterfps-install $P/airootfs/usr/local/bin/masterfps-install
chmod +x $P/airootfs/usr/local/bin/masterfps-install

cp postinstall/masterfps-postinstall $P/airootfs/usr/local/bin/masterfps-postinstall
chmod +x $P/airootfs/usr/local/bin/masterfps-postinstall

mkarchiso -v -w work -o out $P
ls -1 out/*.iso && echo "PRONTO: ISO em ./out/"
