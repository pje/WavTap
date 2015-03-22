PRODUCT_NAME=WavTap
KEXT_DIR=$$(pwd)
KEXT_BUILD_DIR=$(KEXT_DIR)/Build/UninstalledProducts
BUILD_TYPE=Deployment
INSTALL_DESTINATION=/System/Library/Extensionse

build: $(KEXT_BUILD_DIR)/$(PRODUCT_NAME).kext

$(KEXT_BUILD_DIR)/$(PRODUCT_NAME).kext:
	cd $(KEXT_DIR)
	xcodebuild -project $(KEXT_DIR)/$(PRODUCT_NAME).xcodeproj -target WavTapDriver -configuration $(BUILD_TYPE) clean build

install: $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext

$(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext: build
	sudo cp -rv $(KEXT_BUILD_DIR)/$(PRODUCT_NAME).kext $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext
	sudo chmod -R 700 $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext
	sudo chown -R root:wheel $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext
	sudo kextload -v $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext
	sudo kextutil $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext

uninstall:
	if [[ "$(shell kextstat | grep $(PRODUCT_NAME) | grep -v grep)" ]]; then sudo kextunload /System/Library/Extensions/$(PRODUCT_NAME).kext; fi
	sudo rm -rf $(INSTALL_DESTINATION)/$(PRODUCT_NAME).kext
	sudo rm -rf /Library/Receipts/$(PRODUCT_NAME)*
	sudo rm -rf /var/db/receipts/*$(PRODUCT_NAME).*

clean:
	rm -rf $(KEXT_DIR)/Build

.PHONY: build clean install uninstall
