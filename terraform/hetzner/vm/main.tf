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

resource "hcloud_server" "main" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  name        = local.server_hostname
  labels      = var.server_labels
  image       = var.server_image
  server_type = var.server_server_type
  location    = var.server_location
  backups     = var.server_backups
  ssh_keys    = var.server_ssh_keys
}

resource "null_resource" "ssh_check" { # ensure that SSH is ready and accepting connections on all hosts.
  count = var.module_enabled ? 1 : 0 # only run if this variable is true
  
  connection {
    type        = "ssh"
    user        = var.root_username
    host        = hcloud_server.main[0].ipv4_address # [0] selector is required due the `count = var.module_enabled` trick.
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}
