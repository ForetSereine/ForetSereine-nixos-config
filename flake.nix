{
  description = "NixOS avec l'interface Kali (vrais thèmes, menu et zsh de Kali), tous les outils Kali, logithèque Flathub (un seul host, sans GPU dédié)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Partitionnement déclaratif (modules/disk.nix)
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      ...
    }@inputs:
    let
      # Utilisateur et nom de la machine : settings.nix (demandés par install.sh)
      inherit (import ./settings.nix) username hostname;

      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        # Pour les devShells/paquets du flake (le système a allowUnfree = true)
        config.allowUnfreePredicate = p: builtins.elem (nixpkgs.lib.getName p) [ "volatility3" ];
      };
    in
    {
      # sudo nixos-rebuild switch --flake .#<hostname>   (ou : rebuild)
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username hostname; };
        modules = [
          { nixpkgs.hostPlatform = system; }
          { nixpkgs.overlays = [ self.overlays.default ]; }
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          ./hosts/machine
        ];
      };

      # Paquets maison : nix build .#triage / .#capa
      packages.${system} = {
        triage = pkgs.callPackage ./pkgs/triage/package.nix { };
        capa = pkgs.callPackage ./pkgs/capa/package.nix { };
        # Interface Kali : nix build .#kali-themes / .#kali-menu / .#kali-zshrc
        kali-themes = pkgs.callPackage ./pkgs/kali-themes/package.nix { };
        kali-menu = pkgs.callPackage ./pkgs/kali-menu/package.nix { };
        kali-zshrc = pkgs.callPackage ./pkgs/kali-zshrc/package.nix { };
        default = self.packages.${system}.triage;
      };

      overlays.default = final: prev: {
        triage = final.callPackage ./pkgs/triage/package.nix { };
        capa = final.callPackage ./pkgs/capa/package.nix { };
        kali-themes = final.callPackage ./pkgs/kali-themes/package.nix { };
        kali-menu = final.callPackage ./pkgs/kali-menu/package.nix { };
        kali-zshrc = final.callPackage ./pkgs/kali-zshrc/package.nix { };
      };

      # nix develop        → outils Nix
      # nix develop .#dfir → boîte à outils forensique
      devShells.${system} = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt
            nil
            nvd
          ];
        };
        dfir = import ./shells/dfir.nix { inherit pkgs; };
      };

      checks.${system} = {
        inherit (self.packages.${system})
          triage
          capa
          kali-themes
          kali-menu
          kali-zshrc
          ;
      };

      formatter.${system} = pkgs.nixfmt-tree;
    };
}
