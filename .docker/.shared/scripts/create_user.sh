#!/bin/sh

APP_USER=$1
APP_GROUP=$2
APP_USER_ID=$3
APP_GROUP_ID=$4

new_user_id_exists=$(id ${APP_USER_ID} > /dev/null 2>&1; echo $?)
if [ "$new_user_id_exists" = "0" ]; then
    (>&2 echo "ERROR: APP_USER_ID $APP_USER_ID already exists - Aborting!");
    exit 1;
fi

new_group_id_exists=$(getent group ${APP_GROUP_ID} > /dev/null 2>&1; echo $?)
if [ "$new_group_id_exists" = "0" ]; then
    (>&2 echo "ERROR: APP_GROUP_ID $APP_GROUP_ID already exists - Aborting!");
    exit 1;
fi

old_user_id=$(id -u ${APP_USER})
old_user_exists=$(id -u ${APP_USER} > /dev/null 2>&1; echo $?)
old_group_id=$(getent group ${APP_GROUP} | cut -d: -f3)
old_group_exists=$(getent group ${APP_GROUP} > /dev/null 2>&1; echo $?)

if [ "$old_group_id" != "${APP_GROUP_ID}" ]; then
    # create the group
    groupadd -f ${APP_GROUP}
    # and the correct id
    groupmod -g ${APP_GROUP_ID} ${APP_GROUP}
    if [ "$old_group_exists" = "0" ]; then
        # set the permissions of all "old" files and folder to the new group
        find / -group $old_group_id -exec chgrp -h ${APP_GROUP} {} \; || true
    fi
fi

if [ "$old_user_id" != "${APP_USER_ID}" ]; then
    # create the user if it does not exist
    if [ "$old_user_exists" != "0" ]; then
        useradd ${APP_USER} -g ${APP_GROUP}
    fi

    # make sure the home directory exists with the correct permissions
    mkdir -p /home/${APP_USER} && chmod 755 /home/${APP_USER} && chown ${APP_USER}:${APP_GROUP} /home/${APP_USER}

    # change the user id, set the home directory and make sure the user has a login shell
    usermod -u ${APP_USER_ID} -m -d /home/${APP_USER} ${APP_USER} -s $(which bash)

    if [ "$old_user_exists" = "0" ]; then
        # set the permissions of all "old" files and folder to the new user
        find / -user $old_user_id -exec chown -h ${APP_USER} {} \; || true
    fi
fi