#!/usr/bin/env bash

# Fail immediately if any command fails
set -e

usage="Usage: setup-redis.sh project_id"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1

GREEN="\033[0;32m"
NO_COLOR="\033[0m"

project_id=$1
redis_instance_name=$2
region=us-central1
master_service_account_key_location=./gcp-master-service-account-key.json
size=1 # in GiB
network="default" # must be the same as for the VMs
version="redis_6_x" # see https://cloud.google.com/sdk/gcloud/reference/redis/instances/create#--redis-version
private_vpc_range_name="google-managed-services-vpc-allocation"

printf "${GREEN}Activating master service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${master_service_account_key_location}" --project="${project_id}"

# -q is required to skip the AUTH confirmation
printf "${GREEN}Creating the Redis instance${NO_COLOR}\n"
gcloud redis instances create "${redis_instance_name}" \
      --size="${size}" \
      --region="${region}" \
      --network="${network}" \
      --redis-version="${version}" \
      --connect-mode=private-service-access \
      --reserved-ip-range="${private_vpc_range_name}" \
      --enable-auth \
      -q
