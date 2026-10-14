locals {
    hosts = {
        jumphost = true
        devbox = true
    }
}

module "jumphost" {
    count = local.hosts.jumphost ? 1 : 0
    source = "./modules/jumphost"

    # VM Configurations
    ssh_key = var.ssh_key
    jumphost_version = var.jumphost_version

    # DNS Configurations
    domain = var.domain
    cloudflare_zone_id = var.cloudflare_zone_id
}

module "devbox" {
    count = local.hosts.devbox ? 1 : 0
    source = "./modules/devbox"

    ssh_key = var.ssh_key
    subnet_id = module.jumphost[0].subnet_id
    depends_on = [ module.jumphost ]
}