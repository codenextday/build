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

HOST_TOOLCHAIN_PREFIX :=
HOST_CC  := $(HOST_TOOLCHAIN_PREFIX)gcc
HOST_CXX := $(HOST_TOOLCHAIN_PREFIX)g++
HOST_AR  := $(HOST_TOOLCHAIN_PREFIX)ar
HOST_READELF  := $(HOST_TOOLCHAIN_PREFIX)readelf
HOST_NM  := $(HOST_TOOLCHAIN_PREFIX)nm


HOST_GLOBAL_CFLAGS += -m64 -Wa,--noexecstack
HOST_GLOBAL_LDFLAGS += -m64 -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -Wl,--no-undefined-version

ifneq ($(strip $(BUILD_HOST_static)),)
# Statically-linked binaries are desirable for sandboxed environment
HOST_GLOBAL_LDFLAGS += -static
endif # BUILD_HOST_static

HOST_GLOBAL_CFLAGS += -fPIC \
  -no-canonical-prefixes \

HOST_GLOBAL_CFLAGS += -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fstack-protector

# Workaround differences in inttypes.h between host and target.
# See bug 12708004.
HOST_GLOBAL_CFLAGS += -D__STDC_FORMAT_MACROS -D__STDC_CONSTANT_MACROS

HOST_NO_UNDEFINED_LDFLAGS := -Wl,--no-undefined
############################################################
## Macros after this line are shared by the 64-bit config.

# $(1): The file to check
define get-file-size
stat --format "%s" "$(1)" | tr -d '\n'
endef