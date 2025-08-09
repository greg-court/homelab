#!/usr/bin/env bash
set -euo pipefail

: "${REPO_URL:?Must set REPO_URL (e.g. https://github.com/org/repo)}"
: "${GH_PAT:?Must set GH_PAT}"
: "${RUNNER_NAME:=docker-runner-$(hostname)}"
: "${RUNNER_LABELS:=self-hosted,docker}"

GH_PAT=$(echo -n "$GH_PAT" | xargs)
GH_REPO_PATH=$(echo "$REPO_URL" | sed 's#https://github.com/##')

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

  echo "Configuring runner (ephemeral)..."
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
  echo "Runner already configured. Skipping registration."
fi

echo "🚀 Starting runner..."
./run.sh & wait $!
