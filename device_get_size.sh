#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

if [ -z "${DEVICE}" ]; then
    echo "❌ Missing required environment variable: ${bold}DEVICE${normal}"
    exit 1;
fi

SIZE_MB=$(df | grep $DEVICE | awk -F ' ' '{print $2}')
# echo $SIZE_MB

echo "DEVICE = ${bold}$DEVICE${normal}"
echo "SIZE_MB = ${bold}$SIZE_MB${normal}"
