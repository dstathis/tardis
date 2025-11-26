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
      br0.ipv4.addresses = [{
        address = "192.168.1.52";
        prefixLength = 24;
      }];
    };
    defaultGateway = "192.168.1.1";
    nameservers = [ "192.168.1.1" ];
    bridges = {
      br0 = {
        interfaces = [ "enp6s0" ];
      };
    };
  };

  # Users
  users.users.dylan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "incus-admin"];
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

  # incus
  virtualisation.incus = {
    enable = true;
    package = pkgs.incus-lts;
  };
  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "lxdbr0" ];

  # libvirtd
  virtualisation.libvirtd.enable = true;

  # k3s
  services.k3s = {
    enable = true;
    extraFlags = "--disable traefik --disable servicelb --default-local-storage-path /storage/k8s";
  };

  # Metrics
  services.prometheus.exporters.node = {
    enable = true;
    extraFlags = [ "--collector.filesystem.mount-points-exclude=\"^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+|var/lib/containers/storage/.+|var/lib/kubelet/.+|run/user/.+|run/k3s/containerd/.+)($|/)\"" ];
  };

  # Logs
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        disable = true;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://loki-coordinator/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "pods";
        static_configs = [{
          targets = [ "localhost" ];
          labels = {
            job = "pods";
            __path__ = "/var/log/pods/**.log";
          };
        }];
      }];
    };
  };

  system.stateVersion = "24.05";

}
