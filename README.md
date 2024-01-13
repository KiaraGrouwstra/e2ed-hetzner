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

## Code-styling

We try to adhere to the
[naming conventions](https://www.terraform-best-practices.com/naming) and
[code-styling](https://www.terraform-best-practices.com/code-styling) best
practices defined at [Terraform best practices](https://www.terraform-best-practices.com/).

## Secrets

Two steps:

1. Create a variable in `variables.tf` with `sensitive = true`, to prevent it
from appearing in the build output.
2. Add the desired variable to the
[Environment Variables](https://www.terraform.io/language/values/variables#environment-variables).

We may want to look at something like
[git-crypt](https://github.com/AGWA/git-crypt) or a central password store.
