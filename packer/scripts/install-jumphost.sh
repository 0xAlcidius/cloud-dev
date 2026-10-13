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