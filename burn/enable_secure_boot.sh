#!/bin/bash

# bash enable_secure_boot.sh -u udisk/u-boot_signed.imx -k udisk/zImage_signed -r udisk/zImage_mfgtool_signed -h udisk/SRK_1_2_3_4_fuse.bin

# Function to log messages
log() {
    echo "[INFO] $1"
}

# Function to log and handle errors
error_exit() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Check if all required arguments are provided
if [ $# -ne 8 ]; then
    error_exit "Usage: $0 -u <uboot_signed.imx> -k <zImage_signed> -h <srk.bin> -r <zImage_mgtool_signed>"
fi

# Parse arguments
while getopts ":u:k:h:r:" opt; do
    case $opt in
        u)
            UBOOT_SIGNED=$OPTARG
            ;;
        k)
            ZIMAGE_SIGNED=$OPTARG
            ;;
        h)
            SRK_BIN=$OPTARG
            ;;
        r)
            ZIMAGE_MGTOOL_SIGNED=$OPTARG
            ;;
        \?)
            error_exit "Invalid option: -$OPTARG"
            ;;
        :)
            error_exit "Option -$OPTARG requires an argument."
            ;;
    esac
done

# 1. Process srk.bin
log "Processing SRK: $SRK_BIN"
bash prov_srk.sh -f "$SRK_BIN" || error_exit "Failed to process SRK"

# 2. Process uboot_signed.imx
log "Processing U-Boot: $UBOOT_SIGNED"

log "Disabling write protection on mmcblk3boot0"
echo 0 > /sys/block/mmcblk3boot0/force_ro || error_exit "Failed to disable write protection"

log "Clearing mmcblk3boot0"
dd if=/dev/zero of=/dev/mmcblk3boot0 bs=512 && sync || log "Warn to clear mmcblk3boot0"

log "Writing U-Boot to mmcblk3boot0"
dd if="$UBOOT_SIGNED" of=/dev/mmcblk3boot0 bs=512 seek=2 conv=fsync && sync || error_exit "Failed to write U-Boot"

log "Re-enabling write protection on mmcblk3boot0"
echo 1 > /sys/block/mmcblk3boot0/force_ro && sync || error_exit "Failed to re-enable write protection"

log "Enabling boot partition"
mmc bootpart enable 1 1 /dev/mmcblk3 && sync || error_exit "Failed to enable boot partition"

# 3. Process zImage_signed and zImage_mgtool_signed
log "Processing kernel images"

# Check if /dev/mmcblk3p1 is already mounted
MOUNT_POINT="/mnt"
MOUNTED=$(mount | grep "/dev/mmcblk3p1")

if [ -n "$MOUNTED" ]; then
    log "/dev/mmcblk3p1 is already mounted, remounting..."
    umount /dev/mmcblk3p1 || error_exit "Failed to unmount /dev/mmcblk3p1"
fi

log "Mounting /dev/mmcblk3p1 to $MOUNT_POINT"
mount /dev/mmcblk3p1 "$MOUNT_POINT" || error_exit "Failed to mount /dev/mmcblk3p1"

log "Copying $ZIMAGE_SIGNED to /mnt/zImage"
cp "$ZIMAGE_SIGNED" "$MOUNT_POINT/zImage" && sync || error_exit "Failed to copy zImage_signed"

log "Copying $ZIMAGE_MGTOOL_SIGNED to /mnt/rescue/zImage"
cp "$ZIMAGE_MGTOOL_SIGNED" "$MOUNT_POINT/rescue/zImage" && sync && umount /mnt || error_exit "Failed to copy zImage_mgtool_signed"

log "Secure boot setup completed successfully!"
log "reboot your device, if no error, please close your device by $ bash prov_srk.sh -l"