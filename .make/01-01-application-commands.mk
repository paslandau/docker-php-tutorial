##@ [Application: Commands]

# @see https://stackoverflow.com/a/43076457
.PHONY: restart-php-fpm
restart-php-fpm: ## Restart the php-fpm service
	"$(MAKE)" execute-in-container DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME_PHP_FPM) COMMAND="kill -USR2 1"

.PHONY: restart-workers
restart-workers: ## Restart all workers 
	$(EXECUTE_IN_WORKER_CONTAINER) supervisorctl restart all

.PHONY: stop-workers
stop-workers: ## Stop all workers 
	$(EXECUTE_IN_WORKER_CONTAINER) supervisorctl stop worker:*

.PHONY: start-workers
start-workers: ## start all workers 
	$(EXECUTE_IN_WORKER_CONTAINER) supervisorctl start worker:*

.PHONY: execute-in-container
execute-in-container: ## Execute a command in a container. E.g. via "make execute-in-container DOCKER_SERVICE_NAME=php-fpm COMMAND="echo 'hello'"
	@$(if $(DOCKER_SERVICE_NAME),,$(error DOCKER_SERVICE_NAME is undefined))
	@$(if $(COMMAND),,$(error COMMAND is undefined))
	$(EXECUTE_IN_ANY_CONTAINER) $(COMMAND)

.PHONY: enable-xdebug
enable-xdebug: ## Enable xdebug in the given container specified by "DOCKER_SERVICE_NAME". E.g. "make enable-xdebug DOCKER_SERVICE_NAME=php-fpm"
	"$(MAKE)" execute-in-container APP_USER_NAME="root" DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME) COMMAND="sed -i 's/.*zend_extension=xdebug/zend_extension=xdebug/' '/etc/php8/conf.d/zz-app-local.ini'"

.PHONY: disable-xdebug
disable-xdebug: ## Disable xdebug in the given container specified by "DOCKER_SERVICE_NAME". E.g. "make disable-xdebug DOCKER_SERVICE_NAME=php-fpm"
	"$(MAKE)" execute-in-container APP_USER_NAME="root" DOCKER_SERVICE_NAME=$(DOCKER_SERVICE_NAME) COMMAND="sed -i 's/.*zend_extension=xdebug/;zend_extension=xdebug/' '/etc/php8/conf.d/zz-app-local.ini'"

.PHONY: clear-queue
clear-queue: ## Clear the job queue
	$(EXECUTE_IN_APPLICATION_CONTAINER) php artisan queue:clear $(ARGS)
