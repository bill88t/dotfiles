#!/bin/bash
DRM_BASE="/sys/class/drm/"

if [ -d "$DRM_BASE" ]; then
    HIGHEST_CARD_NUM=$(find $DRM_BASE -maxdepth 1 -name "card*" | grep -v -E '.*-' | awk -F'/' '{print $NF}' | sort -n | tail -n 1)

    if [ -z "$HIGHEST_CARD_NUM" ]; then
        exit 1
    fi

    TARGET_CARD_DIR="${DRM_BASE}/${HIGHEST_CARD_NUM}/device"
    USED_MEM=$(cat "${TARGET_CARD_DIR}/mem_info_vram_used")
    TOTAL_MEM=$(cat "${TARGET_CARD_DIR}/mem_info_vram_total")
    PERCENT=$(awk "BEGIN {printf \"%.0f\", ($USED_MEM * 100) / $TOTAL_MEM}")
    MB_FACTOR=1048576
    USED_MB=$(awk "BEGIN {printf \"%.2f\", $USED_MEM / $MB_FACTOR}")
    TOTAL_MB=$(awk "BEGIN {printf \"%.2f\", $TOTAL_MEM / $MB_FACTOR}")
    echo "V ${PERCENT}%"
    echo "${USED_MB} / ${TOTAL_MB} MB"
fi
