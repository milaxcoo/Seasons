#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

echo "Running pre-release safety checks..."

bash tool/check_secret_hygiene.sh

MANIFEST_PATH="build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml"
if [[ -f "$MANIFEST_PATH" ]]; then
  bash tool/check_release_manifest_security.sh "$MANIFEST_PATH"
else
  echo "INFO: merged release manifest not found at $MANIFEST_PATH (skip manifest hardening check)."
  echo "      Generate it with: (cd android && ./gradlew :app:processReleaseMainManifest --no-daemon)"
fi

echo "Pre-release safety checks passed."
