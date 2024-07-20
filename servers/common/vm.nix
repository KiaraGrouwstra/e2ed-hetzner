{ pkgs, ... }: {
  # customize nixos-rebuild build-vm to be a bit more convenient
  virtualisation.vmVariant = {
    # let us log in
    users.mutableUsers = false;
    users.users.root.hashedPassword = "";
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PermitEmptyPasswords = "yes";
        UsePAM = false;
      };
    };

    # automatically log in
    services.getty.autologinUser = "root";
    services.getty.helpLine = ''
      Type `C-a c` to access the qemu console
      Type `C-a x` to quit
    '';
    # access to convenient things
    environment.systemPackages = with pkgs; [
      w3m
      python3
      xterm # for `resize`
    ];
    environment.loginShellInit = ''
      eval "$(resize)"
    '';
    nix.extraOptions = ''
      extra-experimental-features = nix-command flakes
    '';

    # no graphics. see nixos-shell
    virtualisation = {
      graphics = false;
      qemu.consoles = [ "tty0" "hvc0" ];
      qemu.options = [
        "-serial null"
        "-device virtio-serial"
        "-chardev stdio,mux=on,id=char0,signal=off"
        "-mon chardev=char0,mode=readline"
        "-device virtconsole,chardev=char0,nr=0"
      ];
    };
  };
}
