# Enable buildkit for docker and docker-compose by default for every environment.
# For specific environments (e.g. MacBook with Apple Silicon M1 CPU) it should be turned off to work stable
# - this can be done in the .make/.env file
COMPOSE_DOCKER_CLI_BUILD?=1
DOCKER_BUILDKIT?=1

export COMPOSE_DOCKER_CLI_BUILD
export DOCKER_BUILDKIT

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
DOCKER_COMPOSE_FILE_LOCAL_CI:=$(DOCKER_COMPOSE_DIR)/docker-compose.local.ci.yml
DOCKER_COMPOSE_FILE_LOCAL_PROD:=$(DOCKER_COMPOSE_DIR)/docker-compose.local.prod.yml
DOCKER_COMPOSE_FILE_LOCAL:=$(DOCKER_COMPOSE_DIR)/docker-compose.local.yml
DOCKER_COMPOSE_FILE_CI:=$(DOCKER_COMPOSE_DIR)/docker-compose.ci.yml
DOCKER_COMPOSE_FILE_PHP_BASE:=$(DOCKER_COMPOSE_DIR)/docker-compose-php-base.yml
DOCKER_COMPOSE_PROJECT_NAME:=dofroscra_$(ENV)

# We need to "assemble" the correct combination of docker-compose.yml config files
DOCKER_COMPOSE_FILES:=
ifeq ($(ENV),prod)
	DOCKER_COMPOSE_FILES:=-f $(DOCKER_COMPOSE_FILE_LOCAL_CI_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL_PROD)
else ifeq ($(ENV),ci)
	DOCKER_COMPOSE_FILES:=-f $(DOCKER_COMPOSE_FILE_LOCAL_CI_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL_CI) -f $(DOCKER_COMPOSE_FILE_CI)
else ifeq ($(ENV),local)
	DOCKER_COMPOSE_FILES:=-f $(DOCKER_COMPOSE_FILE_LOCAL_CI_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL_CI) -f $(DOCKER_COMPOSE_FILE_LOCAL_PROD) -f $(DOCKER_COMPOSE_FILE_LOCAL)
endif

# We need a couple of environment variables for docker compose so we define a make variable that we can
# then reference later in the Makefile without having to repeat all the environment variables every time
# @see https://www.pascallandau.com/blog/docker-from-scratch-for-php-applications-in-2022/#make-docker-3
DOCKER_COMPOSE_COMMAND:= \
 ENV=$(ENV) \
 TAG=$(TAG) \
 DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
 DOCKER_NAMESPACE=$(DOCKER_NAMESPACE) \
 APP_USER_ID=$(APP_USER_ID) \
 APP_GROUP_ID=$(APP_GROUP_ID) \
 APP_USER_NAME=$(APP_USER_NAME) \
 APP_CODE_PATH_CONTAINER=$(APP_CODE_PATH_CONTAINER) \
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


##@ [Docker compose]

.PHONY: docker-compose-init
docker-compose-init: ## Initialize the .env file for docker compose
	@cp $(DOCKER_ENV_FILE).example $(DOCKER_ENV_FILE)
	
.PHONY: docker-compose-clean
docker-compose-clean: ## Remove the .env file for docker compose
	@rm -f $(DOCKER_ENV_FILE)

.PHONY: validate-docker-compose-variables
validate-docker-compose-variables: validate-docker-variables
	@$(if $(APP_USER_NAME),,$(error APP_USER_NAME is undefined))
	@$(if $(APP_USER_ID),,$(error APP_USER_ID is undefined))
	@$(if $(APP_GROUP_ID),,$(error APP_GROUP_ID is undefined))

.PHONY: docker-compose-build-image
docker-compose-build-image: validate-docker-compose-variables ## Build all docker images OR a specific image by providing the service name via: make docker-compose-build DOCKER_SERVICE_NAME=<service>
	$(DOCKER_COMPOSE) build $(DOCKER_SERVICE_NAME) $(ARGS)

.PHONY: docker-compose-build-php
docker-compose-build-php: validate-docker-compose-variables ## Build the php base image
	$(DOCKER_COMPOSE_PHP_BASE) build $(DOCKER_SERVICE_NAME_PHP_BASE) $(ARGS)

.PHONY: docker-compose-build
docker-compose-build: docker-compose-build-php docker-compose-build-image ## Build the php image and then all other docker images

.PHONY: docker-compose-up
docker-compose-up: validate-docker-compose-variables ## Create and start all docker containers. To create/start only a specific container, use DOCKER_SERVICE_NAME=<service>
	$(DOCKER_COMPOSE) up -d $(DOCKER_SERVICE_NAME)

.PHONY: docker-compose-down
docker-compose-down: validate-docker-compose-variables ## Stop and remove all docker containers.
	@$(DOCKER_COMPOSE) down

.PHONY: docker-compose-restart
docker-compose-restart: validate-docker-compose-variables ## Restart all docker containers.
	@$(DOCKER_COMPOSE) restart

.PHONY: docker-compose-config
docker-compose-config: validate-docker-compose-variables ## List the configuration
	@$(DOCKER_COMPOSE) config

.PHONY: docker-compose-push
docker-compose-push: validate-docker-compose-variables ## Push all docker images to the remote repository
	$(DOCKER_COMPOSE) push $(ARGS)

.PHONY: docker-compose-pull
docker-compose-pull: validate-docker-compose-variables ## Pull all docker images from the remote repository
	$(DOCKER_COMPOSE) pull $(ARGS)

