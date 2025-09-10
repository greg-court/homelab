# Ansible (+ Azure CLI) on top of the official runner
FROM ghcr.io/actions/actions-runner:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release \
      python3 python3-pip python3-venv \
      git openssh-client jq \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] \
    https://packages.microsoft.com/repos/azure-cli/ \
    $(. /etc/os-release; echo $VERSION_CODENAME) main" \
    > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends azure-cli \
 && rm -rf /var/lib/apt/lists/*

# Ansible + friends (pip; multi-arch safe)
RUN pip3 install --no-cache-dir --upgrade pip \
 && pip3 install --no-cache-dir \
      ansible ansible-lint pywinrm proxmoxer requests

USER runner
