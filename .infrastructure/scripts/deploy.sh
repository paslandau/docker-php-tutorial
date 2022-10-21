#!/usr/bin/env bash

set -e

usage="Usage: deploy.sh docker_service_name docker_image_tag (Example: deploy.sh application latest)"
[ -z "$1" ] &&  echo "No docker_service_name given! $usage" && exit 1
[ -z "$2" ] &&  echo "No docker_image_tag given! $usage" && exit 1

docker_service_name=$1
docker_image_tag=$2
docker_service_name_logger="logger"

echo "Cleaning up ALL images older than 7 days"
docker image prune -f -a --filter "until=168h"
echo "Cleaning up untagged images older than 1 day"
docker image prune -f --filter "until=24h"

echo "Initializing the codebase"
make make-init ENVS="ENV=prod TAG=${docker_image_tag} EXECUTE_GCLOUD_IN_CONTAINER=false"
echo "Retrieving secrets"
make gcp-secret-get SECRET_NAME=GPG_KEY > secret.gpg
GPG_PASSWORD=$(make gcp-secret-get SECRET_NAME=GPG_PASSWORD)
echo "Creating docker-run-secrets.env file"
echo "GPG_PASSWORD=$GPG_PASSWORD" > docker-run-secrets.env

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

echo "Pulling image for '${docker_service_name_logger}' on the VM from the registry"
make docker-pull DOCKER_SERVICE_NAME="${docker_service_name_logger}"
echo "Stop the '${docker_service_name_logger}' container on the VM"
make docker-stop DOCKER_SERVICE_NAME="${docker_service_name_logger}" || true
make docker-rm DOCKER_SERVICE_NAME="${docker_service_name_logger}" || true
echo "Start the container for '${docker_service_name_logger}' on the VM"
make docker-run-"${docker_service_name_logger}"
