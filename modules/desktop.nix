{ pkgs, ... }:
{
  # Bureau : XFCE façon Kali (xfce.nix)

  # ── Graphique : puce intégrée au processeur (Intel ou AMD), pas de carte dédiée ──
  # Pilote noyau (i915 / amdgpu) + Mesa : rien de propriétaire à compiler.
  hardware.graphics = {
    enable = true;
    # Décodage vidéo matériel (moins de CPU en lecture vidéo). Sans effet sur AMD,
    # où Mesa s'en charge déjà.
    extraPackages = [ pkgs.intel-media-driver ];
  };

  # ── Son : PipeWire ────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ── Matériel / services de bureau ─────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # s'allume depuis l'icône Bluetooth quand on en a besoin
  };
  services.blueman.enable = true;
  services.udisks2.enable = true; # clés USB
  services.gvfs.enable = true; # corbeille, montage en un clic dans Thunar
  services.libinput.enable = true; # pavé tactile
  # Impression : désactivée (CUPS tourne en permanence). Décommenter si besoin :
  # services.printing.enable = true;

  # ── Polices ───────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    cantarell-fonts # interface
    fira-code # terminal
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
  ];
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Cantarell" ];
    monospace = [ "Fira Code" ];
  };
}
