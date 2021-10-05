terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.12.1"
    }
    random = {
      source = "hashicorp/random"
    }    
  }
  required_version = ">= 0.13"
}