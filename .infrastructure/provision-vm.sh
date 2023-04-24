#!/usr/bin/env bash

# Fail immediately if any command fails
set -e

usage="Usage: provision-vm.sh project_id vm_name"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1
[ -z "$2" ] &&  echo "No vm_name given! $usage" && exit 1

GREEN="\033[0;32m"
NO_COLOR="\033[0m"

project_id=$1
vm_name=$2
vm_zone=us-central1-a
deployment_service_account_key_location=./gcp-service-account-key.json

printf "${GREEN}Provisioning VM for${NO_COLOR}\n"
printf "===\n"
printf "project_id: ${project_id}\n"
printf "vm_name:    ${vm_name}\n"

printf "${GREEN}Activating deployment service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${deployment_service_account_key_location}" --project="${project_id}"

printf "${GREEN}Transferring provisioning script${NO_COLOR}\n"
gcloud compute scp --zone ${vm_zone} --tunnel-through-iap --project=${project_id} ./.infrastructure/scripts/provision.sh ${vm_name}:provision.sh

printf "${GREEN}Executing provisioning script${NO_COLOR}\n"
gcloud compute ssh ${vm_name} --zone ${vm_zone} --tunnel-through-iap --project=${project_id} --command="bash provision.sh"

printf "${GREEN}Authenticating docker via gcloud in the VM${NO_COLOR}\n"
gcloud compute ssh ${vm_name} --zone ${vm_zone} --tunnel-through-iap --project=${project_id} --command="sudo su root -c 'gcloud auth configure-docker --quiet'"

printf "\n\n${GREEN}Provisioning done!${NO_COLOR}\n"
