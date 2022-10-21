##@ [Deployment]

# Note:
# We separate the deployment process in multiple steps so that we can run
# them with the `-k` (--keep-going) flag to ensure that the cleanup step 
# is guaranteed to be executed
.PHONY: deploy
deploy: ## Build all images and deploy them to GCP. Usage: make deploy DEPLOYMENT_TAG=v1.1.0 IGNORE_SECRET_CHANGES=false IGNORE_UNCOMMITTED_CHANGES=false
	@$(if $(DEPLOYMENT_TAG),,$(error "DEPLOYMENT_TAG is undefined"))
	@"$(MAKE)" deploy-prepare
	@"$(MAKE)" -k \
		deploy-execute \
		deploy-cleanup


.PHONY: deploy-prepare
deploy-prepare: ## Prepare the deployment process
	@printf "$(GREEN)Cleaning up old 'deployment-settings.env' file$(NO_COLOR)\n"
	@"$(MAKE)" make-remove-deployment-settings
	@printf "$(GREEN)Verifying that there are no changes in the secrets$(NO_COLOR)\n"
	@"$(MAKE)" deployment-guard-secret-changes
	@printf "$(GREEN)Verifying that there are no uncommitted changes in the codebase$(NO_COLOR)\n"
	@"$(MAKE)" deployment-guard-uncommitted-changes

.PHONY: deploy-execute
deploy-execute: ## Excecute the deployment process
	cat asdafa
	@printf "$(GREEN)Initializing gcloud deployment service account$(NO_COLOR)\n"
	@"$(MAKE)" gcp-activate-deployment-account
	@printf "$(GREEN)Authentication docker with the deployment service account$(NO_COLOR)\n"
	@"$(MAKE)" gcp-authenticate-docker SERVICE_ACCOUNT_KEY_FILE=$(GCP_DEPLOYMENT_SERVICE_ACCOUNT_KEY_FILE)
	@printf "$(GREEN)Switching to 'prod' environment ('deployment-settings.env' file)$(NO_COLOR)\n"
	@"$(MAKE)" make-init-deployment-settings ENVS="ENV=prod TAG=$(DEPLOYMENT_TAG)"
	@printf "$(GREEN)Creating build information file$(NO_COLOR)\n"
	@"$(MAKE)" deployment-create-build-info-file
	@printf "$(GREEN)Building docker images$(NO_COLOR)\n"
	@"$(MAKE)" docker-compose-build
	@printf "$(GREEN)Pushing images to the registry$(NO_COLOR)\n"
	@"$(MAKE)" docker-compose-push
	@printf "$(GREEN)Creating the service-ips file$(NO_COLOR)\n"
	@"$(MAKE)" deployment-create-service-ip-file
	@printf "$(GREEN)Creating the deployment archive$(NO_COLOR)\n"
	@"$(MAKE)" deployment-create-tar
	@printf "$(GREEN)Copying the deployment archive to the VMs and run the deployment$(NO_COLOR)\n"
	@"$(MAKE)" deployment-run-on-vms

.PHONY: deploy-cleanup
deploy-cleanup: ## Clean up temporary artifacts of the deployment process
	@printf "$(GREEN)Clearing deployment archive$(NO_COLOR)\n"
	@"$(MAKE)" deployment-clear-tar
	@printf "$(GREEN)Removing 'deployment-settings.env' file$(NO_COLOR)\n"
	@"$(MAKE)" make-remove-deployment-settings

# directory on the VM that will contain the files to start the docker setup
CODEBASE_DIRECTORY=/tmp/codebase

IGNORE_SECRET_CHANGES?=

