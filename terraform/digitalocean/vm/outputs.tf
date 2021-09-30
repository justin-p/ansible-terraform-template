output "vms" {
  value = digitalocean_droplet.main[*]
}
