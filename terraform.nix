{
  lib,
  pkgs,
  inputs,
  ...
}: let
  util = import ./lib/default.nix {inherit lib;};
  inherit
    (util)
    pipes
    compose
    evolve
    dirContents
    mapVals
    default
    defaults
    inNamespace
    setNames
    setFromKey
    transforms
    tfRef
    var
    ;

  # default if not specified
  private.public_net = {
    ipv6_enabled = false;
    ipv4_enabled = false;
  };

  public.public_net = {
    # auto-generate
    ipv6_enabled = true;
    # € 0.50 / mo
    ipv4_enabled = false;
  };

  nixos.public_net = {
    ipv6_enabled = true;
    ipv4_enabled = true;
  };

  # common options
  hcloud = evolve transforms rec {
    inherit (nixos) public_net;

    # https://docs.hetzner.com/cloud/servers/overview/#pricing
    # cheapest shared-vcpu arm type
    server_type = "cax11"; # arm
    # server_type = "cx31";

    # https://docs.hetzner.com/general/others/data-centers-and-connection
    network_zone = "eu-central";
    location = "nbg1";
    datacenter = "nbg1-dc3";

    ip = {
      # free for primary IPs
      type = "ipv6";
    };

    ssh_keys = tfRef "data.hcloud_ssh_keys.all.ssh_keys.*.name";

    # billed +20%
    backups = false;

    # `xfs` is generally considered to be faster and more scalable,
    # `ext4` is better for reading small files and single-threaded I/O operations.
    format = "ext4";

    # placement_group_id = "production";

    # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/firewall_attachment#ensure-a-server-is-attached-to-a-firewall-on-first-boot
    ignore_remote_firewall_ids = true;
    firewall_ids = ["deny_all"];

    # Whether to try shutting the server down gracefully before deleting it.
    shutdown_before_deletion = true;

    # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs#delete-protection
    # The Hetzner Cloud API allows to protect resources from deletion by putting a "lock" on them.
    # This can also be configured through OpenTofu through the `delete_protection` argument on resources that support it.
    # Please note, that this does not protect deletion from OpenTofu itself,
    # as the Provider will lift the lock in that case.
    # If you also want to protect your resources from deletion by OpenTofu,
    # you can use the [`prevent_destroy` lifecycle attribute](https://opentofu.org/docs/language/meta-arguments/lifecycle#syntax-and-arguments).
    delete_protection = false;

    # Needs to be the same as `delete_protection`
    rebuild_protection = delete_protection;

    # Whether auto delete is enabled.
    # `Important note:` It is recommended to set `auto_delete` to `false`,
    # because if a server assigned to a managed ip is getting deleted,
    # it will also delete the primary IP which will break the TF state.
    auto_delete = false;

    # If true, do not upgrade the disk. This allows downgrading the server type later.
    keep_disk = false;

    network_id = "production";
    network = {
      network_id = "production";
      # https://github.com/hetznercloud/terraform-provider-hcloud/issues/650#issuecomment-1497160625
      alias_ips = [];
    };

    # Automount the volume upon attaching it (server_id must be provided).
    automount = true;

    # In this block you can either enable / disable ipv4 and ipv6
    # or link existing primary IPs (checkout the examples).
    # If this block is not defined, two primary (ipv4 & ipv6) ips getting auto generated.

    # **Note**: the `depend_on` is important when directly attaching the server to a network.
    # Otherwise Terraform will attempt to create server and sub-network in parallel.
    # This may result in the server creation failing randomly.
    depends_on = [
      "hcloud_network_subnet.production"
    ];

    # extraConfig = {};
    # provisioners = [];
    # provisioners = [{"file":{"destination":"/root/.zshrc","source":"~/.zshrc"}},{"remote-exec":{"inline":["shutdown -r +1"]}}];
    # # container-specific config
    # `hcloud image list`
    image = "ubuntu-24.04";
    # placement_group_id = tfRef "hcloud_placement_group.production-dbs.id";
    labels = {
      environment = "production";
    };
  };
  server_common = {
    inherit
      (hcloud)
      server_type
      image
      datacenter
      ssh_keys
      keep_disk
      labels
      backups
      firewall_ids
      ignore_remote_firewall_ids
      network
      delete_protection
      rebuild_protection
      shutdown_before_deletion
      depends_on
      ;
  };
  servers = setNames ((lib.mapAttrs (name: cfg:
    defaults [
      server_common
      {
        public_net = {
          ipv4 = tfRef "hcloud_primary_ip.${name}_ipv4.id";
          ipv6 = tfRef "hcloud_primary_ip.${name}_ipv6.id";
        };
      }
      cfg
    ])) {
    combined = {};
  });

  # Set the variable value in *.tfvars file
  # or using -var="hcloud_api_token=..." CLI option
  variable =
    mapVals (default {
      type = "string";
    }) ((
        mapVals (default {
          sensitive = true;
        }) {
          # tf_cloud_token = {
          #   description = "[Terraform Cloud](https://app.terraform.io/) token";
          # };
          hcloud_api_token = {
            description = "[Hetzner Cloud API Token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token)";
          };
        }
      )
      // (
        mapVals (default {
          sensitive = false;
        }) {
          ssh_key = {
            type = "string";
            description = "SSH private key used by `nixos-anywhere` for server set-up.";
            # sensitive = true;  # hides the key but prevents seeing feedback during apply
          };
          cloudflare_account_id = {};
        }
      ));

  data =
    inNamespace "hcloud"
    (
      lib.genAttrs
      [
        # read:
        # "datacenters"
        # "locations"
        # "images"
        # "server_types"

        # read/write:
        "ssh_keys"
        "certificates"
        "firewalls"
        "floating_ips"
        "load_balancers"
        "networks"
        "placement_groups"
        "primary_ips"
        "servers"
        "volumes"
      ]
      (_type: {"all" = {};})
    );

  # https://registry.terraform.io/providers
  resource =
    {
      # https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/r2_bucket
      # https://developers.cloudflare.com/r2/examples/terraform/
      "cloudflare_r2_bucket" = setNames (mapVals (default {
          account_id = var "cloudflare_account_id";
          location = "WEUR";
        }) {
          "atticd" = {};
        });
    }
    //
    # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
    inNamespace "hcloud"
    {
      ssh_key =
        setNames
        (
          lib.mapAttrs
          (_: v: {public_key = v;})
          (dirContents ".pub" ./ssh-keys)
        );

      # https://docs.hetzner.com/cloud/placement-groups/overview
      placement_group = setNames (mapVals (default {
          # this is the only option so far
          type = "spread";
        }) {
          "production-dbs" = {
            inherit (hcloud) labels;
          };
        });

      # https://docs.hetzner.com/cloud/networks/overview
      network = setNames (mapVals (default {
          inherit (hcloud) delete_protection labels;
          # https://docs.hetzner.com/cloud/networks/connect-dedi-vswitch/
          expose_routes_to_vswitch = false;
          # https://datatracker.ietf.org/doc/html/rfc1918
          ip_range = "10.0.0.0/8";
        }) {
          "production" = {};
        });

      # https://docs.hetzner.com/cloud/networks/faq/#what-are-subnets
      network_subnet =
        mapVals (default {
          inherit (hcloud) network_zone;
          type = "cloud"; # server, cloud or vswitch
          ip_range = "10.0.0.0/24";
          # vswitch_id = 0;
        }) {
          "production" = {
            inherit (hcloud) network_id;
          };
        };

      # https://docs.hetzner.com/cloud/networks/faq/#what-are-routes
      # ensure packets for a given destination IP prefix
      # will be sent to the address specified in its gateway
      network_route = mapVals (default {
        }) {
        "production" = {
          inherit (hcloud) network_id;
          # Destination network or host of this route.
          # Must be a subnet of the ip_range of the Network.
          # Must not overlap with an existing ip_range in any subnets
          # or with any destinations in other routes
          # or with the first ip of the networks ip_range.
          destination = "10.100.1.0/24";
          # Gateway for the route. Cannot be the first ip of the networks ip_range.
          gateway = "10.0.1.1";
        };
      };

      primary_ip = setNames (
        mapVals
        (default {
          inherit (hcloud) delete_protection auto_delete datacenter labels;
          inherit (hcloud.ip) type;
          assignee_type = "server";
        })
        (lib.mergeAttrsList (lib.attrValues (lib.mapAttrs (name: _cfg: {
            "${name}_ipv4" = {
              type = "ipv4";
            };
            "${name}_ipv6" = {
              type = "ipv6";
            };
          })
          servers)))
      );

      # # https://docs.hetzner.com/cloud/floating-ips/faq
      # floating_ip = setNames (mapVals (compose [
      #   (evolve transforms)
      #   (name: {server_id=tfRef "hcloud_server.${name}.id";})
      #   (default {
      #     inherit (hcloud) delete_protection labels;
      #     inherit (hcloud.ip) type;
      #     home_location = hcloud.location;
      #   })
      # ])
      # (lib.mapAttrs (name: _cfg: {
      #   "${name}" = name;
      # })));

      # https://docs.hetzner.com/cloud/firewalls/overview
      firewall = setNames (mapVals (compose [
          (evolve transforms)
          (default {inherit (hcloud) labels;})
        ])
        {
          "deny_all" = {};
          "production" = {
            # The `firewall_ids` property of the `hcloud_server` resource ensures
            # that a server is attached to the specified Firewalls before its first boot.
            # This is not the case when using the `hcloud_firewall_attachment`
            # resource to attach servers to a Firewall.
            apply_to = {
              label_selector = hcloud.labels;
              # server = "tryton";
            };
            rule = [
              {
                direction = "in";
                protocol = "tcp";
                port = "22";
                source_ips = [
                  "0.0.0.0/0"
                  "::/0"
                ];
                # destination_ips = [
                #     format("%s/32", hcloud_server.test_server.ipv4_address)
                # ]
              }
            ];
          };
        });

      # Attaches resource to a Hetzner Cloud Firewall; one per firewall
      # not attached before boot without more workarounds
      firewall_attachment =
        pipes [
          # attach to firewall of the same name
          (setFromKey "firewall_id")
          (mapVals (evolve transforms))
        ] {
          "deny_all" = {
            label_selectors = [hcloud.labels];
          };
          "production" = {
            label_selectors = [hcloud.labels];
            # or:
            # server_ids = ["tryton"];
          };
        };

      # # https://docs.hetzner.com/cloud/volumes/overview/#pricing
      # volume = setNames (setFromKey "server_id" (mapVals (compose [
      #     (evolve transforms)
      #     (default {
      #       inherit (hcloud) delete_protection automount format location;
      #       # https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy
      #       lifecycle.prevent_destroy = true;
      #     })
      #   ])
      #   {
      #     # tfRef "hcloud_volume.combined.linux_device"
      #     "combined" = {
      #       size = 10;
      #     };
      #   }));

      # ssh root@$( tofu output nixserver-server1_ipv4_address ) -i ./sshkey
      server = servers;
    };

