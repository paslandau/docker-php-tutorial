#!/usr/bin/env bash

set -e

usage="Usage: deploy.sh docker_service_name"
[ -z "$1" ] &&  echo "No docker_service_name given! $usage" && exit 1

docker_service_name=$1

echo "Retrieving secrets"
make gcp-secret-get SECRET_NAME=GPG_KEY > secret.gpg
GPG_PASSWORD=$(make gcp-secret-get SECRET_NAME=GPG_PASSWORD)
echo "Creating compose-secrets.env file"
echo "GPG_PASSWORD=$GPG_PASSWORD" > compose-secrets.env
echo "Initializing the codebase"
make make-init ENVS="ENV=prod TAG=latest"
echo "Pulling image for '${docker_service_name}' on the VM from the registry"
make docker-pull DOCKER_SERVICE_NAME="${docker_service_name}"
echo "Stop the '${docker_service_name}' container on the VM"
make docker-stop DOCKER_SERVICE_NAME="${docker_service_name}" || true
make docker-rm DOCKER_SERVICE_NAME="${docker_service_name}" || true

echo "Preparing service IPs as --add-host options"
service_ips=""
while read -r line; 
do 
  service_ips=$service_ips" --add-host $line" 
done < service-ips
echo "Start the container for '${docker_service_name}' on the VM"
make docker-run-"${docker_service_name}" HOST_STRING="$service_ips"
