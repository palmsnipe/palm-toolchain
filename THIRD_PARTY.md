# Third-party inputs

This repository contains build automation and compatibility patches, not
third-party source archives or generated binaries. Exact inputs are recorded in
`config/sources.lock`.

| Input | Source | Treatment |
| --- | --- | --- |
| Retro68 / GCC snapshot | Pinned archive | Downloaded by checksum and patched locally |
| PilRC 3.2 | SourceForge release | Downloaded by checksum and patched locally |
| prc-tools-remix | `jichu4n/prc-tools-remix` | Cloned at an exact commit and patched locally |
| GNU GDB | GNU release archive | Downloaded by checksum |
| GNU config scripts | `gcc-mirror/gcc` | Downloaded by checksum |
| Palm OS SDK 5r3 | User supplied | Never downloaded, redistributed, or modified by this repository |

The MIT License applies to original material authored for this repository.
Downloaded projects retain their own copyright and license. Compatibility
patches are provided under the terms of the upstream projects they modify.
