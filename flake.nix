{
  description = "Hiro-mackay dotfiles: nix-darwin + home-manager on macOS, home-manager on Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Not following nixpkgs: the numtide binary cache only hits on its own pin.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Claude Code plugins, pinned here instead of installed from their marketplaces.
    ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };
    codex-plugin-cc = {
      url = "github:openai/codex-plugin-cc";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      systems = [ "aarch64-darwin" ] ++ linuxSystems;
      forAllSystems = lib.genAttrs systems;
      isDarwin = lib.hasSuffix "darwin";

      # The user is read from the environment so no name is hardcoded. This needs
      # --impure (passed by `nix run .#switch`); pure evaluation such as
      # `nix flake check` falls back to a placeholder user.
      envOr =
        name: fallback:
        let
          value = builtins.getEnv name;
        in
        if value == "" then fallback else value;
      username = envOr "USER" "nixuser";
      homeDirectory =
        system: envOr "HOME" (if isDarwin system then "/Users/${username}" else "/home/${username}");

      darwin = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs username;
          homeDirectory = homeDirectory "aarch64-darwin";
        };
        modules = [
          inputs.determinate.darwinModules.default
          inputs.nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          ./darwin.nix
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
              users.${username}.imports = [ ./home.nix ];
            };
          }
        ];
      };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home.nix
            ./linux.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory system;
            }
          ];
        };
    in
    {
      darwinConfigurations.default = darwin;

      homeConfigurations = lib.genAttrs linuxSystems mkHome;

      packages = forAllSystems (system: {
        switch = import ./nix/switch.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          flake = self.outPath;
        };
      });

      # Evaluating these runs the module assertions (e.g. never evaluated as root).
      checks = forAllSystems (
        system:
        if isDarwin system then
          { default = self.darwinConfigurations.default.system; }
        else
          { home = self.homeConfigurations.${system}.activationPackage; }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
    };
}
