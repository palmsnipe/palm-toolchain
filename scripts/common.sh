#!/usr/bin/env bash

TOOLCHAIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TOOLCHAIN_STATE="${PALM_TOOLCHAIN_STATE:-$TOOLCHAIN_ROOT/.toolchain}"

DOWNLOADS="$TOOLCHAIN_STATE/downloads"
SOURCES="$TOOLCHAIN_STATE/src"
BUILD="$TOOLCHAIN_STATE/build"
PREFIX="$TOOLCHAIN_STATE/prefix"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)}"

# shellcheck source=../config/sources.lock
source "$TOOLCHAIN_ROOT/config/sources.lock"

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

download_verified() {
  local url="$1" destination="$2" expected="$3"
  if [[ -f "$destination" && "$(sha256_file "$destination")" == "$expected" ]]; then
    return
  fi

  rm -f "$destination.part"
  echo "Downloading $(basename "$destination")"
  curl --fail --location --retry 3 --output "$destination.part" "$url"

  local actual
  actual="$(sha256_file "$destination.part")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for $destination: expected $expected, got $actual" >&2
    rm -f "$destination.part"
    exit 1
  fi
  mv "$destination.part" "$destination"
}

clone_at() {
  local repository="$1" destination="$2" commit="$3"
  if [[ ! -d "$destination/.git" ]]; then
    rm -rf "$destination"
    git init --quiet "$destination"
    git -C "$destination" remote add origin "$repository"
  fi
  if ! git -C "$destination" cat-file -e "$commit^{commit}" 2>/dev/null; then
    git -C "$destination" fetch --quiet --depth=1 origin "$commit"
  fi
  git -C "$destination" checkout --quiet --detach "$commit"
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$commit" ]]
}

apply_git_patch_once() {
  local source_dir="$1" patch_file="$2" stamp="$3"
  [[ -f "$stamp" ]] && return
  git -C "$source_dir" apply --check "$patch_file"
  git -C "$source_dir" apply "$patch_file"
  touch "$stamp"
}

apply_archive_patch_once() {
  local source_dir="$1" patch_file="$2" stamp="$3"
  [[ -f "$stamp" ]] && return
  patch -d "$source_dir" -p1 --forward <"$patch_file"
  touch "$stamp"
}