in {
  inherit variable data resource;

  terraform = {
    required_providers = lib.mapAttrs (k: v:
      v
      // {
        # pin provider versions by nix flake inputs
        version = "= ${pkgs.terraform-providers.${k}.version}";
      }) {
      hcloud.source = "hetznercloud/hcloud";
      tls.source = "hashicorp/tls";
      ssh.source = "loafoe/ssh";
      external.source = "hashicorp/external";
      null.source = "hashicorp/null";
      cloudflare.source = "cloudflare/cloudflare";
    };
  };

  provider = {
    hcloud = {
      token = var "hcloud_api_token";
    };
    cloudflare = {
      # token pulled from $CLOUDFLARE_API_TOKEN
    };
  };

  # https://github.com/nix-community/nixos-anywhere/blob/main/terraform/all-in-one.md
  module =
    lib.mapAttrs (server_name: server_cfg: let
      system = util.hcloud_architecture server_cfg.server_type;
      # pin module version by nix flake inputs
      src = inputs.nixos-anywhere.sourceInfo;
    in {
      depends_on = ["hcloud_server.${server_name}"];
      # source = "github.com/numtide/nixos-anywhere?ref=${src.rev}/terraform/all-in-one";
      source = "../nixos-anywhere/terraform/all-in-one";
      nixos_system_attr = ".#nixosConfigurations.${system}.${server_name}.config.system.build.toplevel";
      nixos_partitioner_attr = ".#nixosConfigurations.${system}.${server_name}.config.system.build.diskoScriptNoDeps";
      target_host = tfRef "hcloud_server.${server_name}.ipv4_address";
      instance_id = tfRef "hcloud_server.${server_name}.id";
      install_user = "root";
      install_port = "22";
      install_ssh_key = var "ssh_key";
      debug_logging = true;
      extra_build_env_vars = {
        # all variables
        # TF_VARS = lib.strings.toJSON (lib.mapAttrs (k: _: tfRef "jsonencode(var.${k})") variable);
        # non-sensitive variables
        TF_VARS = tfRef "jsonencode(${lib.strings.toJSON (lib.mapAttrs (k: _: var k) (lib.filterAttrs (_k: v: !(v ? sensitive && v.sensitive)) variable))})";
        TF_DATA = tfRef "jsonencode(${lib.strings.toJSON (lib.mapAttrs (type: instances: lib.mapAttrs (k: _: tfRef "data.${type}.${k}") instances) data)})";
        TF_RESOURCES = tfRef "jsonencode(${lib.strings.toJSON (lib.mapAttrs (type: instances: lib.mapAttrs (k: _: tfRef "resource.${type}.${k}") instances) resource)})";
        TF_SERVER = tfRef "jsonencode(resource.hcloud_server.${server_name})";
        SERVER_NAME = server_name;
      };
    })
    servers;
}
