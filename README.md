# Palm Toolchain

A self-contained macOS and Linux development environment for Palm OS
applications.

It provides:

- GCC 16.1 for Palm OS 68K applications
- GCC and G++ 16.1 for PEAL, XScale, and Wireless MMX ARM code
- GNU binutils 2.46.1 and GDB 17.2
- PilRC and the PRC packaging tools
- Clang support for small freestanding ARMlets
- an example Palm OS application and toolchain checks

Downloaded sources, build files, installed tools, and the SDK remain inside
the repository under `.toolchain/`. Nothing is installed globally.

## Requirements

You need an existing Palm OS SDK 5r4 directory. The SDK is user-supplied and
is not downloaded by this repository.

On macOS, install Xcode Command Line Tools, Homebrew, and the build
dependencies:

```sh
brew bundle
```

On Ubuntu 24.04:

```sh
sudo apt-get update
sudo apt-get install -y \
  autoconf automake bison build-essential ca-certificates clang cmake curl \
  flex git gperf libgmp-dev libmpc-dev libmpfr-dev libtool ninja-build \
  nodejs patch pkg-config texinfo xz-utils
```

The initial build requires an internet connection and several gigabytes of
free disk space.

## Setup

Clone the repository and run one setup command:

```sh
git clone https://github.com/palmsnipe/palm-toolchain.git
cd palm-toolchain
PALM_SDK_SOURCE=/path/to/sdk-5r4 make setup
```

This downloads verified, pinned sources and builds the 68K compiler, ARM
compiler, debugger, resource tools, and packaging tools. It copies the SDK
into `.toolchain/prefix/palmdev/sdk` and applies the compatibility fixes needed
by modern GCC and case-sensitive Linux filesystems. The supplied SDK directory
is never modified.

Verify the completed environment:

```sh
make check
```

`make bootstrap` remains available as an alias for `make setup`.

## Using the toolchain

For an interactive shell:

```sh
source scripts/activate.sh
```

This adds the tools to `PATH` and defines:

```text
PALM_TOOLCHAIN_PREFIX=/path/to/palm-toolchain/.toolchain/prefix
PALM_SDK_HOME=/path/to/palm-toolchain/.toolchain/prefix/palmdev/sdk
```

Application repositories can use `PALM_TOOLCHAIN_PREFIX` directly and do not
need a globally installed Palm compiler.

GDB is included for debugging 68K code. Interactive application debugging
also requires an emulator or device-side debugging stub that can communicate
with GDB.

## Example

Build and validate the included Hello World application:

```sh
make example
```

The resulting application is:

```text
examples/hello-world/build/HelloWorld.prc
```

## Reclaiming build space

The temporary compiler build directories consume most of the disk space.
After a successful setup, remove them with:

```sh
make clean
```

This retains downloaded archives, patched sources, the installed SDK, and the
working toolchain. A later rebuild recreates only the required build
directories.

For a completely fresh rebuild, remove `.toolchain/` manually and run setup
again.

## Linux container

The Dockerfile verifies an SDK-free Linux toolchain on Ubuntu 24.04:

```sh
docker build -t palm-toolchain:linux .
```

Install and check a user-supplied SDK in an ephemeral container:

```sh
docker run --rm \
  --mount type=bind,source=/path/to/sdk-5r4,target=/opt/palm-sdk,readonly \
  palm-toolchain:linux \
  bash -lc 'make install-sdk PALM_SDK_SOURCE=/opt/palm-sdk && make check'
```

The container is intended for Linux validation and future CI work; local
macOS and Linux users can use `make setup` directly.

## Technical details

See [TECHNICAL.md](TECHNICAL.md) for source pinning, Palm-specific GCC
changes, the repository layout, individual bootstrap targets, and validation
details.

## License

Original material in this repository is available under the MIT License. See
`THIRD_PARTY.md` for the licensing of external inputs and compatibility
patches.
