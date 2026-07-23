#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

required=(arm-none-eabi-gcc arm-none-eabi-g++ arm-none-eabi-ld)
for command_name in "${required[@]}"; do
  if [[ ! -x "$PREFIX/bin/$command_name" ]]; then
    echo "Missing $PREFIX/bin/$command_name; run make bootstrap-core" >&2
    exit 1
  fi
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '%s\n' 'int palm_arm_probe(void) { return 42; }' >"$tmp/probe.c"
"$PREFIX/bin/arm-none-eabi-gcc" \
  -marm -mabi=apcs-gnu -march=iwmmxt -mtune=xscale \
  -c "$tmp/probe.c" -o "$tmp/probe.o"
"$PREFIX/bin/arm-none-eabi-readelf" -h "$tmp/probe.o" | grep -q 'Machine:.*ARM'

printf '%s\n' 'extern "C" int palm_arm_cpp_probe(void) { return 42; }' \
  >"$tmp/probe.cc"
"$PREFIX/bin/arm-none-eabi-g++" \
  -marm -mabi=apcs-gnu -march=iwmmxt -mtune=xscale \
  -fno-exceptions -fno-rtti -c "$tmp/probe.cc" -o "$tmp/probe-cpp.o"

clang --target=armv5te-none-eabi -mcpu=arm926ej-s -marm \
  -ffreestanding -c "$tmp/probe.c" -o "$tmp/probe-clang.o"

"$PREFIX/bin/arm-none-eabi-gcc" --version | head -1
echo "ARM compiler check passed."
