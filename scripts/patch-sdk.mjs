#!/usr/bin/env node

import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const sdkRoot = process.argv[2];
if (!sdkRoot) {
  console.error("usage: patch-sdk.mjs <Palm OS SDK 5r4 directory>");
  process.exit(2);
}

const palmTypesPath = join(sdkRoot, "include", "PalmTypes.h");
const original = readFileSync(palmTypesPath, "utf8");
const eol = original.includes("\r\n") ? "\r\n" : "\n";
let source = original.replaceAll("\r\n", "\n");

if (source.includes("__raw_inline__")) {
  if (source.includes("__callseq__")) {
    throw new Error("PalmTypes.h contains both callseq and raw_inline trap declarations");
  }
  console.log("Palm OS SDK GCC trap declarations are already compatible");
} else {
  const startMarker = "\t#ifndef _PalmTypes_OS_CALL_Str";
  const endMarker =
    "\n #else\n\n\t#define _OS_CALL(table, vector)  __attribute__ ((systrap (vector)))";
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start);

  if (start < 0 || end < 0 || !source.slice(start, end).includes("__callseq__")) {
    throw new Error("unsupported PalmTypes.h GCC trap declaration layout");
  }

  const replacement = `\
\t#define _OS_CALL(table, vector) \\
\t\t__attribute__((__raw_inline__(0x4E40 + table, vector)))

\t#define _OS_CALL_WITH_SELECTOR(table, vector, selector) \\
\t\t__attribute__((__raw_inline__(0x7400 + selector, 0x4E40 + table, vector)))

\t#define _OS_CALL_WITH_16BIT_SELECTOR(table, vector, selector) \\
\t\t__attribute__((__raw_inline__(0x3F3C, selector, 0x4E40 + table, vector, 0x544F)))

\t#define _OS_CALL_WITH_UNPOPPED_16BIT_SELECTOR(table, vector, selector) \\
\t\t__attribute__((__raw_inline__(0x3F3C, selector, 0x4E40 + table, vector)))
`;

  source = source.slice(0, start) + replacement + source.slice(end);
  if (source.includes("__callseq__") || !source.includes("__raw_inline__")) {
    throw new Error("failed to replace Palm OS GCC trap declarations");
  }

  writeFileSync(palmTypesPath, source.replaceAll("\n", eol));
  console.log("Applied Palm OS SDK GCC trap compatibility patch");
}

const systemPublicPath = join(
  sdkRoot,
  "include",
  "Core",
  "System",
  "SystemPublic.h",
);
const systemPublic = readFileSync(systemPublicPath, "utf8");
const portableSystemPublic = systemPublic.replace(
  "#include <IMCUtils.h>",
  "#include <ImcUtils.h>",
);
if (portableSystemPublic !== systemPublic) {
  writeFileSync(systemPublicPath, portableSystemPublic);
  console.log("Corrected Palm OS SDK header casing for case-sensitive filesystems");
}
