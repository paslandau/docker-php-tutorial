##@ [Application: QA]

# variables
CORES?=$(shell (nproc  || sysctl -n hw.ncpu) 2> /dev/null)

# constants
## files
ALL_FILES=./
APP_FILES=app/
TEST_FILES=tests/

# Tool CLI config
PHPUNIT_CMD=php vendor/bin/phpunit
PHPUNIT_ARGS= -c phpunit.xml --log-junit .build/report.xml
PHPUNIT_FILES=
PHPSTAN_CMD=php vendor/bin/phpstan analyse
PHPSTAN_ARGS=--level=9
PHPSTAN_FILES=$(APP_FILES) $(TEST_FILES)
PHPCS_CMD=php vendor/bin/phpcs
PHPCS_ARGS=--parallel=$(CORES) --standard=psr12
PHPCS_FILES=$(APP_FILES)
PHPCBF_CMD=php vendor/bin/phpcbf
PHPCBF_ARGS=$(PHPCS_ARGS)
PHPCBF_FILES=$(PHPCS_FILES)
PARALLEL_LINT_CMD=php vendor/bin/parallel-lint
PARALLEL_LINT_ARGS=-j 4 --exclude vendor/ --exclude .docker --exclude .git
PARALLEL_LINT_FILES=$(ALL_FILES)
COMPOSER_REQUIRE_CHECKER_CMD=php vendor/bin/composer-require-checker
COMPOSER_REQUIRE_CHECKER_ARGS=--ignore-parse-errors

# call with NO_PROGRESS=true to hide tool progress (makes sense when invoking multiple tools together)
NO_PROGRESS?=false
ifeq ($(NO_PROGRESS),true)
	PHPSTAN_ARGS+= --no-progress
	PARALLEL_LINT_ARGS+= --no-progress
else
	PHPCS_ARGS+= -p
	PHPCBF_ARGS+= -p
endif

# Use NO_PROGRESS=false when running individual tools.
# On  NO_PROGRESS=true  the corresponding tool has no output on success
#                       apart from its runtime but it will still print 
#                       any errors that occured. 
define execute
	if [ "$(NO_PROGRESS)" = "false" ]; then \
		eval "$(EXECUTE_IN_APPLICATION_CONTAINER) $(1) $(2) $(3) $(4)"; \
	else \
		START=$$(date +%s); \
		printf "%-35s" "$@"; \
		if OUTPUT=$$(eval "$(EXECUTE_IN_APPLICATION_CONTAINER) $(1) $(2) $(3) $(4)" 2>&1); then \
			printf " $(GREEN)%-6s$(NO_COLOR)" "done"; \
			END=$$(date +%s); \
			RUNTIME=$$((END-START)) ;\
			printf " took $(YELLOW)$${RUNTIME}s$(NO_COLOR)\n"; \
		else \
			printf " $(RED)%-6s$(NO_COLOR)" "fail"; \
			END=$$(date +%s); \
			RUNTIME=$$((END-START)) ;\
			printf " took $(YELLOW)$${RUNTIME}s$(NO_COLOR)\n"; \
			echo "$$OUTPUT"; \
			printf "\n"; \
			exit 1; \
		fi; \
	fi
endef

.PHONY: test
test: ## Run all tests
	@$(EXECUTE_IN_APPLICATION_CONTAINER) $(PHPUNIT_CMD) $(PHPUNIT_ARGS) $(ARGS)

.PHONY: phplint
phplint: ## Run phplint on all files
	@$(call execute,$(PARALLEL_LINT_CMD),$(PARALLEL_LINT_ARGS),$(PARALLEL_LINT_FILES), $(ARGS))

.PHONY: phpcs
phpcs: ## Run style check on all application files
	@$(call execute,$(PHPCS_CMD),$(PHPCS_ARGS),$(PHPCS_FILES), $(ARGS))

.PHONY: phpcbf
phpcbf: ## Run style fixer on all application files
	@$(call execute,$(PHPCBF_CMD),$(PHPCBF_ARGS),$(PHPCBF_FILES), $(ARGS))

.PHONY: phpstan
phpstan:  ## Run static analyzer on all application and test files 
	@$(call execute,$(PHPSTAN_CMD),$(PHPSTAN_ARGS),$(PHPSTAN_FILES), $(ARGS))

.PHONY: composer-require-checker
composer-require-checker: ## Run dependency checker
	@$(call execute,$(COMPOSER_REQUIRE_CHECKER_CMD),$(COMPOSER_REQUIRE_CHECKER_ARGS),"", $(ARGS))

.PHONY: qa
qa: ## Run code quality tools on all files
	@"$(MAKE)" -j $(CORES) -k --no-print-directory --output-sync=target qa-exec NO_PROGRESS=true

.PHONY: qa-exec
qa-exec: phpstan \
	phplint \
	composer-require-checker \
	phpcs \
