# TF config

Contains [OpenTofu](https://opentofu.org/) code used to manage our infrastructure, Nix'ified for [Teraflops](https://github.com/aanderse/teraflops).

## Prerequisites

- [Nix](https://nix.dev/) with [Flakes](https://wiki.nixos.org/wiki/Flakes) enabled
- Optionally, to automate Nix shells (`nix develop`) get both:
  - [`direnv`](https://github.com/nix-community/direnv)
  - [`lorri`](https://github.com/nix-community/lorri)
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
# if using direnv
direnv allow
# otherwise:
source .envrc
# then:
# list commands
just -l
# build servers by colmena
teraflops nix build
# debug server nix by colmena
teraflops repl
# try servers locally by arion
arion up
# clear local files
just clean
# authenticate with remote TF backend
just login
# initialize TF
teraflops init
# convert nix to TF by teraflops
just build
# see terraform plan
tofu plan
# apply terraform plan
tofu apply
# list terraform state
tofu state list
# show terraform resources
tofu show
# inspect terraform state
tofu output -json | jaq
# save ssh key
tofu output -json | jaq -r '.teraflops.value.privateKey' > ~/.ssh/teraflops && chmod 0600 ~/.ssh/teraflops
# get server IP
export MY_SERVER=$(terraform output -json | jaq -r '.teraflops.value.nodes.combined.targetHost')
# ssh to server
ssh root@$MY_SERVER
# apply nix changes
teraflops deploy --reboot
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

- `manual`: <http://manual.localhost:8888>

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

## Troubleshooting

### outdated TF providers

> Error: Failed to resolve provider packages
>
> Could not resolve provider hetznercloud/hcloud: the previously-selected version 1.45.0 is no longer available

```sh
just clean
```

## roadmap

- [ ] managing `my-lib`
  - `import`ed everywhere
    - [✅] arion
    - [✅] teraflops
  - smuggled in thru `lib`
    - [❌] arion - can at best smuggle thru `pkgs`
    - [✅] teraflops
  - passed as a module input
    - [❌] arion - works not even if passing a default value e.g. `my-lib ? lib`
    - [✅] teraflops

- [ ] deploy to hetzner
  - [ ] update server in-place by colmena
- [ ] srvos
- [ ] [volumes](https://codeberg.org/kiara/teraflops-poc/issues/5)
- [ ] disko
- [ ] [impermanence](https://codeberg.org/kiara/teraflops-poc/issues/2)
- [ ] [packer](https://codeberg.org/kiara/teraflops-poc/issues/4)
- [ ] disk encryption
- [ ] cache

- [ ] [state backend](https://codeberg.org/kiara/teraflops-poc/issues/13)
- [ ] ensure i can use:
  - [ ] VM: `nixos-rebuild build-vm --flake .#manual && ./result/bin/run-nixos-v`
    - [x] build
    - [x] log in
    - [x] connect to HTTP services
    - [x] use imports
    - [x] containers on server
    - [x] exposing http ports from containers on the server
    - [ ] services can inter-connect
  - [ ] arion: `arion up`
    - [x] build
    - [x] connect to HTTP services
    - [x] use imports
    - [x] containers on server
    - [x] exposing http ports from containers on the server
    - [ ] services can inter-connect
    - [ ] flake-based container LCM
- [ ] [secrets](https://codeberg.org/kiara/teraflops-poc/issues/6)
  - [x] local
  - [ ] deployment
  - [ ] TF
- [ ] [make db connection work](https://code.bij1.org/bij1/bij1.erp/src/branch/main/Makefile#L18): stuck on error `could not serialize access due to concurrent update`
- [ ] tls/ssl
- [ ] restrict sensitive services to access over ssh port forwarding over exposing to 0.0.0.0
- [ ] [add paul's api layer](https://code.bij1.org/bij1/bij1.erp/src/branch/main/src/bij1/api/main.py)
- [x] https://github.com/aanderse/teraflops/issues/11#issuecomment-2192802060
- hashicorp
  - [ ] terraform
  - [ ] consul
  - [ ] vault
  - [ ] nomad
- [ ] [network access](https://codeberg.org/kiara/teraflops-poc/issues/9)
- [ ] [network securing](https://codeberg.org/kiara/teraflops-poc/issues/10)
- [ ] [CI pipeline](https://codeberg.org/kiara/teraflops-poc/issues/12)
- [ ] [share nix store](https://codeberg.org/kiara/teraflops-poc/issues/8)
- [ ] [scale out applications](./servers/)
- [ ] SSO
- [ ] LDAP
- [ ] typhon CI
- [ ] hybrid deployment with colmena targets
- [ ] nested containers for CI
