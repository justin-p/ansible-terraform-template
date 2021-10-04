variable "digitalocean_token" {
  description = "Your Digital Ocean Api token generated from here https://cloud.digitalocean.com/account/api/tokens"
  default     = "123465789"
}

variable "digitalocean_enabled" {
  default     = false
  description = "Determines if terraform will deploy hosts on digitalocean"
}

variable "digitalocean_servers" {
  description = "A map contaning server(s) that should be created."
  type = map(object({
    name               = string
    size               = optional(string)
    tags               = list(string)
    image              = optional(string)
    region             = optional(string)
    ipv6               = optional(bool)
    monitoring         = optional(bool)
    private_networking = optional(bool)
  }))
  default = {
    "host1" = {
      name = "host1"
      tags = ["terraform"]
    }
  }
}

## Default values if incompleet server map is supplied
locals {
  digitalocean_servers = defaults(var.digitalocean_servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })

  # if the digitalocean modules are disabled, set digitalocean_ssh_key to a empty value
  # otherwise use the output of `module.digitalocean_ssh_key`.
  digitalocean_ssh_key = (
    length(module.digitalocean_ssh_key.ssh_key) > 0 ?
    module.digitalocean_ssh_key.ssh_key[0].fingerprint : ""
  )
}

module "digitalocean_ssh_key" {
  source         = "./digitalocean/ssh_key"
  module_enabled = var.digitalocean_enabled

  root_username     = var.root_username
  root_ssh_key_path = var.root_ssh_key_path
}

module "digitalocean_vm" {
  source         = "./digitalocean/vm"
  module_enabled = var.digitalocean_enabled
  for_each       = local.digitalocean_servers

  project_name      = var.project_name
  root_username     = var.root_username
  root_ssh_key_path = var.root_ssh_key_path

  server_name               = each.value.name
  server_tags               = each.value.tags
  server_size               = each.value.size
  server_image              = each.value.image
  server_region             = each.value.region
  
  server_ipv6               = each.value.ipv6
  server_monitoring         = each.value.monitoring
  server_private_networking = each.value.private_networking
  server_ssh_keys           = [local.digitalocean_ssh_key]
}

module "digitalocean_project" {
  source         = "./digitalocean/project"
  module_enabled = var.digitalocean_enabled

  digitalocean_droplets = module.digitalocean_vm
}

output "digitalocean_vms" {
  value = module.digitalocean_vm
}