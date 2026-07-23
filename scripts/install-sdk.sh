#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

sdk_source="${1:-${PALM_SDK_SOURCE:-}}"
required_files=(include/PalmOS.h include/PalmTypes.h include/_PalmTypes.h include/header.gcc)

if [[ -z "$sdk_source" ]]; then
  echo "Palm OS SDK 5r4 is user-supplied and is not downloaded by this repository." >&2
  echo "Set PALM_SDK_SOURCE or pass the SDK directory as the first argument." >&2
  exit 2
fi

if [[ -d "$sdk_source/sdk-5r4" ]]; then
  sdk_source="$sdk_source/sdk-5r4"
fi

for required_file in "${required_files[@]}"; do
  if [[ ! -f "$sdk_source/$required_file" ]]; then
    echo "Not a Palm OS SDK 5r4 directory: missing $required_file" >&2
    exit 1
  fi
done

echo "Installing the user-supplied Palm OS SDK 5r4 under its included terms."
mkdir -p "$PREFIX/palmdev"
staging="$(mktemp -d "$PREFIX/palmdev/.sdk-install.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
cp -R "$sdk_source" "$staging/sdk"
node "$TOOLCHAIN_ROOT/scripts/patch-sdk.mjs" "$staging/sdk"

destination="$PREFIX/palmdev/sdk"
rm -rf "$destination"
mv "$staging/sdk" "$destination"
rm -rf "$PREFIX/palmdev/sdk-5r3" "$PREFIX/palmdev/sdk-5r4"

echo "Installed the GCC-compatible SDK at $destination"
