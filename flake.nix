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
    # Opt-in output-shaping skill (/i-have-adhd), shared by Claude Code and Codex.
    # Only the skill is used; the repo's always-on SessionStart hook is not.
    i-have-adhd = {
      url = "github:ayghri/i-have-adhd";
      flake = false;
    };
    # Warp notifications for Claude Code (the Codex counterpart is codex-warp below).
    claude-code-warp = {
      url = "github:warpdotdev/claude-code-warp";
      flake = false;
    };
    # Codex plugin marketplace, pinned here instead of fetched by Codex from git.
    codex-warp = {
      url = "github:warpdotdev/codex-warp";
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

      # The user comes from the environment (no name is hardcoded), so every evaluation
      # needs --impure; `nix run .#switch` and CI pass it.
      username = builtins.getEnv "USER";
      homeDirectory = builtins.getEnv "HOME";

      # The whole home-manager configuration as one module: this flake's machines use it,
      # and so can another flake that builds on it (a container, say). Such a flake imports
      # it and sets options.dotfiles (options.nix), or plainly overrides what is set with
      # lib.mkDefault; the flake inputs come along, so it passes no specialArgs.
      homeModule = {
        imports = [
          inputs.nix-index-database.homeModules.nix-index
          ./options.nix
          ./home.nix
          ./linux.nix
        ];
        _module.args.inputs = inputs;
      };

      darwin = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs username homeDirectory; };
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
              users.${username}.imports = [ homeModule ];
            };
          }
        ];
      };

      mkHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            homeModule
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in
    {
      homeModules.default = homeModule;

      darwinConfigurations.default = darwin;

      homeConfigurations = lib.genAttrs linuxSystems mkHome;

      packages = forAllSystems (system: {
        switch = import ./nix/switch.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          flake = self.outPath;
        };
      });

      # Evaluating these catches module errors in every configuration.
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
