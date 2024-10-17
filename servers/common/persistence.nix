{
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
