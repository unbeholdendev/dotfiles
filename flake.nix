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
    hermes.url = "github:NousResearch/hermes-agent";
  };

  outputs = { nixpkgs, home-manager, disko, hermes, ... }:
    let
      system = "x86_64-linux";

      # Named rather than allowUnfree, so a second one cannot arrive unseen.
      agentPkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          p: builtins.elem (nixpkgs.lib.getName p) [ "claude-code" ];
      };

      laptopDotfiles = "/home/pycan/Documents/dotfiles";
      # Root's, readable by agent: root must never build from a clone agent can write.
      orenDotfiles = "/srv/dotfiles";

      homeOn = { user, module, dotfiles, target, extraSpecialArgs ? { } }: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = false;
          backupFileExtension = "hm-bak";
          extraSpecialArgs = {
            inherit dotfiles target;
            nixos = true;
          } // extraSpecialArgs;
          users.${user} = import module;
        };
      };
    in
    {
      homeConfigurations = {
        "pycan@t460s" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = {
            dotfiles = laptopDotfiles;
            target = "pycan@t460s";
            nixos = false;
          };
          modules = [ ./home/laptop.nix ];
        };
        container = home-manager.lib.homeManagerConfiguration {
          pkgs = agentPkgs;
          extraSpecialArgs.dotfiles = null;
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
            (homeOn {
              user = "pycan";
              module = ./home/laptop.nix;
              dotfiles = laptopDotfiles;
              target = name;
            })
          ];
        }) // {
        oren = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs.dotfiles = orenDotfiles;
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            ./nixos/oren.nix
            { nixpkgs.pkgs = agentPkgs; }
            (homeOn {
              user = "agent";
              module = ./home/oren.nix;
              dotfiles = orenDotfiles;
              target = "oren";
              extraSpecialArgs = { inherit hermes; };
            })
          ];
        };
      };
    };
}
