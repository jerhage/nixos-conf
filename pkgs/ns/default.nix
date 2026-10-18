# nixpkgs search in the terminal, from nix-search-tv's own fzf wrapper script.
# Taken from the package's source rather than vendored, so it tracks the tool.
{
  writeShellApplication,
  fzf,
  nix-search-tv,
}:
writeShellApplication {
  name = "ns";

  runtimeInputs = [
    fzf
    nix-search-tv
  ];

  # The script uses single-quoted $-expressions that shellcheck reads as
  # unexpanded variables.
  excludeShellChecks = [ "SC2016" ];

  text = builtins.readFile "${nix-search-tv.src}/nixpkgs.sh";
}
