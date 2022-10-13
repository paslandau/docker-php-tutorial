ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base

ENV SERVICE_NAME=application

FROM base as prod

RUN    apk add --update apk-cron \
    && rm -rf /etc/periodic/*  \
              /etc/crontabs/root \
              /var/cache/apk/*

ARG PATH_TO_CRON_OUTPUT_LOG=/var/log/app/cron-output.log
RUN echo "*  *  *  *  * $(which php) ${APP_CODE_PATH}/artisan schedule:run >> ${PATH_TO_CRON_OUTPUT_LOG} 2>&1" > /etc/crontabs/$APP_USER_NAME

# -l: Log level 2 (= everything, according to https://unix.stackexchange.com/a/414010)
# -f: foreground
# -L: Path to cron logfile
CMD [ "crond", "-l", "2", "-f", "-L", "/var/log/app/cron.log" ]

FROM base as ci

USER $APP_USER_NAME

FROM base as local

RUN apk add --no-cache --update \
        openssh

ARG APP_SSH_PASSWORD
RUN echo "$APP_USER_NAME:$APP_SSH_PASSWORD" | chpasswd 2>&1

# Required to start sshd, otherwise the container will error out on startup with the message
# "sshd: no hostkeys available -- exiting."
# @see https://stackoverflow.com/a/65348102/413531 
RUN ssh-keygen -A

# we use SSH deployment configuration in PhpStorm for local development
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
