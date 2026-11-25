#!/bin/bash

set -e

echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections

sudo apt update
sudo apt-get install -y git build-essential wget unzip coreutils

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# Install Golang
mkdir "$WORKDIR/toolchain"
wget -O "$WORKDIR/toolchain.tar.gz" https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
tar -xvf "$WORKDIR/toolchain.tar.gz" -C "$WORKDIR/toolchain"

export GOROOT_BOOTSTRAP=$WORKDIR/toolchain/go
export GO_DIRECTORY="toolchain"

# This is commented out by default. But it can build Golang if the default binary doesn't suffice or something :)
# mkdir "$WORKDIR/build"
# wget -O "$WORKDIR/go.tar.gz" https://go.dev/dl/go$GO_VERSION.src.tar.gz
# tar -xvf "$WORKDIR/go.tar.gz" -C "$WORKDIR/build"
# (cd $WORKDIR/build/go/src && ./make.bash)
# export GO_DIRECTORY="build"

if [[ -d "/usr/local/go" && -f "/usr/local/go/bin/go" && $(sha256sum /usr/local/go/bin/go | cut -d' ' -f1) == $(sha256sum "$WORKDIR/$GO_DIRECTORY/go/bin/go" | cut -d' ' -f1) ]]; then
    echo "The go binary already exists and is an exact copy, skipping"
else
    if [[ -d "/usr/local/go" ]]; then
        sudo rm -rf "/usr/local/go"
    fi
    sudo mv "$WORKDIR/$GO_DIRECTORY/go" /usr/local/go
    sudo ln -sf /usr/local/go/bin/go    /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
fi

# Install Sliver
wget -O "$WORKDIR/sliver.zip" https://github.com/BishopFox/sliver/archive/refs/tags/v$SLIVER_VERSION.zip

unzip "$WORKDIR/sliver.zip" -d "$WORKDIR/sliver"

if [[ -d "/usr/local/sliver" && -f "/usr/local/sliver/sliver-server" ]]; then
    echo "The sliver-server binary already exists, skipping."
else
    (cd "$WORKDIR/sliver/sliver-$SLIVER_VERSION" && make)

    if [[ -d "/usr/local/sliver" ]]; then
        sudo rm -rf "/usr/local/sliver"
    fi
    sudo mv "$WORKDIR/sliver/sliver-$SLIVER_VERSION" /usr/local/sliver
    sudo ln -sf /usr/local/sliver/sliver-server /usr/local/bin/sliver-server
fi

sliver-server --help
go version