#!/bin/bash

set_resolution() {
    local WH="$1"
    if [ "$WH" = "native" ]; then
        env -u LD_PRELOAD /system/bin/cmd activity broadcast \
            --user 0 \
            -a com.termux.x11.CHANGE_PREFERENCE \
            -p com.termux.x11 \
            --es displayResolutionMode native \
            2>/dev/null
    else
        env -u LD_PRELOAD /system/bin/cmd activity broadcast \
            --user 0 \
            -a com.termux.x11.CHANGE_PREFERENCE \
            -p com.termux.x11 \
            --es displayResolutionMode custom \
            --es displayResolutionCustom "$WH" \
            2>/dev/null
    fi
}

CHOICE=$(zenity --list \
    --title="Set Resolution" \
    --column="Resolution" --column="Description" \
    "native"      "native     — device native resolution" \
    "1920x1080"   "1920x1080  — 16:9 FHD" \
    "1600x900"    "1600x900   — 16:9" \
    "1280x720"    "1280x720   — 16:9 HD" \
    "960x540"     "960x540    — 16:9" \
    "2160x1008"   "2160x1008  — S24+ 19.5:9" \
    "1544x720"    "1544x720   — S24+ 19.5:9" \
    "1160x540"    "1160x540   — S24+ 19.5:9" \
    "2184x1968"   "2184x1968  — Fold7 inner 10:9" \
    "1456x1312"   "1456x1312  — Fold7 inner 10:9" \
    "1096x984"    "1096x984   — Fold7 inner 10:9" \
    "2520x1080"   "2520x1080  — Fold7 cover 21:9" \
    "1680x720"    "1680x720   — Fold7 cover 21:9" \
    "1264x540"    "1264x540   — Fold7 cover 21:9" \
    2>/dev/null)

[ -z "$CHOICE" ] && exit 0
set_resolution "$CHOICE"
