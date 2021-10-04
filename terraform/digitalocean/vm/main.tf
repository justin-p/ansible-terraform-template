resource "random_string" "name" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true
    
  length  = 6
  special = false
  upper   = false
}

resource "digitalocean_droplet" "main" {
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  image              = var.server_image
  tags               = flatten(var.server_tags)
  name               = "${var.project_name}-${var.server_name}-${terraform.workspace}-${random_string.name[0].result}"
  region             = var.server_region
  size               = var.server_size
  ipv6               = var.server_ipv6
  monitoring         = var.server_monitoring
  private_networking = var.server_private_networking
  ssh_keys           = var.server_ssh_keys
}

resource "null_resource" "ssh_check" {   # Ensure that SSH is ready and accepting connections on all hosts.
  count = var.module_enabled ? 1 : 0 # only run if this variable is true

  connection {
    type        = "ssh"
    user        = var.root_username
    host        = digitalocean_droplet.main[0].ipv4_address
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}
