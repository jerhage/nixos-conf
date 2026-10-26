{
  config,
  pkgs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  my.user = "jh";
  my.profiles.workstation.enable = true;
  my.profiles.personal.enable = true;

  # machine-specific capabilities
  my.nvidia.enable = true;
  my.zram.enable = true;
  my.gaming.enable = true;
  my.gaming.streaming.enable = true;
  my.gaming.client.enable = true;

  # No 3:2 mode here for helix's panel; 16:9 wastes less of it than 21:9.
  my.gaming.streaming.prepCommands = [
    {
      do = "niri msg output DP-3 mode 1920x1080@143.847";
      undo = "niri msg output DP-3 mode 3440x1440@164.900";
    }
  ];
  my.virtualisation.enable = true;
  my.ssh.server.enable = true;
  my.ssh.server.interfaces = [
    "eno1"
    "tailscale0"
  ];
  my.devtools.enable = true;
  my.secrets.enable = true;
  my.devtools.agentSandbox = true;
  my.tailscale.enable = true;

  # Without this, Tailscale owned /etc/resolv.conf alone and DNS failed at
  # login until the link was toggled -- see modules/dns.nix.
  my.dns.systemdResolved = true;
  my.greeter.backend = "noctalia";

  # Firmware updates for LVFS-supported devices. Not this board's BIOS.
  services.fwupd.enable = true;

  # This board's S3 never resumes; s2idle avoids the firmware handoff.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    # Bounds the boot menu. Older generations stay in /nix until collected.
    systemd-boot.configurationLimit = 10;
  };

  hardware.enableAllFirmware = true;

  time.timeZone = "America/Chicago";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  my.vm.shareDotfiles = false;

  my.sync.pulls.pictures = {
    from = "mbp:~/Pictures/";
    to = "~/Pictures/";
  };

  # my.sync.cloud = {
  #   tmw = {
  #     local = "~/tmw/";
  #     remote = "crypt:tmw/";
  #   };
  # };

  users.users.${config.my.user} = {
    description = "Main User";
    extraGroups = [
      "networkmanager"
      "wireshark"
    ];
  };

  my.apps.enable = true;
  my.accounting.enable = true;

  # One-offs, not part of any module's set.
  environment.systemPackages = with pkgs; [
    claude-code
    rclone # only enabled here because not enabling cloud sync module atm
  ];

  system.stateVersion = "25.11";
}
