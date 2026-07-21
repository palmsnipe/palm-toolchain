#!/usr/bin/env bash
set -euo pipefail

required=(autoconf automake bison cmake flex gmp gperf libmpc mpfr ninja node pkgconf texinfo)

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required for generic host build dependencies: https://brew.sh" >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required. Run: xcode-select --install" >&2
  exit 1
fi

missing=()
for formula in "${required[@]}"; do
  brew list --versions "$formula" >/dev/null 2>&1 || missing+=("$formula")
done

if ((${#missing[@]})); then
  printf 'Missing Homebrew prerequisites. Install them with:\n\n  brew install' >&2
  printf ' %q' "${missing[@]}" >&2
  printf '\n' >&2
  exit 1
fi

echo "All generic toolchain prerequisites are installed."
