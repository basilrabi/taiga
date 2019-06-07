#!/bin/bash

if [[ "${UID}" -ne 0 ]]
then
  echo "This script must be run as root or with sudo."
  exit 1
fi

VOL=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

rm -rf $VOL/conf $VOL/data

mkdir -p $VOL/conf/back
mkdir -p $VOL/conf/front
mkdir -p $VOL/conf/proxy
mkdir -p $VOL/data/db
mkdir -p $VOL/data/media

podman rm -f db
podman rm -f rabbit
podman rm -f front
podman rm -f events
podman rm -f back
podman rm -f proxy

db_ip=10.88.1.64
rabbit_ip=10.88.1.65
front_ip=10.88.1.66
events_ip=10.88.1.67
back_ip=10.88.1.68

podman run --name db -dt \
	--ip $db_ip \
	--env-file variables.env \
	-v $VOL/data/db:/var/lib/postgresql/data:z \
	--image-volume tmpfs \
	docker.io/postgres:11-alpine && \
podman run --name rabbit -dt \
	--ip $rabbit_ip \
	--env-file variables.env \
	docker.io/dockertaiga/rabbit && \
podman run --name front -dt \
	--ip $front_ip \
	--env-file variables.env \
	-v $VOL/conf/front:/taiga-conf:z \
	--image-volume tmpfs \
	docker.io/dockertaiga/front && \
podman run --name events -dt \
	--ip $events_ip \
	--add-host rabbit:$rabbit_ip \
	--env-file variables.env \
	docker.io/dockertaiga/events && \
podman run --name back -dt \
	--ip $back_ip \
	--add-host db:$db_ip \
	--add-host rabbit:$rabbit_ip \
	--env-file variables.env \
	-v $VOL/data/media:/taiga-media:z \
	-v $VOL/conf/back:/taiga-conf:z \
	--image-volume tmpfs \
	docker.io/basilrabi/back && \
podman run --name proxy -dt \
	--add-host front:$front_ip \
	--add-host events:$events_ip \
	--add-host back:$back_ip \
	--env-file variables.env \
	-p 80:80 \
	-v $VOL/conf/proxy:/taiga-conf:z \
	--image-volume tmpfs \
	docker.io/basilrabi/proxy

exit 0

