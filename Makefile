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

install-command: clean-command build-command
	cp -rv $(COMMAND_BUILD_DIR)/* $(COMMAND_INSTALL_DIR)
