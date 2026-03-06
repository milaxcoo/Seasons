#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-local}"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

echo "Running secret hygiene checks (mode: $MODE)"

scan_tracked_files() {
  local matches
  matches="$(
    git ls-files -z | xargs -0 rg -n --no-heading \
      -e 'TELEGRAM_BOT_TOKEN\s*=' \
      -e 'TELEGRAM_CHAT_ID\s*=' \
      -e 'KEYSTORE_PASSWORD\s*=' \
      -e 'KEY_PASSWORD\s*=' \
      -e '-----BEGIN (RSA|EC|OPENSSH|PRIVATE KEY)-----' \
      -e '[0-9]{8,10}:[A-Za-z0-9_-]{30,}' || true
  )"

  if [[ -z "$matches" ]]; then
    return 0
  fi

  local suspicious
  suspicious="$(echo "$matches" | rg -v '<redacted>|\$\{\{\s*secrets\.|String\.fromEnvironment|#\s*Secrets - DO NOT COMMIT' || true)"
  if [[ -n "$suspicious" ]]; then
    echo "ERROR: suspicious secret-like content found in tracked files:"
    echo "$suspicious"
    return 1
  fi

  return 0
}

scan_local_workspace_files() {
  local has_issue=0
  local file
  for file in .env .secrets .local_signing/android-signing.env; do
    if [[ ! -f "$file" ]]; then
      continue
    fi

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" =~ ^[[:space:]]*# ]] && continue
      if [[ "$line" =~ ^[[:space:]]*export[[:space:]]+ ]]; then
        line="${line#export }"
      fi
      if [[ ! "$line" =~ ^[A-Z0-9_]+[[:space:]]*= ]]; then
        continue
      fi

      local key value
      key="${line%%=*}"
      value="${line#*=}"
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"
      value="${value//[[:space:]]/}"

      if [[ -z "$value" ]]; then
        continue
      fi
      if [[ "$value" == "<redacted>" || "$value" == "changeme" ]]; then
        continue
      fi

      if [[ "$key" =~ ^(TELEGRAM_BOT_TOKEN|TELEGRAM_CHAT_ID|KEYSTORE_PASSWORD|KEY_PASSWORD|KEY_ALIAS|KEYSTORE_PATH|ERROR_REPORT_RELAY_API_KEY)$ ]]; then
        echo "ERROR: plaintext value detected in local file '$file' for key '$key'."
        has_issue=1
      fi
    done < "$file"
  done

  if [[ "$has_issue" -ne 0 ]]; then
    return 1
  fi
  return 0
}

scan_tracked_files

if [[ "$MODE" != "--ci" ]]; then
  scan_local_workspace_files
fi

echo "OK: secret hygiene checks passed"
