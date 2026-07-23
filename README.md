# Palm Toolchain

Reproducible macOS tooling for compiling, packaging, and debugging Palm OS
software.

## Included

- Palm-compatible `m68k-none-elf` GCC 9.1
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

## Development status

The compiler is pinned to the latest Retro68 revision that passes the PalmTLS
runtime tests. Retro68's GCC 12, 15, and 16 branches currently regress the
Palm `-mshort` runtime, so GCC 9.1 remains the newest verified choice. The
repository patches its pointer-return ABI, FourCC handling, position-independent
runtime helpers, and Newlib `memset` stack layout.

Users do not need to install or manage Retro68 separately. Palm C projects
should still select a language version explicitly, such as `-std=gnu17`, to
keep builds deterministic.

`make check` compiles Palm headers and the example application against the
locally adapted SDK, catching regressions in the GCC trap declarations.

## License

Original material in this repository is available under the MIT License. See
`THIRD_PARTY.md` for the licensing of external inputs and compatibility
patches.
