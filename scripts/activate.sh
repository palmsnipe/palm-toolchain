#!/usr/bin/env bash

activation_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export PALM_TOOLCHAIN_PREFIX="${PALM_TOOLCHAIN_STATE:-$activation_root/.toolchain}/prefix"
export PALM_SDK_HOME="$PALM_TOOLCHAIN_PREFIX/palmdev/sdk-5r3"
export PATH="$PALM_TOOLCHAIN_PREFIX/bin:$PATH"
unset activation_root

echo "Palm toolchain: $PALM_TOOLCHAIN_PREFIX"
