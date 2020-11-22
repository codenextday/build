SHELL := /bin/bash

# Absolute path of the present working direcotry.
# This overrides the shell variable $PWD, which does not necessarily points to
# the top of the source tree, for example when "make -C" is used in m/mm/mmm.
PWD := $(shell pwd)

TOP := .
TOPDIR :=

BUILD_SYSTEM := $(TOPDIR)build/core
SCRIPTS_DIR := $(TOPDIR)/scripts

ifneq ($(TOPDIR),)
OUT_DIR := $(TOPDIR)out
else
OUT_DIR := $(CURDIR)/out
endif

PROJ_DIR = $(PWD)

ROOTFS_DIR := $(TARGET_OUT)

TARGET_DEVICE := qserver


export TARGET_OUT
export HOST_OUT

# Targets that provide quick help on the build system.
# include $(BUILD_SYSTEM)/help.mk

# Set up various standard variables based on configuration
# and host information.
include $(BUILD_SYSTEM)/config.mk

TARGT_CROSS_COMPILE :=
BUILD_HOST_EXEXUTABLE :=
BUILD_TARGET_EXEXUTABLE :=

#CLEAR_VARS :=

# Bring in standard build system definitions.
include $(BUILD_SYSTEM)/definitions.mk

include $(BUILD_SYSTEM)/Makefile

include $(BUILD_SYSTEM)/kernel.mk
include $(BUILD_SYSTEM)/bootloader.mk

$(info ">> ALL_MODULES before:"$(ALL_MODULES))
include $(TOPDIR)system/build.mk
$(info ">> ALL_MODULES after:"$(ALL_MODULES))

#include $(BUILD_SYSTEM)/Makefile

subdirs := $(TOP)

FULL_BUILD := true


.PHONY: rootfs
rootfs: $(INSTALLED_ROOTFS_TARGET)


all_target:$(ALL_MODULES)
	@echo ">> target modules"  $^                                                                                                                                                                                                                                      

.PHONY: clean
clean:
	@rm -rf $(OUT_DIR)/* $(OUT_DIR)/..?* $(OUT_DIR)/.[!.]*
	@echo "Entire build directory removed."

.PHONY: showcommands
showcommands:
	@echo >/dev/null

.PHONY: nothing
nothing:
	@echo Successfully read the makefiles.

# Used to force goals to build.  Only use for conditionally defined goals.
.PHONY: FORCE
FORCE:
