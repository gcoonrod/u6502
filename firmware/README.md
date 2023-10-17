# u6502 - Firmware

This directory contains the various programs, libraries, and utilities used by the u6502 SBC. 

## Build Process
Currently, all programs for the u6502 are assembled using the ca65 macro assembler which is a part of the [cc65 C Compiler](https://cc65.github.io/) project. ROMs are built in the following two step process:

1. Assembly - `ca65 -vvv --cpu 6502 -l {listingFilePath} -o {outputObjectFilePath} {sourceFilePath}`
2. Linking - `ld65 -o {outputBinaryPath} -C {linkerConfigFilePath} "{objectFilePath}"`
3. Flashing - The output from the linker is a binary that can be burned to the EEPROM (U3). This binary should work with any number of EEPROM programers, but I have only tested it with Xgpro.

A simple PowerShell script [build.ps1](build.ps1) is used to automate the build process in a Windows build environment. Usage of this script requires that the cc65 binaries be in the PATH environment variable. When using this script all output will go into the `build` directory.

### Linker Configuration
The cc65 linker (`ld65`) uses a configuration file to properly layout all of the assembled sources into a single output binary. I don't fully understand the syntax and capabilities of this configuration tool, but the [documentation](https://cc65.github.io/doc/ld65.html) is fairly good. In the case of the u6502, `roms/common/memmap.cfg` is the linker configuration. Of most importance here are the `MEMORY` and `SEGMENTS` sections which define the system's memory map and correlate any segments used in the assembly files with the correct memory locations.