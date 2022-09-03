#!/bin/bash

# This script waits for a docker `$service` to become "healthy"
# by checking the `.State.Health.Status` info of the `docker inspect` command.
# It will check up to `$max` times in a interval of `$interval` seconds.
# @see https://unix.stackexchange.com/a/82610 and https://unix.stackexchange.com/a/137639 for the retry logic
# @see https://stackoverflow.com/a/42738182/413531 for inspecting the "health" status via docker
# @see https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script#comment14155976_6482403 for handling optional arguments

name=$1
max=$2
interval=$3

[ -z "$1" ] && echo "Usage example: bash wait-for-service.sh mysql 5 1" && exit 1;
[ -z "$2" ] && max=30
[ -z "$3" ] && interval=1

echo "Waiting for service '$name' to become healthy, checking every $interval second(s) for max. $max times"

while true; do 
  ((i++))
  echo "[$i/$max] ..."; 
  status=$(docker inspect --format "{{json .State.Health.Status }}" "$(docker ps --filter name="$name" -q)")
  if echo "$status" | grep -q '"healthy"'; then 
   echo "SUCCESS";
   break
  fi
  if [ $i == $max ]; then 
    echo "FAIL"; 
    exit 1
  fi
  sleep $interval; 
done
