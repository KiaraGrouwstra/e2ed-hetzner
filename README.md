# terraform

Contains [Terraform](https://terraform.io/) code used to manage our infrastructure, Nix'ified for [Terranix](https://terranix.org/).

## Prerequisites

- [Nix](https://nix.dev/) with [Flakes](https://nixos.wiki/wiki/Flakes) enabled
- [Hetzner Cloud API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token)
- [Terraform Cloud](https://app.terraform.io/) to use shared state

### Usage

- Run `nix develop -c $SHELL` to enter the development environment if not using [`direnv`](https://zero-to-flakes.com/direnv).
- Run `tofu login app.terraform.io` to log in to the Terraform Cloud backend
- Run `nix run` to apply changes.
- Run `nix flake update` to update dependencies.

### Secrets

- if you want to reset secrets:
  - generate an [`age`](https://age-encryption.org/) key pair, using [`rage`](https://github.com/str4d/rage) installed as part of the nix shell: `rage-keygen -o keys.txt`
  - list it in [`sops`](https://getsops.io/) config file `.sops.yaml`
- key setup: set environment variable `SOPS_AGE_KEY_FILE` or `SOPS_AGE_KEY` so `sops` can locate the secret key to an `age` key pair that has its public key listed in `.sops.yaml`
- encoding secrets: `sops -e secrets.yaml > secrets.enc.yaml`
- decoding secrets: `sops -d secrets.enc.yaml > secrets.yaml`

### Authentication

Create a file `terraform.tfvars` containing:

```tfvars
hcloud_api_token = "<HETZNER_API_KEY>"
```

... substituting in our actual key.

### Managed state

- go to https://gitlab.com/bij1/intranet/terraform/-/terraform
- open the triple dot menu for `bij1` and select `Copy Terraform init command`
- substitute in a personal access token in the shown command
- run the command locally to access the shared state

## [HCL to Nix](https://gist.github.com/KiaraGrouwstra/249ede6a7dfc00ea44d85bc6bdbcd875)

