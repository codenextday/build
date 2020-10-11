# This is included by the top-level Makefile.
# It sets up standard variables based on the
# current configuration and platform, which
# are not specific to what is being built.

# Use bash, not whatever shell somebody has installed as /bin/sh
# This is repeated from main.mk, since envsetup.sh runs this file
# directly.
SHELL := /bin/bash
DATE := date
# Utility variables.
empty :=
space := $(empty) $(empty)
comma := ,
# Note that make will eat the newline just before endef.
define newline


endef
# The pound character "#"
define pound
#
endef
# Unfortunately you can't simply define backslash as \ or \\.
backslash := \a
backslash := $(patsubst %a,%,$(backslash))


# ###############################################################
# Build system internal files
# ###############################################################

CLEAR_VARS:= $(BUILD_SYSTEM)/clear_vars.mk
BUILD_HOST_STATIC_LIBRARY:= $(BUILD_SYSTEM)/host_static_library.mk
BUILD_HOST_SHARED_LIBRARY:= $(BUILD_SYSTEM)/host_shared_library.mk
BUILD_STATIC_LIBRARY:= $(BUILD_SYSTEM)/static_library.mk
BUILD_SHARED_LIBRARY:= $(BUILD_SYSTEM)/shared_library.mk
BUILD_EXECUTABLE:= $(BUILD_SYSTEM)/executable.mk
BUILD_HOST_EXECUTABLE:= $(BUILD_SYSTEM)/host_executable.mk
BUILD_COPY_HEADERS := $(BUILD_SYSTEM)/copy_headers.mk



# ###############################################################
# Parse out any modifier targets.
# ###############################################################

# The 'showcommands' goal says to show the full command
# lines being executed, instead of a short message about
# the kind of operation being done.
SHOW_COMMANDS:= $(filter showcommands,$(MAKECMDGOALS))
hide := $(if $(SHOW_COMMANDS),,@)


include $(BUILD_SYSTEM)/envsetup.mk


# Commands to generate .toc file common to ELF .so files.
define _gen_toc_command_for_elf
$(hide) ($($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)READELF) -d $(1) | grep SONAME || echo "No SONAME for $1") > $(2)
$(hide) $($(PRIVATE_2ND_ARCH_VAR_PREFIX)$(PRIVATE_PREFIX)READELF) --dyn-syms $(1) | awk '{$$2=""; $$3=""; print}' >> $(2)
endef

#################################################################
# toolchains
#################################################################

include $(BUILD_SYSTEM)/host_config.mk
include $(BUILD_SYSTEM)/target_arm64.mk


# 
# Tools that are prebuilts for TARGET_BUILD_APPS
#

ACP := cp


# ---------------------------------------------------------------
# Generic tools.


COLUMN:= column

MD5SUM:=md5sum


# ###############################################################
# Set up final options.
# ###############################################################

ifneq ($(COMMON_GLOBAL_CFLAGS)$(COMMON_GLOBAL_CPPFLAGS),)
$(warning COMMON_GLOBAL_C(PP)FLAGS changed)
$(info *** Device configurations are no longer allowed to change the global flags.)
$(info *** COMMON_GLOBAL_CFLAGS: $(COMMON_GLOBAL_CFLAGS))
$(info *** COMMON_GLOBAL_CPPFLAGS: $(COMMON_GLOBAL_CPPFLAGS))
$(error bailing...)
endif

# These can be changed to modify both host and device modules.
COMMON_GLOBAL_CFLAGS:= -fmessage-length=0 -W -Wall -Wno-unused -Winit-self -Wpointer-arith
COMMON_RELEASE_CFLAGS:= 



COMMON_GLOBAL_CPPFLAGS:= -Wsign-promo
COMMON_RELEASE_CPPFLAGS:=

GLOBAL_CFLAGS_NO_OVERRIDE := \
    -Werror=int-to-pointer-cast \
    -Werror=pointer-to-int-cast \

GLOBAL_CPPFLAGS_NO_OVERRIDE :=

# list of flags to turn specific warnings in to errors
TARGET_ERROR_FLAGS := -Werror=return-type -Werror=address -Werror=sequence-point -Werror=date-time

RELATIVE_PWD := PWD=/proc/self/cwd
# Remove this useless prefix from the debug output.
COMMON_GLOBAL_CFLAGS += -fdebug-prefix-map=/proc/self/cwd=

# Allow the C/C++ macros __DATE__ and __TIME__ to be set to the
# build date and time, so that a build may be repeated.
# Write the date and time to a file so that the command line
# doesn't change every time, which would cause ninja to rebuild
# the files.
$(shell mkdir -p $(OUT_DIR) && \
    $(DATE) "+%b %_d %Y" > $(OUT_DIR)/build_c_date.txt && \
    $(DATE) +%T > $(OUT_DIR)/build_c_time.txt)
BUILD_DATETIME_C_DATE := $$(cat $(OUT_DIR)/build_c_date.txt)
BUILD_DATETIME_C_TIME := $$(cat $(OUT_DIR)/build_c_time.txt)
ifeq ($(OVERRIDE_C_DATE_TIME),true)
COMMON_GLOBAL_CFLAGS += -Wno-builtin-macro-redefined -D__DATE__="\"$(BUILD_DATETIME_C_DATE)\"" -D__TIME__=\"$(BUILD_DATETIME_C_TIME)\"
endif

HOST_GLOBAL_CFLAGS += $(COMMON_GLOBAL_CFLAGS)
HOST_RELEASE_CFLAGS += $(COMMON_RELEASE_CFLAGS)

HOST_GLOBAL_CPPFLAGS += $(COMMON_GLOBAL_CPPFLAGS)
HOST_RELEASE_CPPFLAGS += $(COMMON_RELEASE_CPPFLAGS)

TARGET_GLOBAL_CFLAGS += $(COMMON_GLOBAL_CFLAGS)
TARGET_RELEASE_CFLAGS += $(COMMON_RELEASE_CFLAGS)

TARGET_GLOBAL_CPPFLAGS += $(COMMON_GLOBAL_CPPFLAGS)
TARGET_RELEASE_CPPFLAGS += $(COMMON_RELEASE_CPPFLAGS)

HOST_GLOBAL_LD_DIRS += -L$(HOST_OUT_INTERMEDIATE_LIBRARIES)
TARGET_GLOBAL_LD_DIRS += -L$(TARGET_OUT_INTERMEDIATE_LIBRARIES)

HOST_PROJECT_INCLUDES:= $(SRC_HEADERS) $(SRC_HOST_HEADERS) $(HOST_OUT_HEADERS)
TARGET_PROJECT_INCLUDES:= $(SRC_HEADERS) $(TOPDIR)$(call project-path-for,ril)/include \
		$(TARGET_OUT_HEADERS) \
		$(TARGET_DEVICE_KERNEL_HEADERS) $(TARGET_BOARD_KERNEL_HEADERS) \
		$(TARGET_PRODUCT_KERNEL_HEADERS)

# Many host compilers don't support these flags, so we have to make
# sure to only specify them for the target compilers checked in to
# the source tree.
TARGET_GLOBAL_CFLAGS += $(TARGET_ERROR_FLAGS)

HOST_GLOBAL_CFLAGS += $(HOST_RELEASE_CFLAGS)
HOST_GLOBAL_CPPFLAGS += $(HOST_RELEASE_CPPFLAGS)

TARGET_GLOBAL_CFLAGS += $(TARGET_RELEASE_CFLAGS)
TARGET_GLOBAL_CPPFLAGS += $(TARGET_RELEASE_CPPFLAGS)
