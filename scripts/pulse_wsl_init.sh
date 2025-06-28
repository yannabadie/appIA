# Usage : source scripts/pulse_wsl_init.sh
export PULSE_SERVER="tcp:$(grep nameserver /etc/resolv.conf | awk '{print $2}')"
echo "[Jarvis] PULSE_SERVER défini à $PULSE_SERVER"
