#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

prepare_sources() {
  "$TOOLCHAIN_ROOT/scripts/fetch-sources.sh"
  mkdir -p "$BUILD" "$PREFIX"

  if [[ ! -d "$SOURCES/binutils-2.46.1" ]]; then
    tar -xJf "$DOWNLOADS/$BINUTILS_FILE" -C "$SOURCES"
  fi
  if [[ ! -d "$SOURCES/pilrc-3.2" ]]; then
    mkdir -p "$SOURCES/pilrc-3.2"
    tar -xzf "$DOWNLOADS/$PILRC_FILE" -C "$SOURCES/pilrc-3.2" --strip-components=1
  fi
  if [[ ! -d "$SOURCES/gdb-17.2" ]]; then
    tar -xJf "$DOWNLOADS/$GDB_FILE" -C "$SOURCES"
  fi

  apply_git_patch_once "$SOURCES/prc-tools-remix" \
    "$TOOLCHAIN_ROOT/patches/prc-tools/prc-tools-tools-only.patch" \
    "$SOURCES/prc-tools-remix/.palmsnipe-tools-only"
  apply_git_patch_once "$SOURCES/Retro68" \
    "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-m68k-elf-pragmas.patch" \
    "$SOURCES/Retro68/.palmsnipe-m68k-elf-pragmas"
  apply_git_patch_once "$SOURCES/Retro68" \
    "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-palmos-fourcc.patch" \
    "$SOURCES/Retro68/.palmsnipe-palmos-fourcc"
  apply_git_patch_once "$SOURCES/Retro68" \
    "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-palmos-mshort-memset.patch" \
    "$SOURCES/Retro68/.palmsnipe-palmos-mshort-memset"
  apply_git_patch_once "$SOURCES/Retro68" \
    "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-palmos-pic-libgcc.patch" \
    "$SOURCES/Retro68/.palmsnipe-palmos-pic-libgcc"
  apply_archive_patch_once "$SOURCES/pilrc-3.2" \
    "$TOOLCHAIN_ROOT/patches/pilrc/pilrc-64-bit-resource-directory.patch" \
    "$SOURCES/pilrc-3.2/.palmsnipe-resource-directory-64bit"
  apply_archive_patch_once "$SOURCES/pilrc-3.2" \
    "$TOOLCHAIN_ROOT/patches/pilrc/pilrc-lp64-bitmap-header.patch" \
    "$SOURCES/pilrc-3.2/.palmsnipe-lp64-bitmap"

  while IFS= read -r -d '' file; do cp "$DOWNLOADS/config.guess" "$file"; chmod +x "$file"; done \
    < <(find -L "$SOURCES/prc-tools-remix/prc-tools-2.3" -name config.guess -print0)
  while IFS= read -r -d '' file; do cp "$DOWNLOADS/config.sub" "$file"; chmod +x "$file"; done \
    < <(find -L "$SOURCES/prc-tools-remix/prc-tools-2.3" -name config.sub -print0)
}

