# Use the latest stable Debian slim image as the base
FROM debian:stable-slim@sha256:377ddc2a20fe8632a49b69dcfff10fccbd5b4f0b8c2d593420a6a5e03070dfa1

# Set ENV for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites using a single RUN layer to reduce image size
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        curl \
        jq \
        ca-certificates \
        git \
        openssh-client \
        sudo \
        python3 \
        python3-pip \
        less \
    && rm -rf /var/lib/apt/lists/*

# Install the latest versions of Ansible and ansible-lint from PyPI
RUN echo "--- Installing latest Ansible and Ansible-Lint ---" \
    && pip3 install --break-system-packages --no-cache-dir --upgrade pip \
    && pip3 install --break-system-packages --no-cache-dir \
        ansible \
        ansible-lint \
        pywinrm \
        proxmoxer \
        requests

# Create a non-root user for the runner and give it passwordless sudo
RUN useradd --create-home --shell /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the runner's home directory for the download
WORKDIR /home/runner

# Dynamically find the latest GitHub Actions Runner, download, and install it
RUN echo "--- Fetching latest GitHub Actions Runner ---" \
    && LATEST_VERSION_TAG=$(curl --silent -L -H "Accept: application/vnd.github+json" https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name') \
    && LATEST_VERSION=$(echo "$LATEST_VERSION_TAG" | sed 's/v//') \
    && echo "Latest runner version is: ${LATEST_VERSION}" \
    && RUNNER_URL="https://github.com/actions/runner/releases/download/${LATEST_VERSION_TAG}/actions-runner-linux-x64-${LATEST_VERSION}.tar.gz" \
    && curl -o runner.tar.gz -L "${RUNNER_URL}" \
    && tar xzf ./runner.tar.gz \
    && rm ./runner.tar.gz

# Change ownership of the extracted files to the 'runner' user first.
RUN chown -R runner:runner /home/runner

# NOW, switch to the non-root 'runner' user for all subsequent commands.
USER runner

# As the 'runner' user, install collections and dependencies
RUN ansible-galaxy collection install community.general \
    && sudo /home/runner/bin/installdependencies.sh

# Copy the entrypoint script (already as the 'runner' user)
COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

# The entrypoint will be started by the container runtime
ENTRYPOINT ["/home/runner/entrypoint.sh"]