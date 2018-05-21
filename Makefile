ROOT=$$(pwd)
DRIVER_DIR=$(ROOT)/Driver
APP_DIR=$(ROOT)/App

build: build-driver build-app

build-driver:
	cd $(DRIVER_DIR) && make build

build-app:
	cd $(APP_DIR) && make build

clean: clean-app clean-driver

clean-driver:
	cd $(DRIVER_DIR) && make clean

clean-app:
	cd $(APP_DIR) && make clean

install: build uninstall install-driver install-app

install-driver:
	cd $(DRIVER_DIR) && make install

install-app:
	cd $(APP_DIR) && make install

launch-app:
	cd $(APP_DIR) && make launch

uninstall: uninstall-app uninstall-driver

uninstall-app:
	cd $(APP_DIR) && make uninstall

uninstall-driver:
	cd $(DRIVER_DIR) && make uninstall

.PHONY: build-driver build-app clean-driver clean-app uninstall-driver uninstall-app install-driver install-app launch-app build clean uninstall install
