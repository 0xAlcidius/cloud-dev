variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "domain" {
    type = string
}

variable "ssh_key_pub" {
    type = string
}

variable "wireguard_version" {
    type = string
}