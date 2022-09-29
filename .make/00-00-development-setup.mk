##@ [Development: Setup]

.PHONY: dev-init
dev-init: ## Run this command once after cloning the repo to initialize everything (make, docker, gpg, ...)
	@printf	"$(GREEN)Initializing 'make'$(NO_COLOR)\n"
	"$(MAKE)" -s make-init
	@printf	"$(GREEN)Verifying local tools$(NO_COLOR)\n"
	"$(MAKE)" -s dev-verify-tools
	@printf	"$(GREEN)Verifying 'docker compose' version$(NO_COLOR)\n"
	"$(MAKE)" -s dev-verify-compose-version
	@printf	"$(GREEN)Initializing user id$(NO_COLOR)\n"
	"$(MAKE)" -s dev-init-user-id
	@printf	"$(GREEN)Copying the secret gpg key of the tutorial to './secret.gpg'$(NO_COLOR)\n"
	cp .tutorial/secret.gpg.example ./secret.gpg
	@printf	"$(GREEN)Intializing 'docker'$(NO_COLOR)\n"
	"$(MAKE)" -s docker-init
	@printf	"$(GREEN)Copying the example .env file to './.env'$(NO_COLOR)\n"
	cp ./.env.example ./.env
	@printf	"$(GREEN)DONE$(NO_COLOR)\n"
	@echo "" 
	@printf	"$(GREEN)Next steps:$(NO_COLOR)\n"
	@echo " - run 'make docker-build'    to build the docker setup" 
	@echo " - run 'make docker-up'       to start the docker setup" 
	@echo " - run 'make setup'           to set up the application (e.g. composer dependencies, app key and database)"
	@echo " - run 'make gpg-init'        to initialize gpg in the running containers"
	@echo " - run 'make secret-decrypt'  to decrypt the secrets"
	@echo "" 
	@printf	"==> You should now be able to open http://127.0.0.1/ and see the UI\n"
	@echo "" 
	@echo " - run 'bash test.sh' to test the docker setup (see https://www.pascallandau.com/blog/docker-from-scratch-for-php-applications-in-2022/#php-poc)" 
	@echo " - run 'make test'    to run the application test suite" 
	@echo " - run 'make qa'      to run the application QA tools" 
	@echo "" 

.PHONY: dev-init-user-id
dev-init-user-id: ## Set the correct user id for linux users to avoid permission issues, see https://www.pascallandau.com/blog/docker-from-scratch-for-php-applications-in-2022/#solving-permission-issues
	@if [ "$(OS)" = "Linux" ]; then \
		printf "APP_USER_ID=%s\n" $$(id -u) > .make/.env; \
	  	printf "APP_GROUP_ID=%s\n" $$(id -g) >> .make/.env; \
  	else \
  	  	printf "$(YELLOW)Nothing to do (not a Linux system)$(NO_COLOR)\n"; \
  	fi;

.PHONY: dev-verify-compose-version
dev-verify-compose-version: ## Verify, that docker uses compose version >= v2.5
	@compose_version=$$(docker compose version | cut  -c 25-); \
	result=`.make/scripts/compare_version.sh "$$compose_version" "<" "2.5"`; \
	if [ "$$result" = "0" ]; then \
 	  	printf "$(RED)Your version of docker compose is $$compose_version. It has to be >= 2.5 => Please update compose$(NO_COLOR)\n"; \
 	  	exit 1; \
 	else \
 	  	printf "$(YELLOW)Your version of docker compose is $$compose_version (>= 2.5) => All good.$(NO_COLOR)\n"; \
 	fi;

# see https://stackoverflow.com/a/677212/413531
.PHONY: dev-verify-tools
dev-verify-tools: ## Verify, that the necessary tools exist locally
	@tools="docker bash"; \
	for tool in $$tools; do \
		command -v $$tool >/dev/null 2>&1 || { printf "$(RED)Command '$$tool' not found$(NO_COLOR)\n"; exit 1; } \
	done;
	@printf "$(YELLOW)All tools exist$(NO_COLOR)\n"; \

