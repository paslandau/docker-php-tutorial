##@ [Deployment]

.PHONY: deploy
deploy: # Build all images and deploy them to GCP
	@printf "$(GREEN)Switching to 'local' environment$(NO_COLOR)\n"
	@make --no-print-directory make-init
	@printf "$(GREEN)Starting docker setup locally$(NO_COLOR)\n"
	@make --no-print-directory docker-up
	@printf "$(GREEN)Verifying that there are no changes in the secrets$(NO_COLOR)\n"
	@make --no-print-directory gpg-init
	@make --no-print-directory deployment-guard-secret-changes
	@printf "$(GREEN)Verifying that there are no uncommitted changes in the codebase$(NO_COLOR)\n"
	@make --no-print-directory deployment-guard-uncommitted-changes
	@printf "$(GREEN)Initializing gcloud deployment service account$(NO_COLOR)\n"
	@make --no-print-directory gcp-init-deployment-account
	@printf "$(GREEN)Switching to 'prod' environment$(NO_COLOR)\n"
	@make --no-print-directory make-init ENVS="ENV=prod TAG=latest"
	@printf "$(GREEN)Creating build information file$(NO_COLOR)\n"
	@make --no-print-directory deployment-create-build-info-file
	@printf "$(GREEN)Building docker images$(NO_COLOR)\n"
	@make --no-print-directory docker-build
	@printf "$(GREEN)Pushing images to the registry$(NO_COLOR)\n"
	@make --no-print-directory docker-push
	@printf "$(GREEN)Creating the deployment archive$(NO_COLOR)\n"
	@make deployment-create-tar
	@printf "$(GREEN)Copying the deployment archive to the VM and run the deployment$(NO_COLOR)\n"
	@make --no-print-directory deployment-run-on-vm
	@printf "$(GREEN)Clearing deployment archive$(NO_COLOR)\n"
	@make --no-print-directory deployment-clear-tar
	@printf "$(GREEN)Switching to 'local' environment$(NO_COLOR)\n"
	@make --no-print-directory make-init

# directory on the VM that will contain the files to start the docker setup
CODEBASE_DIRECTORY=/tmp/codebase

IGNORE_SECRET_CHANGES?=

.PHONY: deployment-guard-secret-changes
deployment-guard-secret-changes: ## Check if there are any changes between the decrypted and encrypted secret files
	@if ( ! make secret-diff || [ "$$(make secret-diff | grep ^@@)" != "" ] ) && [ "$(IGNORE_SECRET_CHANGES)" == "" ] ; then \
        printf "Found changes in the secret files => $(RED)ABORTING$(NO_COLOR)\n\n"; \
        printf "Use with IGNORE_SECRET_CHANGES=true to ignore this warning\n\n"; \
        make secret-diff; \
        exit 1; \
    fi
	@echo "No changes in the secret files!"

IGNORE_UNCOMMITTED_CHANGES?=

.PHONY: deployment-guard-uncommitted-changes
deployment-guard-uncommitted-changes: ## Check if there are any git changes and abort if so. The check can be ignore by passing `IGNORE_UNCOMMITTED_CHANGES=true`
	@if [ "$$(git status -s)" != "" ] && [ "$(IGNORE_UNCOMMITTED_CHANGES)" == "" ] ; then \
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
deployment-create-build-info-file: ## Create a file containing version information about the codebase
	@echo "BUILD INFO" > ".build/build-info"
	@echo "==========" >> ".build/build-info"
	@echo "User  :" $$(whoami) >> ".build/build-info"
	@echo "Date  :" $$(date --rfc-3339=seconds) >> ".build/build-info"
	@echo "Branch:" $$(git branch --show-current) >> ".build/build-info"
	@echo "" >> ".build/build-info"
	@echo "Commit" >> ".build/build-info"
	@echo "------" >> ".build/build-info"
	@git log -1 --no-color >> ".build/build-info"

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
	mkdir -p .build/deployment/.docker/docker-compose/
	cp -r .docker/docker-compose/ .build/deployment/.docker/
	cp -r .make .build/deployment/
	cp Makefile .build/deployment/
	cp .infrastructure/scripts/deploy.sh .build/deployment/
	# make sure we don't have any .env files in the build directory (don't wanna leak any secrets) ...
	find .build/deployment -name '.env' -delete
	# ... apart from the .env file we need to start docker
	cp .secrets/prod/docker.env .build/deployment/.docker/.env
	# create the archive
	tar -czvf .build/deployment.tar.gz -C .build/deployment/ ./

.PHONY: deployment-clear-tar
deployment-clear-tar:
	# clear the build directory
	rm -rf .build/deployment
	# remove the archive
	rm -rf .build/deployment.tar.gz

.PHONY: deployment-run-on-vm
deployment-run-on-vm:## Run the deployment script on the VM
	"$(MAKE)" -s gcp-scp-command SOURCE=".build/deployment.tar.gz" DESTINATION="deployment.tar.gz"
	"$(MAKE)" -s gcp-ssh-command COMMAND="sudo rm -rf $(CODEBASE_DIRECTORY) && sudo mkdir -p $(CODEBASE_DIRECTORY) && sudo tar -xzvf deployment.tar.gz -C $(CODEBASE_DIRECTORY) && cd $(CODEBASE_DIRECTORY) && sudo bash deploy.sh"

.PHONY: deployment-setup-db-on-vm
deployment-setup-db-on-vm: ## Setup the application on the VM. CAUTION: The docker setup must be running!
	"$(MAKE)" -s gcp-docker-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="make setup-db"
