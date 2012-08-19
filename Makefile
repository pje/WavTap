SHELL=/bin/sh

ROOT=$$(pwd)
PRODUCT_NAME=WavTap
KEXT_DIR=$(ROOT)/Source
APP_DIR=$(ROOT)/SoundflowerBed
KEXT_BUILD_DIR=$(KEXT_DIR)/Build/UninstalledProducts
APP_BUILD_DIR=$(APP_DIR)/build/UninstalledProducts
APP_INSTALL_DIR=/Applications
CONFIG=Development
SYSTEM_AUDIO_SETUP_APP=/Applications/Utilities/Audio\ MIDI\ Setup.app
build-kext:
	cd $(KEXT_DIR)
	xcodebuild -project $(KEXT_DIR)/Soundflower.xcodeproj -target SoundflowerDriver -configuration $(CONFIG) clean build

build-app:
	cd $(APP_DIR)
	xcodebuild -project $(APP_DIR)/WavTap.xcodeproj -target WavTap -configuration ${CONFIG} clean build

clean-kext:
	rm -rf $(KEXT_DIR)/Build

clean-app:
	rm -rf $(APP_BUILD_DIR)

uninstall-kext:
	if [[ "$(shell kextstat | grep $(PRODUCT_NAME) | grep -v grep)" ]]; then sudo kextunload /System/Library/Extensions/$(PRODUCT_NAME).kext; fi
	sudo rm -rf /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo rm -rf /Library/Receipts/$(PRODUCT_NAME)*
	sudo rm -rf /var/db/receipts/*$(PRODUCT_NAME).*

uninstall-app:
	if [[ "$(shell ps aux | grep $(PRODUCT_NAME).app) | grep -v grep" ]]; then ps -axo pid,command,args | grep $(PRODUCT_NAME) | grep -v grep | awk '{ print $$1 }' | xargs kill -9; fi
	rm -rf /Applications/$(PRODUCT_NAME).app

install-kext: build-kext
	sudo cp -rv $(KEXT_BUILD_DIR)/$(PRODUCT_NAME).kext /System/Library/Extensions
	sudo chmod -R 700 /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo chown -R root:wheel /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo kextload -v /System/Library/Extensions/$(PRODUCT_NAME).kext
	sudo kextutil /System/Library/Extensions/$(PRODUCT_NAME).kext

install-app: build-app
	cp -r $(APP_BUILD_DIR)/$(PRODUCT_NAME).app $(APP_INSTALL_DIR)

COMMAND_DIR := $(ROOT)/Command
COMMAND_INSTALL_DIR := $(HOME)/Library/Services
COMMAND_SCRIPT := $(COMMAND_DIR)/service.sh
COMMAND_BUILD_DIR := $(COMMAND_DIR)/Build
COMMAND_PRODUCT_NAME := WavTap
COMMAND_TEMPLATE_PRODUCT := $(COMMAND_DIR)/$(COMMAND_PRODUCT_NAME).workflow
COMMAND_TEMPLATE_PRODUCT_WFLOW := $(COMMAND_DIR)/WavTap.workflow/Contents/document.wflow
COMMAND_TEMPLATE_PRODUCT_WFLOW_LENGTH := $(shell cat $(COMMAND_TEMPLATE_PRODUCT_WFLOW) | wc -l | xargs)
COMMAND_BUILT_WORKFLOW := $(COMMAND_BUILD_DIR)/$(COMMAND_PRODUCT_NAME).workflow
COMMAND_BUILT_WFLOW := $(COMMAND_BUILT_WORKFLOW)/Contents/document.wflow
COMMAND_PHONY_TARGET_LINENO := $(shell cat $(COMMAND_TEMPLATE_PRODUCT_WFLOW) | grep -Eno 'COMMAND_PHONY_TARGET' | grep -Eo '[0-9]+')
COMMAND_HEAD_N_ARG := $(shell expr $(COMMAND_PHONY_TARGET_LINENO) - 1)
COMMAND_TAIL_N_ARG := $(shell expr $(COMMAND_TEMPLATE_PRODUCT_WFLOW_LENGTH) - $(COMMAND_PHONY_TARGET_LINENO))

clean-command:
	rm -rf $(COMMAND_BUILD_DIR)

build-command:
	mkdir -p $(COMMAND_BUILD_DIR)
	cp -r $(COMMAND_TEMPLATE_PRODUCT) $(COMMAND_BUILD_DIR)
	echo "" > $(COMMAND_BUILT_WFLOW)

	head -n $(COMMAND_HEAD_N_ARG) $(COMMAND_TEMPLATE_PRODUCT_WFLOW) >> $(COMMAND_BUILT_WFLOW)
	echo '<string>' >> $(COMMAND_BUILT_WFLOW)
	cat $(COMMAND_SCRIPT) >> $(COMMAND_BUILT_WFLOW)
	echo '</string>' >> $(COMMAND_BUILT_WFLOW)
	tail -n $(COMMAND_TAIL_N_ARG) $(COMMAND_TEMPLATE_PRODUCT_WFLOW) >> $(COMMAND_BUILT_WFLOW)

install-command: build-command
	cp -rv $(COMMAND_BUILD_DIR)/* $(COMMAND_INSTALL_DIR)

uninstall-command:
	rm -rf $(COMMAND_INSTALL_DIR)/$(COMMAND_PRODUCT_NAME).workflow

build: build-kext build-app build-command

clean: clean-command clean-app clean-kext

uninstall: uninstall-command uninstall-app uninstall-kext

install: build uninstall install-kext install-app install-command
	open $(APP_INSTALL_DIR)/$(PRODUCT_NAME).app
	open $(SYSTEM_AUDIO_SETUP_APP)

test:
	open $(APP_INSTALL_DIR)/$(PRODUCT_NAME).app
	open $(SYSTEM_AUDIO_SETUP_APP)
