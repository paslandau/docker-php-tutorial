##@ [Infrastructure]

.PHONY: infrastructure-setup-vm
infrastructure-setup-vm: ## Set the GCP VM up
	bash .infrastructure/setup-gcp.sh	
