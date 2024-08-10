# https://github.com/balintbarna/nixos-configs/tree/master/hosts/vps
{
  lib,
  pkgs,
  config,
  ...
}: let
  DB_USER = "nextcloud";
  DB_GROUP = "dbaccess";
  host_address = "192.168.100.10";
  guest_address = "192.168.100.11";
in {

  environment.systemPackages = [
    pkgs.sops
  ];

  sops = {
    age.keyFile = "/run/container-secrets/sops_key";
    defaultSopsFile = ../../secrets.enc.yaml;
    # /run/secrets
    secrets = {
      postgres-password-nextcloud = {
        group = DB_GROUP;
        mode = "0440";
        restartUnits = [ "postgresql.service" ];
      };
    };
  };

  users = {
    mutableUsers = false;
    groups = {
      ${DB_GROUP}.members = [
        "postgres"
        DB_USER
      ];
    };
    # generate password hash by `mkpasswd -m sha-512 mySuperSecretPassword`
    users = {
      ${DB_USER} = {
        isSystemUser = true;
      };
      postgres = {
        isSystemUser = true;
      };
    };
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud";
    home = "/var/lib/nextcloud";
    https = true;
    maxUploadSize = "512M";
    configureRedis = true;
    database.createLocally = true;
    config = {
      # adminuser = cfg.admin;
      adminpassFile = config.sops.secrets.postgres-password-nextcloud.path;
      dbtype = "pgsql";
      # dbhost = "/run/postgresql";
    };
    settings = {
      trusted_proxies = [ host_address ];
      maintenance_window_start = 1;
      log_type = "file";
      mail_smtpmode = "smtp";
      # mail_smtphost = pconf.mail.smtp;
      mail_smtpport = 465;
      mail_smtpsecure = "ssl";
      mail_smtpauth = true;
      # mail_smtpname = pconf.mail.business;
      mail_from_address = "cloud";
      # mail_domain = pconf.domain.business;
      overwriteprotocol = "https"; # Nginx only allows SSL
    };
    phpOptions = {
      "opcache.interned_strings_buffer" = "10";
    };
    appstoreEnable = true;
    autoUpdateApps.enable = true;
    extraAppsEnable = true;
    extraApps = { inherit (config.services.nextcloud.package.packages.apps)
      mail calendar contacts end_to_end_encryption forms notes notify_push richdocuments;
    };
    # # Could not resolve host: nextcloud
    # notify_push = {
    #   enable = true;
    #   # Allow using the push service without hard-coding my IP in the configuration
    #   bendDomainToLocalhost = true;
    # };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };

  # environment.variables = {
  #   PODMAN_IGNORE_CGROUPSV1_WARNING = 1;
  # };

  # # Collabora CODE server in a container
  # # Error: crun: creating cgroup directory `/sys/fs/cgroup/freezer/libpod_parent/libpod-*`: No such file or directory: OCI runtime attempted to invoke a command that was not found
  # virtualisation.oci-containers.containers = {
  #   "collabora" = {
  #     image = "collabora/code";
  #     ports = ["9980:9980"];
  #     environment = {
  #       # domain = "${pconf.domain.nextcloud}";
  #       extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
  #     };
  #     extraOptions = ["--cap-add" "MKNOD"];
  #   };
  # };

  systemd.tmpfiles.rules = [
    "d /var/lib/nextcloud 700 nextcloud nextcloud -"
    "d /var/lib/postgresql 700 nextcloud nextcloud -"
    "d /var/lib/nextcloud/data 700 nextcloud nextcloud -"
  ];

}
