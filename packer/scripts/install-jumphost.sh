#!/bin/bash

set -e

echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

sudo apt update
sudo apt-get install -y git build-essential iptables-persistent

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo $(pwd)

# Install Wireguard
git clone --branch "v${WIREGUARD_VERSION}" https://git.zx2c4.com/wireguard-tools.git "$WORKDIR/wireguard-tools"

make -C "$WORKDIR/wireguard-tools/src"
make -C "$WORKDIR/wireguard-tools/src" install

cd /etc/wireguard

# Create config files
WG_IP="10.10.15"
INTERNAL_NETWORK="10.10.0.0/24"
SERVER_PRIVATE_KEY=$(wg genkey)
CLIENT_PRIVATE_KEY=$(wg genkey)

printf '%s\n' "$SERVER_PRIVATE_KEY" > server.key
printf '%s\n' "$CLIENT_PRIVATE_KEY" > client.key

SERVER_PUBLIC_KEY=$(printf '%s' "$SERVER_PRIVATE_KEY" | wg pubkey)
CLIENT_PUBLIC_KEY=$(printf '%s' "$CLIENT_PRIVATE_KEY" | wg pubkey)

printf '%s\n' "$SERVER_PUBLIC_KEY" > server.pub
printf '%s\n' "$CLIENT_PUBLIC_KEY" > client.pub

cat > wg0.conf <<EOF
[Interface]
Address = $WG_IP.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $WG_IP.2/32
EOF

cat > client.conf <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $WG_IP.2/24

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $DOMAIN:51820
AllowedIPs = $WG_IP.1/32, 10.10.0.0/24
PersistentKeepalive = 25
EOF

echo "[+] FINISHED Wireguard setup. Download this configuration file locally:"
echo "-----------------------------------------------------------------------"
cat client.conf
echo "-----------------------------------------------------------------------"

systemctl enable wg-quick@wg0

# Network routing
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/99-sysctl.conf

cat > /etc/iptables/rules.v4 <<EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow connections to wireguard and ssh
-A INPUT -i lo -j ACCEPT
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p udp --dport 51820 -j ACCEPT

# Allow ssh only from wireguard
-I INPUT 4 -i wg0 -p tcp --dport 22 -j ACCEPT

# Allow the wireguard nat to talk to the internal network
-A FORWARD -i wg0 -o enp7s0 -s $WG_IP.0/24 -d $INTERNAL_NETWORK -j ACCEPT
-A FORWARD -i enp7s0 -o wg0 -s $INTERNAL_NETWORK -d $WG_IP.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
COMMIT

*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]

-A POSTROUTING -s $WG_IP.0/24 -d $INTERNAL_NETWORK -o enp7s0 -j MASQUERADE
COMMIT
EOF

# Create new user
adduser --disabled-password --gecos "" user
usermod -aG sudo user
echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user
chmod 440 /etc/sudoers.d/user

mkdir -p /home/user/.ssh
echo $SSH_KEY_PUB > /home/user/.ssh/authorized_keys
chown user:user /home/user/.ssh/authorized_keys
chmod 600 /home/user/.ssh/authorized_keys

# Harden SSH
cat > /etc/ssh/sshd_config.d/00-sshd.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
AllowUsers user
MaxAuthTries 3
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
EOF