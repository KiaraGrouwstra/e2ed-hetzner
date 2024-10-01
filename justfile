set positional-arguments

# default action: list actions
default:
  @just --list

# encode secrets
@encode *args='':
    sops -e secrets.yaml $@ > secrets.enc.yaml
    sops --output-type yaml -e .auto.tfvars.json $@ > .auto.tfvars.enc.yaml

# decode secrets
@decode *args='':
    sops -d secrets.enc.yaml $@ > secrets.yaml
    sops --output-type json -d .auto.tfvars.enc.yaml $@ > .auto.tfvars.json

# log in to the Terraform Cloud backend
@login *args='':
    tofu login app.terraform.io -- $@

# build a main.tf.json using teraflops
@convert:
    nix run .#convert

# clean the local working state,
# fixes error: backend initialization required: please run "tofu init"
@clean *args='':
    nix run .#clean -- $@

# run CI test locally
ci:
    woodpecker-cli exec --env "SOPS_AGE_KEY=$SOPS_AGE_KEY"

# test thru a VM locally
@vm *args='':
    nix run .#vm -- $@

# generate an [`age`](https://age-encryption.org/) key pair
keygen:
    rage-keygen -o keys.txt

# remove local state and derived credentials
@destroy *args='':
    nix run .#destroy -- $@

# update dependencies
update:
    nix flake update && rm -f .terraform.lock.hcl && teraflops init && tofu providers lock
