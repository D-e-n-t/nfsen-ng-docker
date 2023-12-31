#!/bin/bash

if [[ -n ${MIRROR_PORT_OFFSET} ]]; then MIRROR_PORT_OFFSET=100; fi
# avoid process container restart when updating sources.conf
cp /tmp/sources.conf /tmp/sources.set
# read source.set and start a background [sn]fcap process for each source
cat /tmp/sources.set | while read ln; do
    command=""
    # read -r host port protocol <<< $(echo $ln | awk -F ';' '{print $1 " " $2 " " substr($3,1,1)}')
    read -r host port protocol mdest mport <<< $(echo $ln | awk -F ';' '{print $1 " " $2 " " substr($3,1,1) " " $4 " " $5}')
    if [[ -n $mdest ]]; then
        listenport=$port
        port=$(($listenport + $MIRROR_PORT_OFFSET))
        mcommand="samplicate -s 0.0.0.0 -p $listenport -S -d 0 127.0.0.1/$port $mdest/$mport"
        else unset mcommand
    fi
    mkdir -p /data/live/$host && command="${protocol}fcapd -I $host -w /data/live/$host -S 1 -T all -p $port -e -z" && \
    if [ -z "$command" ]; then 
        echo >&2 "Error creating directory /data/live/$host"
        exit 1
    else
        if [[ -n $mcommand ]]; then 
            echo '$' $mcommand; 
           $mcommand &
        fi
        echo '$' $command
        $command &
        sleep 0.1
    fi
    if [ $? -ne 0 ]; then 
        echo >&2 "Startup interrupted !"
        exit
    fi
done
sleep 1
echo "NFDump and Samplecate Running, starting Apache..."

sources=`cat /tmp/sources.conf | sed -re "s/^([^;]*);.*$/'\1',/" | tr '\n' ' ' `
if [[ -n ${INTERESTING_PORTS} ]]; then
	sed -e "s/80, 22, 53, 443/${INTERESTING_PORTS}/" /var/www/html/backend/settings/settings.tmpl | \
        sed -e "s/'router',/$sources/" > /var/www/html/backend/settings/settings.php
    else
        sed -e "s/'router',/$sources/" /var/www/html/backend/settings/settings.tmpl > /var/www/html/backend/settings/settings.php
fi
if php -f /var/www/html/backend/settings/settings.php; then
    /var/www/html/backend/cli.php start
    /usr/sbin/apachectl start
fi

echo "Startup completed.  Entering WatchDog loop"

while true; do
    sleep 60; 
    cat /tmp/sources.set | while read ln; do
        # read -r host port protocol <<< $(echo $ln | awk -F ';' '{print $1 " " $2 " " substr($3,1,1)}')
        read -r host port protocol mdest mport <<< $(echo $ln | awk -F ';' '{print $1 " " $2 " " substr($3,1,1) " " $4 " " $5}')
        if [[ -n $mdest ]]; then
            ps aux| grep '\s'"samplicate -s 0.0.0.0 -p $port"'\s' > /dev/null || { echo >&2 "Missing samplicate process for $host (port $port)"; exit 1; }
            # ps aux| grep '\s'"samplicate -s 0.0.0.0 -p $port"'\s' > /dev/null || { echo >&2 "Missing samplicate process for $host (port $port)"; }
        fi 
        ps aux| grep '\s'$host'\s' > /dev/null || { echo >&2 "Missing collector process for $host (port $port)"; exit 1; }
    done
    if [ $? -ne 0 ]; then 
        echo >&2 "Restarting..."
        break
    fi
done
