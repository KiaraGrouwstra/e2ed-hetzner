# https://github.com/balintbarna/nixos-configs/tree/master/hosts/vps
{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (import ../../lib/default.nix {inherit lib pkgs;}) patchContainers;
  DB_NAME = "nextcloud";
  DB_USER = "nextcloud";
  DB_PORT = 5432;
  host_address = "192.168.100.10";
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
        owner = DB_USER;
        restartUnits = ["postgresql.service"];
      };
    };
  };

  users = {
    mutableUsers = false;
    users.postgres.isSystemUser = true;
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
      adminuser = "root";
      adminpassFile = config.sops.secrets.postgres-password-nextcloud.path;
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      # dbhost = "localhost:${DB_PORT}";
      dbuser = DB_USER;
      dbname = DB_NAME;
    };
    settings = {
      trusted_proxies = [host_address];
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
    autoUpdateApps = {
      enable = true;
      startAt = "05:00:00";
    };
    extraAppsEnable = true;
    # https://apps.nextcloud.com/
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/29.json
    extraApps = {
      inherit
        (config.services.nextcloud.package.packages.apps)
        bookmarks
        calendar
        contacts
        # cookbook
        
        # cospend
        
        # deck # duplicate key value violates unique constraint
        
        end_to_end_encryption
        forms
        gpoddersync
        groupfolders
        impersonate
        integration_openai
        mail
        maps
        # memories
        
        # music # duplicate key value violates unique constraint
        
        notes
        notify_push
        # onlyoffice # duplicate key value violates unique constraint
        
        # phonetrack
        
        # polls # duplicate key value violates unique constraint
        
        # previewgenerator
        
        # qownnotesapi
        
        # registration
        
        richdocuments
        spreed
        tasks
        # twofactor_nextcloud_notification
        
        # twofactor_webauthn
        
        unroundedcorners
        # user_oidc # duplicate key value violates unique constraint
        
        # user_saml
        
        ;
    };
    # # Could not resolve host: nextcloud
    # notify_push = {
    #   enable = true;
    #   # Allow using the push service without hard-coding my IP in the configuration
    #   bendDomainToLocalhost = true;
    # };
  };

  services.nginx.virtualHosts."localhost".listen = [
    {
      addr = "127.0.0.1";
      port = 8000;
    }
  ];

  services.postgresql = {
    enable = true;
    ensureDatabases = [DB_NAME];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local sameuser  all     peer
    '';
    settings = {
      port = DB_PORT;
    };
  };

  # environment.variables = {
  #   PODMAN_IGNORE_CGROUPSV1_WARNING = 1;
  # };

  # Collabora CODE server in a container
  virtualisation.oci-containers.containers = patchContainers {
    "collabora" = {
      image = "collabora/code";
      ports = ["9980:9980"];
      environment = {
        # domain = "${pconf.domain.nextcloud}";
        extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
      };
      extraOptions = ["--cap-add" "MKNOD"];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/nextcloud 700 nextcloud nextcloud -"
    "d /var/lib/postgresql 700 nextcloud nextcloud -"
    "d /var/lib/nextcloud/data 700 nextcloud nextcloud -"
  ];
}
