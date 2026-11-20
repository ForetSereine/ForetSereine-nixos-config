# Réseau via NetworkManager.
#   - Adresse IP : DHCP (Ethernet et wifi). Pour qu'elle ne change jamais, faire une
#     réservation DHCP (« bail statique ») sur la box pour l'adresse MAC de la machine.
#   - DNS : ceux du DHCP sont ignorés, on utilise toujours Cloudflare (IPv4 et IPv6).
{ lib, ... }:
let
  cloudflare = [
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];
in
{
  networking.networkmanager = {
    enable = true;
    # DNS global : remplace les DNS annoncés par le DHCP sur TOUTES les connexions,
    # y compris celles créées plus tard depuis l'icône réseau.
    settings."global-dns-domain-*".servers = lib.concatStringsSep "," cloudflare;
    wifi.powersave = true;
  };

  # Vérifier : `cat /etc/resolv.conf` ne doit lister que les 4 adresses ci-dessus.
}
