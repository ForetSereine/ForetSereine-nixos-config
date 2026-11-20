# nixos-config — NixOS avec l'interface de Kali Linux

🇫🇷 Français · [🇬🇧 English](README.md)

NixOS 26.05 qui ressemble **vraiment** à Kali Linux : le bureau est construit à partir des
paquets officiels de Kali (`kali-themes`, `kali-menu`, `kali-defaults`), avec en plus
**tous les outils de Kali disponibles dans nixpkgs** (~270) et une **logithèque** pour
installer des applications en un clic.

Pour une machine sans carte graphique dédiée, avec un seul NVMe.
Dérivé de la config de [joblinours](https://github.com/joblinours/NixOS_config).

| Réglage | Valeur |
|---|---|
| Machine / utilisateur | choisis à l'installation (par défaut `kali`㉿`kali`, comme sur Kali), stockés dans `settings.nix` |
| Bureau | XFCE avec l'interface de Kali : thème Kali-Dark, menu au dragon et catégories Kali, qterminal, zsh de Kali, écran de connexion Kali |
| Outils | ~270 outils de Kali, rangés dans les catégories du menu (01 - Reconnaissance → 16 - Services) |
| Applications | Logithèque « Logiciels » + Flathub (Discord, Spotify, OBS…) |
| Réseau | DHCP ; DNS Cloudflare forcés (1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, ::1001) |
| Disque | un NVMe, btrfs compressé zstd, swap compressé en RAM (zram) |
| Graphique | puce intégrée Intel ou AMD (Mesa), aucun pilote propriétaire |

## Structure

```
flake.nix               inputs (nixpkgs, home-manager, disko)
settings.nix            nom d'utilisateur et nom de la machine (écrits par install.sh)
hosts/machine/          default.nix (disque, options) + hardware-configuration.nix
modules/
  common.nix            nix, démarrage, langue, clavier, comptes, allègement
  network.nix           DHCP + DNS Cloudflare
  disk.nix              partitionnement du NVMe
  desktop.nix           son, Bluetooth, pilote graphique intégré, polices
  xfce.nix              XFCE + interface Kali (thème, menu, réglages par défaut, LightDM)
  software-center.nix   logithèque « Logiciels » + Flathub
  kali-tools.nix        tous les outils de Kali présents dans nixpkgs, par catégorie
  pentest.nix, dfir.nix outils de sécurité de base
  virtualisation.nix    Docker, démarré à la demande
  security.nix          pare-feu (rien n'entre)
  apps.nix              Firefox, mpv, lecteur PDF…
  network-tools.nix     dig, traceroute, mtr, httpie, WireGuard, OpenVPN…
  dev.nix               C/C++, Rust, Python, Node, Go, Java
  auto-upgrade.nix      mise à jour hebdomadaire
home/user.nix           zsh (le .zshrc de Kali), alias, git
home/xfce.nix           barre de Kali, thème, fond d'écran, raccourcis
pkgs/kali-themes        paquet kali-themes de Kali (thèmes, icônes, fonds, réglages)
pkgs/kali-menu          paquet kali-menu de Kali (catégories 01 - Reconnaissance…)
pkgs/kali-zshrc         le .zshrc de Kali (paquet kali-defaults)
scripts/                install.sh, test.sh
```

## Avant d'installer

1. **Le NVMe est effacé en entier.** Tout système déjà installé dessus disparaît : sauvegarde d'abord ce que tu veux garder.
2. **Secure Boot doit être désactivé** dans le BIOS/UEFI. Le chargeur de démarrage de NixOS n'est pas signé : avec Secure Boot actif, la machine refuse de démarrer. `install.sh` le détecte et prévient.
3. Clavier : la config est en AZERTY **belge** (`be`). Pour un AZERTY français, remplace `be-latin1` et `be` par `fr` dans `modules/common.nix`.
4. Le **nom d'utilisateur** et le **nom de la machine** sont demandés par `install.sh` (stockés dans `settings.nix`, modifiables ensuite).
5. **Espace disque** : compter environ 25 Go non compressés (≈ 12 Go pour le système, ≈ 12 Go pour les outils Kali) ; moins sur le disque grâce à la compression btrfs. Sans les outils Kali : `machine.kaliTools.enable = false;` dans `hosts/machine/default.nix`.

## Installer

Démarre sur l'ISO NixOS 26.05 en mode UEFI, connecte le réseau (`nmtui` pour le wifi), récupère ce dépôt (`git clone` ou clé USB), puis :

```bash
sudo bash scripts/install.sh
```

Le script demande le **nom d'utilisateur** et le **nom de la machine**, détecte le matériel, affiche le disque qui sera effacé, demande `OUI`, installe, **demande les mots de passe de l'utilisateur et de `root`** (aucun mot de passe n'est stocké dans le dépôt), puis copie la config dans `~/nixos-config`. Redémarre, connecte-toi avec ton utilisateur, et lance :

```bash
bash ~/nixos-config/scripts/test.sh
```

**Machine déjà installée avec une ancienne version de cette config** : avant le premier `rebuild`, mets ton nom d'utilisateur et ton nom de machine actuels dans `settings.nix` (sinon un nouvel utilisateur `kali` serait créé), puis `git add settings.nix`.

## Interface Kali

Tout vient des dépôts officiels de Kali (gitlab.com/kalilinux), à une version figée :

- **Thème** Kali-Dark (fenêtres + bordures), icônes Flat-Remix de Kali, polices Cantarell + Fira Code.
- **Menu Whisker au dragon** avec les catégories de Kali : chaque outil installé apparaît tout seul dans sa catégorie.
- **Barre de Kali** : menu, bureau, fichiers, éditeur, navigateur, terminaux, logithèque, bureaux 1 2 3 4, fenêtres, cpu/mem/swap/net, IP du VPN (clic = copier), son, notifications, batterie, heure.
- **qterminal** avec le schéma Kali-Dark, et le **.zshrc de Kali** : `┌──(kali㉿kali)-[~]`, `Ctrl+P` bascule l'invite sur une ligne.
- **Écran de connexion** et **fonds d'écran** officiels de Kali, raccourcis et captures d'écran de Kali.

Personnaliser :

- **Fond d'écran perso** : copie ton image en `home/wallpaper.jpg` (ou `.png`), `git add home/wallpaper.*`, puis `rebuild`.
- **Barre en haut** comme Kali d'origine : `barreEnBas = false;` en haut de `home/xfce.nix`.
- Après le premier `rebuild` depuis une ancienne config : `xfce4-panel -r` (ou se déconnecter/reconnecter).
- Mettre à jour les fichiers Kali : changer `rev` + `hash` dans `pkgs/kali-*/package.nix` (`nix build .#kali-themes` donne le bon hash).

## Outils de Kali

`modules/kali-tools.nix` installe les ~270 outils de Kali qui existent dans nixpkgs (metasploit, sqlmap, hydra, aircrack-ng, netexec, responder, bettercap, impacket, bloodhound-py, nuclei, ffuf, gobuster, ghidra, radare2, autopsy, volatility…), rangés comme dans le menu de Kali.

- Retirer un outil : supprimer son nom dans `modules/kali-tools.nix`. Tout retirer : `machine.kaliTools.enable = false;`.
- Absents de nixpkgs (beef-xss, sliver, spiderfoot, empire, veil, wifiphisher…) : les utiliser via [Exegol](https://exegol.com) (Docker).
- `wapiti` est cassé dans nixpkgs 26.05 : il est commenté dans `modules/pentest.nix`.

## Installer des applications (logithèque)

**Menu → Logiciels** (ou l'icône dans la barre) : on cherche une application, on clique sur **Installer**, et elle apparaît dans le menu. Les applications viennent de [Flathub](https://flathub.org), ajouté automatiquement au premier démarrage. Pas de `rebuild` nécessaire.

En ligne de commande : `flatpak search discord`, `flatpak install flathub com.discordapp.Discord`.

Ce qui doit faire partie du système (outils en ligne de commande, services) s'ajoute plutôt dans les fichiers `.nix` (voir ci-dessous).

## Au quotidien

| Besoin | Commande |
|---|---|
| Appliquer une modification de la config | `rebuild` |
| Mettre à jour tout de suite | `cd ~/nixos-config && nix flake update && rebuild` |
| Revenir en arrière | choisir une génération précédente au menu de démarrage |
| Changer un mot de passe | `passwd`, `sudo passwd root` |
| Installer une application graphique | Menu → Logiciels |
| Ajouter un programme au système | l'ajouter dans `modules/apps.nix`, puis `rebuild` |

- Touche Windows : menu. `Ctrl+Alt+T` : terminal. `Impr. écran` : capture. `Super+E` : fichiers. `Super+L` : verrouiller.
- Le système se met à jour seul chaque semaine ; la nouvelle version s'active au démarrage suivant (`journalctl -u auto-upgrade-hebdo`).
- Le ménage est automatique : anciennes générations supprimées après 7 jours, journaux limités à 200 Mo, TRIM hebdomadaire.
- Docker ne tourne pas tant qu'on ne tape pas de commande `docker`.

## Réactiver ce qui a été retiré

- Impression : décommenter `services.printing.enable` dans `modules/desktop.nix`.
- Serveur SSH : bloc commenté dans `modules/security.nix` (par clé uniquement).
- IP fixe réglée sur la machine plutôt que par réservation DHCP : clic droit sur l'icône réseau → Modifier les connexions → IPv4 → Manuel. Les DNS Cloudflare restent appliqués.

## Crédits

Thèmes, icônes, menu et zshrc : [Kali Linux](https://gitlab.com/kalilinux/packages) (GPL). Kali Linux est une marque d'OffSec ; ce projet n'est ni affilié ni approuvé par OffSec.
