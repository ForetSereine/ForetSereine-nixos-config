# Conteneurs. Pas de VirtualBox (ni hôte, ni additions invité) : rien à compiler.
{ pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;
    # Le démon ne tourne pas au démarrage : il se lance à la première commande
    # `docker …` (activation par socket) → aucune RAM utilisée tant qu'on ne s'en sert pas.
    enableOnBoot = false;
    autoPrune.enable = true;
  };
  environment.systemPackages = with pkgs; [
    lazydocker
    docker-compose
  ];
}
