set positional-arguments

# try locally
default: local

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

# clean the local working state,
# fixes error: backend initialization required: please run "tofu init"
@clean *args='':
    nix run .#clean -- $@

# validate logic
@validate *args='':
    nix run .#validate -- $@

# apply changes
@apply *args='':
    nix run .#apply -- $@

# show generated plan
@plan *args='':
    nix run .#plan -- $@

# run CI test locally
ci:
    woodpecker-cli exec --env "SOPS_AGE_KEY=$SOPS_AGE_KEY"

# apply changes, approving automatically
@cd *args='':
    nix run .#cd -- $@

# try machines in containers locally
@local *args='':
    nix run .#local -- $@

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
    nix flake update && rm -f .terraform.lock.hcl && teraflops init
