{
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
