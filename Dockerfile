# syntax=docker/dockerfile:1
# check=error=true

ARG MODEL=unset
ARG BIT_WIDTH=unset


FROM debian:13 AS build-env
SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]
ENV TZ="Europe/Berlin"
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /build

COPY bashrc /root/.bashrc
RUN <<EOF
  apt-get update
  apt-get install -y bc bison flex git libssl-dev make libc6-dev libncurses5-dev xz-utils kmod
  apt-get install -y crossbuild-essential-armhf
EOF


FROM build-env AS source

RUN git clone https://github.com/raspberrypi/linux
WORKDIR /build/linux


FROM source AS checkout
ARG GIT_REF

RUN <<EOF
  git fetch
  git -c advice.detachedHead=false checkout "${GIT_REF}"
EOF


FROM checkout AS toolchain-64
ARG ARCH=arm64
ARG CROSS_COMPILE=aarch64-linux-gnu-

FROM checkout AS toolchain-32
ARG ARCH=arm
ARG CROSS_COMPILE=arm-linux-gnueabihf-


FROM toolchain-64 AS model-64-2
ARG KERNEL=kernel8
ARG DEF_CONFIG=bcm2711_defconfig
FROM model64-2 AS model-64-3
FROM model64-2 AS model-64-4

FROM toolchain-64 AS model-64-5
ARG KERNEL=kernel_2712
ARG DEF_CONFIG=bcm2712_defconfig

FROM toolchain-32 AS model-32-1
ARG KERNEL=kernel
ARG DEF_CONFIG=bcmrpi_defconfig

FROM toolchain-32 AS model-32-2
ARG KERNEL=kernel7
ARG DEF_CONFIG=bcm2709_defconfig
FROM model32-2 AS model-32-3

FROM toolchain-32 AS model-32-4
ARG KERNEL=kernel7l
ARG DEF_CONFIG=bcm2711_defconfig


FROM model-${BIT_WIDTH}-${MODEL} AS toolchain
ARG CORES


FROM toolchain AS use-config
ARG VERSION

COPY config .config
COPY Module.symvers Module.symvers
RUN echo "${VERSION}" >.version


FROM toolchain AS configure

COPY chaoskey.patch .
RUN <<EOF
  make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" "${DEF_CONFIG}"
  patch -p1 <../chaoskey.patch
EOF


#FROM configure AS configured
FROM use-config AS configured


FROM configured AS compile-full

RUN <<EOF
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" zImage modules dtbs
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" deb-pkg
EOF


FROM configured AS compile-chaoskey

RUN <<EOF
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" kernelversion
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" scripts
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" prepare
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" modules_prepare
  make -j$((CORES*3/2)) ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" M=drivers/usb/misc/
EOF


#FROM compile-full AS final
FROM compile-chaoskey AS final

COPY install_kernel.sh .
