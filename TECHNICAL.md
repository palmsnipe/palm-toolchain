# Palm Toolchain Technical Notes

## Generated layout

The default state directory is `.toolchain/`:

```text
.toolchain/
  downloads/     verified source archives
  src/           extracted and patched source trees
  build/         temporary build directories
  prefix/        installed compiler, tools, debugger, and SDK
```

Set `PALM_TOOLCHAIN_STATE` to place this state elsewhere.

## Reproducibility

Every network input is pinned by commit or SHA-256 in
`config/sources.lock`. Git repositories are checked out detached at the
specified commit. Archives are verified before extraction.

The bootstrap records fingerprints for the compiler builds so unchanged
installations can be reused. `make setup` is safe to run again.

## Compilers

The 68K compiler is GCC 16.1 from a pinned Retro68 revision. Retro68 supplies
the modern GCC source; this repository applies the Palm-specific ABI and
runtime adaptations historically carried by older custom toolchains:

- pointer returns in address register A0
- 32-bit Palm FourCC constants when using `-mshort`
- position-independent libgcc runtime helpers
- the 16-bit-int Newlib `memset` stack layout

GCC 16 currently fails internally when some m68k libgcc helpers combine `-O2`
with position-independent code. Those runtime helpers are therefore built at
`-O1`; application optimization remains controlled by each project.

Native ARM code is a separate target. Small freestanding ARMlets can use
Clang with an explicit target such as `--target=armv5te-none-eabi`. Projects
that require GNU PEAL, XScale, Wireless MMX, or APCS GNU options use the
included `arm-none-eabi` GCC and G++ 16.1.

Both GCC targets use the same pinned GCC source but have separate binutils,
target configuration, runtime libraries, and validation.

## Palm OS SDK

The SDK installer copies a user-supplied SDK 5r4 into
`.toolchain/prefix/palmdev/sdk`. It does not modify the original directory.

The private copy receives two compatibility changes:

- obsolete GCC `callseq` trap declarations become supported `raw_inline`
  declarations
- a legacy header-name case mismatch is corrected for case-sensitive
  filesystems

Replace the installed SDK without rebuilding the compilers with:

```sh
make install-sdk PALM_SDK_SOURCE=/path/to/sdk-5r4
```

## Bootstrap targets

Normal users only need:

```sh
PALM_SDK_SOURCE=/path/to/sdk-5r4 make setup
```

Maintainer targets are also available:

- `make fetch` downloads and verifies external sources
- `make bootstrap-core` builds all tools without installing an SDK
- `make debugger` builds GDB if it is absent
- `make install-sdk PALM_SDK_SOURCE=...` replaces only the SDK

The lower-level `scripts/bootstrap.sh` component arguments exist for
development and troubleshooting.

## Validation

`make check` runs three focused checks:

- `check-core` validates the 68K compiler, FourCC behavior, packaging tools,
  resource compiler, debugger, and JavaScript helpers
- `check-arm` compiles GCC C and C++ Wireless MMX probes and a Clang ARMlet
- `check-sdk` compiles Palm headers, verifies the pointer-return ABI and SDK
  adaptations, and builds the Hello World PRC

This source-and-patch combination has also passed the PalmTLS build suite and
HTTPS runtime tests on emulated 68K Palm m515 and ARM Tungsten E2 devices.

The Dockerfile provides clean Ubuntu 24.04 builds for ARM64 and AMD64. The SDK
is deliberately excluded from the image and must be mounted by the user.
