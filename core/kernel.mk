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
KERNEL_SRC := $(TOPDIR)kernel


KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL
KERNEL_BUILD_IMAGE := $(KERNEL_OUT)/arch/arm64/boot/Image.gz


KERN_ARCH := arm64
KERN_CROSS_COMPILE := $(BUILD_TOP)/prebuilts/gcc/aarch64-linux-gnu/bin/aarch64-linux-gnu-
KERN_CONFIG := qserver_defconfig

FIT_FILE := $(BUILD_TOP)/script/multi.its





$(KERNEL_BUILD_IMAGE): FORCE
	$(hide) $(MAKE) ARCH=$(KERN_ARCH) CROSS_COMPILE=$(KERN_CROSS_COMPILE) -C $(KERNEL_SRC)  O=$(KERNEL_OUT)  $(KERN_CONFIG)
	$(hide) $(MAKE) ARCH=$(KERN_ARCH) CROSS_COMPILE=$(KERN_CROSS_COMPILE) -C $(KERNEL_SRC)  O=$(KERNEL_OUT)  -j6
	@cp $(KERNEL_SRC)/usr/gen_initramfs.sh $(KERNEL_OUT)/usr

$(MKBOOTFS): $(KERNEL_BUILD_IMAGE)
$(info "target "$(INSTALLED_KERNIMAGE_TARGET))
$(INSTALLED_KERNIMAGE_TARGET): $(MKIMAGE)  $(FIT_FILE) $(KERNEL_BUILD_IMAGE) $(INSTALLED_RAMDISK_TARGET)
	@echo "Made kern image: $@"
	@cp $(KERNEL_BUILD_IMAGE) $(PRODUCT_OUT)/
	@cp $(FIT_FILE) $(PRODUCT_OUT)/multi.its
	#@cp $(INSTALLED_RAMDISK_TARGET) $(KERNEL_OUT)/
	#cd $(KERNEL_OUT) && ./mkimage -f  multi.its uImage && cp uImage $@
	cd $(PRODUCT_OUT) && $(MKIMAGE) -f multi.its uImage
