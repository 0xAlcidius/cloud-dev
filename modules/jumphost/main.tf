resource "hcloud_network" "internal-network" {
    name = "internal-network"
    ip_range = "10.10.0.0/24"
}

resource "hcloud_network_subnet" "network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.internal-network.id
  network_zone = var.region
  ip_range     = "10.10.0.0/24"
}

resource "hcloud_firewall" "jh_firewall" {
    name = "jh_firewall"
    rule {
        direction  = "in"
        protocol   = "tcp"
        port       = "22"
        source_ips = [
            "0.0.0.0/0",
            "::/0"
        ]
    }

    rule {
      direction  = "in"
      protocol   = "udp"
      port       = "51820"
      source_ips = ["0.0.0.0/0", "::/0"]
    }
}

resource "hcloud_primary_ip" "jumphost_public_ipv4" {
  name        = "jumphost_public_ipv4"
  location    = var.location
  type        = "ipv4"
  auto_delete = false
  delete_protection = false
}

resource "cloudflare_dns_record" "cloud" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "A"
  content = hcloud_primary_ip.jumphost_public_ipv4.ip_address
  ttl     = 300
  proxied = false
  depends_on = [ hcloud_primary_ip.jumphost_public_ipv4 ]
}

resource "hcloud_server" "jumphost" {
  name         = "jumphost"
  image        =  var.jumphost_version
  server_type  = "cx23"

  firewall_ids = [hcloud_firewall.jh_firewall.id]

  network {
    subnet_id = hcloud_network_subnet.network_subnet.id
    ip = var.jumphost_ip
  }

  depends_on = [hcloud_network_subnet.network_subnet]

  public_net {
    ipv4_enabled = true
    ipv4 = hcloud_primary_ip.jumphost_public_ipv4.id
    ipv6_enabled = false
  }
}