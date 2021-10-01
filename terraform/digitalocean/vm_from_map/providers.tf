terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 1.23.0"
    }
  }
  required_version = ">= 0.13"
  experiments      = [module_variable_optional_attrs]
}

provider "digitalocean" {
  token = var.do_token
}
