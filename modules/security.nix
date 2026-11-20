{ pkgs, ... }:
{
  # ── Pare-feu : rien n'entre ───────────────────────────────────────
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
  };

  # ── SSH entrant : désactivé ───────────────────────────────────────
  # Les mots de passe des comptes sont courts : on n'expose pas de serveur SSH.
  # Pour l'activer plus tard, uniquement par clé :
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     PasswordAuthentication = false;
  #     KbdInteractiveAuthentication = false;
  #     PermitRootLogin = "no";
  #   };
  # };
  # networking.firewall.allowedTCPPorts = [ 22 ];
  # users.users.<utilisateur>.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA…" ];

  # ── Antivirus : à la demande ──────────────────────────────────────
  # Pas de démon clamd (il garde plus d'1 Gio de signatures en RAM).
  # Analyse ponctuelle : `sudo freshclam` puis `clamscan -r <dossier>`.
  environment.systemPackages = [ pkgs.clamav ];
}
