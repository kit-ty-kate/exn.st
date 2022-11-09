FROM --platform=amd64 kittykate/mirageos
COPY --chown=opam:opam src/ /src
WORKDIR /src
RUN opam exec -- mirage configure -t virtio --dhcp true
RUN sed -i -e 's/paf_le_highlevel/paf-le/' mirage/*.opam # Hack to get around https://github.com/mirage/mirage/issues/1372
RUN opam exec -- make pull
RUN opam exec -- mirage build
RUN opam exec -- solo5-virtio-mkimage -f tar -- image.tar.gz \
  ./dist/https.virtio \
  --ipv4-only=true \
  --letsencrypt-production=true \
  --hostname=exn.st
CMD cat image.tar.gz
