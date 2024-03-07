TARGET = iphone:clang:15.6:11.0
PACKAGE_VERSION = 1.0.1
INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BatteryHealthEnabler

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = Preferences
# $(TWEAK_NAME)_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
