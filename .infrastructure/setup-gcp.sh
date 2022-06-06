#!/usr/bin/env bash

usage="Usage: setup-gcp.sh project_id vm_name"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1
[ -z "$2" ] &&  echo "No vm_name given! $usage" && exit 1

GREEN="\033[0;32m"
NO_COLOR="\033[0m"

project_id=$1
vm_name=$2
vm_zone=us-central1-a
master_service_account_key_location=./gcp-master-service-account-key.json
deployment_service_account_id=deployment
deployment_service_account_key_location=./gcp-service-account-key.json
deployment_service_account_mail="${deployment_service_account_id}@${project_id}.iam.gserviceaccount.com"
gpg_secret_key_location=.tutorial/secret-production-protected.gpg.example
gpg_secret_key_password=87654321

printf "${GREEN}Setting up GCP project for${NO_COLOR}\n"
echo "==="
echo "project_id: ${project_id}"
echo "vm_name:    ${vm_name}"

printf "${GREEN}Activating master service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${master_service_account_key_location}" --project="${project_id}"

printf "${GREEN}Enabling APIs${NO_COLOR}\n"
gcloud services enable \
  containerregistry.googleapis.com \
  secretmanager.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  storage.googleapis.com \
  cloudresourcemanager.googleapis.com

printf "${GREEN}Creating deployment service account with id '${deployment_service_account_id}'${NO_COLOR}\n"
gcloud iam service-accounts create "${deployment_service_account_id}" \
  --description="Used for the deployment application" \
  --display-name="Deployment Account"
  
printf "${GREEN}Creating JSON key file for deployment service account at ${deployment_service_account_key_location}${NO_COLOR}\n"
gcloud iam service-accounts keys create "${deployment_service_account_key_location}" \
  --iam-account="${deployment_service_account_mail}"

printf "${GREEN}Adding roles for service account${NO_COLOR}\n"  
roles="storage.admin secretmanager.admin compute.admin iam.serviceAccountUser iap.tunnelResourceAccessor"

for role in $roles; do
  gcloud projects add-iam-policy-binding "${project_id}" --member=serviceAccount:"${deployment_service_account_mail}" "--role=roles/${role}"
done;

printf "${GREEN}Creating secrets${NO_COLOR}\n"
gcloud secrets create GPG_KEY
gcloud secrets versions add GPG_KEY --data-file="${gpg_secret_key_location}"

gcloud secrets create GPG_PASSWORD
echo -n "${gpg_secret_key_password}" | gcloud secrets versions add GPG_PASSWORD --data-file=-

printf "${GREEN}Creating firewall rule to allow HTTP traffic${NO_COLOR}\n"
gcloud compute firewall-rules create default-allow-http --allow tcp:80 --target-tags=http-server

printf "${GREEN}Creating a Compute Instance VM${NO_COLOR}\n"
gcloud compute instances create "${vm_name}" \
    --project="${project_id}" \
    --zone="${vm_zone}" \
    --machine-type=e2-small \
    --network-interface=network-tier=PREMIUM,subnet=default \
    --no-restart-on-failure \
    --maintenance-policy=TERMINATE \
    --provisioning-model=SPOT \
    --instance-termination-action=STOP \
    --service-account="${deployment_service_account_mail}" \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name="${vm_name}",image=projects/debian-cloud/global/images/debian-11-bullseye-v20220519,mode=rw,size=10,type=projects/"${project_id}"/zones/"${vm_zone}"/diskTypes/pd-balanced \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --reservation-affinity=any

printf "${GREEN}Activating deployment service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${deployment_service_account_key_location}" --project="${project_id}"

printf "${GREEN}Transferring provisioning script${NO_COLOR}\n"
echo "Waiting 60s for the instance to be fully ready to receive IAP connections"
sleep 60
gcloud compute scp --zone ${vm_zone} --tunnel-through-iap --project=${project_id} ./.infrastructure/scripts/provision.sh ${vm_name}:provision.sh

printf "${GREEN}Executing provisioning script${NO_COLOR}\n"
gcloud compute ssh ${vm_name} --zone ${vm_zone} --tunnel-through-iap --project=${project_id} --command="bash provision.sh"

printf "${GREEN}Authenticating docker via gcloud in the VM${NO_COLOR}\n"
gcloud compute ssh ${vm_name} --zone ${vm_zone} --tunnel-through-iap --project=${project_id} --command="sudo su root -c 'gcloud auth configure-docker --quiet'"

printf "\n\n${GREEN}Provisioning done!${NO_COLOR}\n"
