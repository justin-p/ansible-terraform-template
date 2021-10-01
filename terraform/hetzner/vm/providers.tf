terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.23.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  required_version = ">= 0.13"
  experiments      = [module_variable_optional_attrs]
}

provider "hcloud" {
  token = var.hetzner_token
}