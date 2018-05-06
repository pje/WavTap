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
	rm -rf $(APP_DIR)/build/WavTap.build

install: build
	rm -rf $(APP_BUILD_DIR)/WavTap.app/WavTap.app # for some reason XCode is generating a smylink here to the parent .app directory (?!), which causes the next line's `cp` to fail with a circular reference error
	cp -r $(APP_BUILD_DIR)/WavTap.app $(APP_INSTALL_DIR)

launch:
	open $(APP_INSTALL_DIR)/WavTap.app

uninstall:
	osascript -e 'tell application "WavTap"' -e 'quit' -e 'end tell'
	rm -rf /Applications/WavTap.app

.PHONY: build clean uninstall install launch
