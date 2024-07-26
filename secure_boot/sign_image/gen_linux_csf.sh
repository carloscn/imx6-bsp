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
        \?) echo "[ERR] Invalid option -$OPTARG" >&2
            exit 1
        ;;
    esac
done

ZIMAGE=${input_file}
GENIVT=genIVT
IVT_BIN=ivt.bin
ZIMAGE_PAD_BIN=zImage-pad.bin
ZIMAGE_PAD_IVT_BIN=zImage-pad-ivt.bin

# Get zImage file size and check for errors
ZIMAGE_SIZE=$(stat -c%s "$ZIMAGE")
if [ $? -ne 0 ] || [ "$ZIMAGE_SIZE" -eq 0 ]; then
    echo "[ERR] Failed to get zImage size or size is 0"
    exit 1
fi

NEXT_4KB_BOUNDARY=$(( (ZIMAGE_SIZE + 0xFFF) & ~0xFFF ))
NEXT_4KB_BOUNDARY_HEX=$(printf "0x%X" $NEXT_4KB_BOUNDARY)

# Generate genIVT script
cat <<EOF > $GENIVT
#! /usr/bin/perl -w
use strict;
open(my \$out, '>:raw', 'ivt.bin') or die "Unable to open: \$!";
print \$out pack("V", 0x412000D1); # IVT Header
print \$out pack("V", 0x10801000); # Jump Location
print \$out pack("V", 0x0); # Reserved
print \$out pack("V", 0x0); # DCD pointer
print \$out pack("V", 0x0); # Boot Data
print \$out pack("V", 0x$((NEXT_4KB_BOUNDARY_HEX + 0x10000000))); # Self Pointer
print \$out pack("V", 0x$((NEXT_4KB_BOUNDARY_HEX + 0x10000020))); # CSF Pointer
print \$out pack("V", 0x0); # Reserved
close(\$out);
EOF

chmod +x $GENIVT
./$GENIVT

# Check genIVT execution result
if [ $? -ne 0 ]; then
    echo "[ERR] Failed to execute genIVT"
    exit 1
fi

# Pad zImage and check objcopy execution result
objcopy -I binary -O binary --pad-to=$NEXT_4KB_BOUNDARY --gap-fill=0x00 $ZIMAGE $ZIMAGE_PAD_BIN
if [ $? -ne 0 ]; then
    echo "[ERR] objcopy failed"
    exit 1
fi

# Concatenate zImage-pad.bin and ivt.bin
cat $ZIMAGE_PAD_BIN $IVT_BIN > $ZIMAGE_PAD_IVT_BIN

# Check zImage-pad-ivt.bin file size
ZIMAGE_PAD_SIZE=$(stat -c%s "$ZIMAGE_PAD_IVT_BIN")
if [ $? -ne 0 ] || [ "$ZIMAGE_PAD_SIZE" -eq 0 ]; then
    echo "[ERR] Failed to get zImage-pad-ivt.bin size or size is 0"
    exit 1
fi
hex_size=$(printf '0x%x' "$ZIMAGE_PAD_SIZE")

# Create u-boot.csf content
csf_content=$(cat <<EOF
[Header]
Version = 4.0
Hash Algorithm = sha256
Engine Configuration = 0
Certificate Format = X509
Signature Format = CMS

[Install SRK]
File = "../certs/SRK_1_2_3_4_table.bin"
Source index = 0

[Install CSFK]
File = "../certs/CSF2_1_sha256_2048_65537_v3_usr_crt.pem"

[Authenticate CSF]

[Install Key]
Verification index = 0
Target index = 2
File = "../certs/IMG2_1_sha256_2048_65537_v3_usr_crt.pem"

[Authenticate Data]
Verification index = 2
Blocks = 0x10800000 0x0 ${hex_size} "zImage-pad-ivt.bin"

EOF
)

# Write content to output file
echo "$csf_content" > "$output_file"

echo "[INFO] Generated $output_file with file size $hex_size"