locals {
    hosts = {
        jumphost = false
    }
}

module "jumphost" {
    count = local.hosts.jumphost ? 1 : 0
    source = "./modules/jumphost"

    jumphost_version = var.jumphost_version
    ssh_key = var.ssh_key
}