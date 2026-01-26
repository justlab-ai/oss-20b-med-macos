#!/bin/bash
#
# Notarize Clinical Scribe for distribution
# Requires: APPLE_ID, TEAM_ID, APP_PASSWORD environment variables
#

set -e

# Configuration
VERSION="1.0.0"
BUILD_DIR="build"
DMG_FILE="${BUILD_DIR}/ClinicalScribe-${VERSION}.dmg"

# Required environment variables
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Validate inputs
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_PASSWORD" ]; then
    echo "❌ Missing required environment variables"
    echo ""
    echo "Required:"
    echo "  APPLE_ID     - Your Apple ID email"
    echo "  TEAM_ID      - Your Team ID (from developer.apple.com)"
    echo "  APP_PASSWORD - App-specific password (from appleid.apple.com)"
    echo ""
    echo "Usage:"
    echo "  APPLE_ID=you@email.com TEAM_ID=XXXXXXXXXX APP_PASSWORD=xxxx-xxxx-xxxx-xxxx ./scripts/notarize.sh"
    exit 1
fi

if [ ! -f "$DMG_FILE" ]; then
    echo "❌ DMG not found: ${DMG_FILE}"
    echo "   Run ./scripts/create-dmg.sh first"
    exit 1
fi

echo "📤 Submitting for notarization..."
echo "   File: ${DMG_FILE}"

# Submit for notarization
xcrun notarytool submit "$DMG_FILE" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

# Staple the notarization ticket
echo "📎 Stapling notarization ticket..."
xcrun stapler staple "$DMG_FILE"

echo ""
echo "✅ Notarization complete!"
echo "   ${DMG_FILE} is ready for distribution"
