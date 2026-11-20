# Applications graphiques du quotidien : le strict nécessaire.
# Pour en ajouter une : chercher son nom sur https://search.nixos.org/packages,
# l'ajouter à la liste, puis `rebuild`.
{ pkgs, ... }:
{
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    mpv # vidéo / audio
    atril # PDF
    remmina # bureau à distance (RDP / VNC)

    # Espace disque
    gdu
    ncdu

    # Infos système (alias neofetch)
    fastfetch
  ];
}
