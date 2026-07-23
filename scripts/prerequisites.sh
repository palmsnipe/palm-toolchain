#!/usr/bin/env bash
set -euo pipefail

host_os="$(uname -s)"

if [[ "$host_os" == Darwin ]]; then
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
elif [[ "$host_os" == Linux ]]; then
  required_commands=(
    autoconf automake bison clang clang++ cmake curl flex git gperf
    make makeinfo ninja node patch pkg-config sha256sum xz
  )
  missing=()
  for command_name in "${required_commands[@]}"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
  done
  for header in gmp.h mpfr.h mpc.h; do
    printf '#include <%s>\n' "$header" \
      | clang -E -x c - >/dev/null 2>&1 || missing+=("$header")
  done
  if ((${#missing[@]})); then
    printf 'Missing Linux prerequisites:' >&2
    printf ' %q' "${missing[@]}" >&2
    printf '\nInstall the packages documented in README.md.\n' >&2
    exit 1
  fi
else
  echo "Unsupported build host: $host_os" >&2
  exit 1
fi

echo "All generic toolchain prerequisites are installed."
