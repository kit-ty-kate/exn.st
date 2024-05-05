#!/bin/sh

set -e

cd unipi

mirage configure -t virtio --dhcp true
make depends
make build

solo5-virtio-mkimage -f tar -- ../image.tar.gz \
	./dist/unipi.virtio \
	--ipv4-only=true \
	--tls=true \
	--hostname=exn.st \
	--production=true \
	--remote=https://20.26.156.215/kit-ty-kate/exn.st.git#static

# TODO: The static IP for GitHub here is used because unipi on GCE, for some reason, is unable to do DNS resolution
