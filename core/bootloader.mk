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
TEE_IMAGE := $(BUILD_TOP)/prebuilts/images/tee-pager.bin

UBOOT_ARCH := arm
UBOOT_CROSS_COMPILE := $(BUILD_TOP)/prebuilts/gcc/aarch64-linux-gnu/bin/aarch64-linux-gnu-
UBOOT_CONFIG := qserver_defconfig

UBOOT_SRC := $(TOPDIR)u-boot-202007
UBOOT_OUT := $(TARGET_OUT_INTERMEDIATES)/UBOOT
UBOOT_IMAGE := $(UBOOT_OUT)/u-boot.bin
UBOOT_MKIMG := $(UBOOT_OUT)/tools/mkimage

TFA_CROSS_COMPILE := $(BUILD_TOP)/prebuilts/gcc/aarch64-elf/bin/aarch64-elf-
TFA_SRC := $(TOPDIR)trusted-firmware-a
TFA_OUT := $(TARGET_OUT_INTERMEDIATES)/TFA
FIP_IMAGE := $(TFA_OUT)/qserver/release/fip.bin
FIP_OFFSET := 0x30040

MERGE_TOOL := $(TOPDIR)script/merge.sh

$(UBOOT_IMAGE): FORCE
	@echo "build uboot in " $(PWD)
	$(MAKE) ARCH=$(UBOOT_ARCH) CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) -C $(UBOOT_SRC)  O=$(UBOOT_OUT)  $(UBOOT_CONFIG)
	$(hide) $(MAKE) ARCH=$(UBOOT_ARCH) CROSS_COMPILE=$(UBOOT_CROSS_COMPILE) -C $(UBOOT_SRC)  O=$(UBOOT_OUT)  -j6

$(MKIMAGE): $(UBOOT_IMAGE)
	@echo "mkimage tool"
	@cp $(UBOOT_OUT)/tools/mkimage $@

$(FIP_IMAGE): $(UBOOT_IMAGE) $(TEE_IMAGE)
	@echo "build trusted firmware for FPGA"
	rm -rf $(TFA_OUT)/qserver-mtd
	CROSS_COMPILE=$(TFA_CROSS_COMPILE) make -C $(TFA_SRC) DEBUG=0 USE_COHERENT_MEM=0 CTX_INCLUDE_AARCH32_REGS=0 HW_ASSISTED_COHERENCY=1 ERROR_DEPRECATED=1 LOAD_IMAGE_V2=1 BOOT_DEVICE=MTD BL33=$(UBOOT_IMAGE) PLAT=qserver BUILD_BASE=$(TFA_OUT)  SPD=opteed BL32=$(TEE_IMAGE) fip  all
	mv $(TFA_OUT)/qserver $(TFA_OUT)/qserver-mtd
	@echo "build trusted firmware for VDK"
	CROSS_COMPILE=$(TFA_CROSS_COMPILE) make -C $(TFA_SRC) FIP_OFFSET=$(FIP_OFFSET) USE_COHERENT_MEM=0 CTX_INCLUDE_AARCH32_REGS=0 HW_ASSISTED_COHERENCY=1 ERROR_DEPRECATED=1 LOAD_IMAGE_V2=1 BL33=$(UBOOT_IMAGE) PLAT=qserver BUILD_BASE=$(TFA_OUT)   fip  all

$(INSTALLED_BOOTLOADER_MODULE): $(FIP_IMAGE) $(MERGE_TOOL) FORCE
	@echo "Made kern image: $@"
	@sh $(MERGE_TOOL) --out-path=$(TFA_OUT)/qserver/release --fip-offset=$(FIP_OFFSET)
	@mv $(TFA_OUT)/qserver/release/u-boot-merge.img $(INSTALLED_BOOTLOADER_MODULE) 
