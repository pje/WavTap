#!/usr/bin/env bash

PRODUCT_NAME=WavTap
INSTALL_DESTINATION=/System/Library/Extensions

sudo chmod -R 700 "$INSTALL_DESTINATION/$PRODUCT_NAME.kext"
sudo chown -R root:wheel "$INSTALL_DESTINATION/$PRODUCT_NAME.kext"
# sudo kextload -v "$INSTALL_DESTINATION/$PRODUCT_NAME.kext"
# sudo kextutil "$INSTALL_DESTINATION/$PRODUCT_NAME.kext"
