export THEOS = /Users/jerix/theos
TARGET := iphone:clang:11.4:9.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = HiOP
HiOP_FILES = main.m AppDelegate.m HiOPEditorViewController.m HiOPCloudSyncManager.m
HiOP_FRAMEWORKS = UIKit Foundation CoreGraphics CloudKit
HiOP_CFLAGS = -fobjc-arc -Wno-deprecated-module-dot-map -Wno-error=deprecated-module-dot-map -Wno-nullability-completeness
HiOP_CODESIGN_FLAGS = -SEntitlements.plist

include $(THEOS_MAKE_PATH)/application.mk
