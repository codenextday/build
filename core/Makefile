# Put some miscellaneous rules here

# HACK: clear LOCAL_PATH from including last build target before calling
# intermedites-dir-for
LOCAL_PATH := $(BUILD_SYSTEM)



# #################################################################
# Targets for boot/OS images
# #################################################################

INSTALLED_BOOTLOADER_MODULE := $(PRODUCT_OUT)/bootloader
MKIMAGE := $(PRODUCT_OUT)/mkimage

# -----------------------------------------------------------------
# the ramdisk
MKBOOTFS := $(TOPDIR)script/gen_initramfs.sh
BUILT_RAMDISK_DIR := $(TOPDIR)system/ramfs

INSTALLED_RAMDISK_TARGET := $(PRODUCT_OUT)/ramdisk.img
$(INSTALLED_RAMDISK_TARGET): $(MKBOOTFS) $(BUILT_RAMDISK_DIR)
	@echo "Target ram disk: $@"
	$(hide) $(MKBOOTFS) -o $@  -u 0  -g 0  $(BUILT_RAMDISK_DIR)

# -----------------------------------------------------------------
# the boot image, which is a collection of other images.
INSTALLED_KERNIMAGE_TARGET := $(PRODUCT_OUT)/kern.img

# -----------------------------------------------------------------
# rootfs image
#
FULL_SYSTEMIMAGE_DEPS :=

$(BUILT_SYSTEMIMAGE): $(FULL_SYSTEMIMAGE_DEPS) $(INSTALLED_FILES_FILE)
	$(call build-systemimage-target,$@)

INSTALLED_SYSTEMIMAGE := $(PRODUCT_OUT)/system.img
INSTALLED_ROOTFS_TARGET := $(PRODUCT_OUT)/rootfs.img
SYSTEMIMAGE_SOURCE_DIR := $(TARGET_OUT)

$(INSTALLED_SYSTEMIMAGE): $(BUILT_SYSTEMIMAGE) $(RECOVERY_FROM_BOOT_PATCH) | $(ACP)
	@echo "Install system fs image: $@"
	$(copy-file-to-target)
	$(hide) $(call assert-max-image-size,$@ $(RECOVERY_FROM_BOOT_PATCH),$(BOARD_SYSTEMIMAGE_PARTITION_SIZE))

.PHONY: kernimg
kernimg: $(INSTALLED_KERNIMAGE_TARGET)
systemimage: $(INSTALLED_SYSTEMIMAGE)

.PHONY: bootloader
bootloader: $(INSTALLED_BOOTLOADER_MODULE)



.PHONY: rootfs
rootfs: $(INSTALLED_ROOTFS_TARGET)


all_target:$(ALL_MODULES)
	@echo ">> target modules"  $^
