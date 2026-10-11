{ ... }:

# NOTE: not imported by modules/home/home.nix. Kept for reference only.
# The server domain was previously globals.Bwserver, which was always "".
{
  services.bitwarden-directory-connector-cli.domain = "";
  services.bitwarden-directory-connector-cli.enable = true;
}
