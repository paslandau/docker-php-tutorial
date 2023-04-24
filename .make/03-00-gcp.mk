##@ [GCP]

.PHONY: gcp-init
gcp-init: validate-gcp-variables ## Initialize the `gcloud` cli and authenticate docker with the keyfile defined via SERVICE_ACCOUNT_KEY_FILE.
	@$(if $(SERVICE_ACCOUNT_KEY_FILE),,$(error "SERVICE_ACCOUNT_KEY_FILE is undefined"))
	gcloud auth activate-service-account --key-file="$(SERVICE_ACCOUNT_KEY_FILE)" --project="$(GCP_PROJECT_ID)"

.PHONY: gcp-init-deployment-account
gcp-init-deployment-account: validate-gcp-variables ## Initialize the `gcloud` cli with the deployment service account 
	@$(if $(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE),,$(error "GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE is undefined"))
	"$(MAKE)" gcp-init SERVICE_ACCOUNT_KEY_FILE=$(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE)
	cat "$(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE)" | docker login -u _json_key --password-stdin https://gcr.io

.PHONY: gcp-init-master-account
gcp-init-master-account: validate-gcp-variables ## Initialize the `gcloud` cli with the master service account 
	@$(if $(GCP_MASTER_SERVICE_ACCOUNT_KEY_FILE),,$(error "GCP_MASTER_SERVICE_ACCOUNT_KEY_FILE is undefined"))
	"$(MAKE)" gcp-init SERVICE_ACCOUNT_KEY_FILE=$(GCP_MASTER_SERVICE_ACCOUNT_KEY_FILE)

.PHONY: validate-gcp-variables
validate-gcp-variables:
	@$(if $(GCP_PROJECT_ID),,$(error "GCP_PROJECT_ID is undefined"))
	@$(if $(GCP_ZONE),,$(error "GCP_ZONE is undefined"))

# @see https://cloud.google.com/sdk/gcloud/reference/compute/ssh
.PHONY: gcp-ssh-command
gcp-ssh-command: validate-gcp-variables ## Run an arbitrary SSH command on the VM via IAP tunnel. Usage: `make gcp-ssh-command COMMAND="whoami"`
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	@$(if $(COMMAND),,$(error "COMMAND is undefined"))
	gcloud compute ssh $(VM_NAME) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap --command="$(COMMAND)"

.PHONY: gcp-ssh-login
gcp-ssh-login: validate-gcp-variables ## Log into a VM via IAP tunnel
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	gcloud compute ssh $(VM_NAME) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap

# @see https://cloud.google.com/sdk/gcloud/reference/compute/scp
.PHONY: gcp-scp-command
gcp-scp-command: validate-gcp-variables ## Copy a file via scp to the VM via IAP tunnel. Usage: `make gcp-scp-command SOURCE="foo" DESTINATION="bar"`
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	@$(if $(SOURCE),,$(error "SOURCE is undefined"))
	@$(if $(DESTINATION),,$(error "DESTINATION is undefined"))
	gcloud compute scp $(SOURCE) $(VM_NAME):$(DESTINATION) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap

# Defines the default secret version to retrieve from the Secret Manager
SECRET_VERSION?=latest

# @see https://cloud.google.com/sdk/gcloud/reference/secrets/versions/access
.PHONY: gcp-secret-get
gcp-secret-get: ## Retrieve and print the secret $(SECRET_NAME) in version $(SECRET_VERSION) from the Secret Manager
	@$(if $(SECRET_NAME),,$(error "SECRET_NAME is undefined"))
	@$(if $(SECRET_VERSION),,$(error "SECRET_VERSION is undefined"))
	@gcloud secrets versions access $(SECRET_VERSION) --secret=$(SECRET_NAME)

.PHONY: gcp-docker-exec
gcp-docker-exec: ## Run a command in a docker container vid compose on the VM. Usage: `make gcp-docker-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="echo 'Hello world!'"`
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DOCKER_COMMAND),,$(error "DOCKER_COMMAND is undefined"))
	"$(MAKE)" -s gcp-ssh-command COMMAND="cd $(CODEBASE_DIRECTORY) && sudo make docker-exec DOCKER_SERVICE_NAME='$(DOCKER_SERVICE_NAME)' DOCKER_COMMAND='$(DOCKER_COMMAND)'"

# see https://cloud.google.com/memorystore/docs/redis/auth-overview#auth_behavior
# see https://cloud.google.com/memorystore/docs/redis/managing-auth#getting_the_auth_string
.PHONY: gcp-get-redis-auth
gcp-get-redis-auth: ## Get the AUTH string of the Redis service
	gcloud redis instances get-auth-string $(VM_NAME_REDIS) --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION)

.PHONY: gcp-info-redis
gcp-info-redis: ## Show redis information
	gcloud redis instances list --project=$(GCP_PROJECT_ID) --region=$(GCP_REGION)

.PHONY: gcp-info-mysql
gcp-info-mysql: ## Show mysql information
	gcloud sql instances list --project=$(GCP_PROJECT_ID)

.PHONY: gcp-info-vms
gcp-info-vms: ## Show VM information
	gcloud compute instances list --project=$(GCP_PROJECT_ID)
