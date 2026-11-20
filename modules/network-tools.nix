# Outils réseau : diagnostic, HTTP/API, VPN (aucun service permanent)
{ pkgs, ... }:
{
  # Profils OpenVPN importables dans NetworkManager (Paramètres → VPN)
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];

  environment.systemPackages = with pkgs; [
    # Diagnostic
    dnsutils # dig, nslookup, host
    traceroute
    mtr
    whois
    ipcalc
    ethtool
    iproute2
    tcpdump
    netcat-openbsd
    socat
    iperf3
    arp-scan
    nethogs
    iftop
    inetutils # telnet, ftp
    wget
    curl

    # HTTP / API
    httpie
    xh
    hurl
    websocat
    grpcurl

    # VPN
    wireguard-tools
    openvpn
  ];
}
