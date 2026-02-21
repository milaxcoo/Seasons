#!/bin/bash
# Build script for release artifacts
# Usage: ./build.sh [apk|appbundle|ios]

set -euo pipefail

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] || [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    echo "❌ ERROR: TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID must not be set for release/profile builds."
    echo "   Remove these variables. Production monitoring will use an on-prem relay later."
    exit 1
fi

BUILD_TYPE=${1:-apk}

echo "🏗️  Building $BUILD_TYPE (Telegram disabled in release/profile)..."

flutter build $BUILD_TYPE --release \
    --dart-define=ENABLE_ERROR_REPORTING=${ENABLE_ERROR_REPORTING:-false} \
    --dart-define=ENABLE_DIAGNOSTIC_EVENTS=${ENABLE_DIAGNOSTIC_EVENTS:-false}

echo "✅ Done!"
