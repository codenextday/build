#
# Copyright (C) 2006 The Android Open Source Project
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


TARGET_TOOLCHAIN_ROOT := prebuilts/gcc/arm-linux-gnueabihf
TARGET_TOOLS_PREFIX := $(TARGET_TOOLCHAIN_ROOT)/bin/arm-linux-gnueabihf-

TARGET_CC := $(TARGET_TOOLS_PREFIX)gcc
TARGET_CXX := $(TARGET_TOOLS_PREFIX)g++
TARGET_AR := $(TARGET_TOOLS_PREFIX)ar
TARGET_OBJCOPY := $(TARGET_TOOLS_PREFIX)objcopy
TARGET_LD := $(TARGET_TOOLS_PREFIX)ld
TARGET_READELF := $(TARGET_TOOLS_PREFIX)readelf
TARGET_STRIP := $(TARGET_TOOLS_PREFIX)strip
TARGET_NM := $(TARGET_TOOLS_PREFIX)nm


TARGET_NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined

TARGET_arm_CFLAGS :=    -O2 \
                        -fomit-frame-pointer \
                        -fstrict-aliasing    \
                        -funswitch-loops

# Modules can choose to compile some source as thumb.
TARGET_thumb_CFLAGS :=  -mthumb \
                        -Os \
                        -fomit-frame-pointer \
                        -fno-strict-aliasing

# Set FORCE_ARM_DEBUGGING to "true" in your buildspec.mk
# or in your environment to force a full arm build, even for
# files that are normally built as thumb; this can make
# gdb debugging easier.  Don't forget to do a clean build.
#
# NOTE: if you try to build a -O0 build with thumb, several
# of the libraries (libpv, libwebcore, libkjs) need to be built
# with -mlong-calls.  When built at -O0, those libraries are
# too big for a thumb "BL <label>" to go from one end to the other.
ifeq ($(FORCE_ARM_DEBUGGING),true)
  TARGET_arm_CFLAGS += -fno-omit-frame-pointer -fno-strict-aliasing
  TARGET_thumb_CFLAGS += -marm -fno-omit-frame-pointer
endif

TARGET_GLOBAL_CFLAGS += \
			-msoft-float \
			-ffunction-sections \
			-fdata-sections \
			-funwind-tables \
			-fstack-protector-strong \
			-Wa,--noexecstack \
			-Werror=format-security \
			-D_FORTIFY_SOURCE=2 \
			-fno-short-enums \
			-no-canonical-prefixes \
			-fno-canonical-system-headers \

# The "-Wunused-but-set-variable" option often breaks projects that enable
# "-Wall -Werror" due to a commom idiom "ALOGV(mesg)" where ALOGV is turned
# into no-op in some builds while mesg is defined earlier. So we explicitly
# disable "-Wunused-but-set-variable" here.
ifneq ($(filter 4.6 4.6.% 4.7 4.7.% 4.8 4.9, $(TARGET_GCC_VERSION)),)
TARGET_GLOBAL_CFLAGS += -fno-builtin-sin \
			-fno-strict-volatile-bitfields
endif

# This is to avoid the dreaded warning compiler message:
#   note: the mangling of 'va_list' has changed in GCC 4.4
#
# The fact that the mangling changed does not affect the NDK ABI
# very fortunately (since none of the exposed APIs used va_list
# in their exported C++ functions). Also, GCC 4.5 has already
# removed the warning from the compiler.
#
TARGET_GLOBAL_CFLAGS += -Wno-psabi

TARGET_GLOBAL_LDFLAGS += \
			-Wl,-z,noexecstack \
			-Wl,-z,relro \
			-Wl,-z,now \
			-Wl,--build-id=md5 \
			-Wl,--warn-shared-textrel \
			-Wl,--fatal-warnings \
			-Wl,--icf=safe \
			-Wl,--hash-style=gnu \
			-Wl,--no-undefined-version

TARGET_GLOBAL_CFLAGS += -mthumb-interwork

TARGET_GLOBAL_CPPFLAGS += -fvisibility-inlines-hidden

# More flags/options can be added here
TARGET_RELEASE_CFLAGS := \
			-DNDEBUG \
			-g \
			-Wstrict-aliasing=2 \
			-fgcse-after-reload \
			-frerun-cse-after-loop \
			-frename-registers



## on some hosts, the target cross-compiler is not available so do not run this command
ifneq ($(wildcard $(TARGET_CC)),)
# We compile with the global cflags to ensure that
# any flags which affect libgcc are correctly taken
# into account.
TARGET_LIBGCC := $(shell $(TARGET_CC) \
        $(TARGET_GLOBAL_CFLAGS) -print-libgcc-file-name)
TARGET_LIBATOMIC := $(shell $(TARGET_CC) \
        $(TARGET_GLOBAL_CFLAGS) -print-file-name=libatomic.a)
TARGET_LIBGCOV := $(shell $(TARGET_CC) \
        $(TARGET_GLOBAL_CFLAGS) -print-file-name=libgcov.a)
endif