#!/system/bin/sh
# Runs when user taps the "Action" button on this module in AxManager.
# Shows a live diagnostic snapshot - real data, no fake numbers.

echo "================================================="
echo "   GFX GAMER LAB - Live Diagnostic"
echo "   https://t.me/gfxgamerlab"
echo "================================================="
echo ""

echo "--- Display ---"
dumpsys display 2>/dev/null | grep -m1 "mActiveModeId\|refreshRate" 
settings get system peak_refresh_rate 2>/dev/null | sed 's/^/Current peak_refresh_rate: /'

echo ""
echo "--- Animation Scale ---"
echo "window_animation_scale    : $(settings get global window_animation_scale 2>/dev/null)"
echo "transition_animation_scale: $(settings get global transition_animation_scale 2>/dev/null)"
echo "animator_duration_scale   : $(settings get global animator_duration_scale 2>/dev/null)"

echo ""
echo "--- Network / Ping ---"
ping -c 4 8.8.8.8 2>/dev/null | tail -n 4

echo ""
echo "--- Memory ---"
cat /proc/meminfo 2>/dev/null | grep -E "MemTotal|MemAvailable"

echo ""
echo "--- Battery / Thermal ---"
dumpsys battery 2>/dev/null | grep -E "level|temperature|status"

echo ""
echo "--- Current Service State ---"
cat /data/local/tmp/gfxgamerlab_state 2>/dev/null

echo ""
echo "================================================="
echo "Telegram : https://t.me/gfxgamerlab"
echo "YouTube  : https://www.youtube.com/@GfxGamerLab_1"
echo "WhatsApp : https://whatsapp.com/channel/0029VbB1E5VFsn0o8MNoAp2l"
echo "================================================="
