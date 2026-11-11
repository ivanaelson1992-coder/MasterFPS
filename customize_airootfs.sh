#!/usr/bin/env bash
# Executado pelo mkarchiso dentro do airootfs, depois do pacstrap.
# Evita conflito com arquivos de propriedade dos pacotes (filesystem, linux-ogc).
set -euo pipefail

install -Dm644 /usr/local/share/masterfps/os-release /usr/lib/os-release
install -Dm644 /usr/local/share/masterfps/issue /etc/issue
install -Dm644 /usr/local/share/masterfps/linux-ogc.preset /etc/mkinitcpio.d/linux-ogc.preset
