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