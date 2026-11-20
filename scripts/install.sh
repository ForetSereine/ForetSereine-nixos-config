#!/usr/bin/env bash
# Installation depuis l'ISO NixOS 26.05 (live, minimal ou graphique), démarrée en UEFI.
# Depuis une copie du dépôt (clé USB, ou `git clone` de TON dépôt) :
#   sudo bash scripts/install.sh
#
# Demande le nom d'utilisateur et le nom de la machine (écrits dans settings.nix),
# puis les mots de passe de l'utilisateur et de root.
# ⚠ EFFACE EN ENTIER le disque déclaré dans hosts/machine/default.nix (machine.disk.device) :
#   il est affiché avant confirmation. Tout système déjà présent dessus est perdu.
# Relançable : si le disque est déjà monté sur /mnt (installation interrompue),
# propose de reprendre sans reformater.
set -euo pipefail
# Facultatif : URL de ton propre dépôt Git, pour lancer ce script seul (sans clone)
REPO_URL="${REPO_URL:-}"
export NIX_CONFIG="experimental-features = nix-command flakes"

# Lancé depuis un clone : on s'en sert ; sinon (curl) : on clone le dépôt
SELF="$(readlink -f "$0" 2>/dev/null || true)"
REPO="$(cd "$(dirname "$SELF")/.." 2>/dev/null && pwd || true)"
if [ ! -f "$REPO/flake.nix" ]; then
  [ -n "$REPO_URL" ] || { echo "✘ Lance ce script depuis une copie du dépôt, ou définis REPO_URL." >&2; exit 1; }
  REPO=/tmp/nixos-config
  if [ -d "$REPO/.git" ]; then
    echo "→ Mise à jour de $REPO"
    nix run nixpkgs#git -- -C "$REPO" pull --ff-only
  else
    echo "→ Clonage de $REPO_URL dans $REPO"
    nix run nixpkgs#git -- clone "$REPO_URL" "$REPO"
  fi
  SELF="$REPO/scripts/install.sh"
fi

# Partitionner et installer exigent root : relance automatique via sudo
[ "$(id -u)" -eq 0 ] || exec sudo bash "$SELF" "$@"

# Secure Boot : le chargeur de démarrage de NixOS (systemd-boot) n'est pas signé.
SB="$(od -An -t u1 -j4 -N1 /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | tr -d ' ' || true)"
if [ ! -d /sys/firmware/efi ]; then
  echo "✘ L'ISO n'a pas démarré en mode UEFI : redémarre dessus en UEFI." >&2
  exit 1
elif [ "$SB" = 1 ]; then
  echo "⚠ Secure Boot est ACTIF sur cette machine."
  echo "  NixOS ne démarrera pas tant qu'il n'est pas désactivé dans le BIOS/UEFI."
  read -rp "  Continuer quand même ? Taper OUI : " ans
  [ "$ans" = "OUI" ] || exit 1
fi

