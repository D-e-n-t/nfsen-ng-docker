# nfsen-ng-docker

Docker setup for running nfsen-ng (Netflow visualizer), nfdump (Netflow/Sflow collector) and samplicator (Netflow/Sflow replicator) together with support for mutiple sources.

This fork runs all services in a single container, mainly so that it runs properly on a Cisco 9300 switch.  Samplicator was added to overcome the number of hosts some devices can export their flow data to.  Note that this setup will only replicate flows to the local container and one external container (althought extending this should be trivial).

## Installation

1. git pull https://github.com/D-e-n-t/nfsen-ng-docker.git
2. verify ports, environment variables and paths in docker-compose.yaml

## Installation on the Cisco 9300 platform (DNA Advantage license required)
Notes: the Cisco 9300 switches use host networking and will ignore ports.  
  The switch must have an SSD installed to use non-Cisco packages.  
  This package is not signed and makes no warranty of fitness for any purpose.  
  This package writes a fair amount of data any may prematurely wear the SSD.  

1. Complete the installation above on a Linux host running docker.
2. Save the image locally: ```docker save | gzip | c93knfsen-ng.tar.gz```
3. Copy the image to your switch.
4. Install the image: ```app-hosting install appid nfsen package usbflash1:c9knfsen-ng.tar.gz```
5. After the image has been installed (check, this can take a while), activate it: ```app-hosting activate appid nfsen```

## Usage

1. fill source.conf
    - csv style file with format : "device;port;proto"
      optionally add a mirror host and port: "device;port;proto;mirror_host;mirror_port"
    - where:
        - device is a display name like 'my-awesome-router'
        - port is a uniq value in-between 9000-9099
        - proto is sflow or nflow depending on your device capabilities)
        - mirror_host is another host that should also receive the flow records
        - mirror_port is the port on the mirror_host (that should receive the flow records)
2. docker-compose up -d
3. browse to http://localhost:81

=> additonally, you may add/remove lines in sources.conf... you need then to restart the stack by issuing 'docker-compose restart'

## Usage on a Cisco 9300 Switch

1. Install and Activate the image per above.
2. Customize the sources.conf file (per above) and copy it to the switch
3. Copy the sources.conf file to the container: ```app-hosting data appid nfsen copy usbflash1:sources.conf /sources.conf```
4. Configure the environment for the container - see code below.
5. Start the container: ```app-hosting start appid nfsen```
6. Access via a web browser (http://IP/) or access the container: ```app-hosting connect appid nfsen session /bin/bash```
Note: it will take 5 mins or so for the rrds to get generated and the inteface to be error free.
      The config above allocates 512 units of CPU time (2 vcpus), 192MB of RAM and 4GB of storage.  Adjust as needed.
```
	    iox
	    app-hosting appid nfsen
	     app-vnic AppGigabitEthernet trunk
	      vlan [Container VLAN ID] guest-interface 0
	     app-vnic management guest-interface 0
	      guest-ipaddress [IP Address] netmask [Netmask]
	     app-default-gateway [Default Gateway] guest-interface 0
	     name-server0 [DNS Server - optional]
	     app-resource docker
	      run-opts 1 " --restart unless-stopped -v $(APP_DATA)/data:/data"
	      run-opts 2 "-v $(APP_DATA)/sources.conf:/tmp/sources.conf:ro"
	      run-opts 3 "-u 0 --entrypoint '/bin/bash /app/entrypoint.sh'"
	     app-resource profile custom
	      cpu 512
	      memory 192
	      persist-disk 4096
	      vcpu 2
	    end
```

  Note: only one of the app-vnic sections should be used (depending if the container IP should be attached to a VLAN on the data plane, or on the management on the back of the switch)
## Tested with:
- FortiGate 100D and 60F
- Cisco 9800-CL Wireless controller
- Cisco 3925 Router
- Cisco 1921 Router
- Cisco 9300 Switches (running IOS-XE 17.9.4a)
- Cisco ASA 5525 Firewall

## An issue ?

1. clone
2. correct
3. share
