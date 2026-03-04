#!/usr/bin/env bash

set -euo pipefail

MANIFEST_PATH="${1:-build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml}"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "ERROR: merged release manifest not found: $MANIFEST_PATH" >&2
  exit 1
fi

FLAT_MANIFEST="$(tr '\n' ' ' < "$MANIFEST_PATH")"

assert_no_exported_component() {
  local component="$1"
  local type="$2"
  local pattern_a="<$type[^>]*android:name=\"$component\"[^>]*android:exported=\"true\""
  local pattern_b="<$type[^>]*android:exported=\"true\"[^>]*android:name=\"$component\""

  if echo "$FLAT_MANIFEST" | grep -Eq "$pattern_a|$pattern_b"; then
    echo "ERROR: forbidden exported $type found in release manifest: $component" >&2
    exit 1
  fi
}

assert_no_exported_component "id.flutter.flutter_background_service.WatchdogReceiver" "receiver"
assert_no_exported_component "id.flutter.flutter_background_service.BootReceiver" "receiver"
assert_no_exported_component "id.flutter.flutter_background_service.BackgroundService" "service"

echo "OK: release manifest background-service components are hardened"
