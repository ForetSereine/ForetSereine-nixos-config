# Logithèque graphique : « Logiciels » (GNOME Software) branché sur Flathub.
# On y cherche une application (Discord, Spotify, OBS, VLC…), bouton « Installer »,
# et elle apparaît dans le menu. Pas besoin de toucher à la config ni de rebuild.
#
# Menu → Usual Applications → System → Logiciels  (ou `gnome-software`)
# En ligne de commande : flatpak search <nom> / flatpak install flathub <id>
#
# Les applications Flatpak sont isolées du système et mises à jour depuis la
# logithèque. Ce qui doit faire partie du système (outils, services) reste dans
# les fichiers .nix.
{ pkgs, ... }:
{
  services.flatpak.enable = true;

  # Portails : boîtes de dialogue « Ouvrir un fichier » des applis Flatpak
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  environment.systemPackages = [ pkgs.gnome-software ];

  # Ajoute Flathub dès le premier démarrage (rien à faire après l'installation)
  systemd.services.flathub = {
    description = "Ajout du dépôt Flathub";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure"; # réessaie si le réseau n'est pas encore là
      RestartSec = 30;
    };
  };
}
