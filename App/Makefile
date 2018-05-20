APP_DIR=$$(pwd)
APP_BUILD_DIR=$(APP_DIR)/build/UninstalledProducts
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
	sudo cp -r $(APP_BUILD_DIR)/WavTap.app $(APP_INSTALL_DIR)

launch:
	open $(APP_INSTALL_DIR)/WavTap.app

uninstall:
	osascript -e 'tell application "WavTap"' -e 'quit' -e 'end tell'
	sudo rm -rf /Applications/WavTap.app

.PHONY: build clean uninstall install launch
