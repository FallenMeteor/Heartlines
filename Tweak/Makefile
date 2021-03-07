TWEAK_NAME = Heartlines
$(TWEAK_NAME)_FILES = Heartlines.x HLSLocalization.m
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = CoreText EventKit
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = AppSupport MediaRemote
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = Cephei
$(TWEAK_NAME)_LIBRARIES = kitten pddokdo sparkcolourpicker
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
