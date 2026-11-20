# nixos-config — NixOS with the Kali Linux desktop

[🇫🇷 Français](README.fr.md) · 🇬🇧 English

NixOS 26.05 that **really** looks like Kali Linux: the desktop is built from Kali's
official packages (`kali-themes`, `kali-menu`, `kali-defaults`), plus **every Kali tool
available in nixpkgs** (~270) and a **software center** to install apps in one click.

For a machine without a dedicated GPU and a single NVMe drive.
Based on [joblinours](https://github.com/joblinours/NixOS_config)' config.

> Code comments and the user-facing messages of the scripts are in French.

| Setting | Value |
|---|---|
| Host / user | chosen at install time (default `kali`㉿`kali`, like Kali), stored in `settings.nix` |
| Desktop | XFCE with Kali's interface: Kali-Dark theme, dragon menu with Kali categories, qterminal, Kali's zsh, Kali login screen |
| Tools | ~270 Kali tools, sorted into the menu categories (01 - Reconnaissance → 16 - Services) |
| Apps | "Software" app store + Flathub (Discord, Spotify, OBS…) |
| Network | DHCP; Cloudflare DNS enforced (1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, ::1001) |
| Disk | one NVMe, zstd-compressed btrfs, compressed RAM swap (zram) |
| Graphics | integrated Intel or AMD GPU (Mesa), no proprietary driver |

## Layout

```
flake.nix               inputs (nixpkgs, home-manager, disko)
settings.nix            user name and host name (written by install.sh)
hosts/machine/          default.nix (disk, options) + hardware-configuration.nix
modules/
  common.nix            nix, boot, locale, keyboard, accounts, trimming
  network.nix           DHCP + Cloudflare DNS
  disk.nix              NVMe partitioning (disko)
  desktop.nix           sound, Bluetooth, integrated GPU, fonts
  xfce.nix              XFCE + Kali interface (theme, menu, defaults, LightDM)
  software-center.nix   "Software" app store + Flathub
  kali-tools.nix        every Kali tool found in nixpkgs, by category
  pentest.nix, dfir.nix core security tools
  virtualisation.nix    Docker, socket-activated
  security.nix          firewall (nothing inbound)
  apps.nix              Firefox, mpv, PDF reader…
  network-tools.nix     dig, traceroute, mtr, httpie, WireGuard, OpenVPN…
  dev.nix               C/C++, Rust, Python, Node, Go, Java
  auto-upgrade.nix      weekly upgrade
home/user.nix           zsh (Kali's .zshrc), aliases, git
home/xfce.nix           Kali panel, theme, wallpaper, shortcuts
pkgs/kali-themes        Kali's kali-themes package (themes, icons, wallpapers, defaults)
pkgs/kali-menu          Kali's kali-menu package (01 - Reconnaissance… categories)
pkgs/kali-zshrc         Kali's .zshrc (kali-defaults package)
scripts/                install.sh, test.sh
```

## Before installing

1. **The NVMe drive is wiped entirely.** Any existing system on it is lost: back up first.
2. **Secure Boot must be disabled** in the BIOS/UEFI. The NixOS boot loader is not signed, so the machine will not boot with Secure Boot on. `install.sh` detects it and warns you.
3. Keyboard: the config uses a **Belgian** AZERTY layout (`be`). For French AZERTY, replace `be-latin1` and `be` with `fr` in `modules/common.nix`; for QWERTY use `us`.
4. **Disk space**: about 25 GB uncompressed (≈ 12 GB for the system, ≈ 12 GB for the Kali tools); less on disk thanks to btrfs compression. Without the Kali tools: `machine.kaliTools.enable = false;` in `hosts/machine/default.nix`.

The **user name** and **host name** are asked by `install.sh` (stored in `settings.nix`, editable later).

## Install

Boot the NixOS 26.05 ISO in UEFI mode, connect to the network (`nmtui` for Wi-Fi), get this repository (`git clone` or a USB stick), then:

```bash
sudo bash scripts/install.sh
```

The script asks for the **user name** and **host name**, detects the hardware, shows the disk that will be wiped, asks you to type `OUI` (French for "yes"), installs, **asks for the user and `root` passwords** (no password is stored in this repository), then copies the config to `~/nixos-config`. Reboot, log in with your user, and run:

```bash
bash ~/nixos-config/scripts/test.sh
```

**Machine already installed with an older version of this config**: before the first `rebuild`, put your current user name and host name in `settings.nix` (otherwise a new `kali` user would be created), then `git add settings.nix`.

## Kali interface

Everything comes from Kali's official repositories (gitlab.com/kalilinux), pinned to a fixed revision:

- **Theme** Kali-Dark (GTK + window borders), Kali's Flat-Remix icons, Cantarell + Fira Code fonts.
- **Whisker menu with the dragon** and Kali's categories: every installed tool shows up in its category by itself.
- **Kali panel**: menu, show desktop, files, editor, browser, terminals, software center, workspaces 1 2 3 4, windows, cpu/mem/swap/net, VPN IP (click to copy), sound, notifications, battery, clock.
- **qterminal** with the Kali-Dark color scheme, and **Kali's .zshrc**: `┌──(kali㉿kali)-[~]`, `Ctrl+P` toggles the one-line prompt.
- Kali's **login screen** and **wallpapers**, Kali's shortcuts and screenshot script.

Customize:

- **Your own wallpaper**: copy your image to `home/wallpaper.jpg` (or `.png`), `git add home/wallpaper.*`, then `rebuild`.
- **Panel at the top** like stock Kali: `barreEnBas = false;` at the top of `home/xfce.nix`.
- After the first `rebuild` from an older config: `xfce4-panel -r` (or log out and back in).
- Update the Kali files: change `rev` + `hash` in `pkgs/kali-*/package.nix` (`nix build .#kali-themes` prints the right hash).

## Kali tools

`modules/kali-tools.nix` installs the ~270 Kali tools that exist in nixpkgs (metasploit, sqlmap, hydra, aircrack-ng, netexec, responder, bettercap, impacket, bloodhound-py, nuclei, ffuf, gobuster, ghidra, radare2, autopsy, volatility…), grouped like Kali's menu.

- Remove a tool: delete its name in `modules/kali-tools.nix`. Remove all: `machine.kaliTools.enable = false;`.
- Not in nixpkgs (beef-xss, sliver, spiderfoot, empire, veil, wifiphisher…): use them through [Exegol](https://exegol.com) (Docker).
- `wapiti` is broken in nixpkgs 26.05, so it is commented out in `modules/pentest.nix`.

## Installing apps (software center)

**Menu → Software** (or the panel icon): search for an app, click **Install**, and it appears in the menu. Apps come from [Flathub](https://flathub.org), which is added automatically on first boot. No `rebuild` needed.

From a terminal: `flatpak search discord`, `flatpak install flathub com.discordapp.Discord`.

Anything that should be part of the system (CLI tools, services) is better added to the `.nix` files (see below).

## Day to day

| Need | Command |
|---|---|
| Apply a config change | `rebuild` |
| Upgrade now | `cd ~/nixos-config && nix flake update && rebuild` |
| Roll back | pick a previous generation in the boot menu |
| Change a password | `passwd`, `sudo passwd root` |
| Install a desktop app | Menu → Software |
| Add a program to the system | add it to `modules/apps.nix`, then `rebuild` |

- Windows key: menu. `Ctrl+Alt+T`: terminal. `Print`: screenshot. `Super+E`: files. `Super+L`: lock.
- The system upgrades itself weekly; the new version is activated on the next boot (`journalctl -u auto-upgrade-hebdo`).
- Cleanup is automatic: generations older than 7 days are deleted, logs capped at 200 MB, weekly TRIM.
- Docker does not run until you type a `docker` command.

## Re-enabling what was removed

- Printing: uncomment `services.printing.enable` in `modules/desktop.nix`.
- SSH server: commented block in `modules/security.nix` (key-only).
- Static IP set on the machine rather than through a DHCP reservation: right-click the network icon → Edit Connections → IPv4 → Manual. Cloudflare DNS still applies.

## Credits

Themes, icons, menu and zshrc: [Kali Linux](https://gitlab.com/kalilinux/packages) (GPL). Kali Linux is a trademark of OffSec; this project is not affiliated with or endorsed by OffSec.
