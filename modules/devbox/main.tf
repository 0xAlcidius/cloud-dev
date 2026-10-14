resource "hcloud_firewall" "db_firewall" {
  name = "db_firewall"
}

resource "hcloud_server" "devbox" {
  name         = "devbox"
  image        = "ubuntu-24.04"
  server_type  = "cx23"

  firewall_ids = [hcloud_firewall.db_firewall.id]
  ssh_keys = [var.ssh_key]

  network {
    subnet_id = var.subnet_id
    ip = var.devbox_ip
  }

  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }
}