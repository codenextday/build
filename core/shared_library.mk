my_prefix := TARGET_

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
endif
ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(TARGET_SHLIB_SUFFIX)
endif
ifneq ($(strip $(OVERRIDE_BUILT_MODULE_PATH)),)
$(error $(LOCAL_PATH): Illegal use of OVERRIDE_BUILT_MODULE_PATH)
endif
ifneq ($(strip $(LOCAL_MODULE_STEM)$(LOCAL_BUILT_MODULE_STEM)$(LOCAL_MODULE_STEM_32)$(LOCAL_MODULE_STEM_64)),)
$(error $(LOCAL_PATH): Cannot set module stem for a library)
endif

$(call target-shared-library-hook)

skip_build_from_source :=
ifdef LOCAL_PREBUILT_MODULE_FILE
ifeq (,$(call if-build-from-source,$(LOCAL_MODULE),$(LOCAL_PATH)))
include $(BUILD_SYSTEM)/prebuilt_internal.mk
skip_build_from_source := true
endif
endif

ifndef skip_build_from_source

# Put the built targets of all shared libraries in a common directory
# to simplify the link line.
OVERRIDE_BUILT_MODULE_PATH := $(TARGET_OUT_INTERMEDIATE_LIBRARIES)

include $(BUILD_SYSTEM)/dynamic_binary.mk

# Define PRIVATE_ variables from global vars
my_target_global_ld_dirs := $(TARGET_GLOBAL_LD_DIRS)
ifeq ($(LOCAL_NO_LIBGCC),true)
my_target_libgcc :=
else
my_target_libgcc := $(TARGET_LIBGCC)
endif
my_target_libatomic := $(TARGET_LIBATOMIC)
ifeq ($(LOCAL_NO_CRT),true)
my_target_crtbegin_so_o :=
my_target_crtend_so_o :=
else
my_target_crtbegin_so_o := $(TARGET_CRTBEGIN_SO_O)
my_target_crtend_so_o := $(TARGET_CRTEND_SO_O)
endif
$(linked_module): PRIVATE_TARGET_GLOBAL_LD_DIRS := $(my_target_global_ld_dirs)
$(linked_module): PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)
$(linked_module): PRIVATE_TARGET_LIBGCC := $(my_target_libgcc)
$(linked_module): PRIVATE_TARGET_LIBATOMIC := $(my_target_libatomic)
$(linked_module): PRIVATE_TARGET_CRTBEGIN_SO_O := $(my_target_crtbegin_so_o)
$(linked_module): PRIVATE_TARGET_CRTEND_SO_O := $(my_target_crtend_so_o)

$(linked_module): \
        $(all_objects) \
        $(all_libraries) \
        $(my_target_crtbegin_so_o) \
        $(my_target_crtend_so_o) \
        $(LOCAL_MODULE_MAKEFILE_DEP) \
        $(LOCAL_ADDITIONAL_DEPENDENCIES)
	$(transform-o-to-shared-lib)

endif  # skip_build_from_source

my_module_arch_supported :=

###########################################################
## Copy headers to the install tree
###########################################################
include $(BUILD_COPY_HEADERS)
