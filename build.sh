#!/bin/bash
# Build script with secrets
# Usage: ./build.sh [apk|appbundle|ios]

# Load secrets from .secrets file
if [ -f ".secrets" ]; then
    export $(cat .secrets | xargs)
fi

# Check if secrets are set
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "⚠️  Warning: Telegram secrets not configured"
    echo "   Create .secrets file with TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID"
fi

BUILD_TYPE=${1:-apk}

echo "🏗️  Building $BUILD_TYPE with secrets..."

flutter build $BUILD_TYPE --release \
    --dart-define=TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN \
    --dart-define=TELEGRAM_CHAT_ID=$TELEGRAM_CHAT_ID

echo "✅ Done!"
