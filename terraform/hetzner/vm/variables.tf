variable "project_name" {
  default = "testing"
}

variable "servers" {
  description = "A map contaning server(s) that should be created."
  type = map(object({
    server_type = optional(string)
    labels      = map(string)
    image       = optional(string)
    name        = string
    location    = optional(string)
    backups     = optional(bool)
  }))
  default = {
    "host1" = {
      name   = "host1"
      labels = { terraform = "" }
    }
  }
}

## Default values if incompleet server map is supplied
locals {
  servers = defaults(var.servers, {
    server_type = "cx11"
    image       = "ubuntu-20.04"
    name        = "testvm"
    location    = "nbg1"
    backups     = false
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

variable "hetzner_token" {
  description = "Your Hetzner API token"
  default     = "abcdefghijklmnopqrstuvwqyzabcdefghijklmnopqrstuvwqyzabcdefghijqr"
}
