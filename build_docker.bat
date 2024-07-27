@echo off
REM This script creates the yocto-ready docker image.
REM The --build-arg options are used to pass data about the current user.
REM Also, a tag is used for easy identification of the generated image.

REM Main

docker build -t imx6_yoctocontainer .

exit /b 0