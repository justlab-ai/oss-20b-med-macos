#!/bin/bash
#
# Build script for Clinical Scribe macOS app
# Creates a proper .app bundle with embedded Ollama
#

set -e

# Configuration
APP_NAME="Clinical Scribe"
EXECUTABLE_NAME="ClinicalScribe"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
OLLAMA_VERSION="0.15.1"

# Code signing (set these environment variables or edit here)
DEVELOPER_ID="${DEVELOPER_ID:-}"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🔨 Building Clinical Scribe..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Download Ollama binary if not cached
OLLAMA_CACHE="${BUILD_DIR}/ollama-cache"
OLLAMA_BINARY="${OLLAMA_CACHE}/ollama"

if [ ! -f "$OLLAMA_BINARY" ]; then
    echo "📥 Downloading Ollama ${OLLAMA_VERSION}..."
    mkdir -p "$OLLAMA_CACHE"

    # Download the tgz archive and extract
    OLLAMA_URL="https://github.com/ollama/ollama/releases/download/v${OLLAMA_VERSION}/ollama-darwin.tgz"
    OLLAMA_TGZ="${OLLAMA_CACHE}/ollama-darwin.tgz"

    curl -L -o "$OLLAMA_TGZ" "$OLLAMA_URL"
    tar -xzf "$OLLAMA_TGZ" -C "$OLLAMA_CACHE"
    rm "$OLLAMA_TGZ"
    chmod +x "$OLLAMA_BINARY"
    echo "✅ Ollama downloaded"
else
    echo "📦 Using cached Ollama binary"
fi

# Build release version
echo "📦 Compiling Swift package (release)..."
swift build -c release

# Create app bundle structure
echo "📁 Creating app bundle..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp ".build/release/${EXECUTABLE_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy Ollama binary into the bundle
cp "$OLLAMA_BINARY" "${APP_BUNDLE}/Contents/Resources/ollama"
chmod +x "${APP_BUNDLE}/Contents/Resources/ollama"
echo "🤖 Ollama bundled"

# Copy Info.plist
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/"

# Copy app icon if it exists
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
    echo "🎨 App icon included"
fi

# Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

# Code signing
if [ -n "$DEVELOPER_ID" ]; then
    echo "🔐 Code signing..."

    # Sign Ollama binary first
    codesign --force --options runtime \
        --sign "$DEVELOPER_ID" \
        "${APP_BUNDLE}/Contents/Resources/ollama"

    # Sign the main app
    codesign --force --deep --options runtime \
        --sign "$DEVELOPER_ID" \
        --entitlements "Resources/Entitlements.plist" \
        "${APP_BUNDLE}"

    echo "✅ Code signing complete"

    # Verify signature
    echo "🔍 Verifying signature..."
    codesign --verify --deep --strict "${APP_BUNDLE}"
    echo "✅ Signature verified"
else
    echo "⚠️  No DEVELOPER_ID set - skipping code signing"
    echo "   To sign, run: DEVELOPER_ID=\"Developer ID Application: ...\" ./scripts/build-app.sh"
fi

echo ""
echo "✅ Build complete!"
echo ""
echo "📍 App bundle: ${APP_BUNDLE}"
echo "   Size: $(du -sh "${APP_BUNDLE}" | cut -f1)"
echo ""
echo "To run:     open \"${APP_BUNDLE}\""
echo "To install: cp -r \"${APP_BUNDLE}\" /Applications/"
