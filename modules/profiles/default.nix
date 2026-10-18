# Two independent axes, combined per host rather than nested: what kind of
# machine it is, and whose it is. A work laptop is portable without being mine,
# which one hierarchy could not express.
#
#   base             interactive, no graphics
#     graphical      the session, saying nothing about power or ownership
#       workstation  graphical, stays put
#       laptop       graphical, runs on battery
#
#     server         headless, runs services
#
#   personal         my own habits and accounts
{
  imports = [
    ./base.nix
    ./graphical.nix
    ./workstation.nix
    ./laptop.nix
    ./server.nix
    ./personal.nix
  ];
}
