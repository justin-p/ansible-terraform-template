resource "digitalocean_ssh_key" "main" {
  name       = "${var.project_name}-${var.root_username}"
  public_key = file("${var.root_ssh_key_path}.pub")
}

resource "digitalocean_droplet" "main" {
  for_each = local.servers # Create a vm for each defined in the server map for this cloud provider

  image              = each.value.image
  tags               = flatten(each.value.tag)
  name               = "${var.project_name}-${each.value.name}-${terraform.workspace}-${random_string.name.result}"
  region             = each.value.region
  size               = each.value.size
  ipv6               = each.value.ipv6
  monitoring         = each.value.monitoring
  private_networking = each.value.private_networking
  ssh_keys           = [digitalocean_ssh_key.main.fingerprint]
}

resource "null_resource" "ssh_check" {
  # Ensure that SSH is ready and accepting connections on all hosts.
  for_each = local.servers

  connection {
    type        = "ssh"
    user        = "root"
    host        = digitalocean_droplet.main["${each.key}"].ipv4_address
    private_key = file("${var.root_ssh_key_path}")
  }

  provisioner "remote-exec" {
    inline = ["echo 'Hello world!'"]
  }
}

resource "digitalocean_project" "main" {
  name        = var.project_name
  description = var.project_description
  purpose     = "Other"
  resources   = [for droplet in digitalocean_droplet.main : droplet.urn] # add all created droplets to our project
}
