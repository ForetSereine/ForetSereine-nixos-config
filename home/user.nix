{
  pkgs,
  lib,
  username,
  ...
}:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05"; # ne pas changer ensuite

  imports = [ ./xfce.nix ];

  home.packages = with pkgs; [
    bat
    eza
  ];

  # ── zsh : le vrai .zshrc de Kali (pkgs/kali-zshrc) ────────────────
  # ┌──(utilisateur㉿machine)-[~/dossier]
  # └─$
  # Ctrl+P : invite sur une ligne / deux lignes. Coloration syntaxique et
  # suggestions grisées (→ pour accepter) avec les couleurs de Kali.
  programs.zsh = {
    enable = true;
    enableCompletion = false; # le zshrc de Kali lance compinit lui-même

    initContent = lib.mkBefore ''
      source ${pkgs.kali-zshrc}/share/kali/zshrc
      # Historique plus long que celui de Kali (1000)
      HISTSIZE=10000
      SAVEHIST=10000
    '';

    shellAliases = {
      ll = "eza -la --git";
      cat = "bat --paging=never";
      rebuild = "nh os switch"; # appliquer la config
      cfg = "cd ~/nixos-config";
      lg = "lazygit";
      lzd = "lazydocker";
      neofetch = "fastfetch";
      open = "xdg-open";
      # plaso n'est pas dans nixpkgs : image Docker officielle
      plaso = ''docker run --rm -it -v "$PWD:/data" log2timeline/plaso'';
    };
  };

  # Ctrl+R : recherche floue dans l'historique
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    # Identité à compléter :
    # settings.user = { name = "…"; email = "…"; };
  };

  # Autopsy : son paquet ne fournit pas d'entrée de menu
  xdg.desktopEntries.autopsy = {
    name = "Autopsy";
    genericName = "Analyse forensique";
    exec = "autopsy";
    icon = "system-search";
    categories = [
      "System"
      "Security"
    ];
  };
}
