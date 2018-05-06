PRODUCT_NAME=WavTap
APP_DIR=$$(pwd)
APP_BUILD_DIR=$(APP_DIR)/build/UninstalledProducts/macosx
APP_INSTALL_DIR=/Applications
BUILD_TYPE=Deployment

build:
	cd $(APP_DIR)
	xcodebuild \
		CONFIGURATION_BUILD_DIR=$(APP_BUILD_DIR) \
		-project $(APP_DIR)/WavTap.xcodeproj \
		-target WavTap \
		-configuration ${BUILD_TYPE} clean build

clean:
	rm -rf $(APP_DIR)/build/UninstalledProducts

install: build
	cp -r $(APP_BUILD_DIR)/$(PRODUCT_NAME).app $(APP_INSTALL_DIR)

launch:
	open $(APP_INSTALL_DIR)/$(PRODUCT_NAME).app

uninstall:
	osascript -e 'tell application "$(PRODUCT_NAME)"' -e 'quit' -e 'end tell'
	rm -rf /Applications/$(PRODUCT_NAME).app

.PHONY: build clean uninstall install launch
