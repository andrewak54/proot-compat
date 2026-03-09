#!/bin/bash

# Resolution switcher for termux-x11.
# Uses termux-x11-preference (works on all devices).
# Falls back to /system/bin/cmd broadcast if termux-x11-preference is missing.
# UI: xterm + bash select (zenity crashes under PRoot due to MIT-SHM BadAccess).

PREF=/data/data/com.termux/files/usr/bin/termux-x11-preference

set_resolution() {
    local WH="$1"
    unset LD_PRELOAD
    if [ -x "$PREF" ]; then
        if [ "$WH" = "native" ]; then
            $PREF displayResolutionMode:native 2>/dev/null
        else
            $PREF displayResolutionMode:custom displayResolutionCustom:"$WH" 2>/dev/null
        fi
    else
        if [ "$WH" = "native" ]; then
            /system/bin/cmd activity broadcast \
                --user 0 -a com.termux.x11.CHANGE_PREFERENCE -p com.termux.x11 \
                --es displayResolutionMode native 2>/dev/null
        else
            /system/bin/cmd activity broadcast \
                --user 0 -a com.termux.x11.CHANGE_PREFERENCE -p com.termux.x11 \
                --es displayResolutionMode custom \
                --es displayResolutionCustom "$WH" 2>/dev/null
        fi
    fi
}

# If running inside a terminal, show menu directly; otherwise open xterm
if [ -t 0 ]; then
    echo "=== Set Resolution ==="
    PS3="Select resolution (number): "
    select CHOICE in \
        "native      — device native" \
        "1920x1080   — 16:9 FHD" \
        "1600x900    — 16:9" \
        "1280x720    — 16:9 HD" \
        "960x540     — 16:9" \
        "2160x1008   — S24+ 19.5:9" \
        "1544x720    — S24+ 19.5:9" \
        "1160x540    — S24+ 19.5:9" \
        "2184x1968   — Fold7 inner 10:9" \
        "1456x1312   — Fold7 inner 10:9" \
        "1096x984    — Fold7 inner 10:9" \
        "2520x1080   — Fold7 cover 21:9" \
        "1680x720    — Fold7 cover 21:9" \
        "1264x540    — Fold7 cover 21:9"
    do
        [ -z "$CHOICE" ] && echo "Invalid choice" && continue
        RES="${CHOICE%%   *}"
        RES="${RES%% *}"
        set_resolution "$RES"
        echo "Set to: $RES"
        break
    done
else
    exec xterm -T "Set Resolution" -geometry 40x20 -e "$0"
fi
