# TOUS les outils de Kali disponibles dans nixpkgs (269), classés comme dans
# le menu de Kali (généré à partir du paquet kali-menu). Chaque outil apparaît
# aussi tout seul dans sa catégorie du menu.
#
# Volumineux : désactiver avec  machine.kaliTools.enable = false;  (hosts/machine/default.nix)
# ou commenter un nom pour retirer un outil.
#
# Absents de nixpkgs : beef-xss, sliver, spiderfoot, gvm (serveur complet), empire,
# veil, wifiphisher, legion, dirsearch… → les utiliser via Exegol (Docker).
# wapiti : cassé dans nixpkgs 26.05 (wapiti-arsenic exige packaging<26).
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.machine.kaliTools.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Installer tous les outils de Kali disponibles dans nixpkgs.";
  };

  config = lib.mkIf config.machine.kaliTools.enable {
    environment.systemPackages = with pkgs; [
      # ── 01 - Reconnaissance ─────────────────────────────────────────
      amass
      arjun
      assetfinder
      bettercap
      bluesnarfer
      burpsuite
      chirp
      crlfuzz
      dalfox
      davtest
      dirb
      dmitry
      dnsenum
      dnsmap
      dnsrecon
      dnstracer
      dnsx
      feroxbuster
      ffuf
      findomain
      gau
      gitxray
      gnuradio
      gobuster
      gospider
      gqrx
      hackrf
      hakrawler
      httpx
      instaloader
      joomscan
      katana
      kismet
      lbd
      maltego
      massdns
      naabu
      nikto
      nmap
      nuclei
      parsero
      photon
      qsreplace
      recon-ng
      redfang
      rustscan
      sdrangel
      sherlock
      subfinder
      subjack
      syft
      theharvester
      ubertooth
      uro
      wfuzz
      whatweb
      wpprobe
      wpscan
      zap

      # ── 02 - Resource Development ───────────────────────────────────
      aflplusplus
      apktool
      bed
      bytecode-viewer
      cutter
      dex2jar
      edb
      exploitdb
      gdb
      gef
      ghidra
      jadx
      metasploit
      msfpc
      oletools
      openocd
      radare2
      rizin
      shellnoob
      spike
      sploitscan

      # ── 03 - Initial Access ─────────────────────────────────────────
      commix
      ghauri
      gophish
      padbuster
      social-engineer-toolkit
      sqlmap

      # ── 04 - Execution ──────────────────────────────────────────────
      armitage
      arsenal
      powersploit

      # ── 05 - Persistence ────────────────────────────────────────────
      laudanum
      seclists
      weevely

      # ── 06 - Privilege Escalation ───────────────────────────────────
      lynis
      unix-privesc-check

      # ── 07 - Defense Evasion ────────────────────────────────────────
      ccrypt
      evil-winrm
      evil-winrm-py
      macchanger
      netexec
      outguess
      python3Packages.impacket
      smbmap
      steghide

      # ── 08 - Credential Access ──────────────────────────────────────
      aircrack-ng
      airgeddon
      asleap
      bully
      certipy
      cewl
      chntpw
      cmospwd
      cowpatty
      crackle
      crowbar
      crunch
      fcrackzip
      freeradius
      hashcat
      hashid
      hcxdumptool
      hcxtools
      john
      johnny
      kerbrute
      legba
      mdk4
      medusa
      mfcuk
      mfoc
      mimikatz
      ncrack
      ophcrack
      ophcrack-cli
      pack
      pixiewps
      responder
      rsmangler
      samdump2
      sipvicious
      thc-hydra
      truecrack
      trufflehog
      wifite2
      wordlists

      # ── 09 - Discovery ──────────────────────────────────────────────
      above
      apache-users
      arp-scan
      arping
      azurehound
      bloodhound-py
      braa
      darkstat
      dnschef
      driftnet
      dsniff
      enum4linux
      enum4linux-ng
      fierce
      firewalk
      fping
      hping
      ike-scan
      ldeep
      masscan
      mdbtools
      nbtscan
      netdiscover
      netmask
      netsniff-ng
      onesixtyone
      p0f
      samba
      sipp
      sipsak
      smtp-user-enum
      snmpcheck
      sqlitebrowser
      sslscan
      swaks
      tcpdump
      tcpflow
      tcpreplay
      thc-ipv6
      wafw00f
      yersinia

      # ── 10 - Lateral Movement ───────────────────────────────────────
      rdesktop

      # ── 11 - Collection ─────────────────────────────────────────────
      ettercap
      httrack
      mitmproxy
      python3Packages.scapy
      ssldump
      sslsplit

      # ── 12 - Command and Control ────────────────────────────────────
      cadaver
      chisel
      dbd
      dns2tcp
      iodine
      ligolo-ng
      minicom
      miredo
      netcat-gnu
      penelope
      proxychains-ng
      proxytunnel
      pwnat
      socat
      sshuttle
      sslh
      stunnel
      termineter
      udptunnel
      villain
      vopono

      # ── 13 - Exfiltration ───────────────────────────────────────────
      goshs

      # ── 14 - Impact ─────────────────────────────────────────────────
      dhcpig
      siege
      slowhttptest

      # ── 15 - Forensics ──────────────────────────────────────────────
      autopsy
      binwalk
      bulk_extractor
      chainsaw
      dc3dd
      dcfldd
      ddrescue
      detect-it-easy
      ext3grep
      ext4magic
      extundelete
      foremost
      galleta
      guymager
      hashdeep
      magicrescue
      missidentify
      myrescue
      pasco
      pdf-parser
      pdfid
      recoverdm
      recoverjpeg
      regripper
      rifiuti
      safecopy
      scalpel
      scrounge-ntfs
      sleuthkit
      ssdeep
      testdisk
      undbx
      unhide
      yara

      # ── 16 - Services and Other Tools ───────────────────────────────
      caido-desktop
      cherrytree
      cryptsetup
      eyewitness
      faraday
      freerdp
      fwbuilder
      gemini-cli
      gvm-tools
      hashrat
      hb-honeypot
      mac-robber
      mariadb.client
      openvas-scanner
      powershell
      shell-gpt
      snort
      witnessme
    ];
  };
}
