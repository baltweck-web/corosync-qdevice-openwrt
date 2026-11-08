FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    build-essential clang flex bison g++ gawk gcc-multilib \
    gettext git libncurses-dev libssl-dev python3 python3-distutils unzip zlib1g-dev \
    file wget rsync ca-certificates pkg-config autoconf automake libtool libnss3-tools \
    patchelf cpio sudo curl jq tar xz-utils zstd \
    && rm -rf /var/lib/apt/lists/*

# Target architecture can be passed via build arg (default: ipq40xx/generic)
ARG OPENWRT_VERSION=25.12.6
ARG TARGET=ipq40xx
ARG SUBTARGET=generic

WORKDIR /opt

# The SDK filename varies per release (gcc version, eabi suffix, tar.xz for
# 23.05 vs tar.zst since 24.10), so discover it from the published sha256sums.
RUN BASE_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}" && \
    SDK_FILE=$(curl -fsSL "${BASE_URL}/sha256sums" | grep -oE 'openwrt-sdk-[^ ]+\.Linux-x86_64\.tar\.(xz|zst)' | head -n1) && \
    test -n "$SDK_FILE" && \
    echo "Downloading OpenWrt SDK: ${BASE_URL}/${SDK_FILE}" && \
    wget -q "${BASE_URL}/${SDK_FILE}"

RUN tar -xf openwrt-sdk-*.tar.* && \
    rm openwrt-sdk-*.tar.* && \
    mv openwrt-sdk-* sdk

# Expose the target selection to build.sh at runtime
ENV TARGET=${TARGET} \
    SUBTARGET=${SUBTARGET}

WORKDIR /opt/sdk

# Pre-seed feeds
RUN ./scripts/feeds update base packages || true

COPY build.sh /build/build.sh
RUN chmod +x /build/build.sh

CMD ["/bin/bash", "/build/build.sh"]
