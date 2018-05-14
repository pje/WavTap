BUILD_TYPE=Deployment

/Library/Audio/Plug-Ins/HAL/WavTap.driver: build
	sudo cp -rv Build/Release/WavTap.driver /Library/Audio/Plug-Ins/HAL/WavTap.driver

build:
	xcodebuild -project WavTapDriver.xcodeproj -target WavTap -configuration $(BUILD_TYPE) clean build

clean:
	xcodebuild -project WavTapDriver.xcodeproj -target WavTap -configuration $(BUILD_TYPE) clean

install: /Library/Audio/Plug-Ins/HAL/WavTap.driver

uninstall:
	sudo rm -rf /Library/Audio/Plug-Ins/HAL/WavTap.driver

reset-core-audio:
	sudo killall coreaudiod

.PHONY: build clean install reset-core-audio uninstall
