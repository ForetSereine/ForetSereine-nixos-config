# Le vrai paquet « kali-themes » de Kali (dépôt officiel gitlab.com/kalilinux) :
# thème GTK/xfwm4 Kali-Dark et Kali-Light, icônes Flat-Remix version Kali (avec
# l'icône du dragon pour le menu), schémas de couleurs du terminal, scripts du
# panneau, réglages XFCE par défaut, plus les fonds d'écran officiels.
{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  fetchurl,
}:
let
  wallpapersRev = "903dfe1d797f8fb82245c536c652e6e5ad7d2fa1";
  wallpaper =
    name: hash:
    fetchurl {
      url = "https://gitlab.com/kalilinux/packages/kali-wallpapers/-/raw/${wallpapersRev}/2026/backgrounds/kali-16x9/${name}";
      inherit hash;
    };
  desktopBackground = wallpaper "kali-cubes.jpg" "sha256-G/lhn1lkDO6cpY7Bt5IxiBVWy1dYkXCb1+kAZR7/cQ8=";
  loginBackground = wallpaper "kali-cubes2.jpg" "sha256-q5+CDnN83DsSmH4FfaM/HqdiY7IT+X5gjWO6X6pjzaM=";
in
stdenvNoCC.mkDerivation {
  pname = "kali-themes";
  version = "2026.4-unstable-2026-11";

  src = fetchFromGitLab {
    group = "kalilinux";
    owner = "packages";
    repo = "kali-themes";
    rev = "1248554c02e111fe25b909733fd3ea0075c4b73e";
    hash = "sha256-/6F0aN8u9VvnH8B6cjpzcPYKbufuJjADBnlpNCHmOvw=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    share=$out/share
    mkdir -p $share/{themes,icons,backgrounds/kali,kali-themes,qtermwidget6,xfce4/terminal,pixmaps}

    # Thèmes GTK 2/3/4 + bordures de fenêtres xfwm4
    for t in Kali-Dark Kali-Dark-xHiDPI Kali-Light Kali-Light-xHiDPI; do
      cp -r share/themes/$t $share/themes/
    done
    # Icônes (Flat-Remix adapté par Kali : dragon, icônes des outils)
    for i in Flat-Remix-Blue-Dark Flat-Remix-Blue-Light; do
      cp -r share/icons/$i $share/icons/
    done
    # Liens cassés éventuels (pointent vers des variantes non installées)
    find $share/icons -xtype l -delete

    cp -r share/qtermwidget6/color-schemes $share/qtermwidget6/
    cp -r share/xfce4/terminal/colorschemes $share/xfce4/terminal/
    cp -r share/gtksourceview-* $share/
    cp kali-logos/*.svg $share/pixmaps/

    # Scripts utilisés par le panneau et les raccourcis Impr. écran
    install -m755 share/kali-themes/xfce4-screenshooter share/kali-themes/xfce4-panel-genmon-vpnip.sh \
      $share/kali-themes/

    cp ${desktopBackground} $share/backgrounds/kali/kali-cubes.jpg
    cp ${loginBackground} $share/backgrounds/kali/kali-cubes2.jpg

    # Réglages par défaut de Kali (lus via /etc/xdg, voir modules/xfce.nix)
    mkdir -p $out/etc/xdg
    cp -r etc/xdg/xfce4 etc/xdg/qterminal.org etc/xdg/gtk-3.0 $out/etc/xdg/

    # Chemins Debian → chemins Nix
    for f in $(grep -rl /usr/share $out/etc $share/kali-themes); do
      substituteInPlace "$f" \
        --replace-quiet /usr/share/backgrounds/kali-16x9/default $share/backgrounds/kali/kali-cubes.jpg \
        --replace-quiet /usr/share/kali-themes $share/kali-themes \
        --replace-quiet /usr/share/sounds /run/current-system/sw/share/sounds
    done
    # Kali lance un terminal root via x-terminal-emulator (alternative Debian)
    substituteInPlace $out/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml \
      --replace-quiet "pkexec x-terminal-emulator" "pkexec qterminal"
    # Nom de la police Fira Code tel que fontconfig le connaît sous NixOS
    substituteInPlace $out/etc/xdg/qterminal.org/qterminal.ini \
      --replace-fail "fontFamily=FiraCode" "fontFamily=Fira Code"

    runHook postInstall
  '';

  passthru = { inherit desktopBackground loginBackground; };

  meta = {
    description = "Thèmes, icônes et réglages XFCE de Kali Linux";
    homepage = "https://gitlab.com/kalilinux/packages/kali-themes";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
