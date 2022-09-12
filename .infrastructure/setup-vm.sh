#!/usr/bin/env bash

# Fail immediately if any command fails
set -e

usage="Usage: setup-vm.sh project_id vm_name"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1
[ -z "$2" ] &&  echo "No vm_name given! $usage" && exit 1

GREEN="\033[0;32m"
NO_COLOR="\033[0m"

project_id=$1
vm_name=$2
enable_public_access=$3
vm_zone=us-central1-a
master_service_account_key_location=./gcp-master-service-account-key.json
deployment_service_account_id=deployment
deployment_service_account_mail="${deployment_service_account_id}@${project_id}.iam.gserviceaccount.com"
network="default"

# By default, VMs should not get an external IP address
# @see https://cloud.google.com/sdk/gcloud/reference/compute/instances/create#--no-address
args_for_public_access="--no-address"
if [ -n "$enable_public_access" ]
then
  # The only exception is the nginx image - that should also be available via http / port 80
  args_for_public_access="--tags=http-server"
fi

printf "${GREEN}Activating master service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${master_service_account_key_location}" --project="${project_id}"

printf "${GREEN}Creating a Compute Instance VM${NO_COLOR}\n"
gcloud compute instances create "${vm_name}" \
    --project="${project_id}" \
    --zone="${vm_zone}" \
    --machine-type=e2-micro \
    --network="${network}" \
    --subnet=default \
    --network-tier=PREMIUM \
    --no-restart-on-failure \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="${deployment_service_account_mail}" \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --create-disk=auto-delete=yes,boot=yes,device-name="${vm_name}",image=projects/debian-cloud/global/images/debian-11-bullseye-v20220822,mode=rw,size=10,type=projects/"${project_id}"/zones/"${vm_zone}"/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any $args_for_public_access

echo "Waiting 60s for the instance to be fully ready to receive IAP connections"
sleep 60
