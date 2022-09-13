# Enable buildkit for docker and docker-compose by default for every environment.
# For specific environments (e.g. MacBook with Apple Silicon M1 CPU) it should be turned off to work stable
# - this can be done in the .make/.env file
COMPOSE_DOCKER_CLI_BUILD?=1
DOCKER_BUILDKIT?=1

export COMPOSE_DOCKER_CLI_BUILD
export DOCKER_BUILDKIT

# Container names
## must match the names used in the docker-composer.yml files
DOCKER_SERVICE_NAME_NGINX:=nginx
DOCKER_SERVICE_NAME_PHP_BASE:=php-base
DOCKER_SERVICE_NAME_PHP_FPM:=php-fpm
DOCKER_SERVICE_NAME_PHP_WORKER:=php-worker
DOCKER_SERVICE_NAME_APPLICATION:=application

# FYI:
# Naming convention for images is $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_SERVICE_NAME)-$(ENV)
# e.g.               docker.io/dofroscra/nginx-local
# $(DOCKER_REGISTRY)---^          ^       ^      ^        docker.io
# $(DOCKER_NAMESPACE)-------------^       ^      ^        dofroscra
# $(DOCKER_SERVICE_NAME)------------------^      ^        nginx
# $(ENV)-----------------------------------------^        local

DOCKER_DIR:=./.docker
DOCKER_ENV_FILE:=$(DOCKER_DIR)/.env
DOCKER_COMPOSE_DIR:=$(DOCKER_DIR)/docker-compose
DOCKER_COMPOSE_FILE_LOCAL_CI_PROD:=$(DOCKER_COMPOSE_DIR)/docker-compose.local.ci.prod.yml
DOCKER_COMPOSE_FILE_LOCAL_PROD:=$(DOCKER_COMPOSE_DIR)/docker-compose.local.prod.yml
DOCKER_COMPOSE_FILE_LOCAL:=$(DOCKER_COMPOSE_DIR)/docker-compose.local.yml
DOCKER_COMPOSE_FILE_CI:=$(DOCKER_COMPOSE_DIR)/docker-compose.ci.yml
DOCKER_COMPOSE_FILE_PROD:=$(DOCKER_COMPOSE_DIR)/docker-compose.prod.yml
DOCKER_COMPOSE_FILE_PHP_BASE:=$(DOCKER_COMPOSE_DIR)/docker-compose-php-base.yml
DOCKER_COMPOSE_PROJECT_NAME:=dofroscra_$(ENV)

# we need to "assemble" the correct combination of docker-compose.yml config files
DOCKER_COMPOSE_FILES=
ifeq ($(ENV),prod)
	DOCKER_COMPOSE_FILES:=-f $(DOCKER_COMPOSE_FILE_LOCAL_CI_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL_PROD) -f $(DOCKER_COMPOSE_FILE_PROD)
else ifeq ($(ENV),ci)
	DOCKER_COMPOSE_FILES:=-f $(DOCKER_COMPOSE_FILE_LOCAL_CI_PROD) -f $(DOCKER_COMPOSE_FILE_CI)
else ifeq ($(ENV),local)
	DOCKER_COMPOSE_FILES:=-f $(DOCKER_COMPOSE_FILE_LOCAL_CI_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL)
endif

# we need a couple of environment variables for docker-compose so we define a make-variable that we can
# then reference later in the Makefile without having to repeat all the environment variables
DOCKER_COMPOSE_COMMAND:= \
 ENV=$(ENV) \
 TAG=$(TAG) \
 DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
 DOCKER_NAMESPACE=$(DOCKER_NAMESPACE) \
 APP_USER_ID=$(APP_USER_ID) \
 APP_GROUP_ID=$(APP_GROUP_ID) \
 APP_USER_NAME=$(APP_USER_NAME) \
 docker compose -p $(DOCKER_COMPOSE_PROJECT_NAME) --env-file $(DOCKER_ENV_FILE)

DOCKER_COMPOSE:=$(DOCKER_COMPOSE_COMMAND) $(DOCKER_COMPOSE_FILES)
DOCKER_COMPOSE_PHP_BASE:=$(DOCKER_COMPOSE_COMMAND) -f $(DOCKER_COMPOSE_FILE_PHP_BASE)

EXECUTE_IN_ANY_CONTAINER?=
EXECUTE_IN_WORKER_CONTAINER?=
EXECUTE_IN_APPLICATION_CONTAINER?=

DOCKER_SERVICE_NAME?=

# we can pass EXECUTE_IN_CONTAINER=true to a make invocation in order to execute the target in a docker container.
# Caution: this only works if the command in the target is prefixed with a $(EXECUTE_IN_*_CONTAINER) variable.
# If EXECUTE_IN_CONTAINER is NOT defined, we will check if make is ALREADY executed in a docker container.
# We still need a way to FORCE the execution in a container, e.g. for Gitlab CI, because the Gitlab
# Runner is executed as a docker container BUT we want to execute commands in OUR OWN docker containers!
EXECUTE_IN_CONTAINER?=
ifndef EXECUTE_IN_CONTAINER
	# check if 'make' is executed in a docker container, see https://stackoverflow.com/a/25518538/413531
	# `wildcard $file` checks if $file exists, see https://www.gnu.org/software/make/manual/html_node/Wildcard-Function.html
	# i.e. if the result is "empty" then $file does NOT exist => we are NOT in a container
	ifeq ("$(wildcard /.dockerenv)","")
		EXECUTE_IN_CONTAINER=true
	endif
