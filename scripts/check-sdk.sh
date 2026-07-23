#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

sdk="$PREFIX/palmdev/sdk"
if [[ ! -f "$sdk/include/PalmOS.h" ]]; then
  echo "Missing Palm OS SDK 5r4 under $PREFIX/palmdev." >&2
  echo "Run make install-sdk PALM_SDK_SOURCE=/path/to/sdk-5r4." >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
"$PREFIX/bin/m68k-none-elf-gcc" -std=gnu17 -m68000 -mno-align-int -mshort \
  -isystem"$sdk/include" \
  -isystem"$sdk/include/Core" \
  -isystem"$sdk/include/Core/Hardware" \
  -isystem"$sdk/include/Core/System" \
  -isystem"$sdk/include/Core/UI" \
  -isystem"$sdk/include/Dynamic" \
  -isystem"$sdk/include/Libraries" \
  -c "$TOOLCHAIN_ROOT/tests/compiler-smoke/palm.c" -o "$tmp/palm.o"

"$PREFIX/bin/m68k-none-elf-objdump" -d "$tmp/palm.o" \
  | sed -n '/<palm_pointer_return_probe>:/,/^$/p' \
  | grep -q '%a0'

grep -q '__raw_inline__' "$sdk/include/PalmTypes.h"
if grep -q '__callseq__' "$sdk/include/PalmTypes.h"; then
  echo "Palm OS SDK GCC compatibility patch is incomplete." >&2
  exit 1
fi

echo "Palm OS SDK 5r4: $sdk"
"${MAKE:-make}" -C "$TOOLCHAIN_ROOT/examples/hello-world" \
  PALM_TOOLCHAIN_PREFIX="$PREFIX" test

echo "SDK integration check passed."
