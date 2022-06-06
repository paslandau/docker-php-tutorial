#!/usr/bin/env bash

usage="Usage: deploy.sh project_id vm_name"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1
[ -z "$2" ] &&  echo "No vm_name given! $usage" && exit 1

GREEN="\033[0;32m"
NO_COLOR="\033[0m"

project_id=$1
vm_name=$2
vm_zone=us-central1-a
image_name="gcr.io/${project_id}/nginx:latest"
deployment_service_account_key_location=./gcp-service-account-key.json

printf "${GREEN}Building nginx docker image with name '${image_name}'${NO_COLOR}\n"
docker build -t "${image_name}" -f - . <<EOF
FROM nginx:1.21.5-alpine

RUN echo "Hello world" >> /usr/share/nginx/html/hello.html

EOF

printf "${GREEN}Authenticating docker${NO_COLOR}\n"
cat "${deployment_service_account_key_location}" | docker login -u _json_key --password-stdin https://gcr.io

printf "${GREEN}Pushing '${image_name}' to registry${NO_COLOR}\n"
docker push "${image_name}"

printf "${GREEN}Transferring deployment script${NO_COLOR}\n"
gcloud compute scp --zone ${vm_zone} --tunnel-through-iap --project=${project_id} ./.infrastructure/scripts/deploy.sh ${vm_name}:deploy.sh

printf "${GREEN}Executing deployment script${NO_COLOR}\n"
gcloud compute ssh ${vm_name} --zone ${vm_zone} --tunnel-through-iap --project=${project_id} --command="bash deploy.sh '${image_name}'"

printf "${GREEN}Retrieving external IP of the VM${NO_COLOR}\n"
ip_address=$(gcloud compute instances describe ${vm_name} --zone ${vm_zone} --project=${project_id} --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
printf "http://${ip_address}/hello.html\n"

printf "\n\n${GREEN}Deployment done!${NO_COLOR}\n"


