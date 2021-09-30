resource "digitalocean_ssh_key" "main" {
  name       = "${var.project}-${var.root_username}"
  public_key = file("${var.root_ssh_key_path}.pub")
}

resource "digitalocean_tag" "main" {
  for_each = toset(var.ansible_groups) # Create a tag for each ansible group
  name = each.value
}

resource "digitalocean_droplet" "main" {
  for_each = toset(var.ansible_groups) # Create a droplet for each ansible group

  image              = var.image
  tags               = [digitalocean_tag.main["${each.value}"].id, var.do_tag]
  name               = "${each.value}-${local.name}"
  region             = var.location
  size               = var.server_type
  ipv6               = var.do_ipv6
  monitoring         = var.do_monitoring
  private_networking = var.do_private_networking
  ssh_keys           = [digitalocean_ssh_key.main.fingerprint]
}

resource "null_resource" "ssh_check" {
  # Ensure that SSH is ready and accepting connections on all hosts.
  for_each = toset(var.ansible_groups)
  
  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.main["${each.value}"].ipv4_address
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}

resource "digitalocean_project" "main" {
  name        = var.project
  description = var.do_description
  purpose     = "Other"
  resources   = [for droplet in digitalocean_droplet.main: droplet.urn] # add all created droplets to our project
}
