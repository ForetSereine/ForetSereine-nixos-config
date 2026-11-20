# Disposition de l'interface Kali, reprise du panneau officiel de Kali
# (kali-themes : etc/xdg/xfce4/panel/default.xml) :
#   menu au dragon | bureau | fichiers | éditeur, navigateur, terminaux, logithèque
#   | bureaux 1 2 3 4
#   | fenêtres ……… cpu mem swap net | icônes | IP VPN | son | notifications | batterie
#   | heure | verrouiller/déconnexion
# Ces réglages sont réappliqués à chaque rebuild ; le reste de ce qui est changé à
# la souris est conservé. Après le premier rebuild : `xfce4-panel -r`.
{ pkgs, lib, ... }:
let
  # ── À adapter ────────────────────────────────────────────────────
  # Kali met la barre en haut ; sur ta photo elle est en bas.
  barreEnBas = true;

  # Fond d'écran : dépose ton image en home/wallpaper.jpg (ou .png), puis
  # `git add home/wallpaper.*` et `rebuild`. Sinon : fond officiel de Kali.
  wallpaper =
    if builtins.pathExists ./wallpaper.jpg then
      ./wallpaper.jpg
    else if builtins.pathExists ./wallpaper.png then
      ./wallpaper.png
    else
      "${pkgs.kali-themes}/share/backgrounds/kali/kali-cubes.jpg";
  # ─────────────────────────────────────────────────────────────────

  kaliScripts = "${pkgs.kali-themes}/share/kali-themes";
  uint = value: {
    type = "uint";
    inherit value;
  };

  # Noms d'écran possibles (portable, HDMI/DP, machine virtuelle) : XFCE range le
  # fond d'écran par nom d'écran.
  monitors = [
    "eDP-1"
    "eDP1"
    "eDP-2"
    "HDMI-1"
    "HDMI-A-1"
    "HDMI-2"
    "DP-1"
    "DP-2"
    "DP-3"
    "Virtual-1"
    "Virtual1"
    "0"
  ];
  backdrop = lib.listToAttrs (
    lib.concatMap (
      m:
      lib.concatMap (
        ws:
        let
          p = "backdrop/screen0/monitor${m}/workspace${toString ws}";
        in
        [
          (lib.nameValuePair "${p}/last-image" "${wallpaper}")
          (lib.nameValuePair "${p}/image-style" 5) # zoom
          (lib.nameValuePair "${p}/color-style" 0)
        ]
      ) (lib.range 0 3)
    ) monitors
  );

  # Lanceurs de la barre (comme les launcher-5/6/7 de Kali)
  launcher = name: exec: icon: ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=${name}
    Exec=${exec}
    Icon=${icon}
    StartupNotify=true
  '';
