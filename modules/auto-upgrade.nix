# Mise à jour automatique hebdomadaire (paquets, Oh My Zsh, plugins…).
# 1. met à jour flake.lock dans ~/nixos-config (en tant qu'utilisateur) ;
# 2. construit le nouveau système et l'active AU PROCHAIN DÉMARRAGE (`boot`),
#    sans toucher à la session en cours. Retour arrière possible au menu de boot.
# Journal : journalctl -u auto-upgrade-hebdo
{ pkgs, username, ... }:
let
  repo = "/home/${username}/nixos-config";
in
{
  systemd.services.auto-upgrade-hebdo = {
    description = "Mise à jour hebdomadaire de NixOS (flake)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [
      nix
      git
      nixos-rebuild-ng
      util-linux # runuser
      hostname
    ];
    serviceConfig.Type = "oneshot";
    script = ''
      runuser -u ${username} -- nix --extra-experimental-features "nix-command flakes" flake update --flake ${repo}
      runuser -u ${username} -- git -C ${repo} add flake.lock
      nixos-rebuild boot --flake "${repo}#$(hostname)"
    '';
  };

  systemd.timers.auto-upgrade-hebdo = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true; # rattrape le passage manqué si la machine était éteinte
      RandomizedDelaySec = "1h";
    };
  };
}
