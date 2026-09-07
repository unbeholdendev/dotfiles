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
    noctalia.url = "github:noctalia-dev/noctalia-shell/cachix";
  };

  outputs = { nixpkgs, home-manager, disko, noctalia, ... }:
    let
      system = "x86_64-linux";

      # Named rather than allowUnfree, so a second one cannot arrive unseen.
      containerPkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          p: builtins.elem (nixpkgs.lib.getName p) [ "claude-code" ];
      };

      hosts = {
        "pycan@t460s" = {
          dotfiles = "/home/pycan/Documents/dotfiles";
          module = ./home/t460s.nix;
        };
        "root@deb-agent" = {
          dotfiles = "/root/dotfiles";
          module = ./home/deb-agent.nix;
        };
      };

      host = target: { dotfiles, module }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit dotfiles target; nixos = false; };
          modules = [ module ];
        };
    in
    {
      homeConfigurations = nixpkgs.lib.mapAttrs host hosts // {
        container = home-manager.lib.homeManagerConfiguration {
          pkgs = containerPkgs;
          extraSpecialArgs = {
            dotfiles = null;
          };
          modules = [ ./home/container.nix ];
        };
      };

      nixosConfigurations.t460s = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          noctalia = noctalia.packages.${system}.default;
        };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          ./nixos/t460s.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = false;
              backupFileExtension = "hm-bak";
              extraSpecialArgs = {
                dotfiles = hosts."pycan@t460s".dotfiles;
                target = "t460s";
                nixos = true;
              };
              users.pycan = import ./home/t460s.nix;
            };
          }
        ];
      };
    };
}
