variable "servers" {
  type = map(object({
    size               = optional(string)
    tag                = list(string)
    image              = optional(string)
    name               = string
    region             = optional(string)
    ipv6               = optional(bool)
    monitoring         = optional(bool)
    private_networking = optional(bool)
  }))
}

locals {
  servers = defaults(var.servers, {
    size               = "s-1vcpu-1gb"
    image              = "ubuntu-20-04-x64"
    region             = "ams3"
    monitoring         = false
    private_networking = false
  })
}

#locals {
#  all_server_tags = flatten(values(var.servers)[*].tag)
#}
#
#resource "digitalocean_tag" "main" {
#  for_each = toset(local.all_server_tags)
#  name     = each.value
#}


resource "digitalocean_ssh_key" "main" {
  name       = "${var.project}-${var.root_username}"
  public_key = file("${var.root_ssh_key_path}.pub")
}

resource "digitalocean_droplet" "main" {
  for_each = local.servers # Create a vm for each defined in the ansible var

  image              = each.value.image
  tags               = flatten(each.value.tag)
  name               = "${var.project}-${each.value.name}-${terraform.workspace}-${random_string.name.result}"
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
  name        = var.project
  description = var.do_description
  purpose     = "Other"
  resources   = [for droplet in digitalocean_droplet.main : droplet.urn] # add all created droplets to our project
}
