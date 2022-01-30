##@ [Application: Setup]

.PHONY: setup-db
setup-db: ## Setup the DB tables
	$(EXECUTE_IN_APPLICATION_CONTAINER) php setup.php $(ARGS);
