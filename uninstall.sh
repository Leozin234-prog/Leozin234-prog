#!/system/bin/sh
# Runs automatically when AxManager removes this module.
# Restores all Android settings to their original defaults.

settings delete system peak_refresh_rate 2>/dev/null
settings delete system min_refresh_rate 2>/dev/null
settings put global window_animation_scale 1.0 2>/dev/null
settings put global transition_animation_scale 1.0 2>/dev/null
settings put global animator_duration_scale 1.0 2>/dev/null
settings put global disable_window_blurs 0 2>/dev/null
settings put secure accessibility_reduce_transparency 0 2>/dev/null
settings put global adaptive_battery_management_enabled 1 2>/dev/null

rm -f /data/local/tmp/gfxgamerlab_state
rm -f /data/local/tmp/gfxgamerlab.log
