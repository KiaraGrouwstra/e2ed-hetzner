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

  # users.users.nextcloud.isNormalUser = true;

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
      # ${DB_USER} = {
      nextcloud = {
        isNormalUser = true;
      };
      postgres = {
        isSystemUser = true;
      };
    };
  };

  # # Reverse proxy for collabora
  # services.nginx.virtualHosts."${pconf.domain.collabora}" = {
  #   enableACME = true;
  #   forceSSL = true;
  #   locations."/" = {
  #     proxyPass = "http://localhost:9980";
  #     proxyWebsockets = true;
  #   };
  # };
  # # Collabora CODE server in a container
  # virtualisation.oci-containers = {
  #   backend = "podman";
  #   containers.collabora = {
  #     image = "collabora/code";
  #     ports = ["9980:9980"];
  #     environment = {
  #       # domain = "${pconf.domain.nextcloud}";
  #       extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
  #     };
  #     extraOptions = ["--cap-add" "MKNOD"];
  #   };
  # };
  # # Reverse proxy for Nextcloud
  # services.nginx.virtualHosts."${pconf.domain.nextcloud}" = {
  #   enableACME = true;
  #   forceSSL = true;
  #   locations."/" = {
  #     proxyPass = "http://${guest_address}";
  #     proxyWebsockets = true;
  #     extraConfig = ''
  #       proxy_redirect http://$host https://$host;  # required for apps
  #     '';
  #   };
  # };
  # # Nextcloud container service timing
  # systemd.services."containers@nextcloud" = {
  #   after = [ "mnt-box.mount" ];
  #   wants = [ "mnt-box.mount" ];
  # };
  # # Nextcloud server in a container
  # containers.nextcloud = {
  #   ephemeral = true;
  #   autoStart = true;
  #   privateNetwork = true;
  #   hostAddress = host_address;
  #   localAddress = guest_address;
  #   hostAddress6 = "fc00::1";
  #   localAddress6 = "fc00::2";
  #   bindMounts = {
  #     "/secrets" = { hostPath = "/persistent/nextcloud/secrets"; };
  #     "/var/lib/nextcloud" = {
  #       hostPath = "/persistent/nextcloud/home";
  #       isReadOnly = false;
  #     };
  #     "/var/lib/nextcloud/data" = {
  #       hostPath = "/mnt/box/nextcloud/data";
  #       isReadOnly = false;
  #     };
  #       "/var/lib/postgresql" = {
  #       hostPath = "/persistent/nextcloud/db";
  #       isReadOnly = false;
  #     };
  #   };
  #   config = { pkgs, config, ... }: {
  #     systemd.tmpfiles.rules = [
  #       "d /var/lib/nextcloud 700 nextcloud nextcloud -"
  #       "d /var/lib/postgresql 700 nextcloud nextcloud -"
  #       "d /var/lib/nextcloud/data 700 nextcloud nextcloud -"
  #     ];
  #     networking.firewall.enable = false;
  #     services.nextcloud = {
  #       enable = true;
  #       package = pkgs.nextcloud29;
  #       # hostName = pconf.domain.nextcloud;
  #       https = true;
  #       maxUploadSize = "20G";
  #       configureRedis = true;
  #       database.createLocally = true;
  #       config = {
  #         dbtype = "pgsql";
  #         # adminuser = pconf.mail.business;
  #         adminpassFile = "/secrets/pw";
  #       };
  #       settings = {
  #         trusted_proxies = [ host_address ];
  #         maintenance_window_start = 1;
  #         log_type = "file";
  #         mail_smtpmode = "smtp";
  #         # mail_smtphost = pconf.mail.smtp;
  #         mail_smtpport = 465;
  #         mail_smtpsecure = "ssl";
  #         mail_smtpauth = true;
  #         # mail_smtpname = pconf.mail.business;
  #         mail_from_address = "cloud";
  #         # mail_domain = pconf.domain.business;
  #       };
  #       phpOptions = {
  #         "opcache.interned_strings_buffer" = "10";
  #       };
  #       appstoreEnable = true;
  #       autoUpdateApps.enable = true;
  #       extraAppsEnable = true;
  #       extraApps = lib.attrValues { inherit (config.services.nextcloud.package.packages.apps)
  #         calendar end_to_end_encryption forms notes notify_push richdocuments;
  #       };
  #     };
  #     system.stateVersion = "24.05";
  #   };
  # };

  # services.nextcloud = {
  #   enable = true;
  #   package = pkgs.nextcloud29;
  #   hostName = "nextcloud";
  #   home = "/var/lib/nextcloud";
  #   maxUploadSize = "512 MB";
  #   configureRedis = true;
  #   config = {
  #     # adminuser = cfg.admin;
  #     adminpassFile = config.sops.secrets.postgres-password-nextcloud.path;
  #     dbtype = "pgsql";
  #     dbhost = "/run/postgresql";
  #   };

  #   https = true;

  #   settings = {
  #     overwriteprotocol = "https"; # Nginx only allows SSL
  #   };

  #   notify_push = {
  #     enable = true;
  #     # Allow using the push service without hard-coding my IP in the configuration
  #     bendDomainToLocalhost = true;
  #   };
  # };

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

  # systemd.services."nextcloud-setup" = {
  #   requires = [ "postgresql.service" ];
  #   after = [ "postgresql.service" ];
  # };

  # # The service above configures the domain, no need for my wrapper
  # services.nginx.virtualHosts."nextcloud.${config.networking.domain}" = {
  #   forceSSL = true;
  #   useACMEHost = config.networking.domain;
  # };

  # my.services.backup = {
  #   paths = [
  #     config.services.nextcloud.home
  #   ];
  #   exclude = [
  #     # image previews can take up a lot of space
  #     "${config.services.nextcloud.home}/data/appdata_*/preview"
  #   ];
  # };

}
