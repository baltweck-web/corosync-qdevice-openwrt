#!/bin/bash
set -e

# Run this script on host machine with Docker installed
# Usage (defaults: ipq40xx/generic on OpenWrt 25.12.6):
#   ./run-build.sh
# Other target/version:
#   OPENWRT_VERSION=23.05.5 TARGET=armsr SUBTARGET=armv8 STAGING_TARGET_DIR=target-aarch64_generic_musl ./run-build.sh
# Or with target architecture override for GL.iNet:
#   TARGET_ARCH_OVERRIDE="aarch64_cortex-a53_neon-vfpv4" ./run-build.sh

OPENWRT_VERSION="${OPENWRT_VERSION:-25.12.6}"
TARGET="${TARGET:-ipq40xx}"
SUBTARGET="${SUBTARGET:-generic}"
# Name of the per-target staging dir inside the SDK (persisted between runs)
STAGING_TARGET_DIR="${STAGING_TARGET_DIR:-target-arm_cortex-a7+neon-vfpv4_musl_eabi}"

mkdir -p sdk-state/build_dir sdk-state/staging_dir sdk-state/dl output

echo "Building Docker build container..."
docker build -t openwrt-corosync-builder \
  --build-arg OPENWRT_VERSION="${OPENWRT_VERSION}" \
  --build-arg TARGET="${TARGET}" \
  --build-arg SUBTARGET="${SUBTARGET}" \
  -f Dockerfile .

echo "Running OpenWrt SDK compilation container..."
docker run --rm \
  -e TARGET_ARCH_OVERRIDE="${TARGET_ARCH_OVERRIDE}" \
  -e TARGET="${TARGET}" \
  -e SUBTARGET="${SUBTARGET}" \
  -v "$(pwd):/build" \
  -v "$(pwd)/sdk-state/build_dir:/opt/sdk/build_dir" \
  -v "$(pwd)/sdk-state/staging_dir:/opt/sdk/staging_dir/${STAGING_TARGET_DIR}" \
  -v "$(pwd)/sdk-state/dl:/opt/sdk/dl" \
  openwrt-corosync-builder bash /build/build.sh \
  | tee output/build.log

echo "Build finished! Check output/ directory for .ipk/.apk packages and SHA256SUMS.txt."
