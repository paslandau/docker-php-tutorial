#!/usr/bin/env bash

# Fail immediately if any command fails
set -e

usage="Usage: setup-gcp.sh project_id"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1

GREEN="\033[0;32m"
NO_COLOR="\033[0m"

project_id=$1
master_service_account_key_location=./gcp-master-service-account-key.json
deployment_service_account_id=deployment
deployment_service_account_key_location=./gcp-service-account-key.json
deployment_service_account_mail="${deployment_service_account_id}@${project_id}.iam.gserviceaccount.com"
gpg_secret_key_location=.tutorial/secret-production-protected.gpg.example
gpg_secret_key_password=87654321
region=us-central1
router_name=default-router
nat_name=default-nat-gateway
network="default"
private_vpc_range_name="google-managed-services-vpc-allocation"
ip_range_network_address="10.111.0.0"

printf "${GREEN}Setting up GCP project for${NO_COLOR}\n"
echo "==="
echo "project_id: ${project_id}"

printf "${GREEN}Activating master service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${master_service_account_key_location}" --project="${project_id}"

# cloudresourcemanager.googleapis.com ?
# servicenetworking.googleapis.com => Manage VPC networks
printf "${GREEN}Enabling APIs${NO_COLOR}\n"
gcloud services enable \
  containerregistry.googleapis.com \
  secretmanager.googleapis.com \
  compute.googleapis.com \
  iam.googleapis.com \
  storage.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  servicenetworking.googleapis.com

printf "${GREEN}Creating deployment service account with id '${deployment_service_account_id}'${NO_COLOR}\n"
gcloud iam service-accounts create "${deployment_service_account_id}" \
  --description="Used for the deployment application" \
  --display-name="Deployment Account"

printf "${GREEN}Creating JSON key file for deployment service account at ${deployment_service_account_key_location}${NO_COLOR}\n"
gcloud iam service-accounts keys create "${deployment_service_account_key_location}" \
  --iam-account="${deployment_service_account_mail}"

printf "${GREEN}Adding roles for service account${NO_COLOR}\n"  
roles="storage.admin secretmanager.admin compute.admin iam.serviceAccountUser iap.tunnelResourceAccessor cloudsql.viewer redis.viewer compute.viewer"

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

printf "${GREEN}Creating Router${NO_COLOR}\n"
gcloud compute routers create "${router_name}" \
      --region="${region}" \
      --network="${network}"

printf "${GREEN}Creating NAT Gateway${NO_COLOR}\n"
gcloud compute routers nats create "${nat_name}" \
    --router="${router_name}" \
    --router-region="${region}" \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges

# Required to reach internal services like Cloud SQL
# see https://cloud.google.com/vpc/docs/configure-private-services-access#procedure
# see https://cloud.google.com/sql/docs/mysql/private-ip#allocated_range_size for the --prefix-length
printf "${GREEN}Creating VPC peering range allocation for internal communication with Google Services${NO_COLOR}\n"
gcloud compute addresses create "${private_vpc_range_name}" \
    --global \
    --purpose=VPC_PEERING \
    --prefix-length=16 \
    --description="Peering range for Google" \
    --network="${network}" \
    --addresses="${ip_range_network_address}"

printf "${GREEN}Creating the actual VPC peering for Google Services${NO_COLOR}\n"
gcloud services vpc-peerings connect \
    --service=servicenetworking.googleapis.com \
    --ranges="${private_vpc_range_name}" \
    --network="${network}"
