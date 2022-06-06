#!/usr/bin/env bash

docker compose -f .dev/scripts/docker-compose-build-context/docker-compose.yml build -q --no-cache
docker compose -f .dev/scripts/docker-compose-build-context/docker-compose.yml run show-build-context | sort
