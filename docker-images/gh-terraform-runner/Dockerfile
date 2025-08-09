# GitHub Actions self-hosted runner for Terraform (+ Azure CLI)
FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive

# Base + Azure CLI deps + Node.js (you had this)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl jq git sudo unzip ca-certificates \
      libicu72 libssl3 libkrb5-3 \
      apt-transport-https lsb-release gnupg \
 && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
 && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/azure-cli.list \
 && apt-get update && apt-get install -y --no-install-recommends azure-cli \
 && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update && apt-get install -y gh \
 && rm -rf /var/lib/apt/lists/*

# Runner user
RUN useradd --create-home --shell /bin/bash runner \
 && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

WORKDIR /home/runner

# Actions runner
RUN RUNNER_VER=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
             | jq -r '.tag_name' | sed 's/^v//') \
 && curl -fsSL -o actions-runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz" \
 && tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz

# Terraform
RUN TERRAFORM_VER=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform \
               | jq -r '.current_version') \
 && curl -fsSL -o terraform.zip \
      "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip" \
 && unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip

RUN chown -R runner:runner /home/runner
USER runner

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
