#!/usr/bin/env bash

PRODUCT_NAME=WavTap
INSTALL_DESTINATION=/System/Library/Extensions

# if [[ "$(kextstat | grep $PRODUCT_NAME | grep -v grep)" ]]; then sudo kextunload "$INSTALL_DESTINATION/$PRODUCT_NAME.kext"; fi
sudo rm -rf "$INSTALL_DESTINATION/$PRODUCT_NAME.kext"
sudo rm -rf /Library/Receipts/$PRODUCT_NAME*
sudo rm -rf /var/db/receipts/*$PRODUCT_NAME.*
