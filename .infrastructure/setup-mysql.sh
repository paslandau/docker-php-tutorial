#!/usr/bin/env bash

# Fail immediately if any command fails
set -e

usage="Usage: setup-mysql.sh project_id mysql_instance_name root_password"
[ -z "$1" ] &&  echo "No project_id given! $usage" && exit 1
[ -z "$2" ] &&  echo "No mysql_instance_name given! $usage" && exit 1
[ -z "$3" ] &&  echo "No root_password given! $usage" && exit 1

. $(dirname "$0")/include/include.sh

project_id=$1
# Note:
# When a mysql instance is deleted, its instance name is BLOCKED for a week (!) or so
# and cannot be re-used. Thus, we force the name as a parameter.
mysql_instance_name=$2
root_password=$3
region=us-central1
master_service_account_key_location=./gcp-master-service-account-key.json
memory="3840MB"
cpus=1
version="MYSQL_8_0"
default_database="application_db"
network="default"
private_vpc_range_name="google-managed-services-vpc-allocation"

printf "${GREEN}Activating master service account${NO_COLOR}\n"
gcloud auth activate-service-account --key-file="${master_service_account_key_location}" --project="${project_id}"

# see https://cloud.google.com/sql/docs/mysql/create-instance
# see https://cloud.google.com/sql/docs/mysql/configure-private-ip#new-private-instance for creating an instance with a private IP
# --no-assign-ip => use a private IP address
# --allocated-ip-range-name= => name of the VPC peering range; see setup-gcp.sh (beta only)
printf "${GREEN}Creating the MySQL instance${NO_COLOR}\n"
gcloud beta sql instances create "${mysql_instance_name}" \
        --database-version="${version}" \
        --cpu="${cpus}" \
        --memory="${memory}" \
        --region="${region}" \
        --network="${network}" \
        --deletion-protection \
        --no-assign-ip \
        --allocated-ip-range-name="${private_vpc_range_name}"

# see https://cloud.google.com/sql/docs/mysql/create-manage-users#change-pwd
printf "${GREEN}Set root password${NO_COLOR}\n"
gcloud sql users set-password root \
        --host=% \
        --instance "${mysql_instance_name}" \
        --password "${root_password}"

# see https://cloud.google.com/sql/docs/mysql/create-manage-databases#create
printf "${GREEN}Create default database${NO_COLOR}\n"
gcloud sql databases create "${default_database}" \
        --instance="${mysql_instance_name}" \
        --charset=utf8mb4 \
        --collation=utf8mb4_unicode_ci
