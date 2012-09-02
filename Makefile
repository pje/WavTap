SHELL=/bin/sh

ROOT=$$(pwd)
PRODUCT_NAME=WavTap
KEXT_DIR=$(ROOT)/Extension
APP_DIR=$(ROOT)/App
KEXT_BUILD_DIR=$(KEXT_DIR)/Build/UninstalledProducts
APP_BUILD_DIR=$(APP_DIR)/build/UninstalledProducts
APP_INSTALL_DIR=/Applications
CONFIG=Development
SYSTEM_AUDIO_SETUP=/Applications/Utilities/Audio\ MIDI\ Setup.app

build-kext:
	cd $(KEXT_DIR)
	xcodebuild -project $(KEXT_DIR)/WavTap.xcodeproj -target WavTapDriver -configuration $(CONFIG) clean build

build-app:
	cd $(APP_DIR)
	xcodebuild -project $(APP_DIR)/WavTap.xcodeproj -target WavTap -configuration ${CONFIG} clean build

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
	$(APP_DIR)/quit.applescript
	rm -rf /Applications/$(PRODUCT_NAME).app

uninstall-command:
	if [[ -a ~/Library/Services/WavTap.workflow ]]; then rm -rf ~/Library/Services/WavTap.workflow; fi

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

launch-system-audio-setup:
	open $(SYSTEM_AUDIO_SETUP)

build: build-kext build-app

clean: clean-app clean-kext

uninstall: uninstall-command uninstall-app uninstall-kext

install: build uninstall install-kext install-app launch-app
