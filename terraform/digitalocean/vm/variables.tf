variable "ansible_groups" {
  description = "A list of tags used for Ansible Groups"
  type        = list(string)
  default     = ["ansible"]
}

variable "project" {
  default = "testing"
}

resource "random_string" "name" {
  length  = 6
  special = false
  upper   = false
}

locals {
  name = "${random_string.name.result}-${var.project}-${terraform.workspace}"
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

variable "image" {
  description = "The image to use when creating the VPS"
  default     = "ubuntu-20-04-x64"
}
variable "location" {
  description = "Region to create VPS in"
  default     = "ams3"
}

variable "server_type" {
  description = "VPS Size"
  default     = "s-1vcpu-1gb"
}

variable "do_tag" {
  description = "Additional tag added to the DigitalOcean Droplet"
  default     = "created_with_ansible_terraform"
}

variable "do_description" {
  description = "Description of the new to the DigitalOcean Droplet"
  default     = "Server deployed with Terraform and Ansible template"
}

variable "do_ipv6" {
  description = "Enable or Disable ipv6"
  default     = true
}

variable "do_monitoring" {
  description = "Enable or disable DigitalOcean Monitoring"
  default     = false
}

variable "do_private_networking" {
  description = "Enable or disable private networking"
  default     = false
}
