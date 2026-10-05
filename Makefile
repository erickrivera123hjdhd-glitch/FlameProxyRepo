TARGET := iphone:clang:latest:14.0
ARCHS = arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FlameProxy
FlameProxy_FILES = Tweak.x
FlameProxy_CFLAGS = -fobjc-arc
FlameProxy_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
