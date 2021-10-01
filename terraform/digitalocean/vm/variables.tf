variable "project_name" {
  default = "testing"
}

variable "project_description" {
  description = "Description of the new to the DigitalOcean Project"
  default     = "Server deployed with Terraform and Ansible template"
}

variable "servers" {
  description = "A map contaning server(s) that should be created."
  type = map(object({
    name               = string
    size               = optional(string)
    tag                = list(string)
    image              = optional(string)
    region             = optional(string)
    ipv6               = optional(bool)
    monitoring         = optional(bool)
    private_networking = optional(bool)
  }))
  default = {
    "host1" = {
      name = "host1"
      tag  = ["terraform"]
    }
  }
}

## Default values if incompleet server map is supplied
locals {
  servers = defaults(var.servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })
}

resource "random_string" "name" {
  length  = 6
  special = false
  upper   = false
}

variable "root_username" {
  description = "The username of the root account"
  default     = "root"
}

variable "root_ssh_key_path" {
  description = "The path of the ssh key for the root account"
  default     = "~/.ssh/temp_key"
}

variable "do_token" {
  description = "Your Digital Ocean Api token generated from here https://cloud.digitalocean.com/account/api/tokens"
  default     = "123465789"
}
