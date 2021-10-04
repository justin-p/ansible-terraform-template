terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 1.23.0"
    }
    random = {
      source = "hashicorp/random"
    }    
  }
  required_version = ">= 0.13"
}