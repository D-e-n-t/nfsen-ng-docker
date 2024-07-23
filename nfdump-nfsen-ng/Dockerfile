FROM php:8.1-apache-bookworm

WORKDIR /var/www/html

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends --no-install-suggests \
         apt-utils pkg-config nfdump rrdtool librrd-dev git nfdump-sflow procps net-tools vim-tiny autotools-dev automake \
    && apt-get clean -y

RUN a2enmod rewrite deflate headers expires
RUN pecl install rrd

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN echo "extension=rrd.so" >> /usr/local/etc/php/conf.d/rrd.ini
RUN sed -e '/<Directory \/var\/www\/>/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' -i /etc/apache2/apache2.conf

RUN git clone https://github.com/mbolli/nfsen-ng.git .

COPY settings.php backend/settings/settings.tmpl

RUN chown -R www-data:www-data .
RUN chmod +x backend/cli.php

WORKDIR /var/www/html/backend/datasources
RUN ln -s /data/port-data data

ENV PROFILES_DATA_PATH  /data
ENV APACHE_CONFDIR	/etc/apache2
ENV APACHE_ENVVARS	/etc/apache2/envvars
ENV APACHE_RUN_USER     www-data
ENV APACHE_RUN_GROUP    www-data
ENV APACHE_LOCK_DIR	/var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2
ENV APACHE_PID_FILE     /var/run/apache2.pid
ENV APACHE_RUN_DIR      /var/run/apache2
ENV APACHE_RUN_GROUP	www-data
ENV APACHE_RUN_USER	www-data
ENV APACHE_LOCK_DIR     /var/lock/apache2
ENV APACHE_LOG_DIR      /var/log/apache2
ENV MIRROR_PORT_OFFSET	100
ENV INTERESTING_PORTS	22,80,53,443
ENV PHP_INI_DIR		/usr/local/etc/php


#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


VOLUME [ "/data" ]

EXPOSE 80
EXPOSE 9100-9150/udp

# End of NFSen-NG setup - Start of Samplicator Setup

WORKDIR /app
RUN git config --global http.sslVerify false && \
    git clone https://github.com/elastiflow/samplicator.git && \
    cd samplicator && \
    git checkout -b 1.3.8rc1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    cd .. 
COPY entrypoint.sh .
RUN chmod a+x /app/entrypoint.sh

ENTRYPOINT [ "/bin/bash", "/app/entrypoint.sh" ]