endif
ifeq ($(EXECUTE_IN_CONTAINER),true)
	EXECUTE_IN_ANY_CONTAINER:=$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_EXEC_OPTIONS) --user $(APP_USER_NAME) $(DOCKER_SERVICE_NAME)
	EXECUTE_IN_APPLICATION_CONTAINER:=$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_EXEC_OPTIONS) --user $(APP_USER_NAME) $(DOCKER_SERVICE_NAME_APPLICATION)
	EXECUTE_IN_WORKER_CONTAINER:=$(DOCKER_COMPOSE) exec $(DOCKER_COMPOSE_EXEC_OPTIONS) --user $(APP_USER_NAME) $(DOCKER_SERVICE_NAME_PHP_WORKER)
endif


##@ [Docker]

.PHONY: docker-init
docker-init: ## Initialize the .env file for docker compose
	@cp $(DOCKER_ENV_FILE).example $(DOCKER_ENV_FILE)

.PHONY: docker-clean
docker-clean: ## Remove the .env file for docker
	@rm -f $(DOCKER_ENV_FILE)

.PHONY: validate-docker-variables
validate-docker-variables: .docker/.env compose-secrets.env
	@$(if $(TAG),,$(error TAG is undefined))
	@$(if $(ENV),,$(error ENV is undefined))
	@$(if $(DOCKER_REGISTRY),,$(error DOCKER_REGISTRY is undefined - Did you run make-init?))
	@$(if $(DOCKER_NAMESPACE),,$(error DOCKER_NAMESPACE is undefined - Did you run make-init?))
	@$(if $(APP_USER_ID),,$(error APP_USER_ID is undefined - Did you run make-init?))
	@$(if $(APP_GROUP_ID),,$(error APP_GROUP_ID is undefined - Did you run make-init?))
	@$(if $(APP_USER_NAME),,$(error APP_USER_NAME is undefined - Did you run make-init?))

.docker/.env:
	@cp $(DOCKER_ENV_FILE).example $(DOCKER_ENV_FILE)

compose-secrets.env:
	@echo "# This file only exists because docker compose cannot run 'build' otherwise," > ./compose-secrets.env
	@echo "# as it is referenced as an 'env_file' in the docker compose config file" >> ./compose-secrets.env
	@echo "# for the 'prod' environment. On 'prod' it will contain the necessary ENV variables," >> ./compose-secrets.env
	@echo "# but on all other environments this 'placeholder' file is created." >> ./compose-secrets.env
	@echo "# The file is generated automatically via 'make' if a docker compose target is executed" >> ./compose-secrets.env
	@echo "# @see https://github.com/docker/compose/issues/1973#issuecomment-1148257736" >> ./compose-secrets.env

.PHONY:docker-build-image
docker-build-image: validate-docker-variables ## Build all docker images OR a specific image by providing the service name via: make docker-build DOCKER_SERVICE_NAME=<service>
	$(DOCKER_COMPOSE) build $(DOCKER_SERVICE_NAME) $(ARGS)

.PHONY: docker-build-php
docker-build-php: validate-docker-variables ## Build the php base image
	$(DOCKER_COMPOSE_PHP_BASE) build $(DOCKER_SERVICE_NAME_PHP_BASE) $(ARGS)

.PHONY: docker-build
docker-build: docker-build-php docker-build-image ## Build the php image and then all other docker images

.PHONY: docker-up
docker-up: validate-docker-variables ## Create and start all docker containers. To create/start only a specific container, use DOCKER_SERVICE_NAME=<service>
	$(DOCKER_COMPOSE) up -d $(DOCKER_SERVICE_NAME)

.PHONY: docker-down
docker-down: validate-docker-variables ## Stop and remove all docker containers.
	@$(DOCKER_COMPOSE) down

.PHONY: docker-config
docker-config: validate-docker-variables ## List the configuration
	@$(DOCKER_COMPOSE) config

.PHONY: docker-push
docker-push: validate-docker-variables ## Push all docker images to the remote repository
	$(DOCKER_COMPOSE) push $(ARGS)

.PHONY: docker-pull
docker-pull: validate-docker-variables ## Pull all docker images from the remote repository
	$(DOCKER_COMPOSE) pull $(ARGS)

.PHONY: docker-exec
docker-exec: validate-docker-variables ## Execute a command in a docker container. Usage: `make docker-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="echo 'Hello world!'"`
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DOCKER_COMMAND),,$(error "DOCKER_COMMAND is undefined"))
	$(DOCKER_COMPOSE) exec -T $(DOCKER_SERVICE_NAME) $(DOCKER_COMMAND)

.PHONY: docker-prune
docker-prune: ## Remove ALL unused docker resources, including volumes
	@docker system prune -a -f --volumes

# @see https://www.linuxfixes.com/2022/01/solved-how-to-test-dockerignore-file.html
# helpful to debug a .dockerignore file
.PHONY: docker-show-build-context
docker-show-build-context: ## Show all files that are in the docker build context for `docker build`
	@echo -e "FROM busybox\nCOPY . /codebase\nCMD find /codebase -print" | docker image build --no-cache -t build-context -f - .
	@docker run --rm build-context | sort

# `docker build` and `docker compose build` are behaving differently
# @see https://github.com/docker/compose/issues/9508
.PHONY: docker-show-compose-build-context
docker-show-compose-build-context: ## Show all files that are in the docker build context for `docker compose build`
	@.dev/scripts/docker-compose-build-context/show-build-context.sh

# Note: This is only a temporary target until https://github.com/docker/for-win/issues/12742 is fixed
.PHONY: docker-fix-mount-permissions
docker-fix-mount-permissions: ## Fix the permissions of the bind-mounted folder, @see https://github.com/docker/for-win/issues/12742
	$(EXECUTE_IN_APPLICATION_CONTAINER) ls -al
