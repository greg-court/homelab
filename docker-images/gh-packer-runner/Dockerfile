# GitHub Actions self-hosted runner for Packer (+ Azure CLI)
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# OS deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl jq git sudo unzip libicu70 libssl3 libkrb5-3 genisoimage \
      gnupg lsb-release apt-transport-https ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends azure-cli \
 && rm -rf /var/lib/apt/lists/*

# Runner user
RUN useradd -m runner

WORKDIR /home/runner

# GitHub Actions runner
RUN RUNNER_VER=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
                    | jq -r '.tag_name' | sed 's/^v//') \
 && curl -fsSL \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz" \
      -o actions-runner.tar.gz \
 && tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz

# Packer
RUN PACKER_VER=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer \
                    | jq -r '.current_version') \
 && curl -fsSL \
      "https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_linux_amd64.zip" \
      -o packer.zip \
 && unzip packer.zip && mv packer /usr/local/bin/ && rm packer.zip

RUN chown -R runner:runner /home/runner
USER runner

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["./entrypoint.sh"]
