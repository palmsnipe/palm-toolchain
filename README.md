# Palm Toolchain

Reproducible macOS tooling for compiling, packaging, and debugging Palm OS
software.

## Included

- Palm-compatible `m68k-none-elf` GCC 16.1 from the latest pinned Retro68
- GNU binutils 2.46.1
- PilRC
- the PRC packaging and object-resource utilities from prc-tools-remix
- `m68k-none-elf-gdb`
- a user-supplied Palm OS SDK 5r4 installation with local GCC compatibility
- relocation generation and PRC validation helpers

## Repository layout

All downloaded and generated state stays inside the repository by default:

```text
.toolchain/
  downloads/     verified source archives
  src/           extracted and patched source trees
  build/         temporary build directories
  prefix/        installed compiler, tools, debugger, and SDK
```

The complete directory is ignored by Git. Remove `.toolchain/` when a fully
clean rebuild is required. Advanced users can override its location with
`PALM_TOOLCHAIN_STATE`.

## What the user needs

- A Mac with Xcode Command Line Tools installed
- Homebrew
- An internet connection for the first build
- Several gigabytes of free disk space for downloaded sources and build files
- An existing Palm OS SDK 5r4 directory

The SDK directory must contain at least:

```text
sdk-5r4/
  include/
    PalmOS.h
    PalmTypes.h
    _PalmTypes.h
    header.gcc
```

## First-time setup

Clone the repository and enter it:

```sh
git clone https://github.com/palmsnipe/palm-toolchain.git
cd palm-toolchain
```

Install the ordinary macOS build dependencies:

```sh
brew bundle
```

Provide the SDK locations and build everything:

```sh
PALM_SDK_SOURCE=/path/to/sdk-5r4 make bootstrap
```

The same SDK supports ordinary 68K applications and projects containing native
ARM modules.

The first build downloads pinned sources, verifies their checksums, compiles
the toolchain, and installs everything under `.toolchain/prefix`. Subsequent
runs reuse the existing downloads and completed tools.

Verify the installation:

```sh
make check
```

The check compiles both a generic 68K source file and a source file including
`PalmOS.h`, verifies that four-character Palm IDs remain 32-bit with `-mshort`,
checks the packaging utilities and debugger, and builds the included Hello
World application into a valid Palm resource database.

## Build the example application

After bootstrapping the toolchain, build the included Palm OS application:

```sh
make example
```

The resulting application is written to:

```text
examples/hello-world/build/HelloWorld.prc
```

Install that file in a Palm OS device or emulator and launch **Hello World**.
It displays a small form whose button closes the application. The example is
intentionally self-contained and shows the complete path from C source and a
PilRC resource file to a packaged PRC. See
`examples/hello-world/README.md` for its layout and individual build targets.

## Using the toolchain

For interactive shell use:

```sh
source scripts/activate.sh
```

This adds `.toolchain/prefix/bin` to `PATH` and defines:

```text
PALM_TOOLCHAIN_PREFIX=/path/to/palm-toolchain/.toolchain/prefix
PALM_SDK_HOME=/path/to/palm-toolchain/.toolchain/prefix/palmdev/sdk
```

Another repository can use `PALM_TOOLCHAIN_PREFIX` directly instead of
requiring global compiler installation.

## Palm OS SDK

The Palm OS SDK is not open-source project content. Obtain SDK 5r4 separately,
read its included terms, and provide its directory explicitly during
bootstrap:

```sh
PALM_SDK_SOURCE=/path/to/sdk-5r4 make bootstrap
```

The installer never downloads or changes the supplied SDK directory. It makes a
private copy under `.toolchain/prefix/palmdev/sdk` and adapts that copy's
obsolete GCC `callseq` trap declarations to the `raw_inline` declarations
supported by this compiler. This compatibility change is required for 68K Palm
system calls to link correctly.

For an existing toolchain installation, replace the installed SDK with:

```sh
make install-sdk PALM_SDK_SOURCE=/path/to/sdk-5r4
```

Every network input is pinned by commit or SHA-256 in `config/sources.lock`.

## Compiler and host portability

The 68K compiler is GCC 16.1 from a pinned Retro68 revision. Retro68 provides
the modern compiler source, while this repository applies the Palm-specific
ABI and runtime adaptations that were historically embedded in older custom
toolchain archives: pointer returns in A0, 32-bit FourCC constants with
`-mshort`, position-independent runtime helpers, and the 16-bit-int Newlib
`memset` stack layout. GCC 16's m68k backend currently fails internally when
some libgcc helpers combine `-O2` with position-independent code, so libgcc is
built at `-O1`; application code remains optimized at the level selected by
each project. This exact source-and-patch combination passes `make check`, the
complete PalmTLS build suite, and an ARM-device HTTPS runtime test.

Native ARMlets are a separate compilation target; they do not use the 68K GCC.
Projects should make their ARM compiler configurable and default to `clang`
with an explicit target such as `--target=armv5te-none-eabi`. This selects
Apple Clang from the Xcode Command Line Tools on macOS and upstream LLVM Clang
on Linux without baking a platform-specific compiler path into the project.

The bootstrap is currently supported on macOS because its host dependencies
are installed and located through Homebrew. Linux support should retain the
same pinned target sources and Palm patches while replacing only the host
dependency discovery. The generated Palm code should not depend on the host
system compiler used to build GCC itself.

Users do not need to install or manage Retro68 separately. Palm C projects
should still select a language version explicitly, such as `-std=gnu17`, to
keep builds deterministic.

`make check` compiles Palm headers and the example application against the
locally adapted SDK, catching regressions in the GCC trap declarations.

## License

Original material in this repository is available under the MIT License. See
`THIRD_PARTY.md` for the licensing of external inputs and compatibility
patches.