# Nom d'utilisateur et nom de la machine → settings.nix
cur() { sed -n "s/^ *$1 = \"\(.*\)\";.*/\1/p" "$REPO/settings.nix" | head -n1; }
while :; do
  read -rp "Nom d'utilisateur [$(cur username)] : " NEWUSER
  NEWUSER="${NEWUSER:-$(cur username)}"
  if [[ "$NEWUSER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && [ "$NEWUSER" != root ]; then break; fi
  echo "  Minuscules, chiffres, - et _, en commençant par une lettre (et pas « root »)."
done
while :; do
  read -rp "Nom de la machine [$(cur hostname)] : " HOST
  HOST="${HOST:-$(cur hostname)}"
  if [[ "$HOST" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then break; fi
  echo "  Lettres, chiffres et - (pas au début ni à la fin), 63 caractères max."
done
printf '%s\n' \
  "# Utilisateur et nom de la machine." \
  "# scripts/install.sh les demande et réécrit ce fichier à l'installation ;" \
  "# on peut aussi les changer à la main (puis \`git add settings.nix\` et \`rebuild\`)." \
  "{" \
  "  username = \"$NEWUSER\";" \
  "  hostname = \"$HOST\";" \
  "}" > "$REPO/settings.nix"
echo "✔ $NEWUSER㉿$HOST"

# Régénère la détection du matériel (sans les montages, gérés par disko)
read -rp "Régénérer hosts/machine/hardware-configuration.nix pour cette machine ? [O/n] " r
if [ "${r:-O}" != n ]; then
  nixos-generate-config --no-filesystems --show-hardware-config > "$REPO/hosts/machine/hardware-configuration.nix"
  echo "✔ Matériel détecté"
fi
# Un flake ne voit que les fichiers suivis par Git
if [ -d "$REPO/.git" ]; then nix run nixpkgs#git -- -C "$REPO" add -A; fi

DISK="$(nix eval --raw "$REPO#nixosConfigurations.$HOST.config.machine.disk.device")"
DATA=()
echo "Host : $HOST"
echo "Disque (sera effacé en entier) : $DISK"
echo
for d in "$DISK" "${DATA[@]}"; do
  [ -e "$d" ] || { echo "✘ Disque introuvable : $d (corrige hosts/machine/default.nix)" >&2; exit 1; }
  lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS "$d"
done

# Garde-fou : jamais depuis un système installé sur un disque cible
# (seuls des montages sous /mnt, laissés par une installation interrompue, sont admis)
MOUNTS=""
for d in "$DISK" "${DATA[@]}"; do
  m="$(lsblk -nro MOUNTPOINTS "$d" | grep . || true)"
  if echo "$m" | grep -v '^$' | grep -qv '^/mnt'; then
    echo "✘ $d est monté hors de /mnt :" >&2
    echo "$m" >&2
    echo "  Ce script doit tourner depuis l'ISO live (prompt nixos@nixos), pas depuis un système installé." >&2
    exit 1
  fi
  MOUNTS="$MOUNTS$m"
done

FORMAT=1
if mountpoint -q /mnt && [ -n "$MOUNTS" ]; then
  read -rp "Le disque est déjà monté sur /mnt (installation interrompue). Reprendre SANS reformater ? [O/n] " r
  [ "${r:-O}" = "n" ] || FORMAT=0
fi

if [ "$FORMAT" -eq 1 ]; then
  read -rp "Tout effacer sur le disque ci-dessus ? Taper OUI : " ans
  [ "$ans" = "OUI" ] || exit 1
  swapoff /mnt/.swapfile 2>/dev/null || true
  umount -R /mnt 2>/dev/null || true
  # 0. Effacement complet AVANT disko : les anciennes signatures (NTFS de Windows,
  #    ext4…) peuvent survivre sous les nouvelles partitions et faire échouer le
  #    montage (« NTFS signature is missing » sur la partition btrfs).
  for d in "$DISK" "${DATA[@]}"; do
    echo "→ Effacement de $d"
    for p in $(lsblk -nrpo NAME "$d" | tail -n +2); do wipefs -af "$p" >/dev/null || true; done
    wipefs -af "$d" >/dev/null
    blkdiscard -f "$d" 2>/dev/null || dd if=/dev/zero of="$d" bs=1M count=64 status=none
  done
  partprobe 2>/dev/null || true
  rm -f /run/blkid/blkid.tab* # cache blkid périmé
  udevadm settle
  # Sur certaines ISO, `mount` sans -t ne reconnaît pas la partition btrfs et
  # tente NTFS (« NTFS signature is missing ») : or disko monte sans -t. On lui
  # fait essayer btrfs puis vfat en premier (fichier propre à l'ISO, en RAM).
  if ! grep -qx btrfs /etc/filesystems 2>/dev/null; then
    { printf 'btrfs\nvfat\n'; cat /etc/filesystems 2>/dev/null || echo '*'; } > /tmp/filesystems.new
    mv /tmp/filesystems.new /etc/filesystems
  fi
  # 1. Partitionnement + formatage + montage sur /mnt
  nix run github:nix-community/disko/latest -- --mode destroy,format,mount --yes-wipe-all-disks --flake "$REPO#$HOST"
fi

# Sur l'ISO live, / et /tmp sont en RAM : on construit et on swappe sur le disque
# pour ne pas saturer la mémoire (paquets non libres décompressés/construits localement)
mkdir -p /mnt/tmp
chmod 1777 /mnt/tmp
export TMPDIR=/mnt/tmp
if ! swapon --show=NAME --noheadings | grep -qx /mnt/.swapfile; then
  [ -f /mnt/.swapfile ] || btrfs filesystem mkswapfile --size 8g /mnt/.swapfile
  swapon /mnt/.swapfile
fi

# 2. Installation (les mots de passe sont demandés juste après)
#    Parallélisme limité pour ne pas saturer la RAM
nixos-install --flake "$REPO#$HOST" --no-root-passwd --max-jobs 2 --cores 2

# 3. Copie du dépôt dans le home de l'utilisateur
U="$(nix eval --raw "$REPO#nixosConfigurations.$HOST.config.users.users" --apply 'u: builtins.head (builtins.filter (n: u.${n}.isNormalUser) (builtins.attrNames u))')"
mkdir -p "/mnt/home/$U"
rm -rf "/mnt/home/$U/nixos-config"
cp -a "$REPO" "/mnt/home/$U/nixos-config"
nixos-enter --root /mnt -c "chown -R $U:users /home/$U/nixos-config"

# 3b. Mots de passe (absents du dépôt public) : redemandés tant qu'ils ne
#     correspondent pas. Déjà définis (installation reprise) : on peut passer.
for who in "$U" root; do
  if nixos-enter --root /mnt -c "passwd -S $who" 2>/dev/null | awk '{print $2}' | grep -q '^P$'; then
    read -rp "Le mot de passe de $who existe déjà. Le changer ? [o/N] " r
    [ "${r:-N}" = o ] || continue
  fi
  echo "→ Mot de passe de $who"
  until nixos-enter --root /mnt -c "passwd $who"; do echo "  Réessaie."; done
done

# 4. Nettoyage : swap et dossier temporaires
swapoff /mnt/.swapfile && rm -f /mnt/.swapfile
rm -rf /mnt/tmp/*

echo "✔ Installé. Retire l'ISO puis : reboot"
