.PHONY: build clean install uninstall

PRODUCT_NAME=WavTap
KEXT_DIR=$$(pwd)
KEXT_BUILD_DIR=$(KEXT_DIR)/Build/UninstalledProducts
BUILD_TYPE=Deployment

build:
	cd $(KEXT_DIR)
	xcodebuild -project $(KEXT_DIR)/$(PRODUCT_NAME).xcodeproj -target WavTapDriver -configuration $(BUILD_TYPE) clean build

clean:
	rm -rf $(KEXT_DIR)/Build

install: build
	sudo cp -rv $(KEXT_BUILD_DIR)/$(PRODUCT_NAME).kext /System/Library/Extensions
	sudo chmod -R 700 /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo chown -R root:wheel /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo kextload -v /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo kextutil /System/Library/Extensions/$(PRODUCT_NAME).kext

uninstall:
	if [[ "$(shell kextstat | grep $(PRODUCT_NAME) | grep -v grep)" ]]; then sudo kextunload /System/Library/Extensions/$(PRODUCT_NAME).kext; fi
	sudo rm -rf /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo rm -rf /Library/Receipts/$(PRODUCT_NAME)*
	sudo rm -rf /var/db/receipts/*$(PRODUCT_NAME).*
