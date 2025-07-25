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
