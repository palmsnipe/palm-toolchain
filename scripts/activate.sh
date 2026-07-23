#!/usr/bin/env bash

if [[ -n "${BASH_SOURCE:-}" ]]; then
  activation_script="${BASH_SOURCE[0]}"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  activation_script="${(%):-%x}"
else
  activation_script="$0"
fi

activation_root="$(cd "$(dirname "$activation_script")/.." && pwd -P)"
export PALM_TOOLCHAIN_PREFIX="${PALM_TOOLCHAIN_STATE:-$activation_root/.toolchain}/prefix"
export PALM_SDK_HOME="$PALM_TOOLCHAIN_PREFIX/palmdev/sdk"
export PATH="$PALM_TOOLCHAIN_PREFIX/bin:$PATH"
unset activation_root activation_script

echo "Palm toolchain: $PALM_TOOLCHAIN_PREFIX"
