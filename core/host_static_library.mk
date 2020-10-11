LOCAL_IS_HOST_MODULE := true
my_prefix := HOST_
LOCAL_HOST_PREFIX :=


ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := STATIC_LIBRARIES
endif
ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := .a
endif
ifneq ($(strip $(LOCAL_MODULE_STEM)$(LOCAL_BUILT_MODULE_STEM)),)
$(error $(LOCAL_PATH): Cannot set module stem for a library)
endif
LOCAL_UNINSTALLABLE_MODULE := true

include $(BUILD_SYSTEM)/binary.mk

$(LOCAL_BUILT_MODULE): $(built_whole_libraries)
$(LOCAL_BUILT_MODULE): $(all_objects)
	$(transform-host-o-to-static-lib)

my_module_arch_supported :=

###########################################################
## Copy headers to the install tree
###########################################################
include $(BUILD_COPY_HEADERS)
