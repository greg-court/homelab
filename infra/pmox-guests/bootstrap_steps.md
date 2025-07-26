## On local client

```bash
for host in pve01 pve02 pve03; do ssh-keygen -R $host; done
for host in pve01 pve02 pve03; do ssh-copy-id -o StrictHostKeyChecking=no root@$host; done
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

## On primary node

```bash
pvecm create pve-cluster01
```

## On joining nodes

```bash
pvecm add pve01
```

## Add shared storage

On any node:

Backup storage etc:

```bash
pvesm add nfs remote-hdd \
    -server truenas.internal \
    -export /mnt/tank-smr/proxmox \
    -path /mnt/pve/remote-hdd \
    -content snippets,vztmpl,backup,iso,import \
    -options vers=4 \
    --prune-backups keep-all=1
```

VM disks:

```bash
pvesm add iscsi remote-iscsi \
    -portal truenas.internal \
    -target iqn.2005-10.org.freenas.ctl:proxmox-vm \
    -content images
```

LXCs:

```bash
pvesm add nfs remote-nfs \
  -server truenas.internal \
  -export /mnt/tank-ssd/proxmox-lxc \
  -path /mnt/pve/remote-nfs \
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
