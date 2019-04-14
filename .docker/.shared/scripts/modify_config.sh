#!/bin/sh

CONFIG_FILE=$1
VAR_NAME=$2
VAR_VALUE=$3

sed -i -e "s#${VAR_NAME}#${VAR_VALUE}#" "${CONFIG_FILE}"

# cat "${CONFIG_FILE}"