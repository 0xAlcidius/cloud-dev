locals {
    hosts = {
        jumphost = false
    }
}

module "jumphost" {
    count = local.hosts.jumphost ? 1 : 0
    source = "./modules/jumphost"

    location = var.location
}