@echo off

docker run ^
       -it --rm ^
	   --cap-add NET_ADMIN --hostname buildserver ^
	   --volume "%CD%\bsp:/home/build/bsp" ^
	   --volume "%CD%\secure_boot:/home/build/secure_boot" ^
	   imx6_yoctocontainer
