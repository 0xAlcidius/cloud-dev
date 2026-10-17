variable "location" {
  type = string
  default = "hel1"
}

variable "region" {
  type = string
  default = "eu-central"
}

variable "jumphost_version" {
  type = string
}

variable "jumphost_ip" {
  type = string
  default = "10.10.0.10"
}

variable "domain" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}