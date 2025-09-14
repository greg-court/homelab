## On local client

```bash
ssh-keygen -R pve
ssh-copy-id -o StrictHostKeyChecking=no root@pve
```

## Install diagnostics packages

```
apt install tree
```

## Configure apt

```bash
#!/bin/bash
set -e

echo ">>> Disabling Proxmox enterprise repo"
sed -i.bak 's/^deb https:/#deb https:/' /etc/apt/sources.list.d/pve-enterprise.list 2>/dev/null || true

echo ">>> Disabling Ceph enterprise repo (if exists)"
sed -i.bak 's|^deb https://enterprise.proxmox.com/debian/ceph.*|# &|' /etc/apt/sources.list.d/*ceph*.list 2>/dev/null || true

echo ">>> Adding Proxmox no-subscription repo"
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-install-repo.list

echo ">>> Adding Debian main repos"
cat <<EOF > /etc/apt/sources.list.d/debian.list
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org/debian-security bookworm-security main contrib
EOF

echo ">>> Downloading Proxmox GPG key"
wget -q https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg \
  -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

echo ">>> Updating and upgrading"
apt update
apt -y full-upgrade
apt autoremove -y
apt clean

echo ">>> DONE"
reboot
```

```bash
## Set local to accept only snippets

pvesm set local --content snippets

### Backup storage etc

pvesm add nfs nfs-hdd \
    -server truenas.internal \
    -export /mnt/tank-smr/proxmox \
    -path /mnt/pve/nfs-hdd \
    -content snippets,vztmpl,backup,iso,import \
    -options vers=4 \
    --prune-backups keep-all=1

### VM disks

# - RUN ON ONE NODE!
########################################## PART 1
# 0) Discover the target again (one node is enough – others will pick it up)
iscsiadm -m discovery -t sendtargets -p truenas.internal

# 1) Add the raw iSCSI LUN to Proxmox (content=none; no “use LUNs directly”)
pvesm add iscsi iscsi-raw \
  -portal truenas.internal \
  -target iqn.2005-10.org.freenas.ctl:proxmox-vm \
  -content none

# 2) Get the device path that appeared
ls -l /dev/disk/by-id/ | grep -i scsi    # find the line for your LUN
DEV=/dev/disk/by-id/scsi-36589cfc0000005b94968269e41f463c2   # <-- adjust

# 3) Create a *regular* LVM volume group on the LUN
pvcreate "$DEV"
vgcreate vg-iscsi "$DEV"

# 4) Register the VG as LVM (THICK) storage in Proxmox
# LVM THIN NOT SUPPORTED FOR MULTI-NODE ACCESS!
pvesm add lvm iscsi-thick \
  -vgname vg-iscsi \
  -content images,rootdir

# 5) Mark it shared in the UI (just metadata; LVM itself still serialises access)
pvesm set iscsi-thick --shared 1

# 6) Verify everything
pvesm status
vgs        # should list vg-iscsi as “shared” and “active”
```

Then reboot other nodes.

LXCs:

```bash
pvesm add nfs nfs-lxc \
  -server truenas.internal \
  -export /mnt/tank-ssd/proxmox-lxc \
  -path /mnt/pve/nfs-lxc \
  -content rootdir \
  -options vers=4
```

## Datacenter configuration

Double check current settings:

```bash
cat /etc/pve/datacenter.cfg
```

Configure:

```bash
cat <<EOF > /etc/pve/datacenter.cfg
keyboard: en-us
tag-style: color-map=dmz:ff2600:FFFFFF
EOF
```

## Configure Backup

```bash
pvesh create /cluster/backup \
  --id daily-all-9pm \
  --all 1 \
  --storage nfs-hdd \
  --mode snapshot \
  --compress zstd \
  --schedule 21:00 \
  --mailto gregcourt10@gmail.com \
  --prune-backups 'keep-daily=7,keep-weekly=4,keep-monthly=3' \
  --notes-template '{{guestname}}' \
  --enabled 1
```

## Enable promiscuous mode on k8s VMs (avoid issues with VIP ARP)

```bash
# loops through VMs with name 'k8s' in it and enables promisc on them
for ID in $(qm list | awk 'tolower($2) ~ /k8s/ {print $1}'); do
  for IF in tap${ID}i0 fwbr${ID}i0 fwpr${ID}p0; do
    ip link show "$IF" >/dev/null 2>&1 && ip link set "$IF" promisc on
  done
done

# or temporarily (though security risk):
ip link set bond0 promisc on
ip link set vmbr0 promisc on
```
