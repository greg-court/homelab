# GitHub Actions self-hosted runner with Docker CLI/Buildx (+ Azure CLI)
FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# Base
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates gnupg lsb-release jq git sudo unzip libicu72 \
      apt-transport-https \
 && rm -rf /var/lib/apt/lists/*

# Docker CLI + Buildx (arch-portable via repo)
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list \
 && apt-get update && apt-get install -y --no-install-recommends \
      docker-ce-cli docker-buildx-plugin docker-compose-plugin \
 && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
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

# Select architecture-specific actions runner
ARG TARGETARCH
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) RUNNER_ARCH="x64" ;; \
      arm64) RUNNER_ARCH="arm64" ;; \
      *) echo "Unsupported arch: $TARGETARCH"; exit 1 ;; \
    esac; \
    RUNNER_VER="$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/^v//')"; \
    curl -fsSL -o actions-runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VER}.tar.gz"; \
    tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz \
 && chown -R runner:runner /home/runner

USER runner

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
