#!/bin/bash

if [[ "${UID}" -ne 0 ]]
then
  echo "This script must be run as root or with sudo."
  exit 1
fi

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

firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

exit 0

