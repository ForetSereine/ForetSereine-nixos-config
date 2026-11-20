# Le vrai ~/.zshrc de Kali (paquet kali-defaults, dépôt officiel) : invite
# ┌──(kali㉿kali)-[~] / └─$, Ctrl+P pour passer sur une ligne, coloration
# syntaxique et suggestions avec les couleurs de Kali.
# Seuls les chemins Debian sont remplacés par ceux du store Nix.
{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  zsh-syntax-highlighting,
  zsh-autosuggestions,
  ncurses,
  coreutils,
}:
stdenvNoCC.mkDerivation {
  pname = "kali-zshrc";
  version = "2026.4-unstable-2026-11";

  src = fetchFromGitLab {
    group = "kalilinux";
    owner = "packages";
    repo = "kali-defaults";
    rev = "76c5b1cabf38b12c8f6478e962285f1bf8de8750";
    hash = "sha256-NC7p8D7dtiiGhnXPqwGxSRWTRxbmcxXVJeY6xZYL+bE=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm644 etc/skel/.zshrc $out/share/kali/zshrc
    substituteInPlace $out/share/kali/zshrc \
      --replace-fail /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
        ${zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
      --replace-fail /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
        ${zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
      --replace-fail /usr/bin/tput ${ncurses}/bin/tput \
      --replace-fail /usr/bin/dircolors ${coreutils}/bin/dircolors
    runHook postInstall
  '';

  meta = {
    description = "zshrc par défaut de Kali Linux";
    homepage = "https://gitlab.com/kalilinux/packages/kali-defaults";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
