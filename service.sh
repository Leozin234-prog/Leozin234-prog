#!/system/bin/sh
# =====================================================================
#   GFX GAMER LAB - AxManager Module (service.sh)
#   Real ADB-based optimizations. No root. No fake claims.
#
#   Telegram : https://t.me/gfxgamerlab
#   YouTube  : https://www.youtube.com/@GfxGamerLab_1
#   WhatsApp : https://whatsapp.com/channel/0029VbB1E5VFsn0o8MNoAp2l
# =====================================================================

MODDIR="${0%/*}"
LOG="/data/local/tmp/gfxgamerlab.log"
CONFIG="$MODDIR/games.conf"
STATE_FILE="/data/local/tmp/gfxgamerlab_state"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"
}

# ---------------------------------------------------------------------
# Default game package list (user can add their own in games.conf)
# ---------------------------------------------------------------------
if [ ! -f "$CONFIG" ]; then
    cat > "$CONFIG" << 'EOF'
# Add one game package name per line.
# Find your game's package name with:
#   adb shell pm list packages | grep -i <part-of-game-name>
#
# Examples (uncomment / edit as needed):
#com.pubg.imobile
#com.tencent.ig
#com.dts.freefireth
#com.activision.callofduty.shooter
EOF
fi

# ---------------------------------------------------------------------
# Apps that are NEVER killed (system-critical, keep device stable)
# ---------------------------------------------------------------------
WHITELIST="com.android.systemui com.android.phone com.android.settings com.axeron.manager com.android.shell"

is_whitelisted() {
    pkg="$1"
    for w in $WHITELIST; do
        [ "$pkg" = "$w" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------
# Get current foreground app package name
# ---------------------------------------------------------------------
get_foreground_pkg() {
    dumpsys window windows 2>/dev/null | grep -m1 'mCurrentFocus' | \
        sed -n 's/.*[{ ]\([a-zA-Z0-9_.]*\)\/.*/\1/p'
}

# ---------------------------------------------------------------------
# Apply gaming optimizations (real, verified ADB settings)
# ---------------------------------------------------------------------
apply_gaming_mode() {
    log "Gaming mode ON - applying optimizations"

    # Force highest supported refresh rate
    MAXRATE=$(dumpsys display 2>/dev/null | tr ',' '\n' | \
        awk -F= '/^ *fps/ {print $2}' | sort -n | tail -1)
    [ -z "$MAXRATE" ] && MAXRATE=90
    settings put system peak_refresh_rate "${MAXRATE}.0" 2>/dev/null
    settings put system min_refresh_rate "${MAXRATE}.0" 2>/dev/null

    # Reduce animations (0.5x, not fully off, per user preference - keeps UI usable)
    settings put global window_animation_scale 0.5 2>/dev/null
    settings put global transition_animation_scale 0.5 2>/dev/null
    settings put global animator_duration_scale 0.5 2>/dev/null

    # Disable window blur / transparency effects (frees GPU compositing load)
    settings put global disable_window_blurs 1 2>/dev/null
    settings put secure accessibility_reduce_transparency 1 2>/dev/null

    # Stop adaptive battery throttling while gaming
    settings put global adaptive_battery_management_enabled 0 2>/dev/null

    # Samsung-specific: disable GOS throttling + boost CPU responsiveness (no-op on non-Samsung)
    settings put global sem_enhanced_cpu_responsiveness 1 2>/dev/null

    log "Optimizations applied (refresh=${MAXRATE}Hz, anim=0.5x)"
}

# ---------------------------------------------------------------------
# Revert everything to Android defaults when game closes
# ---------------------------------------------------------------------
revert_gaming_mode() {
    log "Gaming mode OFF - reverting to defaults"

    settings delete system peak_refresh_rate 2>/dev/null
    settings delete system min_refresh_rate 2>/dev/null
    settings put global window_animation_scale 1.0 2>/dev/null
    settings put global transition_animation_scale 1.0 2>/dev/null
    settings put global animator_duration_scale 1.0 2>/dev/null
    settings put global disable_window_blurs 0 2>/dev/null
    settings put secure accessibility_reduce_transparency 0 2>/dev/null
    settings put global adaptive_battery_management_enabled 1 2>/dev/null

    log "Defaults restored"
}

# ---------------------------------------------------------------------
# Kill all background apps except whitelist + the game itself
# ---------------------------------------------------------------------
kill_background_apps() {
    game_pkg="$1"
    RUNNING=$(dumpsys activity activities 2>/dev/null | \
        grep -o '[a-zA-Z0-9_.]*\/[a-zA-Z0-9_.]*' | cut -d/ -f1 | sort -u)
    for pkg in $RUNNING; do
        if [ "$pkg" != "$game_pkg" ] && ! is_whitelisted "$pkg"; then
            am force-stop "$pkg" 2>/dev/null
            log "Closed background app: $pkg"
        fi
    done
}

# ---------------------------------------------------------------------
# Main monitor loop - checks foreground app every 2 seconds
# ---------------------------------------------------------------------
log "GFX Gamer Lab service started"
echo "idle" > "$STATE_FILE"

while true; do
    CURRENT=$(get_foreground_pkg)
    PREV_STATE=$(cat "$STATE_FILE" 2>/dev/null)

    if [ -n "$CURRENT" ] && grep -qx "$CURRENT" "$CONFIG" 2>/dev/null; then
        # A configured game is in the foreground
        if [ "$PREV_STATE" != "gaming:$CURRENT" ]; then
            apply_gaming_mode
            kill_background_apps "$CURRENT"
            echo "gaming:$CURRENT" > "$STATE_FILE"
        fi
    else
        # No configured game in foreground
        if [ "$PREV_STATE" != "idle" ]; then
            revert_gaming_mode
            echo "idle" > "$STATE_FILE"
        fi
    fi

    sleep 2
done
