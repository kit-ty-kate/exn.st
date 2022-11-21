FROM --platform=amd64 kittykate/mirageos
COPY --chown=opam:opam src/ /exn-st/src
COPY --chown=opam:opam .git/ .gitmodules /exn-st
WORKDIR /exn-st
RUN git submodule update --init
WORKDIR /exn-st/src
RUN opam exec -- mirage configure -t virtio --dhcp true
RUN sed -i -e 's/minimal_http/paf/' mirage/*.opam # Hack to get around https://github.com/mirage/mirage/issues/1372
RUN opam exec -- make pull
RUN opam exec -- mirage build
RUN opam exec -- solo5-virtio-mkimage -f tar -- image.tar.gz \
  ./dist/https.virtio \
  --ipv4-only=true \
  --letsencrypt-production=true \
#  --http=80 \
  --https=443 \
  --hostname=exn.st
CMD cat image.tar.gz
