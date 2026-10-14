#!/bin/bash

set -e

sudo apt update
sudo apt-get install -y git build-essential

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo $(pwd)

git clone --branch "v${WIREGUARD_VERSION}" https://git.zx2c4.com/wireguard-tools.git "$WORKDIR/wireguard-tools"

make -C "$WORKDIR/wireguard-tools/src"
make -C "$WORKDIR/wireguard-tools/src" install

cd /etc/wireguard

WG_IP="10.10.15"
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

systemctl enable wg-quick@wg0

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

chmod 600 /etc/wireguard/*

echo "[+] FINISHED Wireguard setup. Download this configuration file locally:"
echo "-----------------------------------------------------------------------"
cat client.conf
echo "-----------------------------------------------------------------------"