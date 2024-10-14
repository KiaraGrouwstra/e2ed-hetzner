# https://xeiaso.net/blog/paranoid-nixos-2021-07-18/
{
  lib,
  pkgs,
  ...
}: {
  nix.settings.allowed-users = ["root"];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
    # allowedUDPPorts = [ ... ];
  };

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = ["tailscale0"];

  # block fastly IP range 151.101.0.0/16 one level above to block NixOS cache CDN

  # ditch default packages: nano perl rsync
  environment.defaultPackages = lib.mkForce [];

  security = {
    # journalctl -f
    auditd.enable = true;
    audit.enable = lib.mkForce true;
    audit.rules = [
      "-a exit,always -F arch=b64 -S execve"
    ];

    sudo = {
      enable = false;
      execWheelOnly = true;
    };
  };

  # disable proxying traffic
  services.openssh = {
    allowSFTP = false; # Don't set this if you need sftp
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
    settings = {
      PasswordAuthentication = false;
      challengeResponseAuthentication = false;
    };
  };

  # # disable execution for all non nix store file systems
  # fileSystems."/".options = [ "noexec" ];

  # PCI compliance
  environment.systemPackages = [pkgs.clamav];

  # systemd options:

  # ProtectHome/ProtectSystem
  # These options allow you to change how systemd presents critical system files and /home to a given process. You can use this to remove the ability for a service to modify system files or peek into user's home directories, even as root. This allows you to put a lot more limits on a service's power.

  # NoNewPrivileges
  # If this is set, child processes of this service cannot gain more privileges period. Even if the child process is a suid binary.

  # ProtectKernel{Logs,Modules,Tuneables}
  # These ones are fairly simple so I'm gonna use some bullet trees for them:

  # ProtectKernelLogs: If set to true, the service cannot access the kernel message buffer that you get by running dmesg or reading from /proc/kmsg.
  # ProtectKernelModules: If set to true, the service cannot load or unload kernel modules.
  # ProtectKernelTunables: If set to true, various twiddly bits in /proc and /sys that let you control tunable values in the kernel will be made read-only. Most of the time these values are set early in the system boot process and never twiddled with again, so it's reasonable to deny a service (and its child processes) access to these
}
