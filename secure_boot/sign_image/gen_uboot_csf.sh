#!/bin/bash

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 -f <input_file> -o <output_file> -l <log_file>"
    exit 1
fi

while getopts ":f:o:l:" opt; do
    case $opt in
        f) input_file="$OPTARG"
        ;;
        o) output_file="$OPTARG"
        ;;
        l) log_file="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            exit 1
        ;;
    esac
done

file_size=$(stat -c%s "$input_file")
hex_size=$(printf '0x%x' "$file_size")

# Parse log file
if [ ! -f "$log_file" ]; then
    echo "[ERR] Log file $log_file not found"
    exit 1
fi

# Extract HAB Blocks information from log file
hab_blocks=$(grep "HAB Blocks" "$log_file" | awk '{print $3, $4, $5}')
if [ -z "$hab_blocks" ]; then
    echo "[ERR] Could not find HAB Blocks in log file"
    exit 1
fi

# Extract sign_len, start_address, and log_hex_size
read -r sign_len start_address log_hex_size <<< "$hab_blocks"

# Remove leading zeros and add 0x prefix
sign_len=$(printf "0x%x" $((16#$sign_len)))
start_address=$(printf "0x%x" $((16#$start_address)))
log_hex_size=$(printf "0x%x" $((16#$log_hex_size)))

# Compare log hex_size with actual file hex_size
if [ "$hex_size" != "$log_hex_size" ]; then
    echo "[ERR] Log hex_size $log_hex_size does not match file hex_size $hex_size"
    exit 1
fi

# Generate CSF file content
csf_content=$(cat <<EOF
[Header]
Version = 4.0
Security Configuration = Open
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = SW

[Install SRK]
File = "../certs/SRK_1_2_3_4_table.bin"
Source index = 0

[Install CSFK]
File = "../certs/CSF1_1_sha256_2048_65537_v3_usr_crt.pem"

[Authenticate CSF]

[Install Key]
# Key slot index used to authenticate the key to be installed
Verification index = 0
# Key to install
Target index = 2
File = "../certs/IMG1_1_sha256_2048_65537_v3_usr_crt.pem"

[Authenticate Data]
Verification index = 2
Blocks = $sign_len $start_address $hex_size "u-boot.imx"
EOF
)

# Write content to output file
echo "$csf_content" > "$output_file"

echo "[INFO] Generated $output_file with file size $hex_size"
