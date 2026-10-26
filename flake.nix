{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # No follows: pi pins the nixpkgs its release was built against.
    pi.url = "github:earendil-works/pi/stable";
    hermes.url = "github:NousResearch/hermes-agent";
  };

  outputs = { nixpkgs, home-manager, disko, pi, hermes, ... }:
    let
      system = "x86_64-linux";

      # Named rather than allowUnfree, so a second one cannot arrive unseen.
      containerPkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          p: builtins.elem (nixpkgs.lib.getName p) [ "claude-code" ];
      };

      laptopDotfiles = "/home/pycan/Documents/dotfiles";

      hosts = {
        "pycan@t460s" = {
          dotfiles = laptopDotfiles;
          module = ./home/laptop.nix;
        };
        "root@oren" = {
          dotfiles = "/root/dotfiles";
          module = ./home/oren.nix;
        };
      };

      host = target: { dotfiles, module }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit dotfiles target hermes; nixos = false; };
          modules = [ module ];
        };
    in
    {
      homeConfigurations = nixpkgs.lib.mapAttrs host hosts // {
        container = home-manager.lib.homeManagerConfiguration {
          pkgs = containerPkgs;
          extraSpecialArgs = {
            dotfiles = null;
            inherit pi;
          };
          modules = [ ./home/container.nix ];
        };
      };

      nixosConfigurations = nixpkgs.lib.genAttrs [ "t460s" "t14" ] (name:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            ./nixos/${name}.nix
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = false;
                backupFileExtension = "hm-bak";
                extraSpecialArgs = {
                  dotfiles = laptopDotfiles;
                  target = name;
                  nixos = true;
                };
                users.pycan = import ./home/laptop.nix;
              };
            }
          ];
        });
    };
}
