##@ [Application: QA]

.PHONY: test
test: ## Run the test suite 
	$(EXECUTE_IN_WORKER_CONTAINER) vendor/bin/phpunit -c phpunit.xml
