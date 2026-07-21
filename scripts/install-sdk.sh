#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

sdk_source="${1:-${PALM_SDK_SOURCE:-}}"
if [[ -z "$sdk_source" ]]; then
  echo "Palm OS SDK 5r3 is user-supplied and is not downloaded by this repository." >&2
  echo "Set PALM_SDK_SOURCE or pass the SDK directory as the first argument." >&2
  exit 2
fi

if [[ -d "$sdk_source/sdk-5r3" ]]; then
  sdk_source="$sdk_source/sdk-5r3"
fi

for required_file in "Palm License.txt" include/PalmOS.h include/PalmTypes.h; do
  if [[ ! -f "$sdk_source/$required_file" ]]; then
    echo "Not a Palm OS SDK 5r3 directory: missing $required_file" >&2
    exit 1
  fi
done

echo "Installing the user-supplied SDK under its included license."
mkdir -p "$PREFIX/palmdev"
destination="$PREFIX/palmdev/sdk-5r3"
rm -rf "$destination"
cp -R "$sdk_source" "$destination"

echo "Installed an unchanged local SDK copy at $destination"
