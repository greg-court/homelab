#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_NAME:=$(hostname)}"
: "${RUNNER_LABELS:=self-hosted,packer}"
: "${EXTERNAL_HTTP_PORT:?Must set EXTERNAL_HTTP_PORT to match Docker internal port}"
: "${RUNNER_HOSTNAME:=}"
: "${REPO_URL:?Must set REPO_URL}"
: "${GH_PAT:?Must set GH_PAT}"

GH_PAT=$(echo -n "$GH_PAT" | xargs)
GH_REPO_PATH=$(echo "$REPO_URL" | sed 's#https://github.com/##')

export PKR_VAR_http_external_port="$EXTERNAL_HTTP_PORT"
export PKR_VAR_runner_hostname="$RUNNER_HOSTNAME"

echo
echo "🏷️  Runner hostname: ${RUNNER_HOSTNAME:-(unset)}"
echo "🌐 External HTTP port: ${EXTERNAL_HTTP_PORT:-(unset)}"
echo

cd /home/runner

if [[ ! -f .runner ]]; then
  echo "Requesting registration token..."
  REG_TOKEN=$(
    curl -sSL -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${GH_PAT}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/repos/${GH_REPO_PATH}/actions/runners/registration-token" \
    | jq -r '.token'
  )
  test -n "$REG_TOKEN" && [[ "$REG_TOKEN" != "null" ]]

  echo "Registering runner (ephemeral)..."
  ./config.sh \
    --url "$REPO_URL" \
    --token "$REG_TOKEN" \
    --unattended \
    --ephemeral \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --work _work \
    --replace
else
  echo "Runner already configured - skipping registration."
fi

echo "🚀 Starting runner... Listening for jobs."
./run.sh & wait $!
