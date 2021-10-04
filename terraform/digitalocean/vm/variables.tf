variable "module_enabled" {
  type = bool
  default = false
}

variable "project_name" {
  default = "testing"
}

variable "server_name" {
  default = "host1"
}

variable "server_image" {
  default = "ubuntu-20-04-x64"
}

variable "server_tags" {
  default = ["terraform"]
}

variable "server_region" {
  default = "ams3"
}

variable "server_size" {
  default = "s-1vcpu-1gb"
}

variable "server_ipv6" {
  default = false
}

variable "server_monitoring" {
  default = false
}

variable "server_private_networking" {
  default = false
}

variable "server_ssh_keys" {
  default = ""
}

variable "root_username" {
  description = "The username of the root account"
  default     = "root"
}

variable "root_ssh_key_path" {
  description = "The path of the ssh key for the root account"
  default     = "~/.ssh/temp_key"
}

