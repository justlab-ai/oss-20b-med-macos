# Clinical Scribe for macOS

**AI-powered clinical note generation - 100% private, runs on your Mac**

Paste a doctor-patient conversation → Get a professional clinical note → No data leaves your computer.

Ollama is embedded - no external installation required.

---

## How It Works

```
╔═══════════════════════════════════════════════════════════════════════╗
║                    YOUR MAC (Everything stays here)                   ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐               ║
║   │  You paste  │    │  Clinical   │    │   Embedded  │               ║
║   │ conversation│───>│ Scribe App  │───>│   Ollama    │               ║
║   └─────────────┘    └─────────────┘    └──────┬──────┘               ║
║                                                │                      ║
║                                                ▼                      ║
║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐               ║
║   │  You copy   │    │Note streams │    │  AI Model   │               ║
║   │  the note   │<───│ word-by-word│<───│(gpt-oss:20b)│               ║
║   └─────────────┘    └─────────────┘    └─────────────┘               ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

                              Internet (NOT USED) ❌
```

---

## Features

- **Zero Setup**: Ollama bundled in-app with automatic model download
- **Real-time Streaming**: Watch the clinical note generate with live token metrics
- **Generation Metrics**: See tokens/second, elapsed time, and generation phases
- **Privacy First**: All processing happens locally on your Mac
- **Copy to Clipboard**: One-click copy of generated notes

## Requirements

- macOS 13.0+ (Ventura or later)
- ~12 GB disk space for the AI model (one-time download)

---

## Quick Start

### Option 1: Download DMG (Recommended)

Download the latest release from [Releases](https://github.com/justlab-ai/oss-20b-med-macos/releases) and drag to Applications.

### Option 2: Build from Source

```bash
git clone https://github.com/justlab-ai/oss-20b-med-macos.git
cd oss-20b-med-macos
make build
make run
```

## First Launch

On first launch, Clinical Scribe will:
1. Start the embedded Ollama engine
2. Prompt you to download the AI model (~12 GB)
3. Show "Ready!" when setup is complete

The model download is a one-time process. Subsequent launches will start immediately.

---

## Usage

1. **Paste or type** a doctor-patient conversation in the left panel
2. **Select a model** from the dropdown (gpt-oss:20b recommended)
3. Click **Generate** to create the clinical note
4. Watch the note stream in real-time with generation metrics
5. Click **Copy** to copy the note to clipboard

## Build Commands

| Command | Description |
|---------|-------------|
| `make build` | Build .app bundle |
| `make run` | Build and launch |
| `make install` | Install to /Applications |
| `make dmg` | Create DMG installer |
| `make release` | Full signed + notarized release |
| `make clean` | Remove build artifacts |

For code-signed releases:
```bash
make release \
  DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)" \
  APPLE_ID="your@email.com" \
  TEAM_ID="XXXXXXXXXX" \
  APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

## Architecture

Clinical Scribe bundles Ollama directly in the app:

- **Port 11435**: Uses a dedicated port to avoid conflicts with system Ollama
- **Isolated Models**: Models stored in `~/Library/Application Support/ClinicalScribe/models`
- **Auto-start**: Ollama starts automatically when the app launches

## Project Structure

```
oss-20b-med-macos/
├── Package.swift                        # Swift package manifest
├── Makefile                             # Build automation
├── Sources/ClinicalScribe/
│   ├── ClinicalScribeApp.swift          # App entry point
│   ├── ContentView.swift                # Main split-panel UI
│   ├── SetupView.swift                  # First-launch setup
│   ├── OllamaService.swift              # Ollama API client
│   └── EmbeddedOllamaManager.swift      # Embedded Ollama management
├── Resources/
│   ├── Info.plist                       # App metadata
│   └── Entitlements.plist               # App entitlements
└── scripts/
    ├── build-app.sh                     # Build script
    ├── create-dmg.sh                    # DMG creation
    └── notarize.sh                      # Notarization script
```

---

## Links

- [Model Evaluation Results](https://github.com/justlab-ai/oss-20b-aci-bench)
- [JustLab AI](https://github.com/justlab-ai)

MIT License - See [LICENSE](LICENSE) for details.
