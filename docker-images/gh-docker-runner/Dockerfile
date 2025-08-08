# ───────────────────────────────────────────────
# gh-docker-runner — GitHub Actions self-hosted runner
# with Docker CLI + Buildx (host daemon via /var/run/docker.sock)
# ───────────────────────────────────────────────
FROM debian:stable-slim@sha256:377ddc2a20fe8632a49b69dcfff10fccbd5b4f0b8c2d593420a6a5e03070dfa1

ENV DEBIAN_FRONTEND=noninteractive

# --- Base packages -----------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      gnupg \
      lsb-release \
      jq \
      git \
      sudo \
      unzip \
      # --- FIX: Add missing dependency for the Actions Runner ---
      libicu72 \
    && rm -rf /var/lib/apt/lists/*

# --- Docker CLI + Buildx ------------------------------------------------------
# Add the official Docker apt repo (no daemon, just cli/buildx/compose-plugin)
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# --- GitHub CLI (gh) ---------------------------------------------------------
# This section was added to fix the "gh: command not found" error when tagging
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*


# --- Unprivileged runner user -------------------------------------------------
RUN useradd --create-home --shell /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

WORKDIR /home/runner

# --- Latest GitHub Actions runner --------------------------------------------
RUN RUNNER_VER="$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
              | jq -r '.tag_name' | sed 's/^v//')" && \
    curl -fsSL -o actions-runner.tar.gz \
         "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz" && \
    tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz

RUN chown -R runner:runner /home/runner
USER runner

# --- Entrypoint --------------------------------------------------------------
COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]