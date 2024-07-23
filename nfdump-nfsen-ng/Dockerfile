FROM php:8.1-apache-bookworm

MAINTAINER Daniel Tarbuck  <tarbuck@futurewest.ca>

WORKDIR /var/www/html

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends --no-install-suggests \
         pkg-config nfdump rrdtool librrd-dev git nfdump-sflow procps net-tools vim-tiny autotools-dev automake \
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


#ENV PHPIZE_DEPS=$'autoconf \t\tdpkg-dev \t\tfile \t\tg++ \t\tgcc \t\tlibc-dev \t\tmake \t\tpkg-config \t\tre2c'
#ENV PHP_ASC_URL=https://www.php.net/distributions/php-8.1.27.tar.xz.asc
#ENV PHP_CFLAGS='-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64'
#ENV PHP_CPPFLAGS='-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64'
#ENV PHP_LDFLAGS='-Wl,-O1 -pie'
#ENV PHP_SHA256=479e65c3f05714d4aace1370e617d78e49e996ec7a7579a5be47535be61f0658
#ENV PHP_URL=https://www.php.net/distributions/php-8.1.27.tar.xz

#EUID=0
#GPG_KEYS='528995BFEDFBA7191D46839EF9BA0ADA31CBD89E 39B641343D8C104B2B146DC3F9C39DC0B9698544 F1F692238FBC1666E5A5CCD4199F9DFEF6FFBAFD'
#OPTERR=1
#OPTIND=1
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#PHP_VERSION=8.1.27


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

