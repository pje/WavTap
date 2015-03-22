ROOT=$$(pwd)
KEXT_DIR=$(ROOT)/Extension
APP_DIR=$(ROOT)/App

build: build-kext build-app

build-kext:
	cd $(KEXT_DIR) && make build

build-app:
	cd $(APP_DIR) && make build

clean: clean-app clean-kext

clean-kext:
	cd $(KEXT_DIR) && make clean

clean-app:
	cd $(APP_DIR) && make clean

install: build uninstall install-kext install-app launch-app

install-kext:
	cd $(KEXT_DIR) && make install

install-app:
	cd $(APP_DIR) && make install

launch-app:
	cd $(APP_DIR) && make launch

uninstall: uninstall-app uninstall-kext

uninstall-app:
	cd $(APP_DIR) && make uninstall

uninstall-kext:
	cd $(KEXT_DIR) && make uninstall

.PHONY: build-kext build-app clean-kext clean-app uninstall-kext uninstall-app install-kext install-app launch-app build clean uninstall install
