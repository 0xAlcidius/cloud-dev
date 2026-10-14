variable "ssh_key" {
  type = string
}

variable "devbox_ip" {
  type = string
  default = "10.10.0.20"
}

variable "subnet_id" {
    type = string
}