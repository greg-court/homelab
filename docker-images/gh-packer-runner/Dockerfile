FROM ubuntu:22.04@sha256:1ec65b2719518e27d4d25f104d93f9fac60dc437f81452302406825c46fcc9cb

# Install OS dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      curl jq git sudo unzip libicu70 libssl3 libkrb5-3 genisoimage \
    && rm -rf /var/lib/apt/lists/*

# Create unprivileged runner user
RUN useradd -m runner

# Set working directory for runner
WORKDIR /home/runner

# Install latest GitHub Actions runner
RUN RUNNER_VER=$(curl -s https://api.github.com/repos/actions/runner/releases/latest \
                    | jq -r '.tag_name' | sed 's/^v//') && \
    curl -fsSL \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VER}/actions-runner-linux-x64-${RUNNER_VER}.tar.gz" \
      -o actions-runner.tar.gz && \
    tar xzf actions-runner.tar.gz && rm actions-runner.tar.gz

# Install latest Packer
RUN PACKER_VER=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer \
                    | jq -r '.current_version') && \
    curl -fsSL \
      "https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_linux_amd64.zip" \
      -o packer.zip && \
    unzip packer.zip && mv packer /usr/local/bin/ && rm packer.zip

# Ensure runner ownership
RUN chown -R runner:runner /home/runner

# Switch to non-root
USER runner

# Copy entrypoint script
COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

# Expose port (if used by runner)
EXPOSE 8080

# Set entrypoint to the script
ENTRYPOINT ["./entrypoint.sh"]