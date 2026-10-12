# devenv dev shell. Use this over the plain devshell template when you want a
# database or background process to start with the shell.
#
#   nix develop --impure    devenv requires --impure
#   direnv allow            uses the .envrc here
#   devenv up               starts the services and processes below
{
  description = "development environment (devenv)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, devenv, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          {
            languages.elixir.enable = true;
            languages.javascript = {
              enable = true;
              package = pkgs.nodejs_24;

              # Runs the install on shell entry, so a fresh clone is ready.
              # pnpm.enable = true;
              # pnpm.install.enable = true;
            };

            packages = with pkgs; [ ripgrep ];

            # State lives in ./.devenv -- per-project, delete it to reset.
            #
            # services.postgres = {
            #   enable = true;
            #   package = pkgs.postgresql_16;
            #   listen_addresses = "127.0.0.1";
            #   port = 5432;
            #   initialDatabases = [
            #     { name = "myapp_dev"; schema = ./priv/structure.sql; }
            #     { name = "myapp_test"; }
            #   ];
            #   initialScript = "CREATE EXTENSION IF NOT EXISTS citext;";
            # };
            #
            # services.redis.enable = true;
            #
            # processes.server.exec = "mix phx.server";
            # processes.watch = { exec = "pnpm run dev"; cwd = "./assets"; };

            enterShell = ''
              echo "elixir $(elixir --version | tail -1)"
            '';
          }
        ];
      };
    };
}
