# Stick to the requested debian:stable-slim base image
FROM debian:stable-slim@sha256:377ddc2a20fe8632a49b69dcfff10fccbd5b4f0b8c2d593420a6a5e03070dfa1

# Set noninteractive frontend for apt to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install only the necessary OS dependencies for a GitHub Runner and Terraform
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl \
       jq \
       git \
       sudo \
       unzip \
       ca-certificates \
       # --- FIX: Updated package names for Debian 12 (Bookworm) ---
       libicu72 \
       libssl3 \
       libkrb5-3 \
       # --- AZURE CLI DEPENDENCIES ---
       apt-transport-https \
       lsb-release \
       gnupg \
    # --- INSTALL NODE.JS FOR TERRAFORM AZURE PROVIDER ---
    # Download and execute the NodeSource setup script for Node.js 20.x (LTS)
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    # Install Node.js
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- AZURE CLI INSTALLATION ---
# Add the Azure CLI repository and install the 'az' command
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
    && AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y azure-cli

# --- GitHub CLI (gh) ---------------------------------------------------------
# This section was added to allow the custom manual-approval workflow to run on the tf runner
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Create unprivileged runner user for security
RUN useradd --create-home --shell /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner

# Set the working directory
WORKDIR /home/runner

# Install latest GitHub Actions Runner
RUN RUNNER_VER=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
                 | jq -r '.tag_name' | sed 's/^v//') \
    && curl -fsSL \
       "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz" \
       -o actions-runner.tar.gz \
    && tar xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz

# Install latest Terraform
RUN TERRAFORM_VER=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform \
                   | jq -r '.current_version') \
    && curl -fsSL \
       "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip" \
       -o terraform.zip \
    && unzip terraform.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform.zip

# Fix ownership for the runner user
RUN chown -R runner:runner /home/runner

# Switch to the non-root user
USER runner

# Copy entrypoint and make executable
COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

# Set the entrypoint for the container
ENTRYPOINT ["./entrypoint.sh"]