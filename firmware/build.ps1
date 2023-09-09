# Using cc65 tools, assemble and link the firmware using the provided assembly file and
# linker configuration. The resulting binary is placed in the build directory.

# Get the assembly source file and linker configuration file from the command line arguments.
param (
    [Parameter(Mandatory=$true, Position=0)]
    [string]$sourceFile,
    [Parameter(Mandatory=$true, Position=1)]
    [string]$linkerConfigFile
)

# Create variables for the assembled output file, the listing file, and the linked binary file.
$objectFile = "build\" + [System.IO.Path]::GetFileNameWithoutExtension($sourceFile) + ".o"
$listingFile = "build\" + [System.IO.Path]::GetFileNameWithoutExtension($sourceFile) + ".lst"
$binaryFile = "build\" + [System.IO.Path]::GetFileNameWithoutExtension($sourceFile) + ".bin"

# Set up the build directory, if it doesn't exist.
if (!(Test-Path build)) {
    New-Item -ItemType Directory -Force -Path build
}

# Clean the build directory
Remove-Item -Force $objectFile
Remove-Item -Force $listingFile
Remove-Item -Force $binaryFile

# Assemble the firmware
ca65 -vvv --cpu 6502 -l $listingFile -o $objectFile $sourceFile

# Link the firmware
ld65 -o $binaryFile -C $linkerConfigFile "$objectFile"