# try locally
default: local

# encode secrets
encode:
    sops --output-type yaml -e .auto.tfvars.json > .auto.tfvars.enc.yaml

# decode secrets
decode:
    sops --output-type json -d .auto.tfvars.enc.yaml > .auto.tfvars.json

# log in to the Terraform Cloud backend
login:
    tofu login app.terraform.io

# validate logic
validate:
    nix run .#validate

# apply changes
apply:
    nix run .#apply

# show generated plan
plan:
    nix run .#plan

# run CI test locally
ci:
    woodpecker-cli exec --env "SOPS_AGE_KEY=$SOPS_AGE_KEY"

# apply changes, approving automatically
cd:
    nix run .#cd

# run Nomad jobs locally
local:
    nix run .#local

# generate an [`age`](https://age-encryption.org/) key pair
keygen:
    rage-keygen -o keys.txt

# remove local state and derived credentials
destroy:
    nix run .#destroy

# update dependencies
update:
    nix flake update
