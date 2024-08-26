FROM alpine:3.20

RUN apk add --no-cache  bash openssl \
    && ln -sf /bin/bash /usr/bin/bash

WORKDIR /pki
ENTRYPOINT ["/usr/local/bin/pki"]
CMD ["help"]

COPY . /usr/local/bin
