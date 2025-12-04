# Clinical Scribe for macOS

A native macOS app for generating clinical notes from doctor-patient conversations using local LLMs via Ollama.

## Features

- **Split Panel UI**: Conversation input on the left, clinical note output on the right
- **Real-time Streaming**: Watch the clinical note generate word-by-word
- **Multiple Model Support**: Use gpt-oss-20b, Mistral, LLaMA, or any Ollama model
- **Privacy First**: All processing happens locally on your Mac
- **Copy to Clipboard**: One-click copy of generated notes

## Screenshot

```
┌─────────────────────────────────────────────────────────────────────┐
│  Clinical Scribe                                                    │
├──────────────────────────────┬──────────────────────────────────────┤
│ Doctor-Patient Conversation  │ Clinical Note          [Model ▼]    │
│                              │                                      │
│ Doctor: What brings you in?  │ **CHIEF COMPLAINT**                 │
│ Patient: I've had a cough... │ Persistent cough x 2 weeks          │
│                              │                                      │
│                              │ **HISTORY OF PRESENT ILLNESS**      │
│                              │ 45-year-old presents with...        │
│                              │                                      │
│ [Load Sample]                │              [Generate] [Copy]      │
└──────────────────────────────┴──────────────────────────────────────┘
```

## Requirements

- macOS 13.0+ (Ventura or later)
- [Ollama](https://ollama.ai) installed and running
- A language model (gpt-oss-20b recommended)

## Quick Start

### 1. Install Ollama

```bash
brew install ollama
```

### 2. Start Ollama Server

```bash
ollama serve
```

### 3. Pull a Model

```bash
# Recommended: OpenAI's OSS 20B model
ollama pull gpt-oss-20b

# Alternative: Faster, smaller models
ollama pull mistral:7b
ollama pull llama3.2:latest
```

### 4. Build and Run the App

```bash
# Clone the repo
git clone https://github.com/justlab-ai/oss-20b-med-macos.git
cd oss-20b-med-macos

# Open in Xcode
open Package.swift

# Build and run (Cmd+R in Xcode)
```

Or build from command line:

```bash
swift build
swift run ClinicalScribe
```

## Usage

1. **Paste or type** a doctor-patient conversation in the left panel
2. **Select a model** from the dropdown (gpt-oss-20b recommended)
3. Click **Generate** to create the clinical note
4. Watch the note stream in real-time on the right panel
5. Click **Copy** to copy the note to clipboard

## Models Comparison

| Model | Size | Speed | Quality | Best For |
|-------|------|-------|---------|----------|
| gpt-oss-20b | 20B (3.6B active) | ~28s | Best | Production use |
| mistral:7b | 7B | ~5s | Good | Quick drafts |
| llama3.2:latest | 8B | ~6s | Good | General use |

## Tech Stack

- **SwiftUI** - Native macOS UI
- **ollama-swift** - Swift client for Ollama API
- **AsyncThrowingStream** - Real-time streaming responses

## Project Structure

```
oss-20b-med-macos/
├── Package.swift              # Swift package manifest
├── Sources/ClinicalScribe/
│   ├── ClinicalScribeApp.swift  # App entry point
│   ├── ContentView.swift        # Main split-panel UI
│   └── OllamaService.swift      # Ollama API client
└── README.md
```

## Related Projects

- [oss-20b-aci-bench](https://github.com/justlab-ai/oss-20b-aci-bench) - ACI-Bench evaluation of OSS models
- [ollama-swift](https://github.com/mattt/ollama-swift) - Swift client library
- [Ollama](https://ollama.ai) - Local LLM runtime

## License

MIT License - See [LICENSE](LICENSE) for details.

---

Built with [ollama-swift](https://github.com/mattt/ollama-swift) by [@mattt](https://github.com/mattt)
