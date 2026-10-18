{ lib, ... }:
{
  options.my.fleet = lib.mkOption {
    default = { };
    description = ''
      Facts about the other machines. The entries live in
      `hosts/fleet.nix`; this only declares their shape. Read by
      `my.ssh.agent` for the client aliases and by `my.ssh.server` for
      authorized keys.

      Keys are the ssh alias. The local host appears here too, since servers
      need its key, and the client config skips whichever entry matches
      `networking.hostName`.

      Which keys a server trusts is an explicit list today
      (`my.ssh.server.authorize`). If that gets tedious, add a `roles` field
      here and let the server name roles instead of machines, so a new laptop
      is trusted everywhere by one edit.
    '';
    example = {
      mbp = {
        lan = "10.10.1.115";
        tailnet = "jeremys-macbook-pro";
      };
    };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          lan = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Address on the LAN, used as the fallback when the tailnet is
              down. Null for a machine only ever reached over the tailnet.
            '';
          };

          tailnet = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "jeremys-macbook-pro";
            description = ''
              MagicDNS name, when it differs from the alias. Null means the
              alias is already the tailnet name.
            '';
          };

          userKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Public key this machine's user connects with, for the servers
              that should accept it. Null for a machine that never connects
              out, like a host only ever sshed into.
            '';
          };
        };
      }
    );
  };

  # The entries themselves, so adding a machine means editing a file that is
  # only the list.
  config.my.fleet = import ../hosts/fleet.nix;
}
