#!/bin/bash

# 设置日志函数
log() {
    echo "[INFO] $1"
}

chmod -R 777 /home/build/secure_boot
chmod -R 777 /home/build/linux-imx
chmod -R 777 /home/build/u-boot

log "Changing to bsp directory."
cd bsp || { log "Failed to change to bsp directory."; exit 1; }

log "Running make u-boot."
make u-boot || { log "make u-boot failed."; exit 1; }

log "Running make linux."
make linux || { log "make linux failed."; exit 1; }

log "Returning to home directory."
cd .. || { log "Failed to change to home directory."; exit 1; }

log "Changing to secure_boot/sign_image directory."
cd secure_boot/sign_image || { log "Failed to change to secure_boot/sign_image directory."; exit 1; }

log "Running ./copy_images.sh."
./copy_images.sh || { log "./copy_images.sh failed."; exit 1; }

log "Running make all."
make all || { log "make all failed."; exit 1; }

log "Script execution completed."

exec "$@"