FROM debian:11

RUN apt-get update \
    && apt-get install -y nfdump nfdump-sflow procps

WORKDIR /app
COPY entrypoint.sh .
RUN chmod a+x /app/entrypoint.sh

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