build_compiler() {
  local compiler_fingerprint compiler_stamp
  compiler_fingerprint="$({
    printf '%s\n' "$RETRO68_COMMIT" "$BINUTILS_SHA256"
    sha256_file "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-m68k-elf-pragmas.patch"
    sha256_file "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-palmos-fourcc.patch"
    sha256_file "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-palmos-mshort-memset.patch"
    sha256_file "$TOOLCHAIN_ROOT/patches/retro68-palmos/retro68-palmos-pic-libgcc.patch"
  } | shasum -a 256 | awk '{print $1}')"
  compiler_stamp="$PREFIX/.palm-toolchain-compiler.sha256"
  if [[ -x "$PREFIX/bin/m68k-none-elf-gcc" && \
        -x "$PREFIX/bin/m68k-none-elf-ld" ]] && \
     [[ "$("$PREFIX/bin/m68k-none-elf-gcc" -dumpfullversion)" == "$RETRO68_GCC_VERSION" ]] && \
     [[ "$("$PREFIX/bin/m68k-none-elf-ld" --version | head -1)" == *"2.46.1"* ]] && \
     [[ -f "$compiler_stamp" && "$(cat "$compiler_stamp")" == "$compiler_fingerprint" ]]; then
    return
  fi
  local gmp mpfr mpc
  gmp="$(brew --prefix gmp)"
  mpfr="$(brew --prefix mpfr)"
  mpc="$(brew --prefix libmpc)"

  rm -rf "$BUILD/binutils"
  mkdir -p "$BUILD/binutils"
  (
    cd "$BUILD/binutils"
    "$SOURCES/binutils-2.46.1/configure" \
      --target=m68k-none-elf --prefix="$PREFIX" --disable-doc \
      --disable-nls --disable-werror
    make -j"$JOBS"
    make install
  )

  rm -rf "$BUILD/gcc"
  mkdir -p "$BUILD/gcc"
  (
    cd "$BUILD/gcc"
    ac_cv_header_unistd_h=yes \
    ac_cv_type_caddr_t=yes \
    gcc_cv_have_decl_strsignal=yes \
    gcc_cv_have_decl_getrlimit=yes \
    gcc_cv_have_decl_setrlimit=yes \
    MAKEINFO="$(brew --prefix texinfo)/bin/makeinfo" \
      "$SOURCES/Retro68/gcc/configure" \
        --target=m68k-none-elf --prefix="$PREFIX" \
        --enable-languages=c --with-arch=m68k --with-cpu=m68000 \
        --with-gmp="$gmp" --with-mpfr="$mpfr" --with-mpc="$mpc" \
        --without-headers --with-newlib \
        --disable-libssp --disable-multilib --disable-nls --disable-lto
    make -j"$JOBS" || make
    make install
  )
  printf '%s\n' "$compiler_fingerprint" >"$compiler_stamp"
}

build_pilrc() {
  [[ -x "$PREFIX/bin/pilrc" ]] && return
  rm -rf "$BUILD/pilrc"
  mkdir -p "$BUILD/pilrc"
  (
    cd "$BUILD/pilrc"
    "$SOURCES/pilrc-3.2/unix/configure" --disable-debug --disable-dependency-tracking --prefix="$PREFIX"
    make -j"$JOBS"
    install -m 755 pilrc "$PREFIX/bin/pilrc"
    mkdir -p "$PREFIX/share/pilrc"
    cp "$SOURCES/pilrc-3.2/ppmquant/"palette-* "$PREFIX/share/pilrc/"
  )
}

build_prc_tools() {
  [[ -x "$PREFIX/bin/build-prc" ]] && return
  mkdir -p "$BUILD/prc-tools"
  (
    cd "$BUILD/prc-tools"
    CC='clang -std=gnu89 -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion -Wno-error=implicit-int' \
    CXX='clang++ -Wno-error=deprecated-non-prototype -Wno-error=register' \
    CFLAGS='-w -O1 -fcommon -fno-strict-aliasing' \
      "$SOURCES/prc-tools-remix/prc-tools-2.3/configure" \
        --target=m68k-palmos --enable-languages=c --disable-nls \
        --prefix="$PREFIX" --with-palmdev-prefix="$PREFIX/palmdev"
    make -j"$JOBS" tools
    make -C tools install
  )
}

build_gdb() {
  [[ -x "$PREFIX/bin/m68k-none-elf-gdb" ]] && return
  rm -rf "$BUILD/gdb"
  mkdir -p "$BUILD/gdb"
  (
    cd "$BUILD/gdb"
    "$SOURCES/gdb-17.2/configure" \
      --target=m68k-none-elf --program-prefix=m68k-none-elf- \
      --prefix="$PREFIX" --disable-binutils --disable-nls \
      --with-gmp="$(brew --prefix gmp)" --with-mpfr="$(brew --prefix mpfr)" \
      --with-python=no
    make -j"$JOBS" all-gdb
    make install-gdb
  )
}

case "${1:-all}" in
  prepare) prepare_sources ;;
  compiler) prepare_sources; build_compiler; build_pilrc; build_prc_tools ;;
  debugger) prepare_sources; build_gdb ;;
  all)
    if [[ -z "${PALM_SDK_SOURCE:-}" ]]; then
      echo "PALM_SDK_SOURCE must point to a Palm OS SDK 5r4 directory." >&2
      exit 2
    fi
    prepare_sources
    "$TOOLCHAIN_ROOT/scripts/install-sdk.sh" "$PALM_SDK_SOURCE"
    build_compiler
    build_pilrc
    build_prc_tools
    build_gdb
    ;;
  *) echo "usage: $0 [prepare|compiler|debugger|all]" >&2; exit 2 ;;
esac

echo "Palm toolchain installed in $PREFIX"
