## On local client

```bash
for host in pve01 pve02 pve03; do ssh-keygen -R $host; done
for host in pve01 pve02 pve03; do ssh-copy-id -o StrictHostKeyChecking=no root@$host; done
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

```bash
pvesm add nfs remote-hdd \
    -server truenas.internal \
    -export /mnt/tank-smr/proxmox \
    -path /mnt/pve/remote-hdd \
    -content snippets,rootdir,backup,iso,import \
    -options vers=4 \
    --prune-backups keep-all=1
```

```bash
pvesm add iscsi remote-iscsi \
    -portal truenas.internal \
    -target iqn.2025-07.local.truenas:proxmox-extent \
    -content images
```
