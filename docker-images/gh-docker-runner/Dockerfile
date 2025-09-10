# Docker + Buildx + Azure CLI + GitHub CLI on top of the official runner
FROM ghcr.io/actions/actions-runner:latest

USER root

# Common deps
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg lsb-release jq \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI + Buildx + Compose (official Docker APT repo, multi-arch)
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo $ID)/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$(. /etc/os-release; echo $ID) \
    $(. /etc/os-release; echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list \
 && apt-get update && apt-get install -y --no-install-recommends \
      docker-ce-cli docker-buildx-plugin docker-compose-plugin \
 && rm -rf /var/lib/apt/lists/*

# Azure CLI (official Microsoft repo, multi-arch)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] \
    https://packages.microsoft.com/repos/azure-cli/ \
    $(. /etc/os-release; echo $VERSION_CODENAME) main" \
    > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends azure-cli \
 && rm -rf /var/lib/apt/lists/*

# GitHub CLI (official repo)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends gh \
 && rm -rf /var/lib/apt/lists/*

# IMPORTANT: leave the base image's entrypoint intact (ARC will configure the runner)
USER runner
