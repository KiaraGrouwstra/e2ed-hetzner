# TF config

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

### Running the VMs

you can build a VM using

```sh
nixos-rebuild build-vm --flake .#<vm_name>
```

where `<vm_name>` is one of:
- `manual`

then run it with:

```sh
./result/bin/run-nixos-vm
```

State will be persisted in the `nixos.cqow2` file.
The VM will expose web services you can access from the host:

- `manual`: <http://localhost:80>

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

## roadmap

- [ ] ensure i can use:
  - [ ] VM: `nixos-rebuild build-vm --flake .#manual && ./result/bin/run-nixos-v`
    - [x] build
    - [x] log in
    - [ ] connect to HTTP services
    - [ ] use imports
    - [ ] services can inter-connect
    - [ ] containers on server
  - [ ] arion: `arion up`
    - [x] build
    - [x] connect to HTTP services
    - [ ] use imports
    - [ ] services can inter-connect
    - [ ] containers on server
- [ ] https://github.com/aanderse/teraflops/issues/11#issuecomment-2192802060
- [ ] restrict sensitive services to access over ssh port forwarding over exposing to 0.0.0.0
- [ ] [make db connection work](https://code.bij1.org/bij1/bij1.erp/src/branch/main/Makefile#L18)
- [ ] tls/ssl
- [ ] [add paul's api layer](https://code.bij1.org/bij1/bij1.erp/src/branch/main/src/bij1/api/main.py)
- [ ] [reproduce sao setup for use elsewhere](https://discuss.tryton.org/t/state-of-the-dependencies-of-the-web-client/3441/8)
  - bower
    - [x] manual
    - [ ] nix
  - grunt
    - [x] release downloads
    - [ ] manual
    - [ ] nix
- [ ] deploy to hetzner
- [ ] [network access](https://codeberg.org/kiara/teraflops-poc/issues/9)
- [ ] [network securing](https://codeberg.org/kiara/teraflops-poc/issues/10)
- [ ] [volumes](https://codeberg.org/kiara/teraflops-poc/issues/5)
- [ ] [impermanence](https://codeberg.org/kiara/teraflops-poc/issues/2)
- [ ] [secrets](https://codeberg.org/kiara/teraflops-poc/issues/6)
- [ ] [CI pipeline](https://codeberg.org/kiara/teraflops-poc/issues/12)
- [ ] [packer](https://codeberg.org/kiara/teraflops-poc/issues/4)
- [ ] [share nix store](https://codeberg.org/kiara/teraflops-poc/issues/8)
- [ ] [scale out applications](./servers/)
- [ ] SSO
- [ ] LDAP
- [ ] typhon CI
- [ ] hybrid deployment with colmena targets
- [ ] nested containers for CI
