#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Config
###############################################################################
: "${RUNNER_NAME:=packer-runner}"
: "${RUNNER_LABELS:=self-hosted,packer}"
: "${EXTERNAL_HTTP_PORT:?Must set EXTERNAL_HTTP_PORT to match Docker internal port}"
: "${RUNNER_HOSTNAME:=}"

if [[ -z "$REPO_URL" || -z "$GH_PAT" ]]; then
  echo "ERROR: REPO_URL and GH_PAT must be set" >&2
  exit 1
fi

# ==> FIX: Trim any leading/trailing whitespace from the PAT <==
# This prevents the "New-line characters are not allowed" error.
GH_PAT=$(echo -n "$GH_PAT" | xargs)

export PKR_VAR_http_external_port="$EXTERNAL_HTTP_PORT"
export PKR_VAR_runner_hostname="$RUNNER_HOSTNAME"

echo
echo "🏷️  Runner hostname: ${RUNNER_HOSTNAME:-(unset)}"
echo "🌐 External HTTP port: ${EXTERNAL_HTTP_PORT:-(unset)}"
echo

GH_REPO_PATH=$(echo "$REPO_URL" | sed 's#https://github.com/##')

# Change to the runner's home directory
cd /home/runner

###############################################################################
# Register GitHub Actions runner
###############################################################################
if [[ ! -f .runner ]]; then
  echo "Requesting registration token..."

  # Use the PAT to get a short-lived registration token
  REG_TOKEN=$(curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_PAT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${GH_REPO_PATH}/actions/runners/registration-token" \
    | jq -r '.token')

  if [[ -z "$REG_TOKEN" || "$REG_TOKEN" == "null" ]]; then
    echo "ERROR: Failed to get registration token. Check PAT permissions." >&2
    exit 1
  fi

  echo "Registering runner..."
  ./config.sh \
    --url "$REPO_URL" \
    --token "$REG_TOKEN" \
    --unattended \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --work _work \
    --replace
else
  echo "Runner already configured - skipping registration."
fi

###############################################################################
# Run the runner and wait for it to exit
###############################################################################
echo "🚀 Starting runner... Listening for jobs."
./run.sh & wait $!