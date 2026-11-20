{
  pkgs,
  username,
  ...
}:
{
  # ── Nix ───────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true; # fichiers identiques dédupliqués dans /nix/store
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  # Ménage hebdomadaire : les générations de plus de 7 jours sont supprimées
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nixpkgs.config.allowUnfree = true;

  # ── Démarrage ─────────────────────────────────────────────────────
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5; # entrées de générations dans le menu (retour arrière)
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;
  boot.tmp.cleanOnBoot = true;

  # ── Mémoire ───────────────────────────────────────────────────────
  # Swap compressé en RAM (pas de partition ni de fichier de swap sur le NVMe)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  boot.kernel.sysctl = {
    "vm.swappiness" = 180; # réglage conseillé avec zram : compresser plutôt que vider le cache
    "vm.page-cluster" = 0;
  };

  # ── Stockage ──────────────────────────────────────────────────────
  services.fstrim.enable = true; # TRIM hebdomadaire du NVMe
  services.journald.extraConfig = ''
    SystemMaxUse=200M
  '';
  # Vérification mensuelle de l'intégrité btrfs
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };
  # Documentation : on garde les pages man, pas le manuel NixOS hors ligne ni les docs HTML
  documentation.nixos.enable = false;
  documentation.doc.enable = false;
  documentation.info.enable = false;

  # ── Localisation ──────────────────────────────────────────────────
  time.timeZone = "Europe/Brussels";
  i18n.defaultLocale = "fr_BE.UTF-8";
  # Clavier : "be" = AZERTY belge. AZERTY français : mettre "fr" aux deux endroits.
  console.keyMap = "be-latin1";
  services.xserver.xkb = {
    layout = "be";
    variant = "";
  };

  # ── Comptes ───────────────────────────────────────────────────────
  # Aucun mot de passe dans le dépôt (il est public) : scripts/install.sh demande
  # ceux de l'utilisateur et de root à l'installation. Ils se changent ensuite avec
  # `passwd` / `sudo passwd root` et restent valables d'un rebuild à l'autre.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "docker"
      "wireshark"
      "dialout" # ports série
      "video"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # sudo demande le mot de passe de l'utilisateur
  security.sudo.wheelNeedsPassword = true;

  # ── Paquets de base ───────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    nano
    curl
    wget
    htop
    tmux
    ripgrep
    fd
    jq
    tree
    unzip
    p7zip
    file
    pciutils
    usbutils
    lsof
    lm_sensors # `sensors`
    nvd # diff entre générations
  ];
  environment.variables.EDITOR = "nano";
  programs.nano.enable = true;

  # nh : surcouche lisible de nixos-rebuild (`nh os switch`, alias rebuild)
  programs.nh = {
    enable = true;
    flake = "/home/${username}/nixos-config";
  };

  # Binaires précompilés téléchargés (rustup, outils hors nixpkgs)
  programs.nix-ld.enable = true;

  # Mises à jour de firmware à la demande (`fwupdmgr update`), sans service permanent
  services.fwupd.enable = true;
}
