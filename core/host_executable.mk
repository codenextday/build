LOCAL_IS_HOST_MODULE := true
my_prefix := HOST_
LOCAL_HOST_PREFIX :=

$(call host-executable-hook)

skip_build_from_source :=
ifdef LOCAL_PREBUILT_MODULE_FILE
ifeq (,$(call if-build-from-source,$(LOCAL_MODULE),$(LOCAL_PATH)))
include $(BUILD_SYSTEM)/prebuilt_internal.mk
skip_build_from_source := true
endif
endif

ifndef skip_build_from_source

include $(BUILD_SYSTEM)/binary.mk


$(LOCAL_BUILT_MODULE): $(all_objects) $(all_libraries)
	$(transform-host-o-to-executable)

endif  # skip_build_from_source
