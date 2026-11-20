# Socle du système. Chaque fichier se désactive en commentant sa ligne.
{
  imports = [
    ./common.nix # nix, boot, langue, comptes, allègement
    ./auto-upgrade.nix # mise à jour hebdomadaire
    ./disk.nix # un seul NVMe, btrfs compressé
    ./network.nix # DHCP + DNS Cloudflare
    ./desktop.nix # son, Bluetooth, pilote graphique intégré, polices
    ./xfce.nix # bureau XFCE façon Kali
    ./virtualisation.nix # Docker, démarré à la demande
    ./security.nix # pare-feu
    ./apps.nix # applications du quotidien
    ./software-center.nix # logithèque : installer des applis en un clic (Flathub)
    ./network-tools.nix
    ./dev.nix
    ./pentest.nix
    ./kali-tools.nix # tous les outils de Kali présents dans nixpkgs
    ./dfir.nix
    ./home.nix
  ];
}
