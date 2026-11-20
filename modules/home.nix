{ username, ... }:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "hm-backup"; # ne casse pas si un dotfile existe déjà
  home-manager.overwriteBackup = true;
  home-manager.extraSpecialArgs = { inherit username; };
  home-manager.users.${username} = import ../home/user.nix;
}
