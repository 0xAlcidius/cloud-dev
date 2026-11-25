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
            "DOMAIN=${var.domain}",
            "SSH_KEY_PUB=${var.ssh_key_pub}"
        ]
    }
}

source "hcloud" "sliver" {
    token = var.hcloud_token

    location = "hel1"
    image = "ubuntu-24.04"
    server_type = "cx23"
    server_name = "sliver-{{ timestamp }}"

    ssh_username = "root"

    snapshot_name = "jumphost-{{ timestamp }}"
}

build {
    sources = ["source.hcloud.jumphost"]

    provisioner "shell" {
        script = "${path.root}/scripts/install-sliver.sh"
        execute_command = "{{.Vars}} bash '{{.Path}}'"
        environment_vars = [
            "GO_VERSION=${var.go_version}",
            "SLIVER_VERSION=${var.sliver_version}"
        ]
    }

    provisioner "file" {
        source = "${path.root}/scripts/conf/sliver.service"
        destination "/tmp/sliver.service"
    }

    provisioner "shell" {
        inline = [
            "sudo mv /tmp/sliver.service /etc/systemd/system/sliver.service",
            "sudo systemctl daemon-reload",
            "sudo systemctl enable sliver.service"
        ]
    }
}