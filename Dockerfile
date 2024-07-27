FROM ubuntu:18.04

# Update system and add the packages required for Yocto builds.
# Use DEBIAN_FRONTEND=noninteractive, to avoid image build hang waiting
# for a default confirmation [Y/n] at some configurations.

ENV DEBIAN_FRONTEND=noninteractive
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak

RUN \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt update
RUN apt install -y gawk wget git-core diffstat unzip texinfo bc lzop \
    gcc-multilib build-essential chrpath socat cpio python python3 \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping libssl-dev \
    libsdl1.2-dev xterm tar locales net-tools rsync sudo vim curl wget

RUN curl -s "https://raw.githubusercontent.com/carloscn/script/master/down_tool_chains/down_toolchain_old.sh" | bash
RUN rm -rfv *.tar.xz

# Set up locales
RUN locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Yocto needs 'source' command for setting up the build environment, so replace
# the 'sh' alias to 'bash' instead of 'dash'.
RUN rm /bin/sh && ln -s bash /bin/sh

# Install repo
RUN curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo > /bin/repo && chmod a+x /bin/repo


# Add your user to sudoers to be able to install other packages in the container.
RUN groupadd build -g 1000
RUN useradd -ms /bin/bash -p build build -u 1028 -g 1000 && \
        usermod -aG sudo build && \
        echo "build:build" | chpasswd


# Yocto builds should run as a normal user.
USER build

ARG DOCKER_WORKDIR
WORKDIR ${DOCKER_WORKDIR}