in
{
  xdg.configFile = {
    "xfce4/panel/launcher-5/kali-editor.desktop".text =
      launcher "Text Editor" "mousepad %F"
        "accessories-text-editor";
    "xfce4/panel/launcher-6/kali-browser.desktop".text = launcher "Firefox" "firefox %u" "firefox";
    "xfce4/panel/launcher-7/kali-terminal.desktop".text =
      launcher "Terminal Emulator" "exo-open --launch TerminalEmulator"
        "org.xfce.terminalemulator";
    # Kali : « Root Terminal Emulator » ; ici sudo demande le mot de passe dans le terminal
    "xfce4/panel/launcher-7/kali-root-terminal.desktop".text =
      launcher "Root Terminal Emulator" "qterminal -e \"sudo -i\""
        "utilities-root-terminal";
    # Logithèque (modules/software-center.nix) : installer des applis en un clic
    "xfce4/panel/launcher-23/kali-software.desktop".text =
      launcher "Logiciels" "gnome-software"
        "org.gnome.Software";

    # Applications par défaut de Kali : qterminal, Thunar, Firefox
    "xfce4/helpers.rc".text = ''
      WebBrowser=firefox
      TerminalEmulator=qterminal
      FileManager=thunar
    '';
  };

  xfconf.settings = {
    # ── Thème, icônes, polices : ceux de Kali ───────────────────────
    xsettings = {
      "Net/ThemeName" = "Kali-Dark";
      "Net/IconThemeName" = "Flat-Remix-Blue-Dark";
      "Gtk/CursorThemeName" = "Adwaita";
      "Gtk/CursorThemeSize" = 24;
      "Gtk/FontName" = "Cantarell 11";
      "Gtk/MonospaceFontName" = "Fira Code Medium 10";
      "Gtk/ButtonImages" = true;
      "Gtk/MenuImages" = true;
      "Xft/Antialias" = 1;
      "Xft/Hinting" = 1;
      "Xft/HintStyle" = "hintslight";
      "Xft/RGBA" = "rgb";
      "Xfce/SyncThemes" = true;
    };
    xfwm4 = {
      "general/theme" = "Kali-Dark"; # bordures de fenêtres de Kali
      "general/title_font" = "Cantarell Bold 9";
      "general/button_layout" = "O|HMC";
      "general/easy_click" = "Super";
      "general/workspace_count" = 4;
      "general/cycle_workspaces" = false;
      "general/scroll_workspaces" = false;
      "general/box_resize" = true;
      "general/cycle_raise" = true;
    };

    # ── Bureau : fond d'écran + icônes Dossier perso / Système / Corbeille ──
    xfce4-desktop = backdrop // {
      "desktop-icons/style" = 2;
      "desktop-icons/icon-size" = uint 48;
      "desktop-icons/file-icons/show-home" = true;
      "desktop-icons/file-icons/show-filesystem" = true;
      "desktop-icons/file-icons/show-removable" = true;
      "desktop-icons/file-icons/show-trash" = true;
    };

    # ── Barre de Kali ───────────────────────────────────────────────
    xfce4-panel = {
      "configver" = 2;
      "panels" = [ 1 ];
      "panels/dark-mode" = true;
      "panels/panel-1/position" = if barreEnBas then "p=8;x=0;y=0" else "p=6;x=0;y=0";
      "panels/panel-1/position-locked" = true;
      "panels/panel-1/length" = uint 100;
      "panels/panel-1/size" = uint 34;
      "panels/panel-1/icon-size" = uint 0; # taille auto, comme Kali
      # 23 = logithèque, placée juste après les terminaux
      "panels/panel-1/plugin-ids" = lib.range 1 7 ++ [ 23 ] ++ lib.range 8 22;

      "plugins/plugin-1" = "whiskermenu";
      "plugins/plugin-1/button-icon" = "kali-panel-menu"; # le dragon
      "plugins/plugin-1/show-button-title" = false;
      "plugins/plugin-1/load-hierarchy" = true; # catégories 01 - … 13 - comme Kali
      "plugins/plugin-1/item-icon-size" = 2;
      "plugins/plugin-1/category-icon-size" = 1;
      "plugins/plugin-1/hover-switch-category" = true;
      "plugins/plugin-1/launcher-show-description" = false;
      "plugins/plugin-1/position-search-alternate" = false;
      "plugins/plugin-1/position-categories-alternate" = true;
      "plugins/plugin-1/position-profile-alternate" = true;
      "plugins/plugin-1/menu-width" = 570;
      "plugins/plugin-1/menu-height" = 700;
      "plugins/plugin-1/command-settings" = "xfce4-settings-manager";
      "plugins/plugin-1/show-command-settings" = true;
      "plugins/plugin-1/show-command-logout" = true;
      "plugins/plugin-1/show-command-lockscreen" = false;
      "plugins/plugin-1/show-command-switchuser" = false;
      "plugins/plugin-1/show-command-logoutuser" = false;
      "plugins/plugin-1/show-command-restart" = false;
      "plugins/plugin-1/show-command-shutdown" = false;
      "plugins/plugin-1/show-command-suspend" = false;
      "plugins/plugin-1/show-command-hibernate" = false;
      "plugins/plugin-1/show-command-menueditor" = false;
      "plugins/plugin-1/show-command-profile" = false;
      "plugins/plugin-1/favorites" = [
        "xfce4-terminal-emulator.desktop"
        "xfce4-file-manager.desktop"
        "org.xfce.mousepad.desktop"
        "xfce4-web-browser.desktop"
        "org.gnome.Software.desktop"
        "kali-www.desktop"
        "kali-tools.desktop"
        "kali-docs.desktop"
        "kali-bugs.desktop"
        "kali-offsec-training.desktop"
        "kali-exploit-database.desktop"
        "kali-vulnhub.desktop"
      ];

      "plugins/plugin-2" = "separator";
      "plugins/plugin-3" = "showdesktop";
      "plugins/plugin-4" = "directorymenu";
      "plugins/plugin-4/icon-name" = "system-file-manager";
      "plugins/plugin-5" = "launcher";
      "plugins/plugin-5/items" = [ "kali-editor.desktop" ];
      "plugins/plugin-6" = "launcher";
      "plugins/plugin-6/items" = [ "kali-browser.desktop" ];
      "plugins/plugin-7" = "launcher"; # terminal, flèche → terminal root
      "plugins/plugin-7/items" = [
        "kali-terminal.desktop"
        "kali-root-terminal.desktop"
      ];
      "plugins/plugin-7/move-first" = true;
      "plugins/plugin-23" = "launcher";
      "plugins/plugin-23/items" = [ "kali-software.desktop" ];
      "plugins/plugin-8" = "separator";
      "plugins/plugin-9" = "pager"; # bureaux 1 2 3 4
      "plugins/plugin-9/miniature-view" = false;
      "plugins/plugin-9/rows" = uint 1;
      "plugins/plugin-10" = "separator";
      "plugins/plugin-11" = "tasklist";
      "plugins/plugin-11/show-handle" = false;
      "plugins/plugin-11/show-labels" = false;
      "plugins/plugin-11/middle-click" = uint 1;
      "plugins/plugin-11/grouping" = uint 1;
      "plugins/plugin-12" = "separator"; # espace extensible
      "plugins/plugin-12/expand" = true;
      "plugins/plugin-12/style" = uint 0;
      "plugins/plugin-13" = "systemload"; # cpu mem swap net + uptime (ta photo)
      "plugins/plugin-14" = "systray";
      "plugins/plugin-14/size-max" = uint 22;
      "plugins/plugin-14/square-icons" = true;
      "plugins/plugin-14/symbolic-icons" = false;
      "plugins/plugin-15" = "genmon"; # IP du VPN (tun0), clic = copier
      "plugins/plugin-15/command" = "${kaliScripts}/xfce4-panel-genmon-vpnip.sh";
      "plugins/plugin-15/use-label" = false;
      "plugins/plugin-15/update-period" = 1000;
      "plugins/plugin-15/enable-single-row" = true;
      "plugins/plugin-15/font" = "Fira Code Medium 8";
      "plugins/plugin-16" = "pulseaudio";
      "plugins/plugin-17" = "notification-plugin";
      "plugins/plugin-18" = "power-manager-plugin";
      "plugins/plugin-19" = "clock";
      "plugins/plugin-19/digital-layout" = uint 3;
      "plugins/plugin-19/digital-time-format" = "%_H:%M";
      "plugins/plugin-19/digital-time-font" = "Cantarell 11";
      "plugins/plugin-20" = "separator";
      "plugins/plugin-20/style" = uint 0;
      "plugins/plugin-21" = "separator";
      "plugins/plugin-22" = "actions"; # verrouiller + déconnexion
      "plugins/plugin-22/appearance" = uint 0;
      "plugins/plugin-22/items" = [
        "+lock-screen"
        "-switch-user"
        "-separator"
        "-suspend"
        "-hibernate"
        "-hybrid-sleep"
        "-separator"
        "-shutdown"
        "-restart"
        "-separator"
        "+logout"
        "-logout-dialog"
      ];
    };

    # Verrouillage (Super+L, mise en veille) : retour à l'écran de connexion, sans
    # démon d'économiseur d'écran
    xfce4-session."general/LockCommand" = "${pkgs.lightdm}/bin/dm-tool lock";

    # ── Raccourcis de Kali ──────────────────────────────────────────
    xfce4-keyboard-shortcuts = {
      "commands/custom/Super_L" = "xfce4-popup-whiskermenu"; # touche Windows : menu
      "commands/custom/<Primary>Escape" = "xfce4-popup-whiskermenu";
      "commands/custom/<Alt>F1" = "xfce4-popup-whiskermenu --pointer";
      "commands/custom/<Alt>F2" = "xfrun4";
      "commands/custom/<Super>r" = "xfrun4";
      "commands/custom/<Primary><Alt>t" = "exo-open --launch TerminalEmulator";
      "commands/custom/<Super>t" = "exo-open --launch TerminalEmulator";
      "commands/custom/<Primary><Shift><Alt>t" = "qterminal -e \"sudo -i\"";
      "commands/custom/<Super>e" = "exo-open --launch FileManager";
      "commands/custom/<Primary><Alt>f" = "exo-open --launch FileManager";
      "commands/custom/<Super>w" = "exo-open --launch WebBrowser";
      "commands/custom/<Super>l" = "xflock4";
      "commands/custom/<Primary><Alt>l" = "xflock4";
      "commands/custom/<Primary><Shift>Escape" = "xfce4-taskmanager";
      "commands/custom/<Super>p" = "xfce4-display-settings --minimal";
      # Captures d'écran avec le script de Kali (enregistre dans ~/Images + notification)
      "commands/custom/Print" = "${kaliScripts}/xfce4-screenshooter";
      "commands/custom/<Shift>Print" = "${kaliScripts}/xfce4-screenshooter --region";
      "commands/custom/<Alt>Print" = "${kaliScripts}/xfce4-screenshooter --window";
      "commands/custom/<Primary>Print" = "${kaliScripts}/xfce4-screenshooter --fullscreen --clipboard";
      "commands/custom/<Primary><Shift>Print" = "${kaliScripts}/xfce4-screenshooter --region --clipboard";
      "commands/custom/<Primary><Alt>Print" = "${kaliScripts}/xfce4-screenshooter --window --clipboard";
    };

    # ── xfce4-terminal (si on le préfère à qterminal) : schéma Kali ──
    xfce4-terminal = {
      "font-name" = "Fira Code 10";
      "font-use-system" = false;
      "color-foreground" = "#ffffff";
      "color-background" = "#1f2229";
      "misc-menubar-default" = false;
      "scrolling-unlimited" = true;
    };
  };
}
