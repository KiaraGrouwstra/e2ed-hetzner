output "regions_output" {
  value = data.digitalocean_regions.available.regions
}

output "images_output" {
  value = data.digitalocean_images.available
}

output "keys_output" {
  value = data.digitalocean_ssh_keys.keys
}

output "key_output" {
  value = data.digitalocean_ssh_key.kiara.public_key
}

# output "droplets_output" {
#   value = data.digitalocean_droplets.droplets
# }

# output "droplet_output" {
#   value = data.digitalocean_droplet.example.ipv4_address
# }

output "records_output" {
  value = data.digitalocean_records.records
}

output "record_type" {
  value = data.digitalocean_record.static.type
}

# output "fqdn" {
#   value = digitalocean_record.foo.fqdn
# }
