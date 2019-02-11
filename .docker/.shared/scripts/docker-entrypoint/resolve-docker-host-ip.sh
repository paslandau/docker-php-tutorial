#!/bin/sh
set -e

# fix for host.docker.internal not existing on linux https://github.com/docker/for-linux/issues/264
# see https://dev.to/bufferings/access-host-from-a-docker-container-4099
HOST_DOMAIN="host.docker.internal"
# check if the host exists
#see https://stackoverflow.com/a/24049165/413531
if dig ${HOST_DOMAIN} | grep -q 'NXDOMAIN'
then
  # on linux, it will fail - so we'll "manually" add the hostname in the host file
  HOST_IP=$(ip route | awk 'NR==1 {print $3}')
  echo "$HOST_IP\t$HOST_DOMAIN" >> /etc/hosts
fi

exec "$@"
