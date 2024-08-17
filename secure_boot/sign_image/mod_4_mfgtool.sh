#!/bin/bash

# Usage example:
# $ ./mod_4_mfgtool.sh clear_dcd_addr u-boot-dtb.imx
# $ ./cst --i u-boot-csf.txt --o u-boot-csf.bin
# $ ./mod_4_mfgtool.sh set_dcd_addr u-boot-dtb.imx

# Function to print an error message and exit
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    error_exit "Usage: $0 {clear_dcd_addr|set_dcd_addr} <file>"
fi

# Check if the input file exists
if [ ! -f "$2" ]; then
    error_exit "Error: File '$2' not found."
fi

# Clear the DCD address for signing, as UUU will clear it
if [ "$1" == "clear_dcd_addr" ]; then
    # Backup the original DCD address
    dd if="$2" of=dcd_addr.bin bs=1 count=4 skip=12 status=none || error_exit "Error: Failed to read DCD address."

    # Replace the DCD address with a NULL address
    dd if=/dev/zero of="$2" seek=12 bs=1 count=4 conv=notrunc status=none || error_exit "Error: Failed to clear DCD address."

    echo "DCD address cleared successfully."

# Restore the DCD address for mfgtool to locate the DCD table
elif [ "$1" == "set_dcd_addr" ]; then
    # Check if the backup DCD address file exists
    if [ ! -f dcd_addr.bin ]; then
        error_exit "Error: dcd_addr.bin not found. Please run 'clear_dcd_addr' first."
    fi

    # Restore the DCD address from the backup
    dd if=dcd_addr.bin of="$2" seek=12 bs=1 conv=notrunc status=none || error_exit "Error: Failed to restore DCD address."

    echo "DCD address restored successfully."

# Handle invalid commands
else
    error_exit "Invalid command. Use 'clear_dcd_addr' or 'set_dcd_addr'."
fi
