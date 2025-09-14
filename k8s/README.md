# Force reboot cluster

talosctl reboot \
 -n 192.168.2.231,192.168.2.232,192.168.2.233 \
 --mode=powercycle \
 --wait=false \
 --timeout=1m
