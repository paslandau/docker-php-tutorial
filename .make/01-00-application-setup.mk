##@ [Application: Setup]

.PHONY: setup
setup: ## Setup the application
	"$(MAKE)" composer ARGS="install"
	"$(MAKE)" setup-db

.PHONY: setup-db
setup-db: ## Setup the DB tables
	$(EXECUTE_IN_APPLICATION_CONTAINER) php artisan app:setup-db $(ARGS)

.PHONY: composer
composer: ## Run composer commands. Specify the command e.g. via ARGS="install"
	$(EXECUTE_IN_APPLICATION_CONTAINER) composer $(ARGS)

##@ [Application: GPG]

# gpg

DEFAULT_SECRET_GPG_KEY?=secret.gpg
DEFAULT_PUBLIC_GPG_KEYS?=.dev/gpg-keys/*

.PHONY: gpg
gpg: ## Run gpg commands. Specify the command e.g. via ARGS="--list-keys"
	$(EXECUTE_IN_APPLICATION_CONTAINER) gpg $(ARGS)

.PHONY: gpg-export-public-key
gpg-export-public-key: ## Export a gpg public key e.g. via EMAIL="john.doe@example.com" PATH=".dev/gpg-keys/john-public.gpg"
	@$(if $(PATH),,$(error PATH is undefined))
	@$(if $(EMAIL),,$(error EMAIL is undefined))
	"$(MAKE)" -s gpg ARGS="gpg --armor --export $(EMAIL) > $(PATH)"

.PHONY: gpg-export-private-key
gpg-export-private-key: ## Export a gpg private key e.g. via EMAIL="john.doe@example.com" PATH="secret.gpg"
	@$(if $(PATH),,$(error PATH is undefined))
	@$(if $(EMAIL),,$(error EMAIL is undefined))
	"$(MAKE)" -s gpg ARGS="--output $(PATH) --armor --export-secret-key $(EMAIL)"

.PHONY: gpg-import
gpg-import: ## Import a gpg key file e.g. via GPG_KEY_FILES="/path/to/file /path/to/file2"
	@$(if $(GPG_KEY_FILES),,$(error GPG_KEY_FILES is undefined))
	"$(MAKE)" -s gpg ARGS="--import --batch --yes --pinentry-mode loopback $(GPG_KEY_FILES)"

.PHONY: gpg-import-default-secret-key
gpg-import-default-secret-key: ## Import the default secret key
	"$(MAKE)" -s gpg-import GPG_KEY_FILES="$(DEFAULT_SECRET_GPG_KEY)"

.PHONY: gpg-import-default-public-keys
gpg-import-default-public-keys: ## Import the default public keys
	"$(MAKE)" -s gpg-import GPG_KEY_FILES="$(DEFAULT_PUBLIC_GPG_KEYS)" 

.PHONY: gpg-init
gpg-init: gpg-import-default-secret-key gpg-import-default-public-keys ## Initialize gpg in the container, i.e. import all public and private keys

##@ [Application: git secret]

# git-secret

FILES?=

.PHONY: git-secret
git-secret: ## Run git-secret commands. Specify the command e.g. via ARGS="hide"
	$(EXECUTE_IN_APPLICATION_CONTAINER) git-secret $(ARGS)

.PHONY: secret-init
secret-init: ## Initialize git-secret in the repository via `git-secret init`
	"$(MAKE)" -s git-secret ARGS="init"

.PHONY: secret-init-gpg-socket-config
secret-init-gpg-socket-config: ## Initialize the config files to change the gpg socket locations
	echo "%Assuan%" > .gitsecret/keys/S.gpg-agent
	echo "socket=/tmp/S.gpg-agent" >> .gitsecret/keys/S.gpg-agent
	echo "%Assuan%" > .gitsecret/keys/S.gpg-agent.ssh
	echo "socket=/tmp/S.gpg-agent.ssh" >> .gitsecret/keys/S.gpg-agent.ssh
	echo "extra-socket /tmp/S.gpg-agent.extra" > .gitsecret/keys/gpg-agent.conf
	echo "browser-socket /tmp/S.gpg-agent.browser" >> .gitsecret/keys/gpg-agent.conf

.PHONY: secret-encrypt
secret-encrypt: ## Decrypt secret files via `git-secret hide`
	"$(MAKE)" -s git-secret ARGS="hide"

.PHONY: secret-decrypt
secret-decrypt: ## Decrypt secret files via `git-secret reveal -f`. Use FILES=file1 to decrypt only file1 instead of all files
	"$(MAKE)" -s git-secret ARGS="reveal -f $(FILES)"

.PHONY: secret-decrypt-with-password
secret-decrypt-with-password: ## Decrypt secret files using a password for gpg. Use FILES=file1 to decrypt only file1 instead of all files
	@$(if $(GPG_PASSWORD),,$(error GPG_PASSWORD is undefined))
	"$(MAKE)" -s git-secret ARGS="reveal -f -p $(GPG_PASSWORD) $(FILES)" 

.PHONY: secret-add
secret-add: ## Add a file to git secret via `git-secret add $FILES`
	@$(if $(FILES),,$(error FILES is undefined))
	"$(MAKE)" -s git-secret ARGS="add $(FILES)"

.PHONY: secret-cat
secret-cat: ## Show the contents of file to git secret via `git-secret cat $FILES`
	@$(if $(FILES),,$(error FILES is undefined))
	"$(MAKE)" -s git-secret ARGS="cat $(FILES)"

.PHONY: secret-list
secret-list: ## List all files added to git secret `git-secret list`
	"$(MAKE)" -s git-secret ARGS="list"

.PHONY: secret-remove
secret-remove: ## Remove a file from git secret via `git-secret remove $FILES`
	@$(if $(FILES),,$(error FILES is undefined))
	"$(MAKE)" -s git-secret ARGS="remove $(FILES)"

.PHONY: secret-add-user
secret-add-user: ## Remove a user from git secret via `git-secret tell $EMAIL`
	@$(if $(EMAIL),,$(error EMAIL is undefined))
	"$(MAKE)" -s git-secret ARGS="tell $(EMAIL)"

.PHONY: secret-show-users
secret-show-users: ## Show all users that have access to git secret via `git-secret whoknows`
	"$(MAKE)" -s git-secret ARGS="whoknows"

.PHONY: secret-remove-user
secret-remove-user: ## Remove a user from git secret via `git-secret killperson $EMAIL`
	@$(if $(EMAIL),,$(error EMAIL is undefined))
	"$(MAKE)" -s git-secret ARGS="killperson $(EMAIL)"

.PHONY: secret-diff
secret-diff: ## Show the diff between the content of encrypted and decrypted files via `git-secret changes`
	"$(MAKE)" -s git-secret ARGS="changes $(FILES)"
