variable "hcloud_token" {
    type      = string
    sensitive = true
}

variable "jumphost_version" {
    type = string
}

variable "ssh_key" {
    type = string
}

variable "domain" {
    type = string
}

variable "cloudflare_token" {
    type = string
}

variable "cloudflare_zone_id" {
    type = string
}

variable "allow_destroy" {
    type = bool
    default = false
}