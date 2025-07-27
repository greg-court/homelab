#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Config
###############################################################################
# These will be set by Terraform/Docker environment variables
: "${REPO_URL:?Must set REPO_URL}"
: "${GH_PAT:?Must set GH_PAT}"
: "${RUNNER_NAME:=ansible-runner-$(hostname)}"
: "${RUNNER_LABELS:=self-hosted,ansible}"

# Trim leading/trailing whitespace from the PAT to prevent API errors
GH_PAT=$(echo -n "$GH_PAT" | xargs)
GH_REPO_PATH=$(echo "$REPO_URL" | sed 's#https://github.com/##')

# Change to the runner's agent directory
cd /home/runner

###############################################################################
# Register GitHub Actions runner if not already configured
###############################################################################
if [[ ! -f .runner ]]; then
    echo "Requesting registration token..."
    REG_TOKEN=$(curl -L \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_PAT}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${GH_REPO_PATH}/actions/runners/registration-token" \
      | jq -r '.token')

    if [[ -z "$REG_TOKEN" || "$REG_TOKEN" == "null" ]]; then
        echo "❌ ERROR: Failed to get registration token. Check PAT permissions." >&2
        exit 1
    fi

    echo "Configuring runner..."
    ./config.sh \
      --url "$REPO_URL" \
      --token "$REG_TOKEN" \
      --unattended \
      --name "$RUNNER_NAME" \
      --labels "$RUNNER_LABELS" \
      --work _work \
      --replace
else
    echo "Runner already configured. Skipping registration."
fi

###############################################################################
# Run the runner and wait for jobs
###############################################################################
echo "🚀 Starting runner... Listening for jobs."
./run.sh & wait $!