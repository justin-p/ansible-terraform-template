resource "random_pet" "name" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true
  
  length = 2
}

resource "random_string" "name" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true
    
  length  = 6
  special = false
  upper   = false
}

locals {
  # if module_enabled is true (
      # if server_hostname is null (which is the default value), generate a random hostname with random_pet and random_string
  # )
  # else set it server_hostname to disabled
  server_hostname = var.module_enabled == true ? (var.server_hostname != null ? var.server_hostname : "${random_pet.name[0].id}-${random_string.name[0].result}") : "disabled" # [0] selector is required due the `count = var.module_enabled` trick.
  
  # if var.server_create_vpc is true set local.create_vpc to true. Else set it to false.
  create_vpc = var.server_create_vpc == true ? true : false
  # if var.module_enabled is true (
  #   if local.create_vpc is true (which is the default value), set local.server_vpc to the output of digitalocean_vpc.main.
  #   else set it to null (which will place the droplet into the default VPC of its region)
  # )
  # else set it to null
  server_vpc = var.module_enabled ? (local.create_vpc == true ? digitalocean_vpc.main[0].id : null) : null # [0] selector is required due the `count = var.module_enabled` trick.
}

resource "digitalocean_vpc" "main" {
  count = var.module_enabled ? (local.create_vpc ? 1 : 0) : 0 # only run if both variables local.create_vpc and var.module_enabled are true

  name   = "vpc-${local.server_hostname}"
  region = var.server_region
}

resource "digitalocean_droplet" "main" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  name          = local.server_hostname
  image         = var.server_image
  tags          = flatten(var.server_tags)
  size          = var.server_size
  region        = var.server_region
  backups       = var.server_backups
  monitoring    = var.server_monitoring
  ipv6          = var.server_ipv6
  resize_disk   = var.server_resize_disk
  droplet_agent = var.server_droplet_agent
  ssh_keys      = var.server_ssh_keys
  vpc_uuid      = local.server_vpc
}

resource "null_resource" "ssh_check" {   # ensure that SSH is ready and accepting connections on all hosts.
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  connection {
    type        = "ssh"
    user        = var.root_username
    host        = digitalocean_droplet.main[0].ipv4_address # [0] selector is required due the `count = var.module_enabled` trick.
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}
