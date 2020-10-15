###########################################################
## Standard rules for copying files that are prebuilt
##
## Additional inputs from base_rules.make:
## None.
##
###########################################################

ifneq ($(LOCAL_PREBUILT_LIBS),)
$(error dont use LOCAL_PREBUILT_LIBS anymore LOCAL_PATH=$(LOCAL_PATH))
endif
ifneq ($(LOCAL_PREBUILT_EXECUTABLES),)
$(error dont use LOCAL_PREBUILT_EXECUTABLES anymore LOCAL_PATH=$(LOCAL_PATH))
endif
ifneq ($(LOCAL_PREBUILT_JAVA_LIBRARIES),)
$(error dont use LOCAL_PREBUILT_JAVA_LIBRARIES anymore LOCAL_PATH=$(LOCAL_PATH))
endif

# Not much sense to check build prebuilts
LOCAL_DONT_CHECK_MODULE := true
my_prebuilt_src_file := $(LOCAL_PREBUILT_MODULE_FILE)


my_strip_module := $(firstword \
  $(LOCAL_STRIP_MODULE_$($(my_prefix)ARCH)) \
  $(LOCAL_STRIP_MODULE))

ifeq (SHARED_LIBRARIES,$(LOCAL_MODULE_CLASS))
  # Put the built targets of all shared libraries in a common directory
  # to simplify the link line.
  OVERRIDE_BUILT_MODULE_PATH := $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)
  ifeq ($(LOCAL_IS_HOST_MODULE)$(my_strip_module),)
    # Strip but not try to add debuglink
    my_strip_module := no_debuglink
  endif

  ifeq ($(LOCAL_IS_HOST_MODULE)$(my_pack_module_relocations),)
    # Do not pack relocations by default
    my_pack_module_relocations := false
  endif

  ifeq ($(DISABLE_RELOCATION_PACKER),true)
    my_pack_module_relocations := false
  endif
endif

ifneq ($(filter STATIC_LIBRARIES SHARED_LIBRARIES,$(LOCAL_MODULE_CLASS)),)
  prebuilt_module_is_a_library := true
else
  prebuilt_module_is_a_library :=
endif

# Don't install static libraries by default.
ifndef LOCAL_UNINSTALLABLE_MODULE
ifeq (STATIC_LIBRARIES,$(LOCAL_MODULE_CLASS))
  LOCAL_UNINSTALLABLE_MODULE := true
endif
endif


ifneq ($(filter true no_debuglink,$(my_strip_module) $(my_pack_module_relocations)),)
  ifdef LOCAL_IS_HOST_MODULE
    $(error Cannot strip/pack host module LOCAL_PATH=$(LOCAL_PATH))
  endif
  ifeq ($(filter SHARED_LIBRARIES EXECUTABLES,$(LOCAL_MODULE_CLASS)),)
    $(error Can strip/pack only shared libraries or executables LOCAL_PATH=$(LOCAL_PATH))
  endif
  ifneq ($(LOCAL_PREBUILT_STRIP_COMMENTS),)
    $(error Cannot strip/pack scripts LOCAL_PATH=$(LOCAL_PATH))
  endif
  # Set the arch-specific variables to set up the strip/pack rules.
  LOCAL_STRIP_MODULE_$($(my_prefix)ARCH) := $(my_strip_module)
  LOCAL_PACK_MODULE_RELOCATIONS_$($(my_prefix)ARCH) := $(my_pack_module_relocations)
  include $(BUILD_SYSTEM)/dynamic_binary.mk
  built_module := $(linked_module)

else  # my_strip_module and my_pack_module_relocations not true
  include $(BUILD_SYSTEM)/base_rules.mk
  built_module := $(LOCAL_BUILT_MODULE)

ifdef prebuilt_module_is_a_library
export_includes := $(intermediates)/export_includes
$(export_includes): PRIVATE_EXPORT_C_INCLUDE_DIRS := $(LOCAL_EXPORT_C_INCLUDE_DIRS)
$(export_includes) : $(LOCAL_MODULE_MAKEFILE_DEP)
	@echo Export includes file: $< -- $@
	$(hide) mkdir -p $(dir $@) && rm -f $@
ifdef LOCAL_EXPORT_C_INCLUDE_DIRS
	$(hide) for d in $(PRIVATE_EXPORT_C_INCLUDE_DIRS); do \
	        echo "-I $$d" >> $@; \
	        done
else
	$(hide) touch $@
endif

$(LOCAL_BUILT_MODULE) : | $(intermediates)/export_includes
endif  # prebuilt_module_is_a_library

# The real dependency will be added after all Android.mks are loaded and the install paths
# of the shared libraries are determined.
ifdef LOCAL_INSTALLED_MODULE
ifdef LOCAL_SHARED_LIBRARIES
my_shared_libraries := $(LOCAL_SHARED_LIBRARIES)
# Extra shared libraries introduced by LOCAL_CXX_STL.
include $(BUILD_SYSTEM)/cxx_stl_setup.mk
$(my_prefix)DEPENDENCIES_ON_SHARED_LIBRARIES += \
  $(my_register_name):$(LOCAL_INSTALLED_MODULE):$(subst $(space),$(comma),$(my_shared_libraries))

# We also need the LOCAL_BUILT_MODULE dependency,
# since we use -rpath-link which points to the built module's path.
my_built_shared_libraries := \
    $(addprefix $($(my_prefix)OUT_INTERMEDIATE_LIBRARIES)/, \
    $(addsuffix $($(my_prefix)SHLIB_SUFFIX), \
        $(my_shared_libraries)))
$(LOCAL_BUILT_MODULE) : $(my_built_shared_libraries)
endif
endif

# We need to enclose the above export_includes and my_built_shared_libraries in
# "my_strip_module not true" because otherwise the rules are defined in dynamic_binary.mk.
endif  # my_strip_module not true


$(built_module) : $(LOCAL_MODULE_MAKEFILE_DEP) $(LOCAL_ADDITIONAL_DEPENDENCIES)

my_prebuilt_src_file :=
