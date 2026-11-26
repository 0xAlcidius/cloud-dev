# Cloud-Dev
This repository represents my playground using Hetzner as the main cloud service provider. The playground provides a wireguard VPN to gain access to the internal network. From there you can pivot and gain access to different services running within the environment.

## Set up:
1. Ensure you have both Terraform and Packer installed;
2. Navigate to ./packer/;
3. Copy packer.pkrvars.hcl.example into the same directory and rename it to `packer.pkrvars.hcl`:
```
cp packer.pkrvars.hcl.example packer.pkrvars.hcl
```
4. Provide the necessary variables (more on that in [packer](https://github.com/0xAlcidius/cloud-dev#packer));
5. Run the following commands:
```
packer init .
packer build -on-error=cleanup "-var-file=./packer.pkrvars.hcl"
```
6. Within the output, a wireguard configuration was written to the terminal. This is the configuration you can use to connect to the wireguard service;
7. Note which snapshot is made, copy it from the terminal;
8. Navigate to ./ and copy terraform.tfvars.example to terraform.tfvars:
```
cd ..
cp terraform.tfvars.example terraform.rfvars
```
9. Provide only the id of the newly created snapshot (e.g., jumphost_version = `4864636393`);
10. Provide the other variables, some are the same as in packer.pkrvars;
11. Run `terraform init` and `terraform apply`.

### Packer
Packer requires several variables:
* hcloud_token - The API to your Hetzner project;
* domain - A custom domain (e.g., vpn.example.com);
* ssh_key_pub - your ssh key to ssh into the machine if needed;
* wireguard_version - the version for wireguard, this is already provided.

#### Development
In order to develop or alter an installation script, please use the following command to test the script locally:
```
docker run --rm -it -e DEBIAN_FRONTEND=noninteractive -v "$PWD/packer/scripts/install-<IMAGE NAME>.sh:/tmp/install.sh:ro" ubuntu:24.04 bash -c 'apt-get update -qq && apt-get install -yqq sudo >/dev/null && bash -xeo pipefail /tmp/install.sh; echo "=== exit code: $? ==="'
```

### Terraform
Terraform requires several variables:
* hcloud_token - The API to your Hetzner project;
* cloudflare_token - The API to your Cloudflare account (Requires DNS & Zones -> DNS -> edit permissions);
* ssh_key - your ssh key to ssh into the machine;
* domain - A custom domain (e.g., vpn.example.com);
* cloudflare_zone_id - The zone ID of your domain ([In cloudflare](https://developers.cloudflare.com/fundamentals/account/find-account-and-zone-ids/) overview, select the domain you want and navigate to the bottom. The Zone ID can be found under `API`.)
* jumphost_version - The snapshot ID created in packer.

## Usage
This platform can be used to either fork and run your own services behind a VPN configuration, or simply use the services available here. To enable a service, simply in `main.tf` replace a service from false to true:
```terraform 
hosts = {
    jumphost = false // replace to true
    devbox = false // replace to true
}
```

## Technical details
### Jumphost
The jumphost provides a wireguard VPN service. The installation script does several things:
* Installs Wireguard;
* Creates config files for access to the VPN;
* Configurates iptables to allow packets from the Wireguard VPN to the jumphost using SSH;
* Creates a new user with the name `user`;
* Hardens the SSH configuration.