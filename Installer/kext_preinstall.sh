#!/usr/bin/env bash

PRODUCT_NAME=WavTap

# if [[ "$(kextstat | grep $PRODUCT_NAME | grep -v grep)" ]]; then sudo kextunload /System/Library/Extensions/$PRODUCT_NAME.kext; fi
sudo rm -rf /System/Library/Extensions/$PRODUCT_NAME.kext
sudo rm -rf /Library/Receipts/$PRODUCT_NAME*
sudo rm -rf /var/db/receipts/*$PRODUCT_NAME.*
