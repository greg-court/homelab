#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Config
###############################################################################
: "${REPO_URL:?Must set REPO_URL (e.g. https://github.com/org/repo)}"
: "${GH_PAT:?Must set GH_PAT}"
: "${RUNNER_NAME:=docker-runner-$(hostname)}"
: "${RUNNER_LABELS:=self-hosted,docker}"

# Trim PAT whitespace to avoid newline issues
GH_PAT=$(echo -n "$GH_PAT" | xargs)
GH_REPO_PATH=$(echo "$REPO_URL" | sed 's#https://github.com/##')

echo "🏷️  Runner Name: $RUNNER_NAME"
echo "✅ Runner Labels: $RUNNER_LABELS"
echo "🔗 Registering against: $REPO_URL"
echo

###############################################################################
# Register GitHub Actions runner if not already configured
###############################################################################
cd /home/runner
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