# Machine unique : processeur avec puce graphique intégrée, un seul NVMe.
# scripts/install.sh régénère hardware-configuration.nix sur la machine.
{ hostname, ... }:
{
  imports = [
    ../../modules
    ./hardware-configuration.nix
  ];

  networking.hostName = hostname;

  # ⚠ Ce disque est EFFACÉ EN ENTIER à l'installation.
  # Vérifier son nom avec `lsblk` depuis l'ISO (un seul NVMe → nvme0n1).
  machine.disk.device = "/dev/nvme0n1";

  # Profils d'énergie (économie / équilibré / performance). Sur un portable :
  # `powerprofilesctl set power-saver` pour allonger l'autonomie.
  services.power-profiles-daemon.enable = true;

  # Tous les outils de Kali (~12 Go). Mettre false pour un système plus léger.
  machine.kaliTools.enable = true;

  # Version de NixOS à l'INSTALLATION. Ne jamais la changer ensuite.
  system.stateVersion = "26.05";
}
