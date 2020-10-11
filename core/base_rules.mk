#
# Copyright (C) 2008 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

###########################################################
## Common instructions for a generic module.
###########################################################
$(info ">> local mod:"$(LOCAL_MODULE))
LOCAL_MODULE := $(strip $(LOCAL_MODULE))
ifeq ($(LOCAL_MODULE),)
  $(error $(LOCAL_PATH): LOCAL_MODULE is not defined)
endif

LOCAL_IS_HOST_MODULE := $(strip $(LOCAL_IS_HOST_MODULE))
ifdef LOCAL_IS_HOST_MODULE
  ifneq ($(LOCAL_IS_HOST_MODULE),true)
    $(error $(LOCAL_PATH): LOCAL_IS_HOST_MODULE must be "true" or empty, not "$(LOCAL_IS_HOST_MODULE)")
  endif
  my_prefix := HOST_
  my_host := host-
else
  my_prefix := TARGET_
  my_host :=
endif

my_32_64_bit_suffix := $(if $($(my_prefix)IS_64_BIT),64,32)


my_module_path := $(strip $(LOCAL_MODULE_PATH))
ifeq ($(my_module_path),)
  ifdef LOCAL_IS_HOST_MODULE
    partition_tag :=
  else
    partition_tag := 
#$(if $(call should-install-to-system,$(my_module_tags)),,_DATA)
  endif
  install_path_var := $(my_prefix)OUT$(partition_tag)_$(LOCAL_MODULE_CLASS)
  ifeq (true,$(LOCAL_PRIVILEGED_MODULE))
    install_path_var := $(install_path_var)_PRIVILEGED
  endif

  my_module_path := $($(install_path_var))
  ifeq ($(strip $(my_module_path)),)
    $(error $(LOCAL_PATH): unhandled install path "$(install_path_var) for $(LOCAL_MODULE)")
  endif
endif
ifneq ($(strip $(LOCAL_BUILT_MODULE)$(LOCAL_INSTALLED_MODULE)),)
  $(error $(LOCAL_PATH): LOCAL_BUILT_MODULE and LOCAL_INSTALLED_MODULE must not be defined by component makefiles $(LOCAL_BUILT_MODULE) - $(LOCAL_INSTALLED_MODULE) - $(CLEAR_VARS))
endif

my_register_name := $(LOCAL_MODULE)
$(info ">> my_register_name:"$(LOCAL_MODULE))
intermediates := $(call local-intermediates-dir,,,$(my_host_cross))



built_module_path := $(intermediates)
LOCAL_BUILT_MODULE := $(built_module_path)/$(my_built_module_stem)

LOCAL_INSTALLED_MODULE := $(my_module_path)/$(my_installed_module_stem)

# Assemble the list of targets to create PRIVATE_ variables for.
LOCAL_INTERMEDIATE_TARGETS += $(LOCAL_BUILT_MODULE)

###########################################################
## Create .toc files from shared objects to reduce unnecessary rebuild
# .toc files have the list of external dynamic symbols without their addresses.
# As .KATI_RESTAT is specified to .toc files and commit-change-for-toc is used,
# dependent binaries of a .toc file will be rebuilt only when the content of
# the .toc file is changed.
###########################################################
ifndef LOCAL_IS_HOST_MODULE
# Disable .toc optimization for host modules: we may run the host binaries during the build process
# and the libraries' implementation matters.
ifeq ($(LOCAL_MODULE_CLASS),SHARED_LIBRARIES)
LOCAL_INTERMEDIATE_TARGETS += $(LOCAL_BUILT_MODULE).toc
$(LOCAL_BUILT_MODULE).toc: $(LOCAL_BUILT_MODULE)
	$(call transform-shared-lib-to-toc,$<,$@.tmp)
	$(call commit-change-for-toc,$@)

# Kati adds restat=1 to ninja. GNU make does nothing for this.
.KATI_RESTAT: $(LOCAL_BUILT_MODULE).toc
# Build .toc file when using mm, mma, or make $(my_register_name)
$(my_register_name): $(LOCAL_BUILT_MODULE).toc
endif
endif

###########################################################
## make clean- targets
###########################################################
cleantarget := clean-$(my_register_name)
$(cleantarget) : PRIVATE_MODULE := $(my_register_name)
$(cleantarget) : PRIVATE_CLEAN_FILES := \
    $(LOCAL_BUILT_MODULE) \
    $(LOCAL_INSTALLED_MODULE) \
    $(intermediates)
$(cleantarget)::
	@echo "Clean: $(PRIVATE_MODULE)"
	$(hide) rm -rf $(PRIVATE_CLEAN_FILES)

###########################################################
## Common definitions for module.
###########################################################
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_PATH:=$(LOCAL_PATH)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_IS_HOST_MODULE := $(LOCAL_IS_HOST_MODULE)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_HOST:= $(my_host)
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_PREFIX := $(my_prefix)

$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_INTERMEDIATES_DIR:= $(intermediates)

# Tell the module and all of its sub-modules who it is.
$(LOCAL_INTERMEDIATE_TARGETS) : PRIVATE_MODULE:= $(my_register_name)

# Provide a short-hand for building this module.
# We name both BUILT and INSTALLED in case
# LOCAL_UNINSTALLABLE_MODULE is set.
.PHONY: $(my_register_name)
$(my_register_name): $(LOCAL_BUILT_MODULE) $(LOCAL_INSTALLED_MODULE)
	@echo ">> my regitster " $^
# Set up phony targets that covers all modules under the given paths.
# This allows us to build everything in given paths by running mmma/mma.
my_path_components := $(subst /,$(space),$(LOCAL_PATH))
my_path_prefix := MODULES-IN
$(foreach c, $(my_path_components),\
  $(eval my_path_prefix := $(my_path_prefix)-$(c))\
  $(eval .PHONY : $(my_path_prefix))\
  $(eval $(my_path_prefix) : $(my_register_name)))

###########################################################
## Module installation rule
###########################################################

$(LOCAL_INSTALLED_MODULE): $(LOCAL_BUILT_MODULE)
	@echo "Install: $@"
	$(copy-file-to-target-with-cp)


###########################################################
## Register with ALL_MODULES
###########################################################

ALL_MODULES += $(my_register_name)
$(info ">> ALL_MODULES:"$(ALL_MODULES))





