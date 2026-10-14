terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = ">=5.28.0"
    }
  }
}
