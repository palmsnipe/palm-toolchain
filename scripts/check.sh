#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
"$script_dir/check-core.sh"
"$script_dir/check-sdk.sh"

echo "Toolchain checks passed."
