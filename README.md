# Palm Toolchain

Reproducible macOS tooling for compiling, packaging, and debugging Palm OS
software.

> [!IMPORTANT]
> This is an uncommitted extraction preview. The source layout and public
> release are still under review.

## Included

- `m68k-none-elf` GCC and binutils
- PilRC
- the PRC packaging and object-resource utilities from prc-tools-remix
- `m68k-none-elf-gdb`
- a user-supplied, unchanged Palm OS SDK 5r3 installation
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
- An existing Palm OS SDK 5r3 directory

The SDK directory must contain at least:

```text
sdk-5r3/
  Palm License.txt
  include/
    PalmOS.h
    PalmTypes.h
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

Provide the location of the SDK and build everything:

```sh
PALM_SDK_SOURCE=/path/to/sdk-5r3 make bootstrap
```

The first build downloads pinned sources, verifies their checksums, compiles
the toolchain, and installs everything under `.toolchain/prefix`. Subsequent
runs reuse the existing downloads and completed tools.

Verify the installation:

```sh
make check
```

The check compiles both a generic 68K source file and a source file including
`PalmOS.h`, then verifies the packaging utilities and debugger.

## Using the toolchain

For interactive shell use:

```sh
source scripts/activate.sh
```

This adds `.toolchain/prefix/bin` to `PATH` and defines:

```text
PALM_TOOLCHAIN_PREFIX=/path/to/palm-toolchain/.toolchain/prefix
PALM_SDK_HOME=/path/to/palm-toolchain/.toolchain/prefix/palmdev/sdk-5r3
```

Another repository can use `PALM_TOOLCHAIN_PREFIX` directly instead of
requiring global compiler installation.

## Palm OS SDK

The Palm OS SDK is not open-source project content. Obtain SDK 5r3 separately,
read its included license, and provide an existing directory explicitly during
bootstrap:

```sh
PALM_SDK_SOURCE=/path/to/sdk-5r3 make bootstrap
```

The installer verifies the expected layout and makes an unchanged local copy.
It never downloads the SDK.

Every network input is pinned by commit or SHA-256 in `config/sources.lock`.

## Development status

The compiler source is a pinned Retro68-derived snapshot. Retro68 is an
implementation detail of the compiler build; users do not need to install or
manage it separately.

Before the first release, compiler-side compatibility with the SDK's original
`callseq` declarations must be completed and covered by a Palm-header smoke
test. The SDK itself remains unchanged.

## License

Original material in this repository is available under the MIT License. See
`THIRD_PARTY.md` for the licensing of external inputs and compatibility
patches.
