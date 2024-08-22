FROM alpine:3.20

RUN apk add --no-cache  bash \
    && ln -sf /bin/bash /usr/bin/bash
COPY . /usr/local/bin

ENTRYPOINT ["/usr/local/bin/pki"]
CMD ["help"]

