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
