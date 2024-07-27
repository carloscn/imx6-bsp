# imx6 bsp build system

This is this NXP imx6ull board build project. You can make u-boot, linux, and bootscript in this project.

Performing `make u-boot` will make uboot firmware, while `make linux` will make linux kernel.

This project also supports the FIT format image. `make uimage` will make FIT image with a bootscript in the FIT mode.

## Docker

`make all`
