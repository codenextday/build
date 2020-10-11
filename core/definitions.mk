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

##
## Common build system definitions.  Mostly standard
## commands for building various types of targets, which
## are used by others to construct the final targets.
##

# These are variables we use to collect overall lists
# of things being processed.

# The short names of all of the targets in the system.
# For each element of ALL_MODULES, two other variables
# are defined:
#   $(ALL_MODULES.$(target)).BUILT
#   $(ALL_MODULES.$(target)).INSTALLED
# The BUILT variable contains LOCAL_BUILT_MODULE for that
# target, and the INSTALLED variable contains the LOCAL_INSTALLED_MODULE.
# Some targets may have multiple files listed in the BUILT and INSTALLED
# sub-variables.
ALL_MODULES:=

# Full paths to targets that should be added to the "make droid"
# set of installed targets.
ALL_DEFAULT_INSTALLED_MODULES:=


# Full paths to all prebuilt files that will be copied
# (used to make the dependency on acp)
ALL_PREBUILT:=

# Full path to all files that are made by some tool
ALL_GENERATED_SOURCES:=

# Full path to all asm, C, C++, lex and yacc generated C files.
# These all have an order-only dependency on the copied headers
ALL_C_CPP_ETC_OBJECTS:=

# The list of dynamic binaries that haven't been stripped/compressed/etc.
ALL_ORIGINAL_DYNAMIC_BINARIES:=

# Display names for various build targets
TARGET_DISPLAY := target
HOST_DISPLAY := host
HOST_CROSS_DISPLAY := host cross

###########################################################
## Debugging; prints a variable list to stdout
###########################################################

# $(1): variable name list, not variable values
define print-vars
$(foreach var,$(1), \
  $(info $(var):) \
  $(foreach word,$($(var)), \
    $(info $(space)$(space)$(word)) \
   ) \
 )
endef

###########################################################
## Evaluates to true if the string contains the word true,
## and empty otherwise
## $(1): a var to test
###########################################################

define true-or-empty
$(filter true, $(1))
endef


###########################################################
## Retrieve the directory of the current makefile
## Must be called before including any other makefile!!
###########################################################

# Figure out where we are.
define my-dir
$(strip \
  $(eval LOCAL_MODULE_MAKEFILE := $$(lastword $$(MAKEFILE_LIST))) \
  $(eval LOCAL_MODULE_MAKEFILE_DEP := $(if $(BUILDING_WITH_NINJA),,$$(LOCAL_MODULE_MAKEFILE))) \
  $(if $(filter $(BUILD_SYSTEM)/% $(OUT_DIR)/%,$(LOCAL_MODULE_MAKEFILE)), \
    $(error my-dir must be called before including any other makefile. $(BUILD_SYSTEM) -$(OUT_DIR)- $(LOCAL_MODULE_MAKEFILE)) \
   , \
    $(patsubst %/,%,$(dir $(LOCAL_MODULE_MAKEFILE))) \
   ) \
 )
endef


###########################################################
## Retrieve a list of all makefiles immediately below some directory
###########################################################

