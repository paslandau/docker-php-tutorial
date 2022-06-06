ARG ALPINE_VERSION
ARG COMPOSER_VERSION
FROM composer:${COMPOSER_VERSION} as composer
FROM alpine:${ALPINE_VERSION} as base

# make build args available as ENV variables to downstream images
# so that we don't have to pass the same build args again
ARG APP_USER_ID
ARG APP_GROUP_ID
ARG APP_USER_NAME
ARG APP_GROUP_NAME
ARG APP_CODE_PATH
ARG TARGET_PHP_VERSION
ARG ALPINE_VERSION
ARG ENV
ENV APP_USER_ID=${APP_USER_ID}
ENV APP_GROUP_ID=${APP_GROUP_ID}
ENV APP_USER_NAME=${APP_USER_NAME}
ENV APP_GROUP_NAME=${APP_GROUP_NAME}
ENV APP_CODE_PATH=${APP_CODE_PATH}
ENV TARGET_PHP_VERSION=${TARGET_PHP_VERSION}
ENV ALPINE_VERSION=${ALPINE_VERSION}
ENV ENV=${ENV}

RUN addgroup -g $APP_GROUP_ID $APP_GROUP_NAME && \
    adduser -D -u $APP_USER_ID -s /bin/bash $APP_USER_NAME -G $APP_GROUP_NAME && \
    mkdir -p $APP_CODE_PATH && \
    chown $APP_USER_NAME: $APP_CODE_PATH
    
# install git-secret
# @see https://git-secret.io/installation#alpine
ADD https://gitsecret.jfrog.io/artifactory/api/security/keypair/public/repositories/git-secret-apk /etc/apk/keys/git-secret-apk.rsa.pub

# FYI, we are NOT using a cache mount to store the apk cache via
#   RUN --mount=type=cache,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
# @see https://github.com/FernandoMiguel/BuildKit#new-dockerfile
# @see https://wiki.alpinelinux.org/wiki/Local_APK_cache#Enabling_Local_Cache_on_HDD_installs
# because we run --update anyways to get the latest files
RUN echo "https://gitsecret.jfrog.io/artifactory/git-secret-apk/all/main" >> /etc/apk/repositories  && \
    apk add --update --no-cache \
        bash \
        git \
        git-secret \
        # required for git-secret
        gawk \
        gnupg \
        make \
        strace \
        sudo \
        vim 

# install PHP
# Note: we need to use a custom apk repository because the official ones will
#       likely not include the latest PHP version.
# @see https://github.com/codecasts/php-alpine
ADD https://php.hernandev.com/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

#RUN --mount=type=cache,target=/var/cache/apk ln -vs /var/cache/apk /etc/apk/cache && \
RUN apk add ca-certificates && \
    echo "https://php.hernandev.com/v${ALPINE_VERSION}/php-${TARGET_PHP_VERSION}" >> /etc/apk/repositories && \
    apk add --no-cache \
        php-curl~=${TARGET_PHP_VERSION} \
        php-dom~=${TARGET_PHP_VERSION} \
        php-mbstring~=${TARGET_PHP_VERSION} \
        php-pdo_mysql~=${TARGET_PHP_VERSION} \
        php-pdo~=${TARGET_PHP_VERSION} \
        php-phar~=${TARGET_PHP_VERSION} \
        php-redis~=${TARGET_PHP_VERSION} \
        php-xml~=${TARGET_PHP_VERSION} \
        php8~=${TARGET_PHP_VERSION} \
# make "php" as command available by creating a symlink
# https://github.com/codecasts/php-alpine/issues/20#issuecomment-350477886    
    && ln -s /usr/bin/php8 /usr/bin/php

# make bash default shell
RUN sed -e 's;/bin/ash$;/bin/bash;g' -i /etc/passwd

COPY ./.docker/images/php/base/conf.d/zz-app.ini /etc/php8/conf.d/
COPY ./.docker/images/php/base/conf.d/zz-app-${ENV}.ini /etc/php8/conf.d/

COPY ./.docker/images/php/base/.bashrc /home/${APP_USER_NAME}/.bashrc
COPY ./.docker/images/php/base/.bashrc /root/.bashrc

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

# Fix git permission issue:
# `git` introduced a security feature to throw an error if the parent directory 
# of the `.git` directory is owned by another user.
# @see https://github.blog/2022-04-12-git-security-vulnerability-announced/
# @see https://github.com/actions/checkout/issues/760
# 
# Since we might not have full control over the owner 
# ( see e.g. https://github.com/docker/for-win/issues/12742 )
# we will add the $APP_CODE_PATH as a "safe" directory to the global git config via
#  git config --system --add safe.directory "/path/to/git/parent/folder"
# @see https://git-scm.com/docs/git-config/2.36.0#Documentation/git-config.txt-safedirectory
# 
# Without this fix, git-secret will emit the error
#  git-secret: abort: not in dir with git repo. Use 'git init' or 'git clone', then in repo use 'git secret init'
RUN git config --system --add safe.directory "$APP_CODE_PATH"