DOCKER_USERNAME?=root
.PHONY: docker-compose-exec
docker-compose-exec: validate-docker-compose-variables ## Execute a command in a docker container. Usage: `make docker-compose-exec DOCKER_SERVICE_NAME="application" DOCKER_COMMAND="echo 'Hello world!' DOCKER_USERNAME=root"`
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(DOCKER_COMMAND),,$(error "DOCKER_COMMAND is undefined"))
	@$(if $(DOCKER_USERNAME),,$(error "DOCKER_USERNAME is undefined"))
	$(DOCKER_COMPOSE) exec -T --user $(DOCKER_USERNAME) $(DOCKER_SERVICE_NAME) $(DOCKER_COMMAND)

# `docker build` and `docker compose build` are behaving differently
# @see https://github.com/docker/compose/issues/9508
.PHONY: docker-compose-show-build-context
docker-compose-show-build-context: ## Show all files that are in the docker build context for `docker compose build`
	@.dev/scripts/docker-compose-build-context/show-build-context.sh

##@ [Docker]

.PHONY: validate-docker-variables
validate-docker-variables:
	@$(if $(TAG),,$(error TAG is undefined))
	@$(if $(ENV),,$(error ENV is undefined))
	@$(if $(DOCKER_REGISTRY),,$(error DOCKER_REGISTRY is undefined))
	@$(if $(DOCKER_NAMESPACE),,$(error DOCKER_NAMESPACE is undefined))
	@$(if $(APP_CODE_PATH_CONTAINER),,$(error APP_CODE_PATH_CONTAINER is undefined))

.PHONY: docker-prune
docker-prune: ## Remove ALL unused docker resources, including volumes
	@docker system prune -a -f --volumes

# @see https://www.linuxfixes.com/2022/01/solved-how-to-test-dockerignore-file.html
# helpful to debug a .dockerignore file
.PHONY: docker-show-build-context
docker-show-build-context: ## Show all files that are in the docker build context for `docker build`
	@echo -e "FROM busybox\nCOPY . /codebase\nCMD find /codebase -print" | docker image build --no-cache -t build-context -f - .
	@docker run --rm build-context | sort

.PHONY: docker-pull
docker-pull: validate-docker-variables ## Pull a single docker images from the remote repository
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	docker pull $(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_SERVICE_NAME)-$(ENV):$(TAG)

.PHONY: docker-run
docker-run: validate-docker-variables ## Start a single docker container
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	@$(if $(HOST_STRING),,$(error "HOST_STRING is undefined"))
	docker run 	--name $(DOCKER_SERVICE_NAME) \
				-d \
				-it \
				--env-file docker-run-secrets.env \
				--mount type=bind,source="$$(pwd)"/secret.gpg,target=$(APP_CODE_PATH_CONTAINER)/secret.gpg,readonly \
				$(HOST_STRING) \
				$(DOCKER_SERVICE_OPTIONS) \
				$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_SERVICE_NAME)-$(ENV):$(TAG)


# see scripts in .docker/images/logger/logrotate.d for a documentation of the paths of the log volumes
.PHONY: docker-run-logger
docker-run-logger: validate-docker-variables ## Start a logger sidecar container
	docker run 	--name $(DOCKER_SERVICE_NAME_LOGGER) \
				-d \
				-it \
				-v logs-cron:/var/log/cron \
				-v logs-nginx:/var/log/nginx \
				-v logs-app:/var/log/app \
				-v logs-supervisor:/var/log/supervisor \
				-v logs-php-fpm:/var/log/php-fpm \
				$(DOCKER_REGISTRY)/$(DOCKER_NAMESPACE)/$(DOCKER_SERVICE_NAME_LOGGER)-$(ENV):$(TAG)

.PHONY: docker-run-nginx
docker-run-nginx: ## Start the nginx container
	"$(MAKE)" docker-run DOCKER_SERVICE_NAME="$(DOCKER_SERVICE_NAME_NGINX)" DOCKER_SERVICE_OPTIONS="-v logs-nginx:/var/log/nginx -p 80:80 -p 443:443"

.PHONY: docker-run-php-fpm
docker-run-php-fpm: ## Start the php-fpm container
	"$(MAKE)" docker-run DOCKER_SERVICE_NAME="$(DOCKER_SERVICE_NAME_PHP_FPM)" DOCKER_SERVICE_OPTIONS="-v logs-app:/var/log/app -v logs-php-fpm:/var/log/php-fpm -p 9000:9000"

.PHONY: docker-run-application
docker-run-application: ## Start the application container
	"$(MAKE)" docker-run DOCKER_SERVICE_NAME="$(DOCKER_SERVICE_NAME_APPLICATION)" DOCKER_SERVICE_OPTIONS="-v logs-app:/var/log/app"

.PHONY: docker-run-php-worker
docker-run-php-worker: ## Start the php-worker container
	"$(MAKE)" docker-run DOCKER_SERVICE_NAME="$(DOCKER_SERVICE_NAME_PHP_WORKER)" DOCKER_SERVICE_OPTIONS="-v logs-app:/var/log/app -v logs-supervisor:/var/log/supervisor"

.PHONY: docker-stop
docker-stop: validate-docker-variables ## Stop a single docker container
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	docker stop $(DOCKER_SERVICE_NAME)

.PHONY: docker-rm
docker-rm: validate-docker-variables ## Remove a single docker container
	@$(if $(DOCKER_SERVICE_NAME),,$(error "DOCKER_SERVICE_NAME is undefined"))
	docker rm $(DOCKER_SERVICE_NAME)
