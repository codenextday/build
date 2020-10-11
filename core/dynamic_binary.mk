###########################################################
## Standard rules for building any target-side binaries
## with dynamic linkage (dynamic libraries or executables
## that link with dynamic libraries)
##
## Files including this file must define a rule to build
## the target $(linked_module).
###########################################################

# This constraint means that we can hard-code any $(TARGET_*) variables.
ifdef LOCAL_IS_HOST_MODULE
$(error This file should not be used to build host binaries.  Included by (or near) $(lastword $(filter-out config/%,$(MAKEFILE_LIST))))
endif

# The name of the target file, without any path prepended.
# This duplicates logic from base_rules.mk because we need to
# know its results before base_rules.mk is included.
include $(BUILD_SYSTEM)/configure_module_stem.mk

intermediates := $(call local-intermediates-dir)

# Define the target that is the unmodified output of the linker.
# The basename of this target must be the same as the final output
# binary name, because it's used to set the "soname" in the binary.
# The includer of this file will define a rule to build this target.
linked_module := $(intermediates)/$(my_built_module_stem)


###################################
include $(BUILD_SYSTEM)/binary.mk
###################################



###########################################################
## Strip
###########################################################
strip_input := $(linked_module)
strip_output := $(LOCAL_BUILT_MODULE)

$(strip_output): PRIVATE_STRIP := $(TARGET_STRIP)
$(strip_output): PRIVATE_OBJCOPY := $(TARGET_OBJCOPY)
$(strip_output): PRIVATE_READELF := $(TARGET_READELF)

# Strip the binary
#$(strip_output): $(strip_input) | $(TARGET_STRIP)
#	$(transform-to-stripped)

# A product may be configured to strip everything in some build variants.
# We do the stripping as a post-install command so that LOCAL_BUILT_MODULE
# is still with the symbols and we don't need to clean it (and relink) when
# you switch build variant.
ifneq ($(filter $(STRIP_EVERYTHING_BUILD_VARIANTS),$(TARGET_BUILD_VARIANT)),)
$(LOCAL_INSTALLED_MODULE): PRIVATE_POST_INSTALL_CMD := \
  $($(LOCAL_2ND_ARCH_VAR_PREFIX)TARGET_STRIP) --strip-all $(LOCAL_INSTALLED_MODULE)
endif
# Don't strip the binary, just copy it.  We can't skip this step
# because a copy of the binary must appear at LOCAL_BUILT_MODULE.
#
# If the binary we're copying is acp or a prerequisite,
# use cp(1) instead.

#$(strip_output): $(strip_input)
#	@echo "target Unstripped: $(PRIVATE_MODULE) ($@)"
#	$(copy-file-to-target-with-cp)

$(cleantarget): PRIVATE_CLEAN_FILES += \
    $(linked_module) \
    $(breakpad_output) \
    $(symbolic_output) \
    $(strip_output)
