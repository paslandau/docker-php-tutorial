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

RUN apk --update-cache add ca-certificates && \
    echo "https://php.hernandev.com/v${ALPINE_VERSION}/php-${TARGET_PHP_VERSION}" >> /etc/apk/repositories && \
    apk add --update --no-cache  \
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

COPY ./images/php/base/conf.d/zz-app.ini /etc/php8/conf.d/
COPY ./images/php/base/conf.d/zz-app-${ENV}.ini /etc/php8/conf.d/

COPY ./images/php/base/.bashrc /home/${APP_USER_NAME}/.bashrc
COPY ./images/php/base/.bashrc /root/.bashrc

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

