##@ [Application: Setup]

.PHONY: setup
setup: ## Setup the application
	"$(MAKE)" setup-db
	"$(MAKE)" composer ARGS="install"

.PHONY: setup-db
setup-db: ## Setup the DB tables
	$(EXECUTE_IN_APPLICATION_CONTAINER) php artisan app:setup-db $(ARGS);

.PHONY: composer
composer: ## Run composer commands. Specify the command e.g. via ARGS="install"
	$(EXECUTE_IN_APPLICATION_CONTAINER) composer $(ARGS);
