#!/bin/bash

function info(){
  echo "
  
  $1
  
  "
}

info "Building the docker setup"
make make-init
make docker-build

info "Starting the docker setup"
make docker-down
make docker-up

info "Clearing DB"
make setup-db ARGS=--drop

info "Stopping workers"
make stop-workers

info "Ensuring that queue and db are empty"
curl -sS "http://app.local/?queue"
curl -sS "http://app.local/?db"

info "Dispatching a job 'foo'"
curl -sS "http://app.local/?dispatch=foo"

info "Asserting the job 'foo' is on the queue"
curl -sS "http://app.local/?queue"

info "Starting the workers"
make start-workers
sleep 1

info "Asserting the queue is now empty"
curl -sS "http://app.local/?queue"

info "Asserting the db now contains the job 'foo'"
curl -sS "http://app.local/?db"
