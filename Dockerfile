FROM --platform=amd64 ocaml/opam@sha256:112998c37f8dca361bda6a6e76e4f466c5d3ede65d61620100694de80f49fbfc
RUN sudo ln -f /usr/bin/opam-2.1 /usr/bin/opam
RUN sudo apt-get update && sudo apt-get install -yy syslinux fdisk dosfstools
RUN opam install "mirage>=4" ocaml-solo5
COPY --chown=opam:opam src/ /src
WORKDIR /src
RUN opam exec -- mirage configure -t virtio --dhcp true
RUN opam exec -- make depends
RUN opam exec -- mirage build
RUN opam exec -- solo5-virtio-mkimage -f tar -- image.tar.gz dist/https.virtio --ipv4-only=true
CMD cat image.tar.gz
