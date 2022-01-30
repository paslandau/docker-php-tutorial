# Define the default shell
# @see https://stackoverflow.com/a/14777895/413531 for the OS detection logic
OS?=undefined
ifeq ($(OS),Windows_NT)
	# Windows requires the .exe extension, otherwise the entry is ignored
	# @see https://stackoverflow.com/a/60318554/413531
    SHELL := bash.exe
    # make sure that MinGW / MSYSY does not automatically convert paths starting with /
    # @see https://stackoverflow.com/a/48348531
    export MSYS_NO_PATHCONV=1
else
    SHELL := bash
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

-include .make/.env

# Common variable to pass arbitrary options to targets
ARGS?= 

# @see https://www.thapaliya.com/en/writings/well-documented-makefiles/
DEFAULT_GOAL := help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-40s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

include .make/*.mk

##@ [Make]

## Usage: 
## make-init
## 
## make-init ENVS="KEY_1=value1 KEY_2=value2"
.PHONY: make-init
make-init: ENVS= ## Initializes the local .makefile/.env file with ENV variables for make
make-init: 
	@cp .make/.env.example .make/.env
	@for variable in $(ENVS); do \
	  echo $$variable | tee -a .make/.env; \
	  done
	@echo "Please update your .make/.env file with your local settings"
