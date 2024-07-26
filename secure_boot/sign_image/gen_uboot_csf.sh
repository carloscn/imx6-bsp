#!/bin/bash

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 -f <input_file> -o <output_file>"
    exit 1
fi

while getopts ":f:o:" opt; do
    case $opt in
        f) input_file="$OPTARG"
        ;;
        o) output_file="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            exit 1
        ;;
    esac
done

file_size=$(stat -c%s "$input_file")
hex_size=$(printf '0x%x' "$file_size")

csf_content=$(cat <<EOF
[Header]
Version = 4.0
Security Configuration = Open
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS
Engine = CAAM

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
Blocks = 0x177ff400 0x0 $hex_size "u-boot.imx"
EOF
)

echo "$csf_content" > "$output_file"

echo "[INFO] Generated $output_file with file size $hex_size"