# Partitionnement disko : UN seul disque (NVMe), GPT, ESP 1 Gio, btrfs avec sous-volumes.
# Disque choisi par l'host : machine.disk.device = "/dev/nvme0n1";
# ⚠ L'installation EFFACE ce disque en entier (tout autre système qui s'y trouve compris).
{ config, lib, ... }:
let
  mountOptions = [
    "compress=zstd" # compression transparente : moins d'espace occupé, moins d'écritures
    "noatime"
    "discard=async"
  ];
in
{
  options.machine.disk.device = lib.mkOption {
    type = lib.types.str;
    example = "/dev/nvme0n1";
    description = "Disque système (sera entièrement effacé par disko).";
  };

  config.disko.devices.disk.main = {
    type = "disk";
    device = config.machine.disk.device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                inherit mountOptions;
              };
              "@home" = {
                mountpoint = "/home";
                inherit mountOptions;
              };
              "@nix" = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              "@log" = {
                mountpoint = "/var/log";
                inherit mountOptions;
              };
            };
          };
        };
      };
    };
  };
}
