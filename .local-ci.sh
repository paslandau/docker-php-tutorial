#!/usr/bin/env bash
# fail on any error 
# @see https://stackoverflow.com/a/3474556/413531
set -e

make docker-compose-down ENV=ci || true

start_total=$(date +%s)

# STORE GPG KEY and password
cp .tutorial/secret-ci-protected.gpg.example secret.gpg
# The `docker-run-secrets.env` file is used in `.docker/docker-compose/docker-compose.ci.yml`
# to pass make the GPG_PASSWORD available in `.docker/images/php/base/decrypt-secrets.sh`
echo "GPG_PASSWORD=12345678" > docker-run-secrets.env

# DEBUG
docker version
docker compose version
cat /etc/*-release || true

# SETUP DOCKER
make make-init ENVS="ENV=ci EXECUTE_IN_CONTAINER=true"
make docker-compose-init
start_docker_build=$(date +%s)
make docker-compose-build
end_docker_build=$(date +%s)
      
# START DOCKER
start_docker_up=$(date +%s)
make docker-compose-up
end_docker_up=$(date +%s)
    
# QA
start_qa=$(date +%s)
make qa || FAILED=true
end_qa=$(date +%s)
    
# WAIT FOR CONTAINERS
start_wait_for_containers=$(date +%s)
bash .docker/scripts/wait-for-service.sh mysql 30 1
end_wait_for_containers=$(date +%s)

# TEST
start_test=$(date +%s)
make test || FAILED=true
end_test=$(date +%s)

end_total=$(date +%s)

# RUNTIMES
echo "Build docker:        " `expr $end_docker_build - $start_docker_build`
echo "Start docker:        " `expr $end_docker_up - $start_docker_up`
echo "QA:                  " `expr $end_qa - $start_qa`
echo "Wait for containers: " `expr $end_wait_for_containers - $start_wait_for_containers`
echo "Tests:               " `expr $end_test - $start_test`
echo "---------------------"
echo "Total:               " `expr $end_total - $start_total`


# CLEANUP
# reset the default make variables
make make-init
# restore the local GPG key
cp .tutorial/secret.gpg.example secret.gpg

make docker-compose-down ENV=ci || true
  
# EVALUATE RESULTS
if [ "$FAILED" == "true" ]; then echo "FAILED"; exit 1; fi
 
echo "SUCCESS"
