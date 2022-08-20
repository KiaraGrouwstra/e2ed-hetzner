terraform {

  backend "local" {}

  # cloud {
  #   hostname     = "app.terraform.io" # Optional; defaults to app.terraform.io
  #   organization = "bij1"
  #   workspaces {
  #     name = "infra"
  #   }
  # }

  required_providers {
    digitalocean = {
      # https://registry.terraform.io/providers/digitalocean/digitalocean/
      source = "digitalocean/digitalocean"
      # source  = "bij1/greenhost"
      version = "~> 2.21.0"
    }
  }

}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  api_endpoint = "https://service.greenhost.net/api/"
  token        = var.do_token
}

###### REGIONS

data "digitalocean_regions" "available" {
  # filter {
  #   key    = "available"
  #   values = ["true"]
  # }
  # filter {
  #   key    = "features"
  #   values = ["private_networking"]
  # }
  sort {
    key       = "name"
    direction = "desc"
  }
}

###### IMAGES

data "digitalocean_images" "available" {
  # filter {
  #   key    = "distribution"
  #   values = ["Ubuntu"]
  # }
  # filter {
  #   key    = "regions"
  #   values = ["nyc3"]
  # }
  sort {
    key       = "created"
    direction = "desc"
  }
}

###### SSH KEYS

data "digitalocean_ssh_keys" "keys" {
  # filter {
  #   key    = "name"
  #   values = ["laptop", "desktop"]
  # }
  sort {
    key       = "name"
    direction = "asc"
  }
}

data "digitalocean_ssh_key" "kiara" {
  name = "kiara"
}

# # Create a new SSH key
# resource "digitalocean_ssh_key" "key_kiara" {
#   name       = "kiara's key"
#   public_key = file("/home/kiara/.ssh/id_rsa.pub")
# }

###### DROPLETS

# data "digitalocean_droplets" "droplets" {
#   # filter {
#   #   key    = "size"
#   #   values = ["s-1vcpu-1gb"]
#   # }
#   # filter {
#   #   key    = "backups"
#   #   values = ["true"]
#   # }
#   sort {
#     key       = "created_at"
#     direction = "desc"
#   }
# }

# data "digitalocean_droplet" "cloud" {
#   id = "8864"
#   # name = "cloud.bij1.org"
# }

# # Create a new Droplet using the SSH key
# resource "digitalocean_droplet" "web" {
#   image    = "ubuntu-18-04-x64"
#   name     = "web-1"
#   region   = "nyc3"
#   size     = "s-1vcpu-1gb"
#   ssh_keys = [digitalocean_ssh_key.default.fingerprint]
# }

# # Create a new Web Droplet in the nyc2 region
# resource "digitalocean_droplet" "web" {
#   image  = "ubuntu-18-04-x64"
#   name   = "web-1"
#   region = "nyc2"
#   size   = "s-1vcpu-1gb"
#   backups = false
#   monitoring = false
#   ipv6 = false
#   # vpc_uuid = ""
#   # ssh_keys = [] # change = recreate!
#   # resize_disk = true
#   # tags = []
#   # user_data = ""
#   # volume_ids = []
#   # droplet_agent = bool
#   # graceful_shutdown = false
# }

###### DNS RECORDS

data "digitalocean_records" "records" { # records_bij1_net
  domain = "bij1.net"
  # filter {
  #   key = "type"
  #   values = ["MX"]
  # }
  sort {
    key       = "name"
    direction = "asc"
  }
}

# data "digitalocean_records" "records_bij1_org" {
#   domain = "bij1.org"
#   # filter {
#   #   key = "type"
#   #   values = ["MX"]
#   # }
#   sort {
#     key       = "name"
#     direction = "asc"
#   }
# }

data "digitalocean_record" "static" {
  domain = "bij1.net"
  name   = "static"
}

# # Add an A record to the domain.
# resource "digitalocean_record" "foo" {
#   domain = "bij1.org"
#   type   = "A"
#   name   = "foo"
#   value  = "192.168.0.11"
#   ttl    = 86400
# }
