FROM debian:12

RUN apt-get update -y \
    && apt-get install -y nfdump nfdump-sflow procps \
    && apt-get clean -y

WORKDIR /app
COPY entrypoint.sh .
RUN chmod a+x /app/entrypoint.sh

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]
