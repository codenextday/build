# We don't automatically set up rules to build executables for both
# TARGET_ARCH and TARGET_2ND_ARCH.
# By default, an executable is built for TARGET_ARCH.
# To build it for TARGET_2ND_ARCH in a 64bit product, use "LOCAL_MULTILIB := 32"
# To build it for both set LOCAL_MULTILIB := both and specify
# LOCAL_MODULE_PATH_32 and LOCAL_MODULE_PATH_64 or LOCAL_MODULE_STEM_32 and
# LOCAL_MODULE_STEM_64

my_prefix := TARGET_

my_skip_non_preferred_arch :=

ifeq ($(strip $(LOCAL_MODULE_CLASS)),)
LOCAL_MODULE_CLASS := EXECUTABLES
endif
ifeq ($(strip $(LOCAL_MODULE_SUFFIX)),)
LOCAL_MODULE_SUFFIX := $(TARGET_EXECUTABLE_SUFFIX)
endif


$(call target-executable-hook)

skip_build_from_source :=
ifdef LOCAL_PREBUILT_MODULE_FILE
ifeq (,$(call if-build-from-source,$(LOCAL_MODULE),$(LOCAL_PATH)))
include $(BUILD_SYSTEM)/prebuilt_internal.mk
skip_build_from_source := true
endif
endif

ifndef skip_build_from_source

include $(BUILD_SYSTEM)/dynamic_binary.mk

# Check for statically linked libc
ifneq ($(LOCAL_FORCE_STATIC_EXECUTABLE),true)
ifneq ($(filter $(my_static_libraries),libc),)
$(error $(LOCAL_PATH): $(LOCAL_MODULE) is statically linking libc to dynamic executable, please remove libc from static libs or set LOCAL_FORCE_STATIC_EXECUTABLE := true)
endif
endif

# Define PRIVATE_ variables from global vars
my_target_global_ld_dirs := $(TARGET_GLOBAL_LD_DIRS)
ifeq ($(LOCAL_NO_LIBGCC),true)
my_target_libgcc :=
else
my_target_libgcc := $(TARGET_LIBGCC)
endif
my_target_libatomic := $(TARGET_LIBATOMIC)

$(linked_module): PRIVATE_TARGET_GLOBAL_LD_DIRS := $(my_target_global_ld_dirs)
$(linked_module): PRIVATE_TARGET_GLOBAL_LDFLAGS := $(my_target_global_ldflags)
$(linked_module): PRIVATE_TARGET_LIBGCC := $(my_target_libgcc)
$(linked_module): PRIVATE_TARGET_LIBATOMIC := $(my_target_libatomic)
$(linked_module): PRIVATE_TARGET_CRTEND_O := $(my_target_crtend_o)
$(linked_module): PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES := $($(LOCAL_2ND_ARCH_VAR_PREFIX)TARGET_OUT_INTERMEDIATE_LIBRARIES)
$(linked_module): PRIVATE_POST_LINK_CMD := $(LOCAL_POST_LINK_CMD)

#$(info *** so deps: $(my_system_shared_libraries))
ifeq ($(LOCAL_FORCE_STATIC_EXECUTABLE),true)
$(linked_module): $(all_objects) $(all_libraries)
	$(transform-o-to-static-executable)
	$(PRIVATE_POST_LINK_CMD)
else
$(linked_module): $(all_objects) $(all_libraries)
	@echo "link module " $^
	$(transform-o-to-executable)
	$(PRIVATE_POST_LINK_CMD)
endif

endif  # skip_build_from_source