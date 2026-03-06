#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: bash tool/with_release_env.sh <command> [args...]" >&2
  echo "Example: bash tool/with_release_env.sh flutter build appbundle --release" >&2
  exit 1
fi

if ! command -v security >/dev/null 2>&1; then
  echo "ERROR: macOS 'security' command is required for keychain access." >&2
  exit 1
fi

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

read_keychain_secret() {
  local service="$1"
  local required="${2:-true}"
  local value

  value="$(security find-generic-password -a "$USER" -s "$service" -w 2>/dev/null || true)"
  if [[ -n "$value" ]]; then
    printf '%s' "$value"
    return 0
  fi

  if [[ "$required" == "true" ]]; then
    echo "ERROR: keychain item '$service' for account '$USER' is missing." >&2
    echo "Add it with: security add-generic-password -a \"$USER\" -s \"$service\" -w '<value>' -U" >&2
    exit 1
  fi

  printf ''
}

# Non-secret path can be passed via env, or kept in keychain for convenience.
KEYSTORE_PATH_VALUE="${KEYSTORE_PATH:-}"
if [[ -z "$KEYSTORE_PATH_VALUE" ]]; then
  KEYSTORE_PATH_VALUE="$(read_keychain_secret "votepfurapp_keystore_path" false)"
fi

if [[ -z "$KEYSTORE_PATH_VALUE" ]]; then
  echo "ERROR: KEYSTORE_PATH is required (env KEYSTORE_PATH or keychain service votepfurapp_keystore_path)." >&2
  exit 1
fi

KEYSTORE_PASSWORD_VALUE="$(read_keychain_secret "votepfurapp_keystore_password")"
KEY_ALIAS_VALUE="$(read_keychain_secret "votepfurapp_key_alias")"
KEY_PASSWORD_VALUE="$(read_keychain_secret "votepfurapp_key_password")"

ENABLE_ERROR_REPORTING_VALUE="${ENABLE_ERROR_REPORTING:-false}"
ENABLE_DIAGNOSTIC_EVENTS_VALUE="${ENABLE_DIAGNOSTIC_EVENTS:-false}"

ERROR_REPORT_RELAY_URL_VALUE="${ERROR_REPORT_RELAY_URL:-}"
if [[ -z "$ERROR_REPORT_RELAY_URL_VALUE" ]]; then
  ERROR_REPORT_RELAY_URL_VALUE="$(read_keychain_secret "votepfurapp_error_report_relay_url" false)"
fi

ERROR_REPORT_RELAY_API_KEY_VALUE="${ERROR_REPORT_RELAY_API_KEY:-}"
if [[ -z "$ERROR_REPORT_RELAY_API_KEY_VALUE" ]]; then
  ERROR_REPORT_RELAY_API_KEY_VALUE="$(read_keychain_secret "votepfurapp_error_report_relay_api_key" false)"
fi

if [[ "$ENABLE_ERROR_REPORTING_VALUE" == "true" && -z "$ERROR_REPORT_RELAY_URL_VALUE" ]]; then
  echo "ERROR: ENABLE_ERROR_REPORTING=true requires ERROR_REPORT_RELAY_URL (env or keychain)." >&2
  exit 1
fi

env \
  KEYSTORE_PATH="$KEYSTORE_PATH_VALUE" \
  KEYSTORE_PASSWORD="$KEYSTORE_PASSWORD_VALUE" \
  KEY_ALIAS="$KEY_ALIAS_VALUE" \
  KEY_PASSWORD="$KEY_PASSWORD_VALUE" \
  ENABLE_ERROR_REPORTING="$ENABLE_ERROR_REPORTING_VALUE" \
  ENABLE_DIAGNOSTIC_EVENTS="$ENABLE_DIAGNOSTIC_EVENTS_VALUE" \
  ERROR_REPORT_RELAY_URL="$ERROR_REPORT_RELAY_URL_VALUE" \
  ERROR_REPORT_RELAY_API_KEY="$ERROR_REPORT_RELAY_API_KEY_VALUE" \
  "$@"
