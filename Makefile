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

clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(SF_SRC_DIR)/build
	rm -rf $(SFB_SRC_DIR)/build

unload:
	sudo kextunload /System/Library/Extensions/Soundflower.kext #1
	sudo kextunload /System/Library/Extensions/Soundflower.kext #2
	# first unload will often fail, but will cause Soundflowers performAudioEngineStop to be called
	# TODO: fix

uninstall:
	sudo rm -rf /System/Library/Extensions/Soundflower.kext
	sudo rm -rf /Library/Receipts/Soundflower*
	sudo rm -rf /var/db/receipts/com.cycling74.soundflower.*
	sudo rm -rf /Applications/Soundflower

install: all uninstall
	sudo cp -rv $(ROOT)/Build/Soundflower.kext /System/Library/Extensions
	sudo kextload -tv /System/Library/Extensions/Soundflower.kext
	sudo touch /System/Library/Extensions

appIcon.icns:
	cd $(SFB_SRC_DIR) && tiff2icns appIcon.tiff appIcon.icns
