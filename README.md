# MasterFPSOS (Arch + kernel OGC 7.x + KDE Plasma, em pt-BR)

Base Arch Linux (sem Debian) com o kernel **OGC (Open Gaming Collective)** do repositório `[ogc]` (`linux-ogc`, série 7.x).

## Gerar a ISO
Em um Arch Linux (PC, VM ou container) com internet e ~15 GB livres:
```bash
sudo ./build.sh        # resultado em out/masterfps-*.iso
```

## Instalar
Na ISO: `archinstall` → no fim escolha **chroot** e rode:
```bash
cp /usr/local/bin/masterfps-postinstall /mnt/usr/local/bin/
arch-chroot /mnt masterfps-postinstall
```

## Visual e identidade "MasterFPSOS"
O nome **MasterFPSOS** aparece em: `os-release` (nome do sistema), hostname, menu do **GRUB** (e systemd-boot), menus de boot da ISO, **tela de login** (tema SDDM próprio), tela de bloqueio e na marca do tema.
- **Papel de parede**: fênix em arte vetorial com o texto "MasterFPS" (`assets/fenix-masterfps.svg`; prévia em `assets/fenix-masterfps-preview.png`). Usado no desktop, na tela de bloqueio, no login e como fundo do GRUB.
- **Desktop**: KDE Plasma 6 com tema claro, cantos arredondados, ícones Papirus, fonte Inter e dock central.
- A fênix é uma **ilustração original** (não existe fênix "real"; é um animal mitológico, e não uso foto nem arte de terceiros). O visual é inspirado em interfaces modernas, mas não é cópia do HarmonyOS.

## Tudo em português do Brasil
Idioma `pt_BR.UTF-8`, teclado ABNT2, fuso America/Sao_Paulo, Firefox e corretor ortográfico em pt-BR, manuais em português.

## Desempenho (CPU, GPU e latência)
- **Modo Gamer** (`sudo masterfps-boost on|off|status`, ligado no boot): CPU em `performance` com clock mínimo travado no máximo, turbo/boost ligado, latência de despertar da CPU em 0 (sem sono profundo), GPU AMD em `high`, NVIDIA em modo persistente
- **GPU**: cache de shaders de 12 GB, otimizações de driver (Mesa/NVIDIA), `nvidia_drm modeset`, PowerMizer no máximo, `amdgpu ppfeaturemask` liberado
- **Input lag**: mouse/teclado USB com polling de 1 ms, compositor KWin em baixa latência com *tearing* permitido em tela cheia, `threadirqs`, `preempt=full`, `nowatchdog`
- **Sistema**: kernel OGC, escalonador `scx_lavd`, ZRAM, sysctl, BBR, escalonador de disco por tipo
- Opcional: `mitigations=off` (o script pergunta; mais FPS, menos segurança)

## Rodar .exe
Dois cliques ou `masterfps-run jogo.exe` (Proton-GE via umu-launcher, com Wine-Staging de reserva). Também `masterfps-apps` para Bottles, ProtonUp-Qt e Heroic.

## Avisos honestos
- **"100% de FPS" e "0 input lag" não existem.** O que o sistema faz é remover limitadores de software para chegar perto do limite do seu hardware. O FPS máximo depende da CPU/GPU e do jogo.
- "Extrair 100% da CPU" significa clock máximo e sem economia de energia: mais calor, mais consumo e ventoinhas mais altas. Em notebook, use `sudo masterfps-boost off` na bateria.
- Jogos com anticheat de kernel (ex.: Valorant) não rodam no Linux. Confira em protondb.com e areweanticheatyet.com.
- NVIDIA: o driver DKMS pode não compilar no kernel 7.x; nesse caso inicie pelo kernel `linux` de reserva.
- **Não consegui testar** a geração da ISO nem a instalação (meu ambiente não tem internet). Os scripts e arquivos de tema passaram na verificação de sintaxe, mas o layout do dock e algumas chaves do KWin podem precisar de ajuste na primeira execução.
