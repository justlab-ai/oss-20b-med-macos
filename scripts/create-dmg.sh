#!/bin/bash
#
# Create DMG installer for Clinical Scribe
#

set -e

# Configuration
APP_NAME="Clinical Scribe"
DMG_NAME="ClinicalScribe"
VERSION="1.0.0"
BUILD_DIR="build"
DMG_DIR="${BUILD_DIR}/dmg"
DMG_FILE="${BUILD_DIR}/${DMG_NAME}-${VERSION}.dmg"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

# Code signing
DEVELOPER_ID="${DEVELOPER_ID:-}"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ App bundle not found at ${APP_BUNDLE}"
    echo "   Run ./scripts/build-app.sh first"
    exit 1
fi

echo "📀 Creating DMG installer..."

# Clean previous DMG builds
rm -rf "$DMG_DIR"
rm -f "$DMG_FILE"

# Create DMG staging directory
mkdir -p "$DMG_DIR"

# Copy app to DMG directory
cp -R "$APP_BUNDLE" "$DMG_DIR/"

# Create symbolic link to Applications folder
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
echo "📦 Packaging DMG..."
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_FILE"

# Clean up staging directory
rm -rf "$DMG_DIR"

# Sign DMG if developer ID is set
if [ -n "$DEVELOPER_ID" ]; then
    echo "🔐 Signing DMG..."
    codesign --force --sign "$DEVELOPER_ID" "$DMG_FILE"
    echo "✅ DMG signed"
fi

echo ""
echo "✅ DMG created: ${DMG_FILE}"
echo "   Size: $(du -h "$DMG_FILE" | cut -f1)"
