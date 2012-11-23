.PHONY: build-kext build-app clean-kext clean-app uninstall-kext uninstall-app install-kext install-app launch-app build clean uninstall install

SHELL=/bin/sh
ROOT=$$(pwd)
PRODUCT_NAME=WavTap
KEXT_DIR=$(ROOT)/Extension
APP_DIR=$(ROOT)/App
KEXT_BUILD_DIR=$(KEXT_DIR)/Build/UninstalledProducts
APP_BUILD_DIR=$(APP_DIR)/build/UninstalledProducts
APP_INSTALL_DIR=/Applications
BUILD_TYPE=Deployment

build-kext:
	cd $(KEXT_DIR)
	xcodebuild -project $(KEXT_DIR)/WavTap.xcodeproj -target WavTapDriver -configuration $(BUILD_TYPE) clean build

build-app:
	cd $(APP_DIR)
	xcodebuild -project $(APP_DIR)/WavTap.xcodeproj -target WavTap -configuration ${BUILD_TYPE} clean build

clean-kext:
	rm -rf $(KEXT_DIR)/Build

clean-app:
	rm -rf $(APP_DIR)/build/UninstalledProducts

uninstall-kext:
	if [[ "$(shell kextstat | grep $(PRODUCT_NAME) | grep -v grep)" ]]; then sudo kextunload /System/Library/Extensions/$(PRODUCT_NAME).kext; fi
	sudo rm -rf /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo rm -rf /Library/Receipts/$(PRODUCT_NAME)*
	sudo rm -rf /var/db/receipts/*$(PRODUCT_NAME).*

uninstall-app:
	osascript -e 'tell application "$(PRODUCT_NAME)"' -e 'quit' -e 'end tell'
	rm -rf /Applications/$(PRODUCT_NAME).app

install-kext: build-kext
	sudo cp -rv $(KEXT_BUILD_DIR)/$(PRODUCT_NAME).kext /System/Library/Extensions
	sudo chmod -R 700 /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo chown -R root:wheel /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo kextload -v /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo kextutil /System/Library/Extensions/$(PRODUCT_NAME).kext

install-app: build-app
	cp -r $(APP_BUILD_DIR)/$(PRODUCT_NAME).app $(APP_INSTALL_DIR)

launch-app:
	open $(APP_INSTALL_DIR)/$(PRODUCT_NAME).app

build: build-kext build-app

clean: clean-app clean-kext

uninstall: uninstall-app uninstall-kext

install: build uninstall install-kext install-app launch-app
