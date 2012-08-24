#!/usr/bin/env bash

PRODUCT_NAME=WavTap

sudo chmod -R 700 /System/Library/Extensions/$PRODUCT_NAME.kext
sudo chown -R root:wheel /System/Library/Extensions/$PRODUCT_NAME.kext
# sudo kextload -v /System/Library/Extensions/$PRODUCT_NAME.kext
# sudo kextutil /System/Library/Extensions/$PRODUCT_NAME.kext
