#!/usr/bin/env bash

usage="Usage: deploy.sh image_name"
[ -z "$1" ] &&  echo "No image_name given! $usage" && exit 1

image_name=$1
container_name=nginx

echo "Pulling '${image_name}' from registry"
sudo docker pull "${image_name}"

echo "Starting container"
sudo docker kill "${container_name}"; sudo docker run --name "${container_name}" -p 80:80 --rm -d "${image_name}"

echo "Getting secret GPG_KEY"
gcloud secrets versions access latest --secret=GPG_KEY >> ./secret.gpg
head ./secret.gpg

echo "Getting secret GPG_PASSWORD"
GPG_PASSWORD=$(gcloud secrets versions access latest --secret=GPG_PASSWORD)
echo $GPG_PASSWORD

