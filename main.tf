terraform {

  cloud {
    hostname = "app.terraform.io" # Optional; defaults to app.terraform.io
    organization = "bij1"
    workspaces {
      name = "infra"
    }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

}

provider "digitalocean" {}
