{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  my.user = "jh";
  my.profiles.workstation.enable = true;

  # machine-specific capabilities
  my.nvidia.enable = true;
  my.zram.enable = true;
  my.gaming.enable = true;
  my.virtualisation.enable = true;
  my.onepassword.enable = true;
  my.ssh.server.enable = true;
  my.ssh.server.interfaces = [
    "eno1"
    "tailscale0"
  ];
  my.devtools.enable = true;
  my.secrets.enable = true;
  my.devtools.agentSandbox = true;
  my.devtools.languages = [
    "c"
    "deno"
    "elixir"
    "go"
    "nix"
    "node"
    "rust"
  ];
  my.i18n.languages = [
    "korean"
    "japanese"
  ];
  my.tailscale.enable = true;
  my.tailscale.gui = true;

  my.shell.history = "fzf";

  # Without this, Tailscale owned /etc/resolv.conf alone and DNS failed at
  # login until the link was toggled -- see modules/dns.nix.
  my.dns.systemdResolved = true;
  my.greeter.backend = "noctalia";

  # Desktop on mains power: no reason to throttle.
  my.power.profile = "performance";

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

    packages = with pkgs; [
      # chromium
      google-chrome
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
