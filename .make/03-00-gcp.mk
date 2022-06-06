##@ [GCP]

.PHONY: gcp-init
gcp-init: validate-gcp-variables ## Initialize the `gcloud` cli and authenticate docker with the keyfile defined via GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY.
	@$(if $(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY),,$(error "GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY is undefined"))
	@$(if $(GCP_PROJECT_ID),,$(error "GCP_PROJECT_ID is undefined"))
	gcloud auth activate-service-account --key-file="$(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY)" --project="$(GCP_PROJECT_ID)"
	cat "$(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY)" | docker login -u _json_key --password-stdin https://gcr.io

.PHONY: validate-gcp-variables
validate-gcp-variables:
	@$(if $(GCP_PROJECT_ID),,$(error "GCP_PROJECT_ID is undefined"))
	@$(if $(GCP_ZONE),,$(error "GCP_ZONE is undefined"))
	@$(if $(GCP_VM_NAME),,$(error "GCP_VM_NAME is undefined"))

# @see https://cloud.google.com/sdk/gcloud/reference/compute/ssh
.PHONY: gcp-ssh-command
gcp-ssh-command: validate-gcp-variables ## Run an arbitrary SSH command on the VM via IAP tunnel. Usage: `make gcp-ssh-command COMMAND="whoami"`
	@$(if $(COMMAND),,$(error "COMMAND is undefined"))
	gcloud compute ssh $(GCP_VM_NAME) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap --command="$(COMMAND)"

.PHONY: gcp-ssh-login
gcp-ssh-login: validate-gcp-variables ## Log into a VM via IAP tunnel
	gcloud compute ssh $(GCP_VM_NAME) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap

# @see https://cloud.google.com/sdk/gcloud/reference/compute/scp
.PHONY: gcp-scp-command
gcp-scp-command: validate-gcp-variables ## Copy a file via scp to the VM via IAP tunnel. Usage: `make gcp-scp-command SOURCE="foo" DESTINATION="bar"`
	@$(if $(SOURCE),,$(error "SOURCE is undefined"))
	@$(if $(DESTINATION),,$(error "DESTINATION is undefined"))
	gcloud compute scp $(SOURCE) $(GCP_VM_NAME):$(DESTINATION) --project $(GCP_PROJECT_ID) --zone $(GCP_ZONE) --tunnel-through-iap

# Defines the default secret version to retrieve from the Secret Manager
SECRET_VERSION?=latest

# @see https://cloud.google.com/sdk/gcloud/reference/secrets/versions/access
.PHONY: gcp-secret-get
gcp-secret-get: ## Retrieve and print the secret $(SECRET_NAME) in version $(SECRET_VERSION) from the Secret Manager
	@$(if $(SECRET_NAME),,$(error "SECRET_NAME is undefined"))
	@$(if $(SECRET_VERSION),,$(error "SECRET_VERSION is undefined"))
	@gcloud secrets versions access $(SECRET_VERSION) --secret=$(SECRET_NAME)

.PHONY: gcp-docker-exec
gcp-docker-exec: ## Run a command in a docker container on the VM. Usage: `make gcp-docker-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="echo 'Hello world!'"`
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DOCKER_COMMAND),,$(error "DOCKER_COMMAND is undefined"))
	"$(MAKE)" -s gcp-ssh-command COMMAND="cd $(CODEBASE_DIRECTORY) && sudo make docker-exec DOCKER_SERVICE_NAME='$(DOCKER_SERVICE_NAME)' DOCKER_COMMAND='$(DOCKER_COMMAND)'"

# @see https://cloud.google.com/compute/docs/instances/view-ip-address
.PHONY: gcp-show-ip
gcp-show-ip: ## Show the IP address of the VM specified by GCP_VM_NAME.
	gcloud compute instances describe $(GCP_VM_NAME) --zone $(GCP_ZONE) --project=$(GCP_PROJECT_ID) --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

