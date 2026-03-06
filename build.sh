#!/bin/bash
# Build script for release artifacts
# Usage: ./build.sh [apk|appbundle|ios]

set -euo pipefail

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "❌ ERROR: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID must not be set for release/profile builds."
    echo "   Remove these variables. Telegram transport is debug-only."
    exit 1
fi

BUILD_TYPE=${1:-apk}
ENABLE_ERROR_REPORTING_VALUE=${ENABLE_ERROR_REPORTING:-false}
ERROR_REPORT_RELAY_URL_VALUE=${ERROR_REPORT_RELAY_URL:-}

if [ "$ENABLE_ERROR_REPORTING_VALUE" = "true" ] && [ -z "$ERROR_REPORT_RELAY_URL_VALUE" ]; then
    echo "❌ ERROR: ENABLE_ERROR_REPORTING=true requires ERROR_REPORT_RELAY_URL."
    echo "   Keep ENABLE_ERROR_REPORTING=false until secure relay is configured."
    exit 1
fi

echo "🏗️  Building $BUILD_TYPE (Telegram disabled in release/profile)..."

dart_defines=(
  "--dart-define=ENABLE_ERROR_REPORTING=${ENABLE_ERROR_REPORTING_VALUE}"
  "--dart-define=ENABLE_DIAGNOSTIC_EVENTS=${ENABLE_DIAGNOSTIC_EVENTS:-false}"
)

if [ -n "${ERROR_REPORT_RELAY_URL_VALUE}" ]; then
  dart_defines+=("--dart-define=ERROR_REPORT_RELAY_URL=${ERROR_REPORT_RELAY_URL_VALUE}")
fi

if [ -n "${ERROR_REPORT_RELAY_API_KEY:-}" ]; then
  dart_defines+=("--dart-define=ERROR_REPORT_RELAY_API_KEY=${ERROR_REPORT_RELAY_API_KEY}")
fi

flutter build "$BUILD_TYPE" --release "${dart_defines[@]}"

echo "✅ Done!"
