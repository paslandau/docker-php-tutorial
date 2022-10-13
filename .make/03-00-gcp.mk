##@ [GCP]

EXECUTE_GCLOUD_IN_CONTAINER?=true
GCLOUD_VERSION:=403.0.0-slim
GCLOUD_DOCKER_IMAGE_USER=cloudsdk

RUN_GCLOUD_DOCKER_IMAGE_ARGS= -i \
							  --rm \
                              --workdir="/codebase" \
                              --mount type=bind,source="$$(pwd)",target=/codebase \
                              --mount type=volume,src=gcloud-config,dst=/home/$(GCLOUD_DOCKER_IMAGE_USER) \
                              --user $(GCLOUD_DOCKER_IMAGE_USER)

RUN_GCLOUD_DOCKER_IMAGE:=docker run $(RUN_GCLOUD_DOCKER_IMAGE_ARGS) gcr.io/google.com/cloudsdktool/google-cloud-cli:$(GCLOUD_VERSION)
RUN_GCLOUD_DOCKER_IMAGE_WITH_TTY:=$(WINPTY_PREFIX) docker run -t $(RUN_GCLOUD_DOCKER_IMAGE_ARGS) gcr.io/google.com/cloudsdktool/google-cloud-cli:$(GCLOUD_VERSION)

GCLOUD:=gcloud
GCLOUD_WITH_TTY:=gcloud
ifeq ($(EXECUTE_GCLOUD_IN_CONTAINER),true)
	GCLOUD:=$(RUN_GCLOUD_DOCKER_IMAGE) gcloud
	GCLOUD_WITH_TTY:=$(RUN_GCLOUD_DOCKER_IMAGE_WITH_TTY) gcloud
endif

.PHONY: gcp-gcloud
gcp-gcloud: ## Run an arbitrary `gcloud` command specified via ARGS
	$(GCLOUD) $(ARGS) 

.PHONY: gcp-create-ssh-key
gcp-create-ssh-key: ## Create an SSH key pair named "google_compute_engine" in the gcloud docker image at ~/.ssh
	@$(RUN_GCLOUD_DOCKER_IMAGE_WITH_TTY) ssh-keygen -t rsa -f /home/$(GCLOUD_DOCKER_IMAGE_USER)/.ssh/google_compute_engine -C $(GCLOUD_DOCKER_IMAGE_USER) -N "";

.PHONY: gcp-authenticate-docker
gcp-authenticate-docker: ## Authenticate docker with the JSON key file specified via SERVICE_ACCOUNT_KEY_FILE
	@$(if $(SERVICE_ACCOUNT_KEY_FILE),,$(error "SERVICE_ACCOUNT_KEY_FILE is undefined"))
	cat "$(SERVICE_ACCOUNT_KEY_FILE)" | docker login -u _json_key --password-stdin https://gcr.io

.PHONY: gcp-activate-service-account
gcp-activate-service-account: validate-gcp-variables ## Initialize the `gcloud` cli with the service account specified via SERVICE_ACCOUNT_KEY_FILE
	@$(if $(SERVICE_ACCOUNT_KEY_FILE),,$(error "SERVICE_ACCOUNT_KEY_FILE is undefined"))
	$(GCLOUD) auth activate-service-account --key-file="$(SERVICE_ACCOUNT_KEY_FILE)" --project="$(GCP_PROJECT_ID)"

.PHONY: gcp-activate-deployment-account
gcp-activate-deployment-account: validate-gcp-variables ## Initialize the `gcloud` cli with the deployment service account 
	@$(if $(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE),,$(error "GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE is undefined"))
	"$(MAKE)" gcp-activate-service-account SERVICE_ACCOUNT_KEY_FILE=$(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE)

.PHONY: gcp-activate-master-account
gcp-activate-master-account: validate-gcp-variables ## Initialize the `gcloud` cli with the master service account 
	@$(if $(GCP_MASTER_SERVICE_ACCOUNT_KEY_FILE),,$(error "GCP_MASTER_SERVICE_ACCOUNT_KEY_FILE is undefined"))
	"$(MAKE)" gcp-activate-service-account SERVICE_ACCOUNT_KEY_FILE=$(GCP_MASTER_SERVICE_ACCOUNT_KEY_FILE)

.PHONY: validate-gcp-variables
validate-gcp-variables:
	@$(if $(GCP_PROJECT_ID),,$(error "GCP_PROJECT_ID is undefined"))
	@$(if $(GCP_ZONE),,$(error "GCP_ZONE is undefined"))

# @see https://cloud.google.com/sdk/gcloud/reference/compute/ssh
.PHONY: gcp-ssh-command
gcp-ssh-command: validate-gcp-variables ## Run an arbitrary SSH command on the VM via IAP tunnel. Usage: `make gcp-ssh-command COMMAND="whoami"`
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	@$(if $(COMMAND),,$(error "COMMAND is undefined"))
	$(GCLOUD) compute ssh $(VM_NAME) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap --verbosity=error --command="$(COMMAND)"

.PHONY: gcp-ssh-login
gcp-ssh-login: validate-gcp-variables ## Log into a VM via IAP tunnel
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	$(GCLOUD_WITH_TTY) compute ssh $(VM_NAME) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap --verbosity=error

# @see https://cloud.google.com/sdk/gcloud/reference/compute/scp
.PHONY: gcp-scp-command
gcp-scp-command: validate-gcp-variables ## Copy a file via scp to the VM via IAP tunnel. Usage: `make gcp-scp-command SOURCE="foo" DESTINATION="bar"`
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	@$(if $(SOURCE),,$(error "SOURCE is undefined"))
	@$(if $(DESTINATION),,$(error "DESTINATION is undefined"))
	$(GCLOUD) compute scp $(SOURCE) $(VM_NAME):$(DESTINATION) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap --verbosity=error

