#!/usr/bin/env bash

# exit immediately on error
set -e

# initialize make
make make-init ENVS="ENV=prod GPG_PASSWORD=$GPG_PASSWORD"

# read the secret gpg key
make gpg-init

# Only decrypt files required for production
files=$(make secret-list | grep "/\(shared\|prod\)/" | tr '\n' ' ')
make secret-decrypt-with-password FILES="$files"

cp .secrets/prod/app.env .env

# treat this script as a "decorator" and execute any other command after running it
# @see https://www.pascallandau.com/blog/structuring-the-docker-setup-for-php-projects/#using-entrypoint-for-pre-run-configuration
exec "$@"
