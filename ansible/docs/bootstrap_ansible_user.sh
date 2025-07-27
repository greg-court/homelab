set -e

ANSIBLE_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDJp/CC2LAbxlvjOWA9Op/mhtA0An/WLzb9cOYJT/r/ ansible-deploy-key"

# 1. Update package lists and install sudo if it's missing
apt-get update
apt-get install -y sudo

# 2. Create the 'ansible' user
useradd --create-home --shell /bin/bash ansible

# 3. Grant passwordless sudo privileges to the 'ansible' user
echo 'ansible ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/ansible

# 4. Set up the SSH authorized key for the 'ansible' user
mkdir -p /home/ansible/.ssh
echo "${ANSIBLE_PUBLIC_KEY}" > /home/ansible/.ssh/authorized_keys

# 5. Set correct permissions for the SSH directory and key
chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys

echo "Bootstrap complete. The 'ansible' user is ready."