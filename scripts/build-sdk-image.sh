#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
toolchain_root="$(cd "$script_dir/.." && pwd -P)"
sdk_source="${1:-}"
image="${2:-ghcr.io/palmsnipe/palm-toolchain-sdk:5r4-gcc16}"
base_image="${PALM_TOOLCHAIN_IMAGE:-ghcr.io/palmsnipe/palm-toolchain:latest}"
platform="${PALM_TOOLCHAIN_PLATFORM:-linux/amd64}"

if [[ -z "$sdk_source" || ! -d "$sdk_source" ]]; then
  echo "Usage: $0 /path/to/sdk-5r4 [image]" >&2
  exit 2
fi

for required_file in include/PalmOS.h include/PalmTypes.h include/_PalmTypes.h include/header.gcc; do
  if [[ ! -f "$sdk_source/$required_file" ]]; then
    echo "Not a Palm OS SDK 5r4 directory: missing $required_file" >&2
    exit 1
  fi
done

docker build \
  --platform "$platform" \
  --file "$toolchain_root/Dockerfile.sdk" \
  --build-arg "TOOLCHAIN_IMAGE=$base_image" \
  --tag "$image" \
  "$sdk_source"

echo "Built private SDK image: $image"
