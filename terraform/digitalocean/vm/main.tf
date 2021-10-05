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
  # if server_hostname is null (which is the default value), generate a random hostname with random_pet and random_string
  server_hostname = var.server_hostname != null ? var.server_hostname : "${random_pet.name[0].id}-${random_string.name[0].result}" # [0] selector is required due the `count = var.module_enabled` trick.
}

resource "digitalocean_droplet" "main" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  name               = local.server_hostname
  image              = var.server_image
  tags               = flatten(var.server_tags)
  region             = var.server_region
  size               = var.server_size
  ipv6               = var.server_ipv6
  monitoring         = var.server_monitoring
  private_networking = var.server_private_networking
  ssh_keys           = var.server_ssh_keys
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
