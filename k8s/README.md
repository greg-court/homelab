# optional

kubectl cordon n1.klab.internal
kubectl drain n1.klab.internal --ignore-daemonsets --delete-emptydir-data --forcey
kubectl delete node n1.klab.internal

# nuke

talosctl reset \
 --system-labels-to-wipe EPHEMERAL,STATE \
 --graceful=false \
 --reboot \
 -e n1.klab.internal -n n1.klab.internal
