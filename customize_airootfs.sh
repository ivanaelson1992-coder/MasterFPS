#!/usr/bin/env bash
# Executado pelo mkarchiso dentro do airootfs, depois do pacstrap.
# Evita conflito com arquivos de propriedade dos pacotes (filesystem, linux-ogc).
set -euo pipefail

install -Dm644 /usr/local/share/masterfps/os-release /usr/lib/os-release
install -Dm644 /usr/local/share/masterfps/issue /etc/issue
install -Dm644 /usr/local/share/masterfps/linux-ogc.preset /etc/mkinitcpio.d/linux-ogc.preset

# Shell do root na live = bash (o pacote 'filesystem' sobrescreve o /etc/passwd
# do airootfs, então a troca precisa acontecer aqui, após o pacstrap).
usermod -s /bin/bash root 2>/dev/null || sed -i 's|/usr/bin/zsh$|/bin/bash|' /etc/passwd

# Garante o auto-início do instalador mesmo se o shell continuar zsh
# (/etc/zprofile é lido por shells de login zsh; /etc/profile.d por bash).
cat >> /etc/zprofile <<'ZEOF'

# MasterFPSOS: inicia o instalador no primeiro login da live (tty1)
if [[ $(tty 2>/dev/null) == /dev/tty1 && ! -e /run/masterfps-installer-ran && -x /usr/local/bin/masterfps-install ]]; then
  touch /run/masterfps-installer-ran
  clear
  /usr/local/bin/masterfps-install
fi
ZEOF

# ================= SESSÃO LIVE GRÁFICA: Plasma com login automático + instalador
useradd -m -s /bin/bash masterfps 2>/dev/null || true
echo 'masterfps ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/99-masterfps-live
chmod 440 /etc/sudoers.d/99-masterfps-live

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<'EOF'
[Autologin]
User=masterfps
Session=plasma
Relogin=false
EOF

systemctl enable sddm
systemctl mask getty@tty1

# O instalador abre sozinho na área de trabalho; há também um ícone no Desktop
mkdir -p /etc/xdg/autostart /home/masterfps/Desktop
cat > /etc/xdg/autostart/masterfps-install.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Instalar o MasterFPSOS
Exec=konsole -e sudo /usr/local/bin/masterfps-install
Icon=system-installer
Terminal=false
EOF
cat > /home/masterfps/Desktop/Instalar-MasterFPSOS.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Instalar o MasterFPSOS
Name[pt_BR]=Instalar o MasterFPSOS
Comment[pt_BR]=Instala o MasterFPSOS no computador
Exec=konsole -e sudo /usr/local/bin/masterfps-install
Icon=system-installer
Terminal=false
Categories=System;
EOF
chmod +x /home/masterfps/Desktop/Instalar-MasterFPSOS.desktop
chown -R masterfps:masterfps /home/masterfps/Desktop
