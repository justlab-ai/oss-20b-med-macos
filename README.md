# Clinical Scribe for macOS

**AI-powered clinical note generation - 100% private, runs on your Mac**

Paste a doctor-patient conversation → Get a professional clinical note → No data leaves your computer.

---

## How It Works

```
╔═══════════════════════════════════════════════════════════════════════╗
║                    YOUR MAC (Everything stays here)                   ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐               ║
║   │  You paste  │    │  Clinical   │    │   Ollama    │               ║
║   │ conversation│───>│ Scribe App  │───>│   Server    │               ║
║   └─────────────┘    └─────────────┘    └──────┬──────┘               ║
║                                                │                      ║
║                                                ▼                      ║
║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐               ║
║   │  You copy   │    │Note streams │    │  AI Model   │               ║
║   │  the note   │<───│ word-by-word│<───│(gpt-oss-20b)│               ║
║   └─────────────┘    └─────────────┘    └─────────────┘               ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝

                              Internet (NOT USED) ❌
```

---

## Quick Start

```bash
# 1. Install & start Ollama
brew install ollama
ollama serve                    # Keep running

# 2. Download AI model (new terminal)
ollama pull gpt-oss-20b

# 3. Run the app
git clone https://github.com/justlab-ai/oss-20b-med-macos.git
cd oss-20b-med-macos
open Package.swift              # Press Cmd+R in Xcode
```

**Requirements**: macOS 13+, 16GB RAM, ~15GB storage

---

## Links

- [Model Evaluation Results](https://github.com/justlab-ai/oss-20b-aci-bench)
- [JustLab AI](https://github.com/justlab-ai)

MIT License
