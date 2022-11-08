FROM --platform=amd64 kittykate/mirageos
COPY --chown=opam:opam src/ /src
WORKDIR /src
RUN opam exec -- mirage configure -t virtio --dhcp true
RUN opam exec -- make depends
RUN opam exec -- mirage build
RUN opam exec -- solo5-virtio-mkimage -f tar -- image.tar.gz dist/https.virtio --ipv4-only=true
CMD cat image.tar.gz
