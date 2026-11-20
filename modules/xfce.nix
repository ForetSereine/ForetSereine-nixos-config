# Bureau XFCE avec la VRAIE interface de Kali Linux, construite à partir des
# paquets officiels de Kali (pkgs/kali-*) :
#   - thème GTK + bordures de fenêtres Kali-Dark, icônes Flat-Remix version Kali
#   - menu Whisker avec le dragon et les catégories « 01 - Reconnaissance »…
#   - qterminal avec le schéma Kali-Dark, zsh avec le .zshrc de Kali
#   - écran de connexion LightDM comme sur Kali (Kali-Light + fond « cubes »)
#   - réglages XFCE par défaut de Kali (raccourcis, Thunar, session…)
# La disposition de la barre et le fond d'écran sont dans home/xfce.nix.
{ pkgs, lib, ... }:
let
  kali = pkgs.kali-themes;
  menu = pkgs.kali-menu;

  # Fichiers de réglages par défaut de Kali, installés dans /etc/xdg comme sur Kali.
  # Ils servent de valeurs par défaut : ce que l'utilisateur change reste prioritaire.
  kaliXdg = [
    "xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
    "xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml"
    "xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml"
    "xfce4/xfconf/xfce-perchannel-xml/thunar.xml"
    "xfce4/panel/default.xml"
    "xfce4/terminal/terminalrc"
    "xfce4/helpers.rc"
    "qterminal.org/qterminal.ini"
    "gtk-3.0/settings.ini"
  ];
in
{
  services.xserver = {
    enable = true;
    desktopManager.xfce = {
      enable = true;
      enableScreensaver = false; # verrouillage par l'écran de connexion (home/xfce.nix)
    };

    # Écran de connexion de Kali : thème clair, fond « cubes », mêmes indicateurs
    displayManager.lightdm = {
      enable = true;
      background = kali.loginBackground;
      greeters.gtk = {
        enable = true;
        theme = {
          name = "Kali-Light";
          package = kali;
        };
        iconTheme = {
          name = "Flat-Remix-Blue-Light";
          package = kali;
        };
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
          size = 24;
        };
        clock-format = "%d %b, %H:%M";
        indicators = [
          "~host"
          "~spacer"
          "~session"
          "~layout"
          "~a11y"
          "~clock"
          "~power"
        ];
        extraConfig = ''
          font-name = Cantarell 11
          xft-antialias = true
          xft-dpi = 96
          xft-hintstyle = slight
          xft-rgba = rgb
        '';
      };
    };
    excludePackages = [ pkgs.xterm ];
  };
  services.displayManager.defaultSession = "xfce";

  # Réglages par défaut de Kali + menu de Kali (catégories des outils)
  environment.etc =
    lib.genAttrs (map (f: "xdg/${f}") kaliXdg) (f: {
      source = "${kali}/etc/${f}";
    })
    // {
      "xdg/menus/xfce-applications.menu".source = "${menu}/etc/xdg/menus/xfce-applications.menu";
      "xdg/menus/applications-merged/kali-applications.menu".source =
        "${menu}/etc/xdg/menus/applications-merged/kali-applications.menu";
      # Menu Whisker : réglages de Kali (favoris adaptés aux noms des raccourcis ici)
      "xdg/xfce4/whiskermenu/defaults.rc".text =
        builtins.replaceStrings
          [
            "exo-terminal-emulator.desktop,root-terminal.desktop,"
            "exo-file-manager.desktop"
            "xfce-text-editor.desktop"
            "exo-web-browser.desktop"
            "offsec-training.desktop"
            "exploit-database.desktop"
            "vulnhub.desktop"
          ]
          [
            "xfce4-terminal-emulator.desktop,"
            "xfce4-file-manager.desktop"
            "org.xfce.mousepad.desktop"
            "xfce4-web-browser.desktop"
            "kali-offsec-training.desktop"
            "kali-exploit-database.desktop"
            "kali-vulnhub.desktop"
          ]
          (builtins.readFile "${kali}/etc/xdg/xfce4/whiskermenu/defaults.rc");
      # Comme sur Kali : pas de bip de la carte mère
      "xdg/autostart/xfce-disable-motherboard-beep.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Disable motherboard beep
        Exec=${pkgs.xset}/bin/xset b off
        OnlyShowIn=XFCE;
        NoDisplay=true
      '';
    };

  # Dossiers de share/ que NixOS ne lie pas d'office dans /run/current-system/sw
  environment.pathsToLink = [
    "/share/qtermwidget6" # schémas de couleurs Kali-Dark / Kali-Light de qterminal
    "/share/backgrounds"
    "/share/kali-themes"
    "/share/xfce4"
    "/share/gtksourceview-3.0"
    "/share/gtksourceview-4"
    "/share/gtksourceview-5"
  ];

  # Applications XFCE dont on n'a pas l'usage
  environment.xfce.excludePackages = with pkgs; [
    parole # lecteur vidéo (on a mpv)
    xfburn
  ];

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  programs.xfconf.enable = true;
  services.tumbler.enable = true; # miniatures dans Thunar

  environment.systemPackages = with pkgs; [
    # Interface Kali
    kali-themes
    kali-menu
    adwaita-icon-theme # curseur + icônes de repli de Flat-Remix
    lxqt.qterminal # terminal par défaut de Kali

    # Greffons de la barre, comme sur Kali
    xfce4-whiskermenu-plugin # menu au dragon
    xfce4-systemload-plugin # cpu / mem / swap / net / uptime
    xfce4-cpugraph-plugin
    xfce4-genmon-plugin # IP du VPN (tun0) dans la barre
    xfce4-pulseaudio-plugin # volume
    xclip # clic sur l'IP du VPN → copiée

    # Outils du bureau
    xfce4-screenshooter # Impr. écran (via le script de Kali)
    xdg-user-dirs # dossier Images pour les captures
    sound-theme-freedesktop # son de capture d'écran
    pulseaudio # paplay / pactl (clients seulement, le son reste PipeWire)
    xfce4-taskmanager
    mousepad # éditeur de texte
    ristretto # images
    xarchiver # archives
    pavucontrol # réglages audio
    networkmanagerapplet # icône réseau
  ];
}
