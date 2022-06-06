#!/usr/bin/env bash

echo "Retrieving secrets"
make gcp-secret-get SECRET_NAME=GPG_KEY > secret.gpg
GPG_PASSWORD=$(make gcp-secret-get SECRET_NAME=GPG_PASSWORD)
echo "Creating compose-secrets.env file"
echo "GPG_PASSWORD=$GPG_PASSWORD" > compose-secrets.env
echo "Initializing the codebase"
make make-init ENVS="ENV=prod TAG=latest"
echo "Pulling images on the VM from the registry"
make docker-pull
echo "Stop the containers on the VM"
make docker-down || true
echo "Start the containers on the VM"
make docker-up
