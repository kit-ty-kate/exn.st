FROM --platform=amd64 kittykate/mirageos
RUN sudo mkdir /exn-st && sudo chown opam:opam /exn-st
COPY --chown=opam:opam src/ /exn-st/src
COPY --chown=opam:opam vendors/ /exn-st/vendors
COPY --chown=opam:opam .git/ /exn-st/.git
COPY --chown=opam:opam .gitmodules /exn-st/.gitmodules
WORKDIR /exn-st
RUN git submodule update --init
RUN opam exec -- mirage configure -t virtio --dhcp true -f src/config.ml
RUN opam exec -- make pull
RUN opam exec -- mirage build -f src/config.ml
RUN opam exec -- solo5-virtio-mkimage -f tar -- image.tar.gz \
  ./src/dist/unikernel.virtio \
  --ipv4-only=true \
  --letsencrypt-production=true \
#  --http=80 \
  --https=443 \
  --hostname=exn.st
CMD cat image.tar.gz
