#!/bin/bash

# Local Pre-Setup Script
if [ -x /data/local-setup.sh ]; then
  /data/local-setup.sh
fi

# Initial Setup
if [[ -n ${MIRROR_PORT_OFFSET} ]]; then MIRROR_PORT_OFFSET=100; fi
if [[ -f ${APACHE_SITE} ]]; then
    # Enable additional site from file (bind a file and specify the container mount point in the environment variable)
    cd /etc/apache2/sites-enabled && ln -s ${APACHE_SITE}
    if [[ -n ${APACHE_PROXY} ]]; then
        # Enable Apache mod_proxy
        cd /etc/apache2/mods-enabled && ln -s ../mods-available/proxy.conf && \
                ln -s ../mods-available/proxy.load && ln -s ../mods-available/proxy_http.load
    fi
    if [[ -n ${APACHE_SSL} ]]; then
        # Enable Apache mod_ssl if this environment variable is set
        cd /etc/apache2/mods-enabled && ln -s ../mods-available/ssl.conf && \
                ln -s ../mods-available/ssl.load && ln -s ../mods-available/socache_shmcb.load
    fi
    cd /app
fi
if [[ -L /var/www/html/backend/datasources/data && -d /var/www/html/backend/datasources/data ]]; then
    # previously, interesting port data was stored in the container, but this caused temporary issues after a restart
    echo "Port data has already been migrated."
else
    # If there's a link and it's broken, get rid of it.
    if [[ -L /var/www/html/backend/datasources/data ]]; then rm /var/www/html/backend/datasources/data; mkdir /var/www/html/backend/datasources/data; fi
    # Now we move the port data to a location in the persistent data store
    mv /var/www/html/backend/datasources/data /data/port-data && ln -s /data/port-data /var/www/html/backend/datasources/data 
    echo "Port data migrated."
fi


# avoid process container restart when updating sources.conf
if [[ ! -f /tmp/sources.conf ]]; then echo "router1;9000;nflow" > /tmp/sources.conf; fi
cp /tmp/sources.conf /tmp/sources.set

# read source.set and start a background [sn]fcap process for each source
cat /tmp/sources.set | while read ln; do
    command=""
    read -r host port protocol mdest mport <<< $(echo $ln | awk -F ';' '{print $1 " " $2 " " substr($3,1,1) " " $4 " " $5}')
    if [[ -n $mdest ]]; then
        # If we're mirroring the traffic, run samplicate and nfcapd can listen on localhost interface (at a differnet port)
        listenport=$port
        port=$(($listenport + $MIRROR_PORT_OFFSET))
        mcommand="samplicate -s 0.0.0.0 -p $listenport -f -S -d 0 127.0.0.1/$port $mdest/$mport"
        bind="-b 127.0.0.1"
        else unset mcommand bind
    fi

    # Create the data directory (if required) and change ownership
    mkdir -p /data/live/$host && chown nobody:nogroup -R /data/live/$host && \
            command="${protocol}fcapd -u nobody -g nogroup -I $host $bind -w /data/live/$host -S 1 -p $port -e -z -D" 
    if [ -z "$command" ]; then 
        echo >&2 "Error creating directory /data/live/$host"
        exit 1
    else
	# All good, let's do it then
        if [[ -n $mcommand ]]; then 
           # Run the mirror command
           echo '$' $mcommand; 
           $mcommand
        fi
        # Run the capture command
        echo '$' $command
        $command
        sleep 0.1 # not sure this is needed anymore
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
        # It might be a good ideal to check Interesting Ports here.  Should be comma separated integers, strings (quotes) break everything.
	sed -e "s/80, 22, 53, 443/${INTERESTING_PORTS}/" /var/www/html/backend/settings/settings.tmpl | \
        sed -e "s/'router',/$sources/" > /var/www/html/backend/settings/settings.php
    else
        sed -e "s/'router',/$sources/" /var/www/html/backend/settings/settings.tmpl > /var/www/html/backend/settings/settings.php
fi
if php -f /var/www/html/backend/settings/settings.php; then
    # Startup the background listner and Apache
    /var/www/html/backend/cli.php start
    /usr/sbin/apachectl start
fi

echo "Startup completed.  Entering WatchDog loop"

while true; do
    sleep 60; 
    cat /tmp/sources.set | while read ln; do
        read -r host port protocol mdest mport <<< $(echo $ln | awk -F ';' '{print $1 " " $2 " " substr($3,1,1) " " $4 " " $5}')
        if [[ -n $mdest ]]; then
            ps aux| grep '\s'"samplicate -s 0.0.0.0 -p $port"'\s' > /dev/null || { echo >&2 "Missing samplicate process for $host (port $port)"; exit 1; }
        fi 
        ps aux| grep '\s'$host'\s' > /dev/null || { echo >&2 "Missing collector process for $host (port $port)"; exit 1; }
    done
    if [ $? -ne 0 ]; then 
        echo >&2 "Restarting..."
        break
    fi
done
