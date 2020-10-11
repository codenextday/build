# Variables we check:
#     HOST_BUILD_TYPE = { release debug }
#     TARGET_BUILD_TYPE = { release debug }
# and we output a bunch of variables, see the case statement at
# the bottom for the full list
#     OUT_DIR is also set to "out" if it's not already set.
#         this allows you to set it to somewhere else if you like
#     SCAN_EXCLUDE_DIRS is an optional, whitespace separated list of
#         directories that will also be excluded from full checkout tree
#         searches for source or make files, in addition to OUT_DIR.
#         This can be useful if you set OUT_DIR to be a different directory
#         than other outputs of your build system.

# ---------------------------------------------------------------
# Set up configuration for host machine.  We don't do cross-
# compiles except for arm/mips, so the HOST is whatever we are
# running on

UNAME := $(shell uname -sm)

# HOST_OS
ifneq (,$(findstring Linux,$(UNAME)))
  HOST_OS := linux
endif
ifneq (,$(findstring Darwin,$(UNAME)))
  HOST_OS := darwin
endif
ifneq (,$(findstring Macintosh,$(UNAME)))
  HOST_OS := darwin
endif

# BUILD_OS is the real host doing the build.
BUILD_OS := $(HOST_OS)

ifeq ($(HOST_OS),)
$(error Unable to determine HOST_OS from uname -sm: $(UNAME)!)
endif

# HOST_ARCH
ifneq (,$(findstring x86_64,$(UNAME)))
  HOST_ARCH := x86_64
else
ifneq (,$(findstring x86,$(UNAME)))
$(error Building on a 32-bit x86 host is not supported: $(UNAME)!)
endif
endif

BUILD_ARCH := $(HOST_ARCH)

ifeq ($(HOST_ARCH),)
$(error Unable to determine HOST_ARCH from uname -sm: $(UNAME)!)
endif

# the host build defaults to release, and it must be release or debug
ifeq ($(HOST_BUILD_TYPE),)
HOST_BUILD_TYPE := release
endif

ifneq ($(HOST_BUILD_TYPE),release)
ifneq ($(HOST_BUILD_TYPE),debug)
$(error HOST_BUILD_TYPE must be either release or debug, not '$(HOST_BUILD_TYPE)')
endif
endif


# TARGET_COPY_OUT_* are all relative to the staging directory, ie PRODUCT_OUT.
# Define them here so they can be used in product config files.
TARGET_COPY_OUT_SYSTEM := rootfs
TARGET_COPY_OUT_DATA := data
#TARGET_COPY_OUT_ROOT := root
###########################################

# ---------------------------------------------------------------
# Set up configuration for target machine.
# The following must be set:
# 		TARGET_OS = { linux }
# 		TARGET_ARCH = { arm | x86 | mips }

TARGET_OS := linux
# TARGET_ARCH should be set by BoardConfig.mk and will be checked later
ifneq ($(filter %64,$(TARGET_ARCH)),)
TARGET_IS_64_BIT := true
endif

# the target build type defaults to release
ifneq ($(TARGET_BUILD_TYPE),debug)
TARGET_BUILD_TYPE := release
endif

# ---------------------------------------------------------------
# figure out the output directories

ifeq (,$(strip $(OUT_DIR)))
ifeq (,$(strip $(OUT_DIR_COMMON_BASE)))
ifneq ($(TOPDIR),)
OUT_DIR := $(TOPDIR)out
else
OUT_DIR := $(CURDIR)/out
endif
else
OUT_DIR := $(OUT_DIR_COMMON_BASE)/$(notdir $(PWD))
endif
endif

DEBUG_OUT_DIR := $(OUT_DIR)/debug

# Move the host or target under the debug/ directory
# if necessary.
TARGET_OUT_ROOT_release := $(OUT_DIR)/target
TARGET_OUT_ROOT_debug := $(DEBUG_OUT_DIR)/target
TARGET_OUT_ROOT := $(TARGET_OUT_ROOT_$(TARGET_BUILD_TYPE))

HOST_OUT_ROOT_release := $(OUT_DIR)/host
HOST_OUT_ROOT_debug := $(DEBUG_OUT_DIR)/host
HOST_OUT_ROOT := $(HOST_OUT_ROOT_$(HOST_BUILD_TYPE))

# We want to avoid two host bin directories in multilib build.
HOST_OUT_release := $(HOST_OUT_ROOT_release)/$(HOST_OS)-$(HOST_PREBUILT_ARCH)
HOST_OUT_debug := $(HOST_OUT_ROOT_debug)/$(HOST_OS)-$(HOST_PREBUILT_ARCH)
HOST_OUT := $(HOST_OUT_$(HOST_BUILD_TYPE))
# TODO: remove
BUILD_OUT := $(HOST_OUT)

