#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-taimen-dump}"
mkdir -p "$OUT"

PARTITIONS=(
    boot_a boot_b
    dtbo_a dtbo_b
    vendor_a vendor_b
    system_a system_b
    vbmeta_a vbmeta_b
    userdata
)

echo "Checking device..."
adb get-state >/dev/null

echo "Checking root..."
adb shell 'id' | grep -q 'uid=0' ||
    { echo "ERROR: root unavailable"; exit 1; }

echo "Dumping to: $OUT"
echo

for part in "${PARTITIONS[@]}"; do
    echo "==> $part"

    adb exec-out "dd if=/dev/block/by-name/$part bs=4M 2>/dev/null" > "$OUT/$part.img"

    # Make sure we didn't get an empty/truncated result.
    if [[ ! -s "$OUT/$part.img" ]]; then
        echo "ERROR: $part produced an empty image"
        rm -f "$OUT/$part.img"
        exit 1
    fi

    sha256sum "$OUT/$part.img" >> "$OUT/SHA256SUMS"
done

echo
echo "Done."
echo "Hashes: $OUT/SHA256SUMS"
