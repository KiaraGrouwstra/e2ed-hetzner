# tofu

Contains [OpenTofu](https://opentofu.org/) code used to manage our infrastructure, Nix'ified for [Terranix](https://terranix.org/).

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

### Handling [credentials](#secrets)

### Applying changes

```sh
nix run
```

### Validating logic

```sh
nix run .#check
```

### Showing the generated plan

```sh
nix run .#plan
```

### Applying changes, approving automatically

```sh
nix run .#cd
```

### Removing local state and derived credentials

```sh
nix run .#destroy
```

### Running Nomad jobs locally

```sh
nix run .#local
```

### Updating dependencies

```sh
nix flake update
```

### Simulating a CI test

[substituting](#secrets) `<SOPS_AGE_KEY>`, run:

```sh
woodpecker-cli exec --env "SOPS_AGE_KEY=<SOPS_AGE_KEY>"
```

## Secrets

- if you want to reset secrets:
  - generate an [`age`](https://age-encryption.org/) key pair, using [`rage`](https://github.com/str4d/rage) installed as part of the nix shell:

    ```sh
    rage-keygen -o keys.txt
    ```

  - list it in [`sops`](https://getsops.io/) config file `.sops.yaml`
- key setup: set environment variable `SOPS_AGE_KEY_FILE` or `SOPS_AGE_KEY` so `sops` can locate the secret key to an `age` key pair that has its public key listed in `.sops.yaml`, e.g.:

    ```sh
    export SOPS_AGE_KEY_FILE=./keys.txt
    ```

- encoding secrets:

    ```sh
    nix run .#encode
    ```

- decoding secrets:

    ```sh
    nix run .#decode
    ```

- setting Terraform Cloud credentials, either by:
  - decode (as per above) to reuse the shared session

  - log in to the Terraform Cloud backend:

    ```sh
    tofu login app.terraform.io
    ```

### Configuring

In `.auto.tfvars.json` override any OpenTofu variables, e.g.:

```tfvars
hcloud_location = "nbg1"
```

## [HCL to Nix](https://gist.github.com/KiaraGrouwstra/249ede6a7dfc00ea44d85bc6bdbcd875)