#HOST_CROSS_OUT_release := $(HOST_OUT_ROOT_release)/windows-$(HOST_PREBUILT_ARCH)
#HOST_CROSS_OUT_debug := $(HOST_OUT_ROOT_debug)/windows-$(HOST_PREBUILT_ARCH)
#HOST_CROSS_OUT := $(HOST_CROSS_OUT_$(HOST_BUILD_TYPE))

TARGET_PRODUCT_OUT_ROOT := $(TARGET_OUT_ROOT)/product

TARGET_COMMON_OUT_ROOT := $(TARGET_OUT_ROOT)/common
HOST_COMMON_OUT_ROOT := $(HOST_OUT_ROOT)/common

PRODUCT_OUT := $(TARGET_PRODUCT_OUT_ROOT)/$(TARGET_DEVICE)

#OUT_DOCS := $(TARGET_COMMON_OUT_ROOT)/docs

BUILD_OUT_EXECUTABLES := $(BUILD_OUT)/bin

HOST_OUT_EXECUTABLES := $(HOST_OUT)/bin
HOST_OUT_SHARED_LIBRARIES := $(HOST_OUT)/lib64

HOST_OUT_INTERMEDIATES := $(HOST_OUT)/obj
HOST_OUT_HEADERS := $(HOST_OUT_INTERMEDIATES)/include
HOST_OUT_INTERMEDIATE_LIBRARIES := $(HOST_OUT_INTERMEDIATES)/lib
#HOST_OUT_NOTICE_FILES := $(HOST_OUT_INTERMEDIATES)/NOTICE_FILES
HOST_OUT_COMMON_INTERMEDIATES := $(HOST_COMMON_OUT_ROOT)/obj
#HOST_OUT_FAKE := $(HOST_OUT)/fake_packages


#HOST_OUT_GEN := $(HOST_OUT)/gen
#HOST_OUT_COMMON_GEN := $(HOST_COMMON_OUT_ROOT)/gen

#HOST_CROSS_OUT_GEN := $(HOST_CROSS_OUT)/gen

HOST_LIBRARY_PATH := $(HOST_OUT_SHARED_LIBRARIES)


TARGET_OUT_INTERMEDIATES := $(PRODUCT_OUT)/obj
TARGET_OUT_HEADERS := $(TARGET_OUT_INTERMEDIATES)/include
TARGET_OUT_INTERMEDIATE_LIBRARIES := $(TARGET_OUT_INTERMEDIATES)/lib
TARGET_OUT_COMMON_INTERMEDIATES := $(TARGET_COMMON_OUT_ROOT)/obj

#TARGET_OUT_GEN := $(PRODUCT_OUT)/gen
#TARGET_OUT_COMMON_GEN := $(TARGET_COMMON_OUT_ROOT)/gen

TARGET_OUT := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_SYSTEM)

target_out_shared_libraries_base := $(TARGET_OUT)

TARGET_OUT_EXECUTABLES := $(TARGET_OUT)/bin
TARGET_OUT_OPTIONAL_EXECUTABLES := $(TARGET_OUT)/xbin
ifeq ($(TARGET_IS_64_BIT),true)
# /system/lib always contains 32-bit libraries,
# and /system/lib64 (if present) always contains 64-bit libraries.
TARGET_OUT_SHARED_LIBRARIES := $(target_out_shared_libraries_base)/lib64
else
TARGET_OUT_SHARED_LIBRARIES := $(target_out_shared_libraries_base)/lib
endif
TARGET_OUT_RENDERSCRIPT_BITCODE := $(TARGET_OUT_SHARED_LIBRARIES)
TARGET_OUT_ETC := $(TARGET_OUT)/etc

#TARGET_OUT_SYSTEM_OTHER := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_SYSTEM_OTHER)


TARGET_OUT_DATA := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_DATA)
TARGET_OUT_DATA_EXECUTABLES := $(TARGET_OUT_EXECUTABLES)
TARGET_OUT_DATA_SHARED_LIBRARIES := $(TARGET_OUT_SHARED_LIBRARIES)
TARGET_OUT_DATA_ETC := $(TARGET_OUT_ETC)
TARGET_OUT_CACHE := $(PRODUCT_OUT)/cache
TARGET_OUT_VENDOR := $(PRODUCT_OUT)/$(TARGET_COPY_OUT_VENDOR)
target_out_vendor_shared_libraries_base := $(TARGET_OUT_VENDOR)


ifeq (,$(strip $(DIST_DIR)))
  DIST_DIR := $(OUT_DIR)/dist
endif

ifeq ($(PRINT_BUILD_CONFIG),)
PRINT_BUILD_CONFIG := true
endif
