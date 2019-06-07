#!/bin/bash

if [[ "${UID}" -ne 0 ]]
then
  echo "This script must be run as root or with sudo."
  exit 1
fi

VOL=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

mkdir -p $VOL/conf/back
mkdir -p $VOL/conf/front
mkdir -p $VOL/conf/proxy
mkdir -p $VOL/data/db
mkdir -p $VOL/data/media

container_name=(db rabbit front events back proxy)
podman rm -f ${container_name[@]}

podman run --name db -dt \
	--ip 10.88.0.64 \
	--env-file variables.env \
	-v $VOL/data/db:/var/lib/postgresql/data:z \
	--image-volume tmpfs \
	docker.io/postgres:11-alpine && \
podman run --name rabbit -dt \
	--ip 10.88.0.65 \
	--env-file variables.env \
	docker.io/dockertaiga/rabbit && \
podman run --name front -dt \
	--ip 10.88.0.66 \
	--env-file variables.env \
	-v $VOL/conf/front:/taiga-conf:z \
	--image-volume tmpfs \
	docker.io/dockertaiga/front && \
podman run --name events -dt \
	--ip 10.88.0.67 \
	--add-host rabbit:10.88.0.65 \
	--env-file variables.env \
	docker.io/dockertaiga/events && \
podman run --name back -dt \
	--ip 10.88.0.68 \
	--add-host db:10.88.0.64 \
	--add-host rabbit:10.88.0.65 \
	--env-file variables.env \
	-v $VOL/data/media:/taiga-media:z \
	-v $VOL/conf/back:/taiga-conf:z \
	--image-volume tmpfs \
	docker.io/basilrabi/back && \
podman run --name proxy -dt \
	--add-host front:10.88.0.66 \
	--add-host events:10.88.0.67 \
	--add-host back:10.88.0.68 \
	--env-file variables.env \
	-p 80:80 \
	-v $VOL/conf/proxy:/taiga-conf:z \
	--image-volume tmpfs \
	docker.io/basilrabi/proxy
podman stop -t 10 ${container_name[@]}

# db service

cat >/etc/systemd/system/taigadb.service <<EOL
[Unit]
Description=Taiga Database Service
Wants=syslog.service

[Service]
Restart=always
ExecStart=podman start -a db
ExecStop=podman stop -t 10 db

[Install]
WantedBy=multi-user.target
EOL

# rabbit service

cat >/etc/systemd/system/taigarabbit.service <<EOL
[Unit]
Description=Taiga Rabbit Service
Wants=syslog.service

[Service]
Restart=always
ExecStart=podman start -a rabbit
ExecStop=podman stop -t 10 rabbit

[Install]
WantedBy=multi-user.target
EOL

# front service

cat >/etc/systemd/system/taigafront.service <<EOL
[Unit]
Description=Taiga Front Service
Wants=syslog.service

[Service]
Restart=always
ExecStart=podman start -a front
ExecStop=podman stop -t 10 front

[Install]
WantedBy=multi-user.target
EOL

# events service

cat >/etc/systemd/system/taigaevents.service <<EOL
[Unit]
Description=Taiga Events Service
Wants=syslog.service
Requires=taigarabbit.service
After=taigarabbit.service

[Service]
Restart=always
ExecStart=podman start -a events
ExecStop=podman stop -t 10 events

[Install]
WantedBy=multi-user.target
EOL

# back service

cat >/etc/systemd/system/taigaback.service <<EOL
[Unit]
Description=Taiga Back Service
Wants=syslog.service
Requires=taigadb.service
Requires=taigarabbit.service
After=taigadb.service
After=taigarabbit.service

[Service]
Restart=always
ExecStart=podman start -a back
ExecStop=podman stop -t 10 back

[Install]
WantedBy=multi-user.target
EOL

# proxy service

cat >/etc/systemd/system/taigaproxy.service <<EOL
[Unit]
Description=Taiga Proxy Service
Wants=syslog.service
Requires=taigafront.service
Requires=taigaevents.service
Requires=taigaback.service
After=taigafront.service
After=taigaevents.service
After=taigaback.service

[Service]
ExecStart=podman start -a proxy
ExecStop=podman stop -t 10 proxy

[Install]
WantedBy=multi-user.target
EOL

systemctl enable taigadb.service
systemctl enable taigarabbit.service
systemctl enable taigafront.service
systemctl enable taigaevents.service
systemctl enable taigaback.service
systemctl enable taigaproxy.service

systemctl restart taigadb.service
systemctl restart taigarabbit.service
systemctl restart taigafront.service
systemctl restart taigaevents.service
systemctl restart taigaback.service
systemctl restart taigaproxy.service

exit 0

