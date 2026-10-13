resource "hcloud_network" "internal-network" {
    name = "internal-network"
    ip_range = "10.10.0.0/24"
}

resource "hcloud_network_subnet" "network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.internal-network.id
  network_zone = var.location
  ip_range     = "10.10.0.0/24"
}

resource "hcloud_firewall" "firewall" {
    name = "firewall"
    rule {
        direction  = "in"
        protocol   = "tcp"
        port       = "22"
        source_ips = [
            "0.0.0.0/0",
            "::/0"
        ]
    }
}

data "hcloud_ssh_key" "ssh_key" {
  name = var.ssh_key
}

resource "hcloud_server" "jumphost" {
  name         = "jumphost"
  image        =  var.jumphost_version
  server_type  = "cx23"

  firewall_ids = [hcloud_firewall.firewall.id]
  ssh_keys = [data.hcloud_ssh_key.ssh_key.id]

  network {
    subnet_id = hcloud_network_subnet.network_subnet.id
    ip = "10.10.0.10"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}