{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Named rather than allowUnfree, so a second one cannot arrive unseen.
      containerPkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          p: builtins.elem (nixpkgs.lib.getName p) [ "claude-code" ];
      };
    in
    {
      homeConfigurations = {
        "pycan@t460s" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            dotfiles = "/home/pycan/Documents/dotfiles";
            target = "pycan@t460s";
          };
          modules = [ ./home/t460s.nix ];
        };

        container = home-manager.lib.homeManagerConfiguration {
          pkgs = containerPkgs;
          extraSpecialArgs = {
            dotfiles = null;
          };
          modules = [ ./home/container.nix ];
        };

        "root@deb-agent" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            dotfiles = "/root/dotfiles";
            target = "root@deb-agent";
          };
          modules = [ ./home/deb-agent.nix ];
        };
      };
    };
}
