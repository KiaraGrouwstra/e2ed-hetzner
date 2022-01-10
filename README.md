# terraform

Contains Terraform code used to manage our infrastructure.

## Prerequisites

### Pre-commit hook

We want all our Terraform code to be well formatted and adhering to standards,
enforced by `terraform fmt`. Thus there is a pre-commit hook available to
validate this. Unfortunately this cannot be enforced remotely, so there is a
_one time_ manual step needed.

Run the following command right after cloning the repository:

```sh
./install_precommit_hook.sh
```

This will make sure you have the pre-commit hook installed so there is less of
a chance you push something that doesn't match our standards.

### Terraform

As we're using GitLab's Terraform image for our CI/CD pipeline, we'll stick to
using the latest version of Terraform. Instruction on how to install Terraform
can be found here: <https://www.terraform.io/downloads>

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
