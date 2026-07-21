#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

required=(m68k-none-elf-gcc m68k-none-elf-objcopy m68k-none-elf-gdb pilrc build-prc m68k-palmos-obj-res m68k-palmos-stubgen)
for command_name in "${required[@]}"; do
  if [[ ! -x "$PREFIX/bin/$command_name" ]]; then
    echo "Missing $PREFIX/bin/$command_name; run make bootstrap" >&2
    exit 1
  fi
done

sdk="$PREFIX/palmdev/sdk-5r3"
if [[ ! -f "$sdk/include/PalmOS.h" ]]; then
  echo "Missing Palm OS SDK 5r3 under $PREFIX/palmdev; rerun bootstrap with PALM_SDK_SOURCE." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '%s\n' 'int palm_toolchain_probe(void) { return 42; }' >"$tmp/probe.c"
"$PREFIX/bin/m68k-none-elf-gcc" -m68000 -mshort -c "$tmp/probe.c" -o "$tmp/probe.o"
"$PREFIX/bin/m68k-none-elf-objdump" -f "$tmp/probe.o" | grep -q m68k

"$PREFIX/bin/m68k-none-elf-gcc" -m68000 -mno-align-int -mshort \
  -isystem"$sdk/include" \
  -isystem"$sdk/include/Core" \
  -isystem"$sdk/include/Core/Hardware" \
  -isystem"$sdk/include/Core/System" \
  -isystem"$sdk/include/Core/UI" \
  -isystem"$sdk/include/Dynamic" \
  -isystem"$sdk/include/Libraries" \
  -c "$TOOLCHAIN_ROOT/tests/compiler-smoke/palm.c" -o "$tmp/palm.o"

"$PREFIX/bin/m68k-none-elf-gcc" --version | head -1
"$PREFIX/bin/m68k-none-elf-gdb" --version | head -1
"$PREFIX/bin/pilrc" --version 2>&1 | head -1
node --check "$TOOLCHAIN_ROOT/tools/generate-m68k-relocs.mjs"
node --check "$TOOLCHAIN_ROOT/tools/validate-prc.mjs"
echo "Toolchain check passed."
