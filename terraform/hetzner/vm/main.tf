resource "random_string" "name" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  length  = 6
  special = false
  upper   = false
}

resource "hcloud_server" "main" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  labels      = var.server_labels
  name        = "${var.project_name}-${var.server_name}-${terraform.workspace}-${random_string.name[0].result}"
  image       = var.server_image
  server_type = var.server_server_type
  location    = var.server_location
  backups     = var.server_backups
  ssh_keys    = var.server_ssh_keys
}

resource "null_resource" "ssh_check" { # Ensure that SSH is ready and accepting connections on all hosts.
  count = var.module_enabled ? 1 : 0 # only run if this variable is true
  
  connection {
    type        = "ssh"
    user        = var.root_username
    host        = hcloud_server.main[0].ipv4_address
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}