.PHONY: deployment-guard-secret-changes
deployment-guard-secret-changes: ## Check if there are any changes between the decrypted and encrypted secret files. The check can be ignore by passing `IGNORE_SECRET_CHANGES=true`
	@if  [ "$(IGNORE_SECRET_CHANGES)" != "true" ] ; then \
  		"$(MAKE)" docker-compose-up; \
  		"$(MAKE)" gpg-init; \
		if ( ! "$(MAKE)" secret-diff || [ "$$("$(MAKE)" secret-diff | grep ^@@)" != "" ] ) ; then \
			printf "Found changes in the secret files => $(RED)ABORTING$(NO_COLOR)\n\n"; \
			printf "Use with IGNORE_SECRET_CHANGES=true to ignore this warning\n\n"; \
			"$(MAKE)" secret-diff; \
			exit 1; \
		fi \
    fi
	@echo "No changes in the secret files!"

IGNORE_UNCOMMITTED_CHANGES?=

.PHONY: deployment-guard-uncommitted-changes
deployment-guard-uncommitted-changes: ## Check if there are any git changes and abort if so. The check can be ignore by passing `IGNORE_UNCOMMITTED_CHANGES=true`
	@if [ "$(IGNORE_UNCOMMITTED_CHANGES)" != "true" ] && [ "$$(git status -s)" != "" ] ; then \
        printf "Found uncommitted changes in git => $(RED)ABORTING$(NO_COLOR)\n\n"; \
        printf "Use with IGNORE_UNCOMMITTED_CHANGES=true to ignore this warning\n\n"; \
        git status -s; \
        exit 1; \
    fi
	@echo "No uncommitted changes found!"

# FYI: make converts all new lines in spaces when they are echo'd 
# @see https://stackoverflow.com/a/54068252/413531
# To execute a shell command via $(command), the $ has to be escaped with another $
#  ==> $$(command)
# @see https://stackoverflow.com/a/26564874/413531
.PHONY: deployment-create-build-info-file
deployment-create-build-info-file: ## Create a file containing version information about the codebase. Usage: make deployment-create-build-info-file DEPLOYMENT_TAG=v1.1.0
	@$(if $(DEPLOYMENT_TAG),,$(error "DEPLOYMENT_TAG is undefined"))
	@echo "BUILD INFO" > ".build/build-info"
	@echo "==========" >> ".build/build-info"
	@echo "User  :" $$(whoami) >> ".build/build-info"
	@echo "Date  :" $$(date --rfc-3339=seconds) >> ".build/build-info"
	@echo "Branch:" $$(git branch --show-current) >> ".build/build-info"
	@echo "Tag   :" $(DEPLOYMENT_TAG) >> ".build/build-info"
	@echo "" >> ".build/build-info"
	@echo "Commit" >> ".build/build-info"
	@echo "------" >> ".build/build-info"
	@git log -1 --no-color >> ".build/build-info"

# The
#  sed -i "s/\r//g"
# part is required, because on windows the resulting file might contain "\r\n" line endings
.PHONY: deployment-create-service-ip-file
deployment-create-service-ip-file: ## Create a file containing the IPs of all services
	@"$(MAKE)" -s gcp-get-ips > ".build/service-ips"
	@$(LINUX_UTILITY_CONTAINER) sed -i "s/\r//g" ".build/service-ips"

# create tar archive
#  tar -czvf archive.tar.gz ./source
#
# extract tar archive
#  tar -xzvf archive.tar.gz -C ./target
#
# @see https://www.cyberciti.biz/faq/how-to-create-tar-gz-file-in-linux-using-command-line/
# @see https://serverfault.com/a/330133
.PHONY: deployment-create-tar
deployment-create-tar:
	# create the build directory
	rm -rf .build/deployment
	mkdir -p .build/deployment
	# copy the necessary files
	cp -r .make .build/deployment/
	find .build/deployment -name '*.env' -delete
	cp .make/variables.env .build/deployment/.make/variables.env
	cp Makefile .build/deployment/
	cp .infrastructure/scripts/deploy.sh .build/deployment/
	# move the ip services file
	mv .build/service-ips .build/deployment/service-ips
	# create the archive
	tar -czvf .build/deployment.tar.gz -C .build/deployment/ ./

.PHONY: deployment-clear-tar
deployment-clear-tar:
	# clear the build directory
	rm -rf .build/deployment
	# remove the archive
	rm -rf .build/deployment.tar.gz

