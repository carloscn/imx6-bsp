#!/bin/bash

# Define the base path for the eFuse registers
REG_PATH="/sys/fsl_otp"

# Function to write and verify a value to a specific eFuse path
write_and_verify() {
    local value=$1
    local path=$2
    echo "[INFO] Writing $value to $path"
    echo "$value" > "$path"
    local read_value=$(cat "$path")
    if [ "$read_value" == "$value" ]; then
        echo "[INFO] Verification successful for $path: $read_value"
    else
        echo "[ERROR] Verification failed for $path! Expected: $value, Read: $read_value"
        return 1
    fi
    return 0
}

# Function to check if all relevant SRK registers are 0
check_registers_are_zero() {
    local paths=("${REG_PATH}/HW_OCOTP_SRK0" "${REG_PATH}/HW_OCOTP_SRK1" "${REG_PATH}/HW_OCOTP_SRK2" "${REG_PATH}/HW_OCOTP_SRK3"
                 "${REG_PATH}/HW_OCOTP_SRK4" "${REG_PATH}/HW_OCOTP_SRK5" "${REG_PATH}/HW_OCOTP_SRK6" "${REG_PATH}/HW_OCOTP_SRK7")

    for path in "${paths[@]}"; do
        # Check if the file exists
        if [ ! -f "$path" ]; then
            echo "[INFO] Register $path does not exist, treating as 0."
            continue
        fi

        local read_value=$(cat "$path" 2>/dev/null)  # Read value, ignore errors if file is empty or doesn't exist

        # If value is empty, treat it as 0
        if [ -z "$read_value" ]; then
            echo "[INFO] Register $path is empty, treating as 0."
            continue
        fi

        # Convert the hex value to integer for comparison
        local int_value=$((read_value))

        if [ "$int_value" -ne 0 ]; then
            echo "[ERROR] Register $path is not zero! Current value: $read_value (int: $int_value)"
            return 1
        fi
    done
    echo "[INFO] All relevant registers are zero."
    return 0
}

# Initialize variables
SRK_FUSE=""
LOCK=false
SUCCESS=true

# Parse arguments
while getopts ":f:l" opt; do
    case $opt in
        f)
            SRK_FUSE=$OPTARG
            ;;
        l)
            LOCK=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# If only -l is specified, write and verify CFG5 and exit
if [ -z "$SRK_FUSE" ] && $LOCK; then
    if write_and_verify "0x2" "${REG_PATH}/HW_OCOTP_CFG5"; then
        echo "[INFO] HW_OCOTP_CFG5 lock successful."
    else
        echo "[ERROR] HW_OCOTP_CFG5 lock failed."
        exit 1
    fi
    exit 0
fi

# Check if SRK_FUSE is specified
if [ -z "$SRK_FUSE" ]; then
    echo "Usage: $0 -f <SRK_FUSE> [-l]"
    exit 1
fi

# Check if the specified file exists
if [ ! -f "$SRK_FUSE" ]; then
    echo "Error: File $SRK_FUSE not found!"
    exit 1
fi

# Check if all relevant registers are zero (only when -f is specified)
if ! check_registers_are_zero; then
    echo "[ERROR] Registers are not in the expected state (all zero). Aborting."
    exit 1
fi

# Process the SRK values and write to eFuse
INDEX=0
while IFS= read -r line; do
    EXPECTED_VALUE="0x$line"
    EFUSE_PATH="${REG_PATH}/HW_OCOTP_SRK$INDEX"

    # Write and verify SRK values
    if ! write_and_verify "$EXPECTED_VALUE" "$EFUSE_PATH"; then
        SUCCESS=false
    fi

    INDEX=$((INDEX + 1))
done < <(hexdump -e '/4 "%08x\n"' "$SRK_FUSE")

# If lock is specified, write and verify CFG5 after SRK values
if $LOCK; then
    if write_and_verify "0x2" "${REG_PATH}/HW_OCOTP_CFG5"; then
        echo "[INFO] HW_OCOTP_CFG5 lock successful."
    else
        echo "[ERROR] HW_OCOTP_CFG5 lock failed."
        SUCCESS=false
    fi
fi

# Print final result
if $SUCCESS; then
    echo "[INFO] All eFuse values were written and verified successfully."
else
    echo "[ERROR] Some eFuse values failed verification."
    exit 1
fi
