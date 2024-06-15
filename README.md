# tofu

Contains [OpenTofu](https://opentofu.org/) code used to manage our infrastructure, Nix'ified for [Teraflops](https://github.com/aanderse/teraflops).

## Prerequisites

- [Nix](https://nix.dev/) with [Flakes](https://nixos.wiki/wiki/Flakes) enabled
- Credentials (see [configuring](#configuring)), if not using the [shared secrets](#secrets):
  - `tf_cloud_token`: [Terraform Cloud](https://app.terraform.io/) token to use shared state
  - `hcloud_api_token`: [Hetzner Cloud API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token)

## Usage

### Development shell

Before issuing any other commands, enter the development environment (if not using [`direnv`](https://zero-to-flakes.com/direnv)):

```sh
nix develop -c $SHELL
```

### Commands

```sh
just -l
```

#### [nixos host](https://github.com/hercules-ci/arion/issues/122)

```nix
  systemd.enableUnifiedCgroupHierarchy = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.defaultNetwork.dnsname.enable = true;
  # Use your username instead of `myuser`
  users.extraUsers.myuser.extraGroups = ["podman"];
  virtualisation.podman.dockerSocket.enable = true;
  environment.systemPackages = [
     pkgs.docker-client
  ];
```

### Secrets

- if you want to reset secrets:
  - generate keypair: `just keygen`
  - list it in [`sops`](https://getsops.io/) config file `.sops.yaml`
- key setup: set environment variable `SOPS_AGE_KEY_FILE` or `SOPS_AGE_KEY` so `sops` can locate the secret key to an `age` key pair that has its public key listed in `.sops.yaml`, e.g. (listed in `.envrc`):

    ```sh
    export SOPS_AGE_KEY_FILE=./keys.txt
    ```

- setting Terraform Cloud credentials, either by:
  - decode (as per above) to reuse the shared session
  - log in to the Terraform Cloud backend: `just login`

### Configuring

In `.auto.tfvars.json` override any OpenTofu variables, e.g.:

```tfvars
hcloud_location = "nbg1"
```

## [HCL to Nix](https://gist.github.com/KiaraGrouwstra/249ede6a7dfc00ea44d85bc6bdbcd875)

## Deploying to a different architecture

### Nixos host

```nix
    # cross-compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
```