# Defines the default secret version to retrieve from the Secret Manager
SECRET_VERSION?=latest

# @see https://cloud.google.com/sdk/gcloud/reference/secrets/versions/access
.PHONY: gcp-secret-get
gcp-secret-get: ## Retrieve and print the secret $(SECRET_NAME) in version $(SECRET_VERSION) from the Secret Manager
	@$(if $(SECRET_NAME),,$(error "SECRET_NAME is undefined"))
	@$(if $(SECRET_VERSION),,$(error "SECRET_VERSION is undefined"))
	@$(GCLOUD) secrets versions access $(SECRET_VERSION) --secret=$(SECRET_NAME)

DOCKER_USERNAME?=root
.PHONY: gcp-docker-compose-exec
gcp-docker-compose-exec: ## Run a command in a docker container vid compose on the VM. Usage: `make gcp-docker-compose-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="echo 'Hello world!'"` 
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DOCKER_COMMAND),,$(error "DOCKER_COMMAND is undefined"))
	@$(if $(DOCKER_USERNAME),,$(error "DOCKER_USERNAME is undefined"))
	"$(MAKE)" -s gcp-ssh-command COMMAND="cd $(CODEBASE_DIRECTORY) && sudo make docker-compose-exec DOCKER_USERNAME='$(DOCKER_USERNAME)' DOCKER_SERVICE_NAME='$(DOCKER_SERVICE_NAME)' DOCKER_COMMAND='$(DOCKER_COMMAND)'"

.PHONY: gcp-docker-exec
gcp-docker-exec: ## Run a command in a docker container on the VM. Usage: `make gcp-docker-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="echo 'Hello world!'"` DOCKER_USERNAME=root
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DOCKER_COMMAND),,$(error "DOCKER_COMMAND is undefined"))
	@$(if $(DOCKER_USERNAME),,$(error "DOCKER_USERNAME is undefined"))
	"$(MAKE)" -s gcp-ssh-command COMMAND="cd $(CODEBASE_DIRECTORY) && sudo docker exec --user $(DOCKER_USERNAME) $(DOCKER_SERVICE_NAME) $(DOCKER_COMMAND)"

# Retrieve IPs 

.PHONY: gcp-get-ips
gcp-get-ips: ## Get the IP addresses for all services
	@printf "$(DOCKER_SERVICE_NAME_MYSQL):"
	@"$(MAKE)" -s gcp-get-private-ip-mysql
	@printf "$(DOCKER_SERVICE_NAME_REDIS):"
	@"$(MAKE)" -s gcp-get-private-ip-redis
	@for vm_name_service_name in $(ALL_VM_SERVICE_NAMES); do \
  		vm_name=`echo $$vm_name_service_name | cut -d ":" -f 1`; \
  		service_name=`echo $$vm_name_service_name | cut -d ":" -f 2`; \
  		printf "$$service_name:"; \
  		"$(MAKE)" -s gcp-get-private-ip-vm VM_NAME=$$vm_name; \
  	  done;

# @see https://cloud.google.com/compute/docs/instances/view-ip-address
.PHONY: gcp-get-public-ip-vm
gcp-get-public-ip-vm: ## Get the public ip of a VM
	@$(if $(GCP_PROJECT_ID),,$(error "GCP_PROJECT_ID is undefined"))
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	$(GCLOUD) compute instances describe $(VM_NAME) --format="get(networkInterfaces[0].accessConfigs[0].natIP)" --project=$(GCP_PROJECT_ID) --zone=$(GCP_ZONE)

.PHONY: gcp-get-private-ip-vm
gcp-get-private-ip-vm: ## Get the private ip of a VM
	@$(if $(GCP_PROJECT_ID),,$(error "GCP_PROJECT_ID is undefined"))
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	$(GCLOUD) compute instances describe $(VM_NAME) --format="get(networkInterfaces[0].networkIP)" --project=$(GCP_PROJECT_ID) --zone=$(GCP_ZONE)

.PHONY: gcp-get-private-ip-mysql
gcp-get-private-ip-mysql: ## Get the private IP address of the SQL service
	$(GCLOUD) sql instances describe $(VM_NAME_MYSQL) --format="get(ipAddresses[0].ipAddress)" --project=$(GCP_PROJECT_ID)

.PHONY: gcp-get-private-ip-redis
gcp-get-private-ip-redis: ## Get the private IP address of the Redis service
	$(GCLOUD) redis instances describe $(VM_NAME_REDIS) --format="get(host)" --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION)

# see https://cloud.google.com/memorystore/docs/redis/auth-overview#auth_behavior
# see https://cloud.google.com/memorystore/docs/redis/managing-auth#getting_the_auth_string
.PHONY: gcp-get-redis-auth
gcp-get-redis-auth: ## Get the AUTH string of the Redis service
	$(GCLOUD) redis instances get-auth-string $(VM_NAME_REDIS) --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION) | cut -d " " -f 2

.PHONY: gcp-info-redis
gcp-info-redis: ## Show redis information
	$(GCLOUD) redis instances list --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION)

.PHONY: gcp-info-mysql
gcp-info-mysql: ## Show mysql information
	$(GCLOUD) sql instances list --project=$(GCP_PROJECT_ID)

.PHONY: gcp-info-vms
gcp-info-vms: ## Show VM information
	$(GCLOUD) compute instances list --project=$(GCP_PROJECT_ID)
