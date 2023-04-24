##@ [Infrastructure]

# Setup

.PHONY: infrastructure-setup
infrastructure-setup: ## Set the whole infrastructure up
	"$(MAKE)" infrastructure-setup-gcp
	"$(MAKE)" infrastructure-setup-all-vms
	"$(MAKE)" infrastructure-provision-all

.PHONY: infrastructure-setup-gcp
infrastructure-setup-gcp: ## Set the GCP project up
	bash .infrastructure/setup-gcp.sh $(GCP_PROJECT_ID) $(ARGS)

.PHONY: infrastructure-setup-mysql
infrastructure-setup-mysql: ## Set the mysql instance up. The ROOT_PASSWORD variable is required to defined the password for the root user
	@$(if $(ROOT_PASSWORD),,$(error "ROOT_PASSWORD is undefined"))
	bash .infrastructure/setup-mysql.sh $(GCP_PROJECT_ID) $(VM_NAME_MYSQL) $(ROOT_PASSWORD) $(ARGS)

.PHONY: infrastructure-setup-redis
infrastructure-setup-redis: ## Set the redis instance up
	bash .infrastructure/setup-redis.sh $(GCP_PROJECT_ID) $(VM_NAME_REDIS) $(ARGS)

.PHONY: infrastructure-setup-vm
infrastructure-setup-vm: ## Setup the VM specified via VM_NAME. Usage: make infrastructure-setup-vm VM_NAME=php-worker ARGS=""
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	bash .infrastructure/setup-vm.sh $(GCP_PROJECT_ID) $(VM_NAME) $(ARGS)

.PHONY: infrastructure-setup-all-vms
infrastructure-setup-all-vms: ## Setup all VMs
	@printf "$(YELLOW)The setup runs in parallel but the output will only be visible once a process is fully finished (can take a couple of minutes)$(NO_COLOR)\n"
	"$(MAKE)" -j --output-sync=target 	infrastructure-setup-vm-application \
										infrastructure-setup-vm-php-fpm \
										infrastructure-setup-vm-php-worker \
										infrastructure-setup-vm-nginx \
										infrastructure-setup-redis \
										infrastructure-setup-mysql

.PHONY: infrastructure-setup-vm-application
infrastructure-setup-vm-application:
	"$(MAKE)" --no-print-directory infrastructure-setup-vm VM_NAME=$(VM_NAME_APPLICATION)

.PHONY: infrastructure-setup-vm-php-fpm
infrastructure-setup-vm-php-fpm:
	"$(MAKE)" --no-print-directory infrastructure-setup-vm VM_NAME=$(VM_NAME_PHP_FPM)

.PHONY: infrastructure-setup-vm-php-worker
infrastructure-setup-vm-php-worker:
	"$(MAKE)" --no-print-directory infrastructure-setup-vm VM_NAME=$(VM_NAME_PHP_WORKER)

.PHONY: infrastructure-setup-vm-nginx
infrastructure-setup-vm-nginx:
	"$(MAKE)" --no-print-directory infrastructure-setup-vm VM_NAME=$(VM_NAME_NGINX) ARGS="enable_public_access"

# Provisioninig

.PHONY: infrastructure-provision-vm
infrastructure-provision-vm: ## Provision the VM specified via VM_NAME. Usage: make infrastructure-provision-vm VM_NAME=php-worker ARGS=""
	@$(if $(VM_NAME),,$(error "VM_NAME is undefined"))
	bash .infrastructure/provision-vm.sh $(GCP_PROJECT_ID) $(VM_NAME) $(ARGS) \
		&& printf "$(GREEN)Success at provisioning $(VM_NAME)$(NO_COLOR)\n" \
		|| printf "$(RED)Failed provisioning $(VM_NAME)$(NO_COLOR)\n"

.PHONY: infrastructure-provision-all
infrastructure-provision-all: ## Provision all VMs
	@printf "$(YELLOW)The provisioning runs in parallel but the output will only be visible once a process is fully finished (can take a couple of minutes)$(NO_COLOR)\n"
	"$(MAKE)" -j --output-sync=target 	infrastructure-provision-vm-application \
										infrastructure-provision-vm-php-fpm \
										infrastructure-provision-vm-php-worker \
										infrastructure-provision-vm-nginx

.PHONY: infrastructure-provision-vm-application
infrastructure-provision-vm-application:
	"$(MAKE)" --no-print-directory infrastructure-provision-vm VM_NAME=$(VM_NAME_APPLICATION)

.PHONY: infrastructure-provision-vm-php-fpm
infrastructure-provision-vm-php-fpm:
	"$(MAKE)" --no-print-directory infrastructure-provision-vm VM_NAME=$(VM_NAME_PHP_FPM)

.PHONY: infrastructure-provision-vm-php-worker
infrastructure-provision-vm-php-worker:
	"$(MAKE)" --no-print-directory infrastructure-provision-vm VM_NAME=$(VM_NAME_PHP_WORKER)

.PHONY: infrastructure-provision-vm-nginx
infrastructure-provision-vm-nginx:
	"$(MAKE)" --no-print-directory infrastructure-provision-vm VM_NAME=$(VM_NAME_NGINX)

# Misc

.PHONY: infrastructure-info
infrastructure-info: ## Print information about the infrastructure	
	@"$(MAKE)" -s --no-print-directory gcp-info-vms
	@echo ""
	@"$(MAKE)" -s --no-print-directory gcp-info-redis
	@echo ""
	@"$(MAKE)" -s --no-print-directory gcp-info-mysql

## TODO Problem: Output is not synchronized
## Uses "&" to start job in the background for parallelization
## @see 
#.PHONY: test1
#test1: ## Provision all VMs
#	@for vm_name in $(ALL_VM_SERVICE_NAMES); do \
#  		asd=$$(make infrastructure-provision-vm VM_NAME="$$vm_name") & \
#	done; \
#	wait; \
#	echo "ALL DONE"
