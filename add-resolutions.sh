#!/bin/bash
OUTPUT="External Display"

add_mode() {
    local W=$1 H=$2 RATE=${3:-60}
    local MODELINE NAME
    MODELINE=$(cvt $W $H $RATE 2>/dev/null | grep Modeline | sed 's/.*Modeline //')
    [ -z "$MODELINE" ] && return
    NAME=$(echo "$MODELINE" | awk '{print $1}' | tr -d '"')
    xrandr --newmode $MODELINE 2>/dev/null
    xrandr --addmode "$OUTPUT" "$NAME" 2>/dev/null
}

# 16:9 standard
add_mode 1600 900
add_mode 1280 720
add_mode 960  540

# 19.5:9 — Samsung S24+ native ratio (3088x1440)
add_mode 2160 1008
add_mode 1544 720
add_mode 1160 540

# 10:9 — Samsung Z Fold7 inner screen (2184x1968)
add_mode 2184 1968
add_mode 1456 1312
add_mode 1092 984

# 21:9 — Samsung Z Fold7 cover screen (2520x1080)
add_mode 2520 1080
add_mode 1680 720
add_mode 1260 540
