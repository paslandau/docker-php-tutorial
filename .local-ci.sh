#!/usr/bin/env bash
# fail on any error 
# @see https://stackoverflow.com/a/3474556/413531
set -e

make docker-down ENV=ci || true

start_total=$(date +%s)

# STORE GPG KEY
cp secret-protected.gpg.example secret.gpg

# DEBUG
docker version
docker compose version
cat /etc/*-release || true

# SETUP DOCKER
make make-init ENVS="ENV=ci TAG=latest EXECUTE_IN_CONTAINER=true GPG_PASSWORD=12345678"
start_docker_build=$(date +%s)
make docker-build
end_docker_build=$(date +%s)
mkdir -p .build && chmod 777 .build
      
# START DOCKER
start_docker_up=$(date +%s)
make docker-up
end_docker_up=$(date +%s)
make gpg-init
make secret-decrypt-with-password
    
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
make docker-down ENV=ci || true
  
# EVALUATE RESULTS
if [ "$FAILED" == "true" ]; then echo "FAILED"; exit 1; fi
 
echo "SUCCESS"
