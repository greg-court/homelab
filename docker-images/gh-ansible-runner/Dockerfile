# GitHub Actions self-hosted runner for Ansible (+ Azure CLI)
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Base tooling
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends \
      curl jq ca-certificates git openssh-client sudo \
      python3 python3-pip less \
      gnupg lsb-release apt-transport-https \
 && rm -rf /var/lib/apt/lists/*

# Azure CLI (official repo)
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends azure-cli \
 && rm -rf /var/lib/apt/lists/*

# Ansible + tools
RUN pip3 install --break-system-packages --no-cache-dir --upgrade pip \
 && pip3 install --break-system-packages --no-cache-dir \
      ansible ansible-lint pywinrm proxmoxer requests

# Runner user
RUN useradd --create-home --shell /bin/bash runner \
 && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/runner

# Latest GitHub Actions runner
RUN LATEST_VERSION_TAG=$(curl -sL -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name') \
 && LATEST_VERSION=${LATEST_VERSION_TAG#v} \
 && curl -fsSL -o runner.tar.gz \
      "https://github.com/actions/runner/releases/download/${LATEST_VERSION_TAG}/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz" \
 && tar xzf runner.tar.gz && rm runner.tar.gz \
 && chown -R runner:runner /home/runner

USER runner

# Install runner deps script (as provided by actions runner)
RUN sudo /home/runner/bin/installdependencies.sh

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["/home/runner/entrypoint.sh"]
