# Palm Toolchain

Reproducible macOS and Linux tooling for compiling, packaging, and debugging Palm OS
software.

## Included

- Palm-compatible `m68k-none-elf` GCC 16.1 from the latest pinned Retro68
- `arm-none-eabi` GCC and G++ 16.1 for PEAL, XScale, and Wireless MMX projects
- GNU binutils 2.46.1
- PilRC
- the PRC packaging and object-resource utilities from prc-tools-remix
- `m68k-none-elf-gdb`
- host-provided Clang for small freestanding ARMlets
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

- macOS with Xcode Command Line Tools and Homebrew, or a recent Linux
  distribution with the documented build packages
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

On macOS, install the ordinary build dependencies:

```sh
brew bundle
```

On Ubuntu 24.04, install the equivalent packages:

```sh
sudo apt-get update
sudo apt-get install -y \
  autoconf automake bison build-essential ca-certificates clang cmake curl \
  flex git gperf libgmp-dev libmpc-dev libmpfr-dev libtool ninja-build \
  nodejs patch pkg-config texinfo xz-utils
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

`make check-core` validates the compiler and tools without an SDK.
`make check-sdk` validates the installed SDK and builds the example.

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

## Linux container

The Docker image builds and validates the complete SDK-free toolchain on
Ubuntu 24.04:

```sh
docker build -t palm-toolchain:linux .
```

Docker builds for the host architecture by default. To reproduce the
architecture used by standard GitHub-hosted Ubuntu runners:

```sh
docker build --platform linux/amd64 -t palm-toolchain:linux-amd64 .
```

The Palm OS SDK is deliberately excluded from the image. Mount a user-supplied
SDK to install and validate it inside an ephemeral container:

```sh
docker run --rm \
  --mount type=bind,source=/path/to/sdk-5r4,target=/opt/palm-sdk,readonly \
  palm-toolchain:linux \
  bash -lc 'make install-sdk PALM_SDK_SOURCE=/opt/palm-sdk && make check'
```

This same image can build an application mounted at `/workspace`:

```sh
docker run --rm \
  --mount type=bind,source=/path/to/sdk-5r4,target=/opt/palm-sdk,readonly \
  --mount type=bind,source=/path/to/app,target=/workspace \
  palm-toolchain:linux \
  bash -lc 'make install-sdk PALM_SDK_SOURCE=/opt/palm-sdk &&
            make -C /workspace'
```

The image defines both `PALM_TOOLCHAIN_ROOT` and `PALM_TOOLCHAIN_PREFIX`, so
applications can use the installed compiler as well as the repository's PRC
validation and relocation helpers.

The container recipe has been verified locally on Linux ARM64 and AMD64,
including SDK installation and the complete example build. It is intended to
become the shared foundation for GitHub Actions, but this repository does not
include a workflow yet.

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
supported by this compiler. It also corrects a legacy header-name case mismatch
that fails on Linux's case-sensitive filesystems. These compatibility changes
are required for portable 68K Palm builds.

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
complete PalmTLS build suite, and verified HTTPS runtime tests on an emulated
68K Palm m515 and ARM Tungsten E2.

Native ARMlets are a separate compilation target; they do not use the 68K GCC.
Small ARMlets can use configurable `clang` with an explicit target such as
`--target=armv5te-none-eabi`. Legacy projects that rely on GNU-specific PEAL,
XScale, or Wireless MMX options use the included `arm-none-eabi` GCC 16.1.
Both GCC targets are built from the same pinned modern GCC source, while their
target libraries and ABI checks remain separate. The Linux container provides
both GCC and Clang.

The bootstrap supports macOS through Homebrew and Linux through ordinary
system development packages. Both hosts use the same pinned target sources and
Palm patches. Generated Palm code does not depend on the host system compiler
used to build GCC itself.

Users do not need to install or manage Retro68 separately. Palm C projects
should still select a language version explicitly, such as `-std=gnu17`, to
keep builds deterministic.

`make check` compiles Palm headers and the example application against the
locally adapted SDK, catching regressions in the GCC trap declarations.

## License

Original material in this repository is available under the MIT License. See
`THIRD_PARTY.md` for the licensing of external inputs and compatibility
patches.
