source "hcloud" "jumphost" {
    token = var.hcloud_token

    location = "hel1"
    image = "ubuntu-24.04"
    server_type = "cx23"
    server_name = "jumphost-{{ timestamp }}"

    ssh_username = "root"

    snapshot_name = "jumphost-{{ timestamp }}"
}

build {
    sources = ["source.hcloud.jumphost"]

    provisioner "shell" {
        inline = ["cloud-init status --wait --long"]
        valid_exit_codes = [0,2]
    }

    provisioner "shell" {
        script = "${path.root}/scripts/install-jumphost.sh"
        execute_command = "{{.Vars}} bash '{{.Path}}'"
        environment_vars = [
            "WIREGUARD_VERSION=${var.wireguard_version}",
            "DOMAIN=${var.domain}"
        ]
    }
}