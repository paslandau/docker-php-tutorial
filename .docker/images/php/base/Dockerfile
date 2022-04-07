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
        git-secret \
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
    COMPOSER_HOME=/tmp/.composer composer install --no-scripts --no-plugins --no-progress -o 

# copy the full codebase
COPY . /codebase

RUN mv /dependencies/vendor /codebase/vendor && \
    cd /codebase && \
    # remove files we don't require in the image to keep the image size small
    rm -rf .docker/ && \
    # we need a git repository for git-secret to work (can be an empty one)
    git init

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

