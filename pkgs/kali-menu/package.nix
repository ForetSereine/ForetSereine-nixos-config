# Le vrai menu de Kali (dépôt officiel gitlab.com/kalilinux) : catégories
# « 01 - Reconnaissance », « 02 - Resource Development »… avec les icônes des
# outils et les ~550 raccourcis de Kali.
#
# Sur Kali, seuls les raccourcis des outils installés apparaissent. Ici chaque
# raccourci reçoit un TryExec=<commande> : le menu XFCE (garcon) masque tout seul
# ceux dont la commande n'est pas installée. Ajouter un outil dans
# modules/pentest.nix le fait donc apparaître dans sa catégorie Kali.
{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:
stdenvNoCC.mkDerivation {
  pname = "kali-menu";
  version = "2026.4-unstable-2026-11";

  src = fetchFromGitLab {
    group = "kalilinux";
    owner = "packages";
    repo = "kali-menu";
    rev = "e444c43782cd35d76ee3efb39132f5e1ac5b2274";
    hash = "sha256-cTKAmvTYmLhmBwH4iMDOR+mvCoECPnCAgjX9l9uHkAM=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 exec-in-shell $out/share/kali-menu/exec-in-shell
    install -Dm644 desktop-directories/*.directory -t $out/share/desktop-directories/
    # Référencé par le menu XFCE de Kali mais fourni ailleurs sur Debian
    cat > $out/share/desktop-directories/usual-apps.directory <<EOF
    [Desktop Entry]
    Name=Usual Applications
    Name[fr]=Applications usuelles
    Icon=applications-other
    Type=Directory
    EOF
    mkdir -p $out/share/icons
    cp -r menu-icons $out/share/icons/hicolor
    rm -rf $out/share/icons/hicolor/scalable/categories/old

    install -Dm644 menus/kali-applications.menu $out/etc/xdg/menus/applications-merged/kali-applications.menu
    install -Dm644 menus/xfce-applications.menu $out/etc/xdg/menus/xfce-applications.menu

    apps=$out/share/applications
    mkdir -p $apps
    for f in desktop-files/*.desktop; do
      exec_line=$(sed -n 's/^Exec=//p' "$f" | head -n1)
      tryexec=""
      case "$exec_line" in
        */helper-scripts/*) continue ;;            # scripts propres à Debian
        /usr/share/kali-menu/exec-in-shell*)
          # exec-in-shell "sudo nmap -h" → nmap
          cmd=$(printf '%s' "$exec_line" | sed -E 's|^/usr/share/kali-menu/exec-in-shell "?||; s|"$||; s|^sudo (-E )?||')
          tryexec=''${cmd%% *} ;;
        pkexec\ *)
          cmd=''${exec_line#pkexec }; tryexec=''${cmd%% *} ;;
        x-www-browser*) ;;                          # liens web : toujours affichés
        x-terminal-emulator*-e\ *)                  # « … -e kali-tweaks » → kali-tweaks
          cmd=''${exec_line#*-e }; tryexec=''${cmd%% *} ;;
        *) tryexec=''${exec_line%% *} ;;
      esac

      name=$(basename "$f")
      case "$name" in kali-*) ;; *) name="kali-$name" ;; esac  # pas de conflit avec les .desktop des paquets

      sed -e "s|/usr/share/kali-menu/exec-in-shell|$out/share/kali-menu/exec-in-shell|" \
          -e 's|^Exec=x-www-browser|Exec=xdg-open|' \
          -e 's|^Exec=x-terminal-emulator|Exec=exo-open --launch TerminalEmulator|' \
          -e '/^TryExec=/d' \
          "$f" > "$apps/$name"
      if [ -n "$tryexec" ]; then
        sed -i "/^Exec=/a TryExec=$tryexec" "$apps/$name"
      fi
    done

    runHook postInstall
  '';

  meta = {
    description = "Menu des applications de Kali Linux (catégories MITRE ATT&CK)";
    homepage = "https://gitlab.com/kalilinux/packages/kali-menu";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
