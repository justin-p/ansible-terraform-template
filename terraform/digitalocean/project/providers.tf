terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.12.1"
    }
  }
  required_version = ">= 0.13"
}
