#!/bin/bash
# Build script with secrets
# Usage: ./build.sh [apk|appbundle|ios]

set -euo pipefail

# Load secrets from .secrets file
if [ -f ".secrets" ]; then
    set -a
    # shellcheck disable=SC1091
    source .secrets
    set +a
fi

TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN:-}
TELEGRAM_CHAT_ID=${TELEGRAM_CHAT_ID:-}

# Check if secrets are set
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "⚠️  Warning: Telegram secrets not configured"
    echo "   Create .secrets file with TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID"
fi

BUILD_TYPE=${1:-apk}

echo "🏗️  Building $BUILD_TYPE with secrets..."

flutter build $BUILD_TYPE --release \
    --dart-define=TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN \
    --dart-define=TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID \
    --dart-define=ENABLE_ERROR_REPORTING=${ENABLE_ERROR_REPORTING:-false} \
    --dart-define=ENABLE_DIAGNOSTIC_EVENTS=${ENABLE_DIAGNOSTIC_EVENTS:-false}

echo "✅ Done!"