WORKDIR $APP_CODE_PATH

FROM base as codebase

# By only copying the composer files required to run composer install
# the layer will be cached and only invalidated when the composer dependencies are changed
COPY ./composer.json /dependencies/
COPY ./composer.lock /dependencies/

# use a cache mount to cache the composer dependencies
# this is essentially a cache that lives in Docker BuildKit (i.e. has nothing to do with the host system) 
RUN --mount=type=cache,target=/tmp/.composer \
    cd /dependencies && \
    # COMPOSER_HOME=/tmp/.composer sets the home directory of composer that
    # also controls where composer looks for the cache 
    # so we don't have to download dependencies again (if they are cached)
    # @see https://stackoverflow.com/a/60518444 for the correct if-then-else syntax:
    # - end all commands with ; \
    # - except THEN and ELSE
    if [ "$ENV" == "prod" ] ; \
    then \
      # on production, we don't want test dependencies
      COMPOSER_HOME=/tmp/.composer composer install --no-scripts --no-plugins --no-progress -o --no-dev; \
    else  \
      COMPOSER_HOME=/tmp/.composer composer install --no-scripts --no-plugins --no-progress -o; \
    fi
 
# copy the full codebase
COPY . /codebase

# move the dependencies
RUN mv /dependencies/vendor /codebase/vendor

# remove files we don't require in the image to keep the image size small
RUN cd /codebase && \
    rm -rf .docker/ .build/ .infrastructure/ && \
    if [ "$ENV" == "prod" ] ; \
    then \
      # on production, we don't want tests
      rm -rf tests/; \
    fi
 
# Remove all secrets that are NOT required for the given ENV:
#  `find /codebase/.secrets -type f -print` lists all files in the .secrets directory
#  `grep -v "/\(shared\|$ENV\)/"` matches only the files that are NOT in the shared/ or $ENV/ (e.g. prod/) directories
#  `grep -v ".secret\$"` ensures that we remove all files that are NOT ending in .secret
#    FYI: 
#     the "$" has to be escaped with a "\" 
#     "Escaping is possible by adding a \ before the variable"
#     @see https://docs.docker.com/engine/reference/builder/#environment-replacement
#  `xargs rm -f` retrieves the remaining file and deletes them
#    FYI: 
#     `xargs` is necessary to convert the stdin to args for `rm`
#     @see https://stackoverflow.com/a/20307392/413531
#     the `-f` flag is required so that `rm` doesn't fail if no files are matched
RUN find /codebase/.secrets -type f -print | grep -v "/\(shared\|$ENV\)/" | xargs rm -f && \
    find /codebase/.secrets -type f -print | grep -v ".secret\$" | xargs rm -f && \
    # list the remaining files for debugging purposes
    find /codebase/.secrets -type f -print

# We need a git repository for git-secret to work (can be an empty one)
RUN cd /codebase && \
    git init

FROM base as prod

# We will use a custom ENTRYPOINT to decrypt the secrets when the container starts.
# This way, we can store the secrets in their encrypted form directly in the image.
# Note: Because we defined a custom ENTRYPOINT, the default CMD of the base image
#       will be overriden. Thus, we must explicitly re-define it here via `CMD ["/bin/sh"]`.
#       This behavior is described in the docs as:
#       "If CMD is defined from the base image, setting ENTRYPOINT will reset CMD to an empty value. In this scenario, CMD must be defined in the current image to have a value."
#       @see https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
COPY ./.docker/images/php/base/decrypt-secrets.sh /decrypt-secrets.sh
RUN chmod +x /decrypt-secrets.sh
CMD ["/bin/sh"]
ENTRYPOINT ["/decrypt-secrets.sh"]

COPY --from=codebase --chown=$APP_USER_NAME:$APP_GROUP_NAME /codebase $APP_CODE_PATH

COPY --chown=$APP_USER_NAME:$APP_GROUP_NAME ./.build/build-info $APP_CODE_PATH/build-info

FROM base as ci

COPY --from=codebase --chown=$APP_USER_NAME:$APP_GROUP_NAME /codebase $APP_CODE_PATH

FROM base as local

# add app user to sudoers
# see https://ostechnix.com/add-delete-and-grant-sudo-privileges-to-users-in-alpine-linux/ for adding sudo
# see https://askubuntu.com/a/340669 for not requiring a sudo pw
RUN echo "root ALL=(ALL) NOPASSWD: ALL " | tee -a "/etc/sudoers.d/users" && \
    echo "${APP_USER_NAME} ALL=(ALL) NOPASSWD: ALL " | tee -a "/etc/sudoers.d/users"

RUN apk add --no-cache --update \
        mysql-client \
        redis \
        php-xdebug~=${TARGET_PHP_VERSION} \
    # ensure that xdebug is not enabled by default
    && rm -f /etc/php8/conf.d/00_xdebug.ini

