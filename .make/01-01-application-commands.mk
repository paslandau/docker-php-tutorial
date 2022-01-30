##@ [Application: Commands]

.PHONY: restart-workers
restart-workers: ## Restart all workers 
	$(EXECUTE_IN_WORKER_CONTAINER) supervisorctl restart all;

.PHONY: stop-workers
stop-workers: ## Stop all workers 
	$(EXECUTE_IN_WORKER_CONTAINER) supervisorctl stop worker:*;

.PHONY: start-workers
start-workers: ## start all workers 
	$(EXECUTE_IN_WORKER_CONTAINER) supervisorctl start worker:*;