.PHONY: deployment-run-on-vms
deployment-run-on-vms: ## Run the deployment script on all VMs
	"$(MAKE)" -j --output-sync=target	deployment-run-on-vm-application \
 				 						deployment-run-on-vm-php-fpm \
 				 						deployment-run-on-vm-php-worker \
 				 						deployment-run-on-vm-nginx

.PHONY: deployment-run-on-vm
deployment-run-on-vm: ## Run the deployment script on a VM. Usage: make VM_NAME=application-vm DOCKER_SERVICE_NAME=application DEPLOYMENT_TAG=v1.1.0
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DEPLOYMENT_TAG),,$(error "DEPLOYMENT_TAG is undefined"))
	"$(MAKE)" -s gcp-scp-command SOURCE=".build/deployment.tar.gz" DESTINATION="deployment.tar.gz"
	"$(MAKE)" -s gcp-ssh-command COMMAND="sudo rm -rf $(CODEBASE_DIRECTORY) && sudo mkdir -p $(CODEBASE_DIRECTORY) && sudo tar -xzvf deployment.tar.gz -C $(CODEBASE_DIRECTORY) && cd $(CODEBASE_DIRECTORY) && sudo bash deploy.sh $(DOCKER_SERVICE_NAME) $(DEPLOYMENT_TAG)"

.PHONY: deployment-run-on-vm-application
deployment-run-on-vm-application:
	"$(MAKE)" deployment-run-on-vm VM_NAME=$(VM_NAME_APPLICATION) DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME_APPLICATION)

.PHONY: deployment-run-on-vm-php-fpm
deployment-run-on-vm-php-fpm:
	"$(MAKE)" deployment-run-on-vm VM_NAME=$(VM_NAME_PHP_FPM) DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME_PHP_FPM)

.PHONY: deployment-run-on-vm-php-worker 
deployment-run-on-vm-php-worker:
	"$(MAKE)" deployment-run-on-vm VM_NAME=$(VM_NAME_PHP_WORKER) DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME_PHP_WORKER)

.PHONY: deployment-run-on-vm-nginx
deployment-run-on-vm-nginx:
	"$(MAKE)" deployment-run-on-vm VM_NAME=$(VM_NAME_NGINX) DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME_NGINX)

.PHONY: deployment-setup-db-on-vm
deployment-setup-db-on-vm: ## Setup the application on the VM. CAUTION: The docker setup must be running!
	"$(MAKE)" -s gcp-docker-exec VM_NAME="$(VM_NAME_APPLICATION)" DOCKER_SERVICE_NAME="$(DOCKER_SERVICE_NAME_APPLICATION)" DOCKER_COMMAND="php artisan app:setup-db" DOCKER_USERNAME=$(APP_USER_NAME)

.PHONY: deployment-info
deployment-info: ## Print information about the deployed containers	
	@for vm_name_service_name in $(ALL_VM_SERVICE_NAMES); do \
  		vm_name=`echo $$vm_name_service_name | cut -d ":" -f 1`; \
  		service_name=`echo $$vm_name_service_name | cut -d ":" -f 2`; \
  		printf "$(GREEN)$$service_name:$(NO_COLOR)\n"; \
		"$(MAKE)" -s gcp-ssh-command VM_NAME="$$vm_name" COMMAND="sudo docker ps"; \
		if [ "$$service_name" != "$(DOCKER_SERVICE_NAME_NGINX)" ]; then \
			"$(MAKE)" -s gcp-docker-exec VM_NAME="$$vm_name" DOCKER_SERVICE_NAME="$$service_name" DOCKER_COMMAND="cat build-info"; \
		fi; \
  		printf "\n\n"; \
  	done; \
  	public_ip=$$("$(MAKE)" -s gcp-get-public-ip-vm VM_NAME=$(VM_NAME_NGINX)); \
  	echo "Visit the UI at: http://$$public_ip/";
