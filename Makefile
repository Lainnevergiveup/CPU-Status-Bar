.PHONY: build run clean dist

SPM_TARGET  = cpu-status-bar
APP_NAME    = SysMonitor
BUILD_DIR   = .build
SPM_BIN     = $(BUILD_DIR)/release/$(SPM_TARGET)
APP_BUNDLE  = $(BUILD_DIR)/$(APP_NAME).app
DIST_APP    = $(APP_NAME).app

build:
	swift build -c release
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(SPM_BIN)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	@cp Resources/Info.plist "$(APP_BUNDLE)/Contents/"
	@echo "Built: $(APP_BUNDLE)"

run: build
	open "$(APP_BUNDLE)"

dist: build
	rm -rf "$(DIST_APP)"
	cp -R "$(APP_BUNDLE)" "$(DIST_APP)"
	@echo "Packaged: $(DIST_APP)"

clean:
	rm -rf $(BUILD_DIR) $(DIST_APP)
