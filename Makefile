# @see https://tech.davis-hansson.com/p/make/
# define the default shell
SHELL := bash

# Add the -T options to "docker compose exec" to avoid the 
# "panic: the handle is invalid"
# error on Windows and Linux 
# @see https://stackoverflow.com/a/70856332/413531
DOCKER_COMPOSE_EXEC_OPTIONS=-T

# Empty for Linux and Mac
WINPTY_PREFIX=

# OS is a defined variable for WIN systems, so "uname" will not be executed
OS?=$(shell uname)
# Values of OS:
#   Windows => Windows_NT 
#   Mac 	=> Darwin 
#   Linux 	=> Linux 
ifeq ($(OS),Windows_NT)
	# Windows requires the .exe extension, otherwise the entry is ignored
	# @see https://stackoverflow.com/a/60318554/413531
    SHELL := bash.exe
    # When allocating a terminal, the corresponding command must be prefixed
    # with `winpty` to avoid the "The input device is not a TTY" error
    # @see http://www.pascallandau.com/blog/setting-up-git-bash-mingw-msys2-on-windows/#the-role-of-winpty-fixing-the-input-device-is-not-a-tty
	WINPTY_PREFIX=winpty
	# Export MSYS_NO_PATHCONV=1 as environment variable to avoid automatic path conversion
	# (the export does only apply locally to `make` and the scripts that are invoked,
	# it does not affect the global environment)
    # @see http://www.pascallandau.com/blog/setting-up-git-bash-mingw-msys2-on-windows/#fixing-the-path-conversion-issue-for-mingw-msys2
	export MSYS_NO_PATHCONV=1
else ifeq ($(OS),Darwin)
    # On Mac, the -T must be omitted to avoid cluttered output
    # @see https://github.com/moby/moby/issues/37366#issuecomment-401157643
	DOCKER_COMPOSE_EXEC_OPTIONS=
endif

# @see https://tech.davis-hansson.com/p/make/ for some make best practices
# use bash strict mode @see http://redsymbol.net/articles/unofficial-bash-strict-mode/
# -e 			- instructs bash to immediately exit if any command has a non-zero exit status
# -u 			- a reference to any variable you haven't previously defined - with the exceptions of $* and $@ - is an error
# -o pipefail 	- if any command in a pipeline fails, that return code will be used as the return code 
#				  of the whole pipeline. By default, the pipeline's return code is that of the last command - even if it succeeds.
# https://unix.stackexchange.com/a/179305
# -c            - Read and execute commands from string after processing the options. Otherwise, arguments are treated  as filed. Example:
#                 bash -c "echo foo" # will excecute "echo foo"
#                 bash "echo foo"    # will try to open the file named "echo foo" and execute it 
.SHELLFLAGS := -euo pipefail -c
# display a warning if variables are used but not defined
MAKEFLAGS += --warn-undefined-variables
# remove some "magic make behavior"
MAKEFLAGS += --no-builtin-rules

# don't print directory information by default
# @see https://stackoverflow.com/a/8080887
ifndef VERBOSE
MAKEFLAGS += --no-print-directory
endif

# include the default variables
include .make/variables.env
# include the current environment settings
-include .make/.env
# include the deployment environment settings
-include .make/deployment-settings.env

# Common variable to pass arbitrary options to targets
ARGS?= 

# bash colors
RED:=\033[0;31m
GREEN:=\033[0;32m
YELLOW:=\033[0;33m
NO_COLOR:=\033[0m

# @see https://www.thapaliya.com/en/writings/well-documented-makefiles/
.DEFAULT_GOAL:=help

# Define a helper container invocation for linux utilities to ensure commands like "sed" 
# can be invoked uniformely across different OS
# @see https://stackoverflow.com/a/19457213/413531 for a description of the `sed` issue
# Usage in a make target:
# $(LINUX_UTILITY_CONTAINER) sed -i "s/\r//g" ".build/service-ips"
# Using a container can be "disabled" by setting EXECUTE_IN_LINUX_UTILITY_CONTAINER to "false"
LINUX_UTILITY_CONTAINER=
EXECUTE_IN_LINUX_UTILITY_CONTAINER?=true
ifeq ($(EXECUTE_IN_LINUX_UTILITY_CONTAINER),true)
	LINUX_UTILITY_CONTAINER=docker run -i --rm -v $$(pwd):/codebase --workdir /codebase busybox 
endif

include .make/*.mk

# Note:
# We are NOT using $(MAKEFILE_LIST) but defined the required make files manually via "Makefile .make/*.mk"
# because $(MAKEFILE_LIST) also contains the .env files AND we cannot force the order of the files
help:
	@printf '%-43s \033[1mDefault values: \033[0m     \n'
	@printf '%-43s ===================================\n'
	@printf '%-43s ENV: \033[31m "$(ENV)" \033[0m     \n'
	@printf '%-43s TAG: \033[31m "$(TAG)" \033[0m     \n'
	@printf '%-43s ===================================\n'
	@printf '%-43s \033[3mRun the following command to set them:\033[0m\n'
	@printf '%-43s \033[1mmake make-init ENVS="ENV=prod TAG=latest"\033[0m\n'
	@awk 'BEGIN {FS = ":.*##"; printf "\n\033[1mUsage:\033[0m\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-40s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile .make/*.mk

##@ [Make]

ENVS?=ENV=local
.PHONY: make-init
make-init: ## Initializes the local `.make/.env` file with ENV variables for make. Use via ENVS="KEY_1=value1 KEY_2=value2"
	@$(if $(ENVS),,$(error ENVS is undefined))
	@rm -f .make/.env
	@for variable in $(ENVS); do \
	  echo $$variable | tee -a .make/.env > /dev/null 2>&1; \
	done
	@echo "Created a local .make/.env file"

.PHONY: make-init-deployment-settings
make-init-deployment-settings: ## Create a `deployment-settings.env` file to ensure that no local-only variables are affecting the deployment. Use via ENVS="KEY_1=value1 KEY_2=value2"
	@cp .make/variables.env .make/deployment-settings.env
	@for variable in $(ENVS); do \
	  echo $$variable | tee -a .make/deployment-settings.env > /dev/null 2>&1; \
	done

.PHONY: make-remove-deployment-settings
make-remove-deployment-settings: ## Remove the `deployment-settings.env` file 
	rm -f .make/deployment-settings.env

.PHONY: docs
docs: ## Show the docu for the target specified by TARGET. 
	@$(if $(TARGET),,$(error TARGET is undefined. Usage: $@ TARGET=docs))
	@"$(MAKE)" -s | grep $(TARGET)

