#!/usr/bin/env bash
# Vérifie que l'installation correspond à la config.
#   bash ~/nixos-config/scripts/test.sh
set -u
REPO="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
WANTUSER="$(sed -n 's/^ *username = "\(.*\)";.*/\1/p' "$REPO/settings.nix" | head -n1)"

PASS=0; FAIL=0; WARN=0
ok()  { printf '  \033[32m✔\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
ko()  { printf '  \033[31m✘\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
wn()  { printf '  \033[33m!\033[0m %s\n' "$*"; WARN=$((WARN+1)); }
sec() { printf '\n\033[1m%s\033[0m\n' "$*"; }
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else ko "$d"; fi; }

sec "1. Système"
check "NixOS 26.05"               grep -q '^26\.05' /run/current-system/nixos-version
check "utilisateur = $WANTUSER"   test "$(whoami)" = "$WANTUSER"
state="$(systemctl is-system-running 2>/dev/null || true)"
case "$state" in
  running)  ok "systemd : running" ;;
  degraded) wn "systemd : degraded → systemctl --failed" ;;
  *)        ko "systemd : $state" ;;
esac
check "racine en btrfs compressé" sh -c 'findmnt -no FSTYPE,OPTIONS / | grep -q "btrfs.*compress=zstd"'
check "zram actif"                sh -c 'swapon --show | grep -q zram'

sec "2. Réseau"
check "adresse obtenue par DHCP"  sh -c 'nmcli -t -f IP4.ADDRESS dev show | grep -q .'
check "DNS = Cloudflare uniquement" sh -c '
  ns="$(grep ^nameserver /etc/resolv.conf | cut -d" " -f2)"; [ -n "$ns" ] &&
  ! echo "$ns" | grep -vqxE "1\.1\.1\.1|1\.0\.0\.1|2606:4700:4700::1111|2606:4700:4700::1001"'
check "résolution (nixos.org)"    getent hosts nixos.org
check "pare-feu actif"            systemctl is-active --quiet nftables

sec "3. Bureau"
check "session XFCE"              sh -c '[ "${XDG_CURRENT_DESKTOP:-}" = XFCE ]'
check "thème Kali-Dark"           sh -c 'xfconf-query -c xsettings -p /Net/ThemeName | grep -qx Kali-Dark'
check "bordures Kali-Dark"        sh -c 'xfconf-query -c xfwm4 -p /general/theme | grep -qx Kali-Dark'
check "icônes Flat-Remix de Kali" sh -c 'xfconf-query -c xsettings -p /Net/IconThemeName | grep -qx Flat-Remix-Blue-Dark'
check "menu au dragon"            sh -c 'xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-icon | grep -qx kali-panel-menu'
check "menu Kali (catégories)"    test -e /etc/xdg/menus/applications-merged/kali-applications.menu
check "nmap dans le menu Kali"    test -e /run/current-system/sw/share/applications/kali-nmap.desktop
check "qterminal par défaut"      grep -q '^TerminalEmulator=qterminal' "$HOME/.config/xfce4/helpers.rc"
check "zshrc de Kali"             grep -q kali-zshrc "$HOME/.zshrc"
check "outils Kali (msfconsole)"  command -v msfconsole
check "outils Kali (sqlmap)"      command -v sqlmap
check "logithèque installée"      command -v gnome-software
check "dépôt Flathub configuré"   sh -c 'flatpak remotes | grep -q flathub'
check "PipeWire"                  sh -c 'pactl info | grep -qi pipewire'
check "pilote graphique intégré chargé" sh -c 'lsmod | grep -qE "^(i915|xe|amdgpu) "'

sec "4. Allègement"
check "pas de VirtualBox"         sh -c '! command -v VirtualBox && ! lsmod | grep -q vbox'
check "pas de pilote NVIDIA"      sh -c '! lsmod | grep -q "^nvidia"'
check "Docker activé par socket"  systemctl is-active --quiet docker.socket
check "pas de démon ClamAV"       sh -c '! systemctl is-active --quiet clamav-daemon'
check "pas de serveur SSH"        sh -c '! systemctl is-active --quiet sshd'
printf '  RAM utilisée : %s\n' "$(free -h | awk '/^Mem/ {print $3 " / " $2}')"
printf '  Disque utilisé : %s\n' "$(df -h / | awk 'NR==2 {print $3 " / " $2}')"

sec "5. Comptes"
check "groupe wheel (sudo)"       sh -c 'id -nG | grep -qw wheel'
check "shell = zsh"               sh -c 'getent passwd "$(whoami)" | grep -q zsh'

printf '\n\033[1mRésultat : %d OK, %d échec(s), %d avertissement(s)\033[0m\n' "$PASS" "$FAIL" "$WARN"
[ "$FAIL" -eq 0 ]
