#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=common.sh
source "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

mkdir -p "$DOWNLOADS" "$SOURCES"

download_verified "$RETRO68_SOURCE_URL" "$DOWNLOADS/$RETRO68_SOURCE_FILE" "$RETRO68_SOURCE_SHA256"
download_verified "$PILRC_URL" "$DOWNLOADS/$PILRC_FILE" "$PILRC_SHA256"
download_verified "$GDB_URL" "$DOWNLOADS/$GDB_FILE" "$GDB_SHA256"
download_verified "$CONFIG_GUESS_URL" "$DOWNLOADS/config.guess" "$CONFIG_GUESS_SHA256"
download_verified "$CONFIG_SUB_URL" "$DOWNLOADS/config.sub" "$CONFIG_SUB_SHA256"
clone_at "$PRC_TOOLS_REPOSITORY" "$SOURCES/prc-tools-remix" "$PRC_TOOLS_COMMIT"

echo "Verified sources are available under $TOOLCHAIN_STATE"
