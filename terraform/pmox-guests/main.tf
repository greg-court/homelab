locals {
  lxc_nodes = toset([for _, cfg in var.lxcs : cfg.node_name])
}

resource "proxmox_virtual_environment_file" "ansible_hook" {
  for_each     = local.lxc_nodes
  node_name    = each.key
  datastore_id = "local"
  content_type = "snippets"
  file_mode    = "0755"

  source_raw {
    file_name = "ansible-bootstrap.sh"
    data = <<HOOK
#!/usr/bin/env bash
vmid="$1"; phase="$2"
# Run a few seconds after post-start so the CT is unlocked & networking is up
if [ "$phase" = "post-start" ]; then
  nohup bash -c "
    sleep 5
    pct exec $vmid -- bash -s <<'SCRIPT'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Run once
if [ -f /root/.ansible_bootstrapped ]; then exit 0; fi

# Be tolerant of first-boot networks
for i in {1..20}; do apt-get update && break || sleep 2; done
apt-get install -y sudo openssh-server

# Create user if missing
id -u ansible >/dev/null 2>&1 || useradd --create-home --shell /bin/bash ansible

# SSH key
install -d -m 700 -o ansible -g ansible /home/ansible/.ssh
cat >/home/ansible/.ssh/authorized_keys <<'KEY'
${var.ansible_public_key}
KEY
chown -R ansible:ansible /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys

# Passwordless sudo
echo 'ansible ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible

# SSH service (Ubuntu/Debian)
systemctl enable --now ssh || systemctl enable --now sshd || true

touch /root/.ansible_bootstrapped
echo "Bootstrap complete."
SCRIPT
  " >/var/log/ct-$vmid-bootstrap.log 2>&1 &
fi
HOOK
  }
}

# Attach that hook to each LXC definition passed into the module
locals {
  lxcs_with_hook = {
    for name, cfg in var.lxcs :
    name => merge(cfg, {
      hook_script_file_id = proxmox_virtual_environment_file.ansible_hook[cfg.node_name].id
    })
  }
}

module "lxcs" {
  source = "../../tf-modules/proxmox-lxcs"
  lxcs   = local.lxcs_with_hook
}
