{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = "
    MAILADDR root
  ";

  # Network
  networking = {
    hostName = "tardis";
    interfaces = {
      enp5s0.ipv4.addresses = [{
        address = "192.168.1.52";
        prefixLength = 24;
      }];
    };
    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" ];
  };

  # Users
  users.users.dylan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "lxd" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Tailscale
  services.tailscale = {
    enable = true;
    authKeyFile = "/root/tailscale.key";
  };

  time.timeZone = "Europe/Athens";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    gnupg
    lm_sensors
    parted
    tmux
    vim
  ];

  # openssh
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # lxd
  virtualisation.lxd.enable = true;
  virtualisation.libvirtd.enable = true;
  networking.firewall.trustedInterfaces = [ "lxdbr0" ];

  # k3s
  services.k3s = {
    enable = true;
    extraFlags = "--disable traefik --default-local-storage-path /storage/k8s";
  };

  system.stateVersion = "24.05";

}