define all-makefiles-under
$(sort $(wildcard $(1)/*/build.mk))
endef

###########################################################
## Retrieve a list of all makefiles immediately below your directory
## Must be called before including any other makefile!!
###########################################################

define all-subdir-makefiles
$(call all-makefiles-under,$(call my-dir))
endef

###########################################################
## Look in the named list of directories for makefiles,
## relative to the current directory.
## Must be called before including any other makefile!!
###########################################################

# $(1): List of directories to look for under this directory
define all-named-subdir-makefiles
$(sort $(wildcard $(addsuffix /build.mk, $(addprefix $(call my-dir)/,$(1)))))
endef

###########################################################
## Find all of the directories under the named directories with
## the specified name.
## Meant to be used like:
##    INC_DIRS := $(call all-named-dirs-under,inc,.)
###########################################################

define all-named-dirs-under
$(call find-subdir-files,$(2) -type d -name "$(1)")
endef

###########################################################
## Find all the directories under the current directory that
## haves name that match $(1)
###########################################################

define all-subdir-named-dirs
$(call all-named-dirs-under,$(1),.)
endef

###########################################################
## Find all of the files under the named directories with
## the specified name.
## Meant to be used like:
##    SRC_FILES := $(call all-named-files-under,*.h,src tests)
###########################################################

define all-named-files-under
$(call find-files-in-subdirs,$(LOCAL_PATH),"$(1)",$(2))
endef

###########################################################
## Find all of the files under the current directory with
## the specified name.
###########################################################

define all-subdir-named-files
$(call all-named-files-under,$(1),.)
endef


###########################################################
## Find all of the c files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-c-files-under,src tests)
###########################################################

define all-c-files-under
$(call all-named-files-under,*.c,$(1))
endef

###########################################################
## Find all of the c files from here.  Meant to be used like:
##    SRC_FILES := $(call all-subdir-c-files)
###########################################################

define all-subdir-c-files
$(call all-c-files-under,.)
endef

###########################################################
## Find all of the cpp files under the named directories.
## LOCAL_CPP_EXTENSION is respected if set.
## Meant to be used like:
##    SRC_FILES := $(call all-cpp-files-under,src tests)
###########################################################

define all-cpp-files-under
$(sort $(patsubst ./%,%, \
  $(shell cd $(LOCAL_PATH) ; \
          find -L $(1) -name "*$(or $(LOCAL_CPP_EXTENSION),.cpp)" -and -not -name ".*") \
 ))
endef

###########################################################
## Find all of the cpp files from here.  Meant to be used like:
##    SRC_FILES := $(call all-subdir-cpp-files)
###########################################################

define all-subdir-cpp-files
$(call all-cpp-files-under,.)
endef


###########################################################
## Find all of the S files under the named directories.
## Meant to be used like:
##    SRC_FILES := $(call all-c-files-under,src tests)
###########################################################

define all-S-files-under
$(call all-named-files-under,*.S,$(1))
endef


define find-subdir-files
$(sort $(patsubst ./%,%,$(shell cd $(LOCAL_PATH) ; find -L $(1))))
endef

###########################################################
# find the files in the subdirectory $1 of LOCAL_DIR
# matching pattern $2, filtering out files $3
# e.g.
#     SRC_FILES += $(call find-subdir-subdir-files, \
#                         css, *.cpp, DontWantThis.cpp)
###########################################################

define find-subdir-subdir-files
$(sort $(filter-out $(patsubst %,$(1)/%,$(3)),$(patsubst ./%,%,$(shell cd \
            $(LOCAL_PATH) ; find -L $(1) -maxdepth 1 -name $(2)))))
endef


###########################################################
# Use utility find to find given files in the given subdirs.
# This function uses $(1), instead of LOCAL_PATH as the base.
# $(1): the base dir, relative to the root of the source tree.
# $(2): the file name pattern to be passed to find as "-name".
# $(3): a list of subdirs of the base dir.
# Returns: a list of paths relative to the base dir.
###########################################################

define find-files-in-subdirs
$(sort $(patsubst ./%,%, \
  $(shell cd $(1) ; \
          find -L $(3) -name $(2) -and -not -name ".*") \
 ))
endef

###########################################################
## Scan through each directory of $(1) looking for files
## that match $(2) using $(wildcard).  Useful for seeing if
## a given directory or one of its parents contains
## a particular file.  Returns the first match found,
## starting furthest from the root.
###########################################################

define find-parent-file
$(strip \
  $(eval _fpf := $(sort $(wildcard $(foreach f, $(2), $(strip $(1))/$(f))))) \
  $(if $(_fpf),$(_fpf), \
       $(if $(filter-out ./ .,$(1)), \
             $(call find-parent-file,$(patsubst %/,%,$(dir $(1))),$(2)) \
        ) \
   ) \
)
endef

###########################################################
## Function we can evaluate to introduce a dynamic dependency
###########################################################

define add-dependency
$(1): $(2)
endef

###########################################################
## Reverse order of a list
###########################################################

define reverse-list
$(if $(1),$(call reverse-list,$(wordlist 2,$(words $(1)),$(1)))) $(firstword $(1))
endef

###########################################################
## The intermediates directory.  Where object files go for
## a given target.  We could technically get away without
## the "_intermediates" suffix on the directory, but it's
## nice to be able to grep for that string to find out if
## anyone's abusing the system.
###########################################################

# $(1): target class, like "APPS"
# $(2): target name, like "NotePad"
# $(3): if non-empty, this is a HOST target.
# $(4): if non-empty, force the intermediates to be COMMON
# $(5): if non-empty, force the intermediates to be for the 2nd arch
# $(6): if non-empty, force the intermediates to be for the host cross os
define intermediates-dir-for
$(strip \
    $(eval _idfName := $(strip $(1))) \
    $(if $(_idfName),, \
        $(error $(LOCAL_PATH): Name not defined in call to intermediates-dir-for)) \
    $(eval _idfPrefix := $(if $(strip $(2)),HOST,TARGET)) \
    $(eval _idfIntBase := $($(_idfPrefix)_OUT_COMMON_INTERMEDIATES)) \
    $(_idfIntBase)/$(_idfName)_obj \
)
endef

# Uses LOCAL_MODULE_CLASS, LOCAL_MODULE, and LOCAL_IS_HOST_MODULE
# to determine the intermediates directory.
#
# $(1): if non-empty, force the intermediates to be COMMON
# $(2): if non-empty, force the intermediates to be for the 2nd arch
# $(3): if non-empty, force the intermediates to be for the host cross os
define local-intermediates-dir
$(strip \
    $(if $(strip $(LOCAL_MODULE)),, \
        $(error $(LOCAL_PATH): LOCAL_MODULE not defined before call to local-intermediates-dir)) \
    $(call intermediates-dir-for,$(LOCAL_MODULE),$(LOCAL_IS_HOST_MODULE)) \
)
endef

###########################################################
## Convert "path/to/libXXX.so" to "-lXXX".
## Any "path/to/libXXX.a" elements pass through unchanged.
###########################################################

define normalize-libraries
$(foreach so,$(filter %.so,$(1)),-l$(patsubst lib%.so,%,$(notdir $(so))))\
$(filter-out %.so,$(1))
endef

# TODO: change users to call the common version.
define normalize-host-libraries
$(call normalize-libraries,$(1))
endef

define normalize-target-libraries
$(call normalize-libraries,$(1))
endef

###########################################################
## Returns true if $(1) and $(2) are equal.  Returns
## the empty string if they are not equal.
###########################################################
define streq
$(strip $(if $(strip $(1)),\
  $(if $(strip $(2)),\
    $(if $(filter-out __,_$(subst $(strip $(1)),,$(strip $(2)))$(subst $(strip $(2)),,$(strip $(1)))_),,true), \
    ),\
  $(if $(strip $(2)),\
    ,\
    true)\
 ))
endef

###########################################################
## Convert "a b c" into "a:b:c"
###########################################################
define normalize-path-list
$(subst $(space),:,$(strip $(1)))
endef

###########################################################
## Read the word out of a colon-separated list of words.
## This has the same behavior as the built-in function
## $(word n,str).
##
## The individual words may not contain spaces.
##
## $(1): 1 based index
## $(2): value of the form a:b:c...
###########################################################

define word-colon
$(word $(1),$(subst :,$(space),$(2)))
endef

###########################################################
## Convert "a=b c= d e = f" into "a=b c=d e=f"
##
## $(1): list to collapse
## $(2): if set, separator word; usually "=", ":", or ":="
##       Defaults to "=" if not set.
###########################################################

define collapse-pairs
$(eval _cpSEP := $(strip $(if $(2),$(2),=)))\
$(subst $(space)$(_cpSEP)$(space),$(_cpSEP),$(strip \
    $(subst $(_cpSEP), $(_cpSEP) ,$(1))))
endef



###########################################################
## Append a leaf to a base path.  Properly deals with
## base paths ending in /.
##
## $(1): base path
## $(2): leaf path
###########################################################

define append-path
$(subst //,/,$(1)/$(2))
endef


###########################################################
## Output the command lines, or not
###########################################################

ifeq ($(strip $(SHOW_COMMANDS)),)
define pretty
@echo $1
endef
else
define pretty
endef
endif

###########################################################
## Commands for munging the dependency files the compiler generates
###########################################################
# $(1): the input .d file
# $(2): the output .P file
define transform-d-to-p-args
$(hide) cp $(1) $(2); \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
		-e '/^$$/ d' -e 's/$$/ :/' < $(1) >> $(2); \
	rm -f $(1)
endef

define transform-d-to-p
$(call transform-d-to-p-args,$(@:%.o=%.d),$(@:%.o=%.P))
endef

###########################################################
## Commands for including the dependency files the compiler generates
###########################################################
# $(1): the .P file
# $(2): the main build target
ifeq ($(BUILDING_WITH_NINJA),true)
define include-depfile
$(eval $(2) : .KATI_DEPFILE := $1)
endef
else
define include-depfile
$(eval -include $1)
endef
endif

# $(1): object files
define include-depfiles-for-objs
$(foreach obj, $(1), $(call include-depfile, $(obj:%.o=%.P), $(obj)))
endef



###########################################################
## Commands for running gcc to compile a C++ file
###########################################################

define transform-cpp-to-o
@echo "target $(PRIVATE_ARM_MODE) C++: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(hide) $(RELATIVE_PWD) $(PRIVATE_CXX) \
	$(addprefix -I , $(PRIVATE_C_INCLUDES)) \
	$(shell cat $(PRIVATE_IMPORT_INCLUDES)) \
	$(addprefix -isystem ,\
	    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	        $(filter-out $(PRIVATE_C_INCLUDES), \
	            $(PRIVATE_TARGET_PROJECT_INCLUDES) \
	            $(PRIVATE_TARGET_C_INCLUDES)))) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_TARGET_GLOBAL_CFLAGS) \
	    $(PRIVATE_TARGET_GLOBAL_CPPFLAGS) \
	    $(PRIVATE_ARM_CFLAGS) \
	 ) \
	$(PRIVATE_RTTI_FLAG) \
	$(PRIVATE_CFLAGS) \
	$(PRIVATE_CPPFLAGS) \
	$(PRIVATE_DEBUG_CFLAGS) \
	$(PRIVATE_CFLAGS_NO_OVERRIDE) \
	$(PRIVATE_CPPFLAGS_NO_OVERRIDE) \
	-MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
$(transform-d-to-p)
endef


###########################################################
## Commands for running gcc to compile a C file
###########################################################

# $(1): extra flags
define transform-c-or-s-to-o-no-deps
@mkdir -p $(dir $@)
$(hide) $(RELATIVE_PWD) $(PRIVATE_CC) \
	$(addprefix -I , $(PRIVATE_C_INCLUDES)) \
	$(shell cat $(PRIVATE_IMPORT_INCLUDES)) \
	$(addprefix -isystem ,\
	    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	        $(filter-out $(PRIVATE_C_INCLUDES), \
	            $(PRIVATE_TARGET_PROJECT_INCLUDES) \
	            $(PRIVATE_TARGET_C_INCLUDES)))) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_TARGET_GLOBAL_CFLAGS) \
	    $(PRIVATE_TARGET_GLOBAL_CONLYFLAGS) \
	    $(PRIVATE_ARM_CFLAGS) \
	 ) \
	 $(1) \
	-MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

define transform-c-to-o-no-deps
@echo "target $(PRIVATE_ARM_MODE) C: $(PRIVATE_MODULE) <= $<"
$(call transform-c-or-s-to-o-no-deps, \
    $(PRIVATE_CFLAGS) \
    $(PRIVATE_CONLYFLAGS) \
    $(PRIVATE_DEBUG_CFLAGS) \
    $(PRIVATE_CFLAGS_NO_OVERRIDE))
endef

define transform-s-to-o-no-deps
@echo "target asm: $(PRIVATE_MODULE) <= $<"
$(call transform-c-or-s-to-o-no-deps, $(PRIVATE_ASFLAGS))
endef

define transform-c-to-o
$(transform-c-to-o-no-deps)
$(transform-d-to-p)
endef

define transform-s-to-o
$(transform-s-to-o-no-deps)
$(transform-d-to-p)
endef

# YASM compilation
define transform-asm-to-o
@mkdir -p $(dir $@)
$(hide) $(YASM) \
    $(addprefix -I , $(PRIVATE_C_INCLUDES)) \
    $(TARGET_GLOBAL_YASM_FLAGS) \
    $(PRIVATE_ASFLAGS) \
    -o $@ $<
endef

###########################################################
## Commands for running gcc to compile a host C++ file
###########################################################

define transform-host-cpp-to-o
@echo "$($(PRIVATE_PREFIX)DISPLAY) C++: $(PRIVATE_MODULE) <= $<"
@mkdir -p $(dir $@)
$(hide) $(RELATIVE_PWD) $(PRIVATE_CXX) \
	$(addprefix -I , $(PRIVATE_C_INCLUDES)) \
	$(shell cat $(PRIVATE_IMPORT_INCLUDES)) \
	$(addprefix -isystem ,\
	    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	        $(filter-out $(PRIVATE_C_INCLUDES), \
	            $($(PRIVATE_PREFIX)PROJECT_INCLUDES) \
	            $(PRIVATE_HOST_C_INCLUDES)))) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_HOST_GLOBAL_CFLAGS) \
	    $(PRIVATE_HOST_GLOBAL_CPPFLAGS) \
	 ) \
	$(PRIVATE_CFLAGS) \
	$(PRIVATE_CPPFLAGS) \
	$(PRIVATE_DEBUG_CFLAGS) \
	$(PRIVATE_CFLAGS_NO_OVERRIDE) \
	$(PRIVATE_CPPFLAGS_NO_OVERRIDE) \
	-MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
$(transform-d-to-p)
endef


###########################################################
## Commands for running gcc to compile a host C file
###########################################################

# $(1): extra flags
define transform-host-c-or-s-to-o-no-deps
@mkdir -p $(dir $@)
$(hide) $(RELATIVE_PWD) $(PRIVATE_CC) \
	$(addprefix -I , $(PRIVATE_C_INCLUDES)) \
	$(shell cat $(PRIVATE_IMPORT_INCLUDES)) \
	$(addprefix -isystem ,\
	    $(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	        $(filter-out $(PRIVATE_C_INCLUDES), \
	            $($(PRIVATE_PREFIX)PROJECT_INCLUDES) \
	            $(PRIVATE_HOST_C_INCLUDES)))) \
	-c \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	    $(PRIVATE_HOST_GLOBAL_CFLAGS) \
	    $(PRIVATE_HOST_GLOBAL_CONLYFLAGS) \
	 ) \
	$(1) \
	$(PRIVATE_CFLAGS_NO_OVERRIDE) \
	-MD -MF $(patsubst %.o,%.d,$@) -o $@ $<
endef

define transform-host-c-to-o-no-deps
@echo "$($(PRIVATE_PREFIX)DISPLAY) C: $(PRIVATE_MODULE) <= $<"
$(call transform-host-c-or-s-to-o-no-deps, $(PRIVATE_CFLAGS) $(PRIVATE_CONLYFLAGS) $(PRIVATE_DEBUG_CFLAGS))
endef

define transform-host-s-to-o-no-deps
@echo "$($(PRIVATE_PREFIX)DISPLAY) asm: $(PRIVATE_MODULE) <= $<"
$(call transform-host-c-or-s-to-o-no-deps, $(PRIVATE_ASFLAGS))
endef

define transform-host-c-to-o
$(transform-host-c-to-o-no-deps)
$(transform-d-to-p)
endef

define transform-host-s-to-o
$(transform-host-s-to-o-no-deps)
$(transform-d-to-p)
endef

 

###########################################################
## Rules to compile a single C/C++ source with ../ in the path
###########################################################
# Replace "../" in object paths with $(DOTDOT_REPLACEMENT).
DOTDOT_REPLACEMENT := dotdot/

## Rule to compile a C++ source file with ../ in the path.
## Must be called with $(eval).
# $(1): the C++ source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-cpp-file
o := $(intermediates)/$(patsubst %$(LOCAL_CPP_EXTENSION),%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)cpp-to-o)
$$(call include-depfiles-for-objs, $$(o))
$(3) += $$(o)
endef

## Rule to compile a C source file with ../ in the path.
## Must be called with $(eval).
# $(1): the C source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-c-file
o := $(intermediates)/$(patsubst %.c,%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)c-to-o)
$$(call include-depfiles-for-objs, $$(o))
$(3) += $$(o)
endef

## Rule to compile a .S source file with ../ in the path.
## Must be called with $(eval).
# $(1): the .S source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-s-file
o := $(intermediates)/$(patsubst %.S,%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)s-to-o)
$$(call include-depfiles-for-objs, $$(o))
$(3) += $$(o)
endef

## Rule to compile a .s source file with ../ in the path.
## Must be called with $(eval).
# $(1): the .s source file in LOCAL_SRC_FILES.
# $(2): the additional dependencies.
# $(3): the variable name to collect the output object file.
define compile-dotdot-s-file-no-deps
o := $(intermediates)/$(patsubst %.s,%.o,$(subst ../,$(DOTDOT_REPLACEMENT),$(1)))
$$(o) : $(TOPDIR)$(LOCAL_PATH)/$(1) $(2)
	$$(transform-$$(PRIVATE_HOST)s-to-o-no-deps)
$(3) += $$(o)
endef


###########################################################
## Commands for running host ar
###########################################################

# $(1): the full path of the source static library.
define _extract-and-include-single-host-whole-static-lib
$(hide) ldir=$(PRIVATE_INTERMEDIATES_DIR)/WHOLE/$(basename $(notdir $(1)))_objs;\
    rm -rf $$ldir; \
    mkdir -p $$ldir; \
    cp $(1) $$ldir; \
    lib_to_include=$$ldir/$(notdir $(1)); \
    filelist=; \
    subdir=0; \
    for f in `$($(PRIVATE_PREFIX)AR) t $(1) | \grep '\.o$$'`; do \
        if [ -e $$ldir/$$f ]; then \
           mkdir $$ldir/$$subdir; \
           ext=$$subdir/; \
           subdir=$$((subdir+1)); \
           $($(PRIVATE_PREFIX)AR) m $$lib_to_include $$f; \
        else \
           ext=; \
        fi; \
        $($(PRIVATE_PREFIX)AR) p $$lib_to_include $$f > $$ldir/$$ext$$f; \
        filelist="$$filelist $$ldir/$$ext$$f"; \
    done ; \
    $($(PRIVATE_PREFIX)AR) $($(PRIVATE_PREFIX)GLOBAL_ARFLAGS) \
        $(PRIVATE_ARFLAGS) $@ $$filelist

endef

define extract-and-include-host-whole-static-libs
$(call extract-and-include-whole-static-libs-first, $(firstword $(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)))
$(foreach lib,$(wordlist 2,999,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)), \
    $(call _extract-and-include-single-host-whole-static-lib, $(lib)))
endef

# Explicitly delete the archive first so that ar doesn't
# try to add to an existing archive.
define transform-host-o-to-static-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) StaticLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
@rm -f $@
$(extract-and-include-host-whole-static-libs)
$(call split-long-arguments,$($(PRIVATE_PREFIX)AR) \
    $($(PRIVATE_PREFIX)GLOBAL_ARFLAGS) \
    $(PRIVATE_ARFLAGS) $@,$(PRIVATE_ALL_OBJECTS))
endef


###########################################################
## Commands for running gcc to link a shared library or package
###########################################################

# ld just seems to be so finicky with command order that we allow
# it to be overriden en-masse see combo/linux-arm.make for an example.
ifneq ($(HOST_CUSTOM_LD_COMMAND),true)
define transform-host-o-to-shared-lib-inner
$(hide) $(PRIVATE_CXX) \
	-Wl,-rpath-link=$($(PRIVATE_PREFIX)OUT_INTERMEDIATE_LIBRARIES) \
	-Wl,-rpath,\$$ORIGIN/../$(notdir $($(PRIVATE_PREFIX)OUT_SHARED_LIBRARIES)) \
	-Wl,-rpath,\$$ORIGIN/$(notdir $($(PRIVATE_PREFIX)OUT_SHARED_LIBRARIES)) \
	-shared -Wl,-soname,$(notdir $@) \
	$($(PRIVATE_PREFIX)GLOBAL_LD_DIRS) \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
	   $(PRIVATE_HOST_GLOBAL_LDFLAGS) \
	) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-host-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-host-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),-lgcov) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_HOST_LIBPROFILE_RT)) \
	$(call normalize-host-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_LDLIBS)
endef
endif

define transform-host-o-to-shared-lib
@echo "$($(PRIVATE_PREFIX)DISPLAY) SharedLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-host-o-to-shared-lib-inner)
endef

define transform-host-o-to-package
@echo "$($(PRIVATE_PREFIX)DISPLAY) Package: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-host-o-to-shared-lib-inner)
endef


###########################################################
## Commands for running gcc to link a shared library or package
###########################################################

define transform-o-to-shared-lib-inner
$(PRIVATE_CXX) \
	-Wl,-soname,$(notdir $@) \
	-Wl,--gc-sections \
	-shared \
	$(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_TARGET_COVERAGE_LIB)) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(PRIVATE_TARGET_LIBGCC) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_LDLIBS)
endef

define transform-o-to-shared-lib
@echo "target SharedLib: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-shared-lib-inner)
endef

###########################################################
## Commands for filtering a target executable or library
###########################################################

ifneq ($(TARGET_BUILD_VARIANT),user)
  TARGET_STRIP_EXTRA = && $(PRIVATE_OBJCOPY) --add-gnu-debuglink=$< $@
  TARGET_STRIP_KEEP_SYMBOLS_EXTRA = --add-gnu-debuglink=$<
endif

define transform-to-stripped
@echo "target Strip: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_STRIP) --strip-all $< -o $@ \
  $(if $(PRIVATE_NO_DEBUGLINK),,$(TARGET_STRIP_EXTRA))
endef

define transform-to-stripped-keep-symbols
@echo "target Strip (keep symbols): $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(hide) $(PRIVATE_OBJCOPY) \
    `$(PRIVATE_READELF) -S $< | awk '/.debug_/ {print "-R " $$2}' | xargs` \
    $(TARGET_STRIP_KEEP_SYMBOLS_EXTRA) $< $@
endef

###########################################################
## Commands for packing a target executable or library
###########################################################

define pack-elf-relocations
@echo "target Pack Relocations: $(PRIVATE_MODULE) ($@)"
$(copy-file-to-target-with-cp)
$(hide) $(RELOCATION_PACKER) $@
endef

###########################################################
## Commands for running gcc to link an executable
###########################################################

define transform-o-to-executable-inner
$(hide) $(PRIVATE_CXX) -pie \
	-Bdynamic \
	-Wl,--gc-sections \
	-Wl,-z,nocopyreloc \
	$(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
	-Wl,-rpath-link=$(PRIVATE_TARGET_OUT_INTERMEDIATE_LIBRARIES) \
	$(PRIVATE_TARGET_CRTBEGIN_DYNAMIC_O) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_TARGET_COVERAGE_LIB)) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(PRIVATE_TARGET_LIBGCC) \
	$(call normalize-target-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-o $@ \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_TARGET_CRTEND_O) \
	$(PRIVATE_LDLIBS)
endef

define transform-o-to-executable
@mkdir -p $(dir $@)
$(transform-o-to-executable-inner)
endef


###########################################################
## Commands for linking a static executable. In practice,
## we only use this on arm, so the other platforms don't
## have transform-o-to-static-executable defined.
## Clang driver needs -static to create static executable.
## However, bionic/linker uses -shared to overwrite.
## Linker for x86 targets does not allow coexistance of -static and -shared,
## so we add -static only if -shared is not used.
###########################################################

define transform-o-to-static-executable-inner
$(hide) $(PRIVATE_CXX) \
	-Bstatic \
	$(if $(filter $(PRIVATE_LDFLAGS),-shared),,-static) \
	-Wl,--gc-sections \
	-o $@ \
	$(PRIVATE_TARGET_GLOBAL_LD_DIRS) \
	$(PRIVATE_TARGET_CRTBEGIN_STATIC_O) \
	$(PRIVATE_TARGET_GLOBAL_LDFLAGS) \
	$(PRIVATE_LDFLAGS) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-target-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(call normalize-target-libraries,$(filter-out %libcompiler_rt.a,$(filter-out %libc_nomalloc.a,$(filter-out %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))))) \
	-Wl,--start-group \
	$(call normalize-target-libraries,$(filter %libc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
	$(call normalize-target-libraries,$(filter %libc_nomalloc.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_TARGET_COVERAGE_LIB)) \
	$(PRIVATE_TARGET_LIBATOMIC) \
	$(call normalize-target-libraries,$(filter %libcompiler_rt.a,$(PRIVATE_ALL_STATIC_LIBRARIES))) \
	$(PRIVATE_TARGET_LIBGCC) \
	-Wl,--end-group \
	$(PRIVATE_TARGET_CRTEND_O)
endef

define transform-o-to-static-executable
@echo "target StaticExecutable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-o-to-static-executable-inner)
endef


###########################################################
## Commands for running gcc to link a host executable
###########################################################
ifdef BUILD_HOST_static
HOST_FPIE_FLAGS :=
else
HOST_FPIE_FLAGS := -pie
# Force the correct entry point to workaround a bug in binutils that manifests with -pie
ifeq ($(HOST_CROSS_OS),windows)
HOST_CROSS_FPIE_FLAGS += -Wl,-e_mainCRTStartup
endif
endif

ifneq ($(HOST_CUSTOM_LD_COMMAND),true)
define transform-host-o-to-executable-inner
$(hide) $(PRIVATE_CXX) \
	$(PRIVATE_ALL_OBJECTS) \
	-Wl,--whole-archive \
	$(call normalize-host-libraries,$(PRIVATE_ALL_WHOLE_STATIC_LIBRARIES)) \
	-Wl,--no-whole-archive \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--start-group) \
	$(call normalize-host-libraries,$(PRIVATE_ALL_STATIC_LIBRARIES)) \
	$(if $(PRIVATE_GROUP_STATIC_LIBRARIES),-Wl$(comma)--end-group) \
	$(if $(filter true,$(NATIVE_COVERAGE)),-lgcov) \
	$(if $(filter true,$(NATIVE_COVERAGE)),$(PRIVATE_HOST_LIBPROFILE_RT)) \
	$(call normalize-host-libraries,$(PRIVATE_ALL_SHARED_LIBRARIES)) \
	-Wl,-rpath-link=$($(PRIVATE_PREFIX)OUT_INTERMEDIATE_LIBRARIES) \
	-Wl,-rpath,\$$ORIGIN/../$(notdir $($(PRIVATE_PREFIX)OUT_SHARED_LIBRARIES)) \
	-Wl,-rpath,\$$ORIGIN/$(notdir $($(PRIVATE_PREFIX)OUT_SHARED_LIBRARIES)) \
	$($(PRIVATE_PREFIX)GLOBAL_LD_DIRS) \
	$(if $(PRIVATE_NO_DEFAULT_COMPILER_FLAGS),, \
		$(PRIVATE_HOST_GLOBAL_LDFLAGS) \
	) \
	$(PRIVATE_LDFLAGS) \
	-o $@ \
	$(PRIVATE_LDLIBS)
endef
endif

define transform-host-o-to-executable
@echo "$($(PRIVATE_PREFIX)DISPLAY) Executable: $(PRIVATE_MODULE) ($@)"
@mkdir -p $(dir $@)
$(transform-host-o-to-executable-inner)
endef


# Moves $1.tmp to $1 if necessary. This is designed to be used with
# .KATI_RESTAT. For kati, this function doesn't update the timestamp
# of $1 when $1.tmp is identical to $1 so that ninja won't rebuild
# targets which depend on $1. For GNU make, this function simply
# copies $1.tmp to $1.
ifeq ($(BUILDING_WITH_NINJA),true)
define commit-change-for-toc
$(hide) if cmp -s $1.tmp $1 ; then \
 rm $1.tmp ; \
else \
 mv $1.tmp $1 ; \
fi
endef
else
define commit-change-for-toc
@# make doesn't support restat. We always update .toc files so the dependents will always be updated too.
$(hide) mv $1.tmp $1
endef
endif

###########################################################
## Commands for copying files
###########################################################

# Define a rule to copy a header.  Used via $(eval) by copy_headers.make.
# $(1): source header
# $(2): destination header
define copy-one-header
$(2): $(1)
	@echo "Header: $$@"
	$$(copy-file-to-new-target-with-cp)
endef

# Define a rule to copy a file.  For use via $(eval).
# $(1): source file
# $(2): destination file
define copy-one-file
$(2): $(1)
	@echo "Copy: $$@"
	$$(copy-file-to-target-with-cp)
endef

# Copies many files.
# $(1): The files to copy.  Each entry is a ':' separated src:dst pair
# Evaluates to the list of the dst files (ie suitable for a dependency list)
define copy-many-files
$(foreach f, $(1), $(strip \
    $(eval _cmf_tuple := $(subst :, ,$(f))) \
    $(eval _cmf_src := $(word 1,$(_cmf_tuple))) \
    $(eval _cmf_dest := $(word 2,$(_cmf_tuple))) \
    $(eval $(call copy-one-file,$(_cmf_src),$(_cmf_dest))) \
    $(_cmf_dest)))
endef


# The -t option to acp and the -p option to cp is
# required for OSX.  OSX has a ridiculous restriction
# where it's an error for a .a file's modification time
# to disagree with an internal timestamp, and this
# macro is used to install .a files (among other things).

# Copy a single file from one place to another,
# preserving permissions and overwriting any existing
# file.
# We disable the "-t" option for acp cannot handle
# high resolution timestamp correctly on file systems like ext4.
# Therefore copy-file-to-target is the same as copy-file-to-new-target.
define copy-file-to-target-with-cp
@mkdir -p $(dir $@)
$(hide) cp -fp $< $@
endef


# The same as copy-file-to-target, but strip out "# comment"-style
# comments (for config files and such).
define copy-file-to-target-strip-comments
@mkdir -p $(dir $@)
$(hide) sed -e 's/#.*$$//' -e 's/[ \t]*$$//' -e '/^$$/d' < $< > $@
endef

# The same as copy-file-to-target, but don't preserve
# the old modification time.
define copy-file-to-new-target
@mkdir -p $(dir $@)
$(hide) $(ACP) -fp $< $@
endef

# The same as copy-file-to-new-target, but use the local
# cp command instead of acp.
define copy-file-to-new-target-with-cp
@mkdir -p $(dir $@)
$(hide) cp -f $< $@
endef

# Copy a prebuilt file to a target location.
define transform-prebuilt-to-target
@echo "$(if $(PRIVATE_IS_HOST_MODULE),host,target) Prebuilt: $(PRIVATE_MODULE) ($@)"
$(copy-file-to-target-with-cp)
endef

# broken:
#	$(foreach file,$^,$(if $(findstring,.a,$(suffix $file)),-l$(file),$(file)))

###########################################################
## Misc notes
###########################################################

#DEPDIR = .deps
#df = $(DEPDIR)/$(*F)

#SRCS = foo.c bar.c ...

#%.o : %.c
#	@$(MAKEDEPEND); \
#	  cp $(df).d $(df).P; \
#	  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
#	      -e '/^$$/ d' -e 's/$$/ :/' < $(df).d >> $(df).P; \
#	  rm -f $(df).d
#	$(COMPILE.c) -o $@ $<

#-include $(SRCS:%.c=$(DEPDIR)/%.P)


#%.o : %.c
#	$(COMPILE.c) -MD -o $@ $<
#	@cp $*.d $*.P; \
#	  sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
#	      -e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
#	  rm -f $*.d
