resource "hcloud_ssh_key" "main" {
  name       = "${var.project}-${var.root_username}"
  public_key = file("${var.root_ssh_key_path}.pub")
}

resource "hcloud_server" "main" {
  for_each = toset(var.ansible_groups) # Create a droplet for each ansible group
  labels      = {ansible_group = "${each.value}"}
  name        = "${each.value}-${local.name}"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  backups     = "false"
  ssh_keys    = [hcloud_ssh_key.main.id]
}

resource "null_resource" "ssh_check" {
  # Ensure that SSH is ready and accepting connections on all hosts.
  for_each = toset(var.ansible_groups)
  
  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.main["${each.value}"].ipv4_address
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}
