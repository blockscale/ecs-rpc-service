FROM ethereum/client-go:v1.9.8

ENV AWSCLI_VERSION "1.16.290"

USER root
RUN apk add --update \
    bash \
    python \
    python-dev \
    py-pip \
    build-base \
    && pip install awscli==$AWSCLI_VERSION --no-warn-script-location --upgrade --user \
    && apk --purge -v del py-pip \
    && rm -rf /var/cache/apk/*

COPY ./start-geth.sh /root/start-geth.sh
RUN chmod +x /root/start-geth.sh

EXPOSE 8080 8545 8180
ENTRYPOINT ["/root/start-geth.sh"]
