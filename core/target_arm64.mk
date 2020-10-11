#
# Copyright (C) 2013 The Android Open Source Project
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

TARGET_ARCH_VARIANT := armv8

TARGET_TOOLCHAIN_ROOT := prebuilts/gcc/aarch64-linux-gnu
TARGET_TOOLS_PREFIX := $(TARGET_TOOLCHAIN_ROOT)/bin/aarch64-linux-gnu-

TARGET_CC := $(TARGET_TOOLS_PREFIX)gcc
TARGET_CXX := $(TARGET_TOOLS_PREFIX)g++
TARGET_AR := $(TARGET_TOOLS_PREFIX)ar
TARGET_OBJCOPY := $(TARGET_TOOLS_PREFIX)objcopy
TARGET_LD := $(TARGET_TOOLS_PREFIX)ld
TARGET_READELF := $(TARGET_TOOLS_PREFIX)readelf
TARGET_STRIP := $(TARGET_TOOLS_PREFIX)strip
TARGET_NM := $(TARGET_TOOLS_PREFIX)nm

define transform-shared-lib-to-toc
$(call _gen_toc_command_for_elf,$(1),$(2))
endef

TARGET_NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined

TARGET_GLOBAL_CFLAGS += \
    -fno-strict-aliasing \

TARGET_GLOBAL_CFLAGS += \
			-fstack-protector-strong \
			-ffunction-sections \
			-fdata-sections \
			-funwind-tables \
			-Wa,--noexecstack \
			-Werror=format-security \
			-D_FORTIFY_SOURCE=2 \
			-fno-short-enums \
			-no-canonical-prefixes \
			-fno-canonical-system-headers

# Help catch common 32/64-bit errors.
TARGET_GLOBAL_CFLAGS += \
    -Werror=pointer-to-int-cast \
    -Werror=int-to-pointer-cast \
    -Werror=implicit-function-declaration \

TARGET_GLOBAL_CFLAGS += -fno-strict-volatile-bitfields

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
			-Wl,-maarch64linux \
			-Wl,--hash-style=gnu \
			-Wl,--fix-cortex-a53-843419 \
			-Wl,--no-undefined-version

# Disable transitive dependency library symbol resolving.
TARGET_GLOBAL_LDFLAGS += -Wl,--allow-shlib-undefined

TARGET_GLOBAL_CPPFLAGS += -fvisibility-inlines-hidden

# More flags/options can be added here
TARGET_RELEASE_CFLAGS := \
			-DNDEBUG \
			-O2 -g \
			-Wstrict-aliasing=2 \
			-fgcse-after-reload \
			-frerun-cse-after-loop \
			-frename-registers


TARGET_LIBGCC := $(shell $(TARGET_CC) $(TARGET_GLOBAL_CFLAGS) \
	-print-libgcc-file-name)
TARGET_LIBATOMIC := $(shell $(TARGET_CC) $(TARGET_GLOBAL_CFLAGS) \
	-print-file-name=libatomic.a)
TARGET_LIBGCOV := $(shell $(TARGET_CC) $(TARGET_GLOBAL_CFLAGS) \
	-print-file-name=libgcov.a)
