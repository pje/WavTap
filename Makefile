SHELL=/bin/sh

ROOT=$$(pwd)
SF_SRC_DIR=$(ROOT)/Source
SFB_SRC_DIR=$(ROOT)/SoundflowerBed
BUILD_DIR=$(ROOT)/Build
CONFIG="Development"

Soundflower.kext:
	cd $(SF_SRC_DIR)
	xcodebuild -project $(SF_SRC_DIR)/Soundflower.xcodeproj -target SoundflowerDriver -configuration ${CONFIG} clean build

SoundflowerBed:
	cd $(SFB_SRC_DIR)
	xcodebuild -project $(SFB_SRC_DIR)/Soundflowerbed.xcodeproj -target Soundflowerbed -configuration ${CONFIG} clean build

all: Soundflower.kext SoundflowerBed

installer: build
	cd $(ROOT)/Tools && ./installer.rb

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SF_SRC_DIR)/build
	rm -rf $(SFB_SRC_DIR)/build
