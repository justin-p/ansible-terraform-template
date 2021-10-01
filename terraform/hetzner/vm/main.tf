resource "hcloud_ssh_key" "main" {
  name       = "${var.project_name}-${var.root_username}"
  public_key = file("${var.root_ssh_key_path}.pub")
}

resource "hcloud_server" "main" {
  for_each = local.servers # Create a vm for each defined in the server map for this cloud provider

  labels      = each.value.labels
  name        = "${var.project_name}-${each.value.name}-${terraform.workspace}-${random_string.name.result}"
  image       = each.value.image
  server_type = each.value.server_type
  location    = each.value.location
  backups     = each.value.backups
  ssh_keys    = [hcloud_ssh_key.main.id]
}

resource "null_resource" "ssh_check" {
  # Ensure that SSH is ready and accepting connections on all hosts.
  for_each = local.servers

  connection {
    type        = "ssh"
    user        = "root"
    host        = hcloud_server.main["${each.key}"].ipv4_address
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}
