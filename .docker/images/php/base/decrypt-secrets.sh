#!/usr/bin/env bash

# The scripts expects the environment variable ENV and GPG_PASSWORD to exist
usage="Usage: ENV=prod GPG_PASSWORD=secret_gpg_password decrypt-secrets.sh"
[ -z "$ENV" ] &&  echo "ENV variable ENV does not exist! $usage" && exit 1
[ -z "$GPG_PASSWORD" ] &&  echo "ENV variable GPG_PASSWORD does not exist! $usage" && exit 1

# exit immediately on error
set -e

# initialize make
make make-init ENVS="GPG_PASSWORD=${GPG_PASSWORD}"

# initialize gpg
make gpg-init

# Only decrypt files required for the given ENV
files=$(make secret-list | grep "/\(shared\|${ENV}\)/" | tr '\n' ' ')
make secret-decrypt-with-password FILES="$files"

cp ".secrets/${ENV}/app.env" .env

# treat this script as a "decorator" and execute any other command after running it
# @see https://www.pascallandau.com/blog/structuring-the-docker-setup-for-php-projects/#using-entrypoint-for-pre-run-configuration
exec "$@"
