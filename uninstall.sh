#!/bin/bash

if [[ "${UID}" -ne 0 ]]
then
  echo "This script must be run as root or with sudo."
  exit 1
fi

VOL=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )

systemctl stop taigaproxy.service
systemctl stop taigaback.service
systemctl stop taigaevents.service
systemctl stop taigafront.service
systemctl stop taigarabbit.service
systemctl stop taigadb.service

systemctl disable taigadb.service
systemctl disable taigarabbit.service
systemctl disable taigafront.service
systemctl disable taigaevents.service
systemctl disable taigaback.service
systemctl disable taigaproxy.service

rm -rf $VOL/conf $VOL/data

container_name=(db rabbit front events back proxy)
podman rm -f ${container_name[@]}

podman image rm docker.io/basilrabi/proxy \
                docker.io/basilrabi/back \
                docker.io/dockertaiga/front \
                docker.io/dockertaiga/events \
                docker.io/dockertaiga/rabbit \
                docker.io/postgres:11-alpine

exit 0

