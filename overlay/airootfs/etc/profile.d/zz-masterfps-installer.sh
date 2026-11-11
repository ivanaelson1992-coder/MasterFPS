# Inicia o instalador do MasterFPSOS no primeiro login da ISO live (tty1).
# Depois do primeiro acesso, use: masterfps-install
if [[ $(tty 2>/dev/null) == /dev/tty1 && ! -e /run/masterfps-installer-ran && -x /usr/local/bin/masterfps-install ]]; then
  touch /run/masterfps-installer-ran
  clear
  /usr/local/bin/masterfps-install
fi
