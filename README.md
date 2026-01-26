# Clinical Scribe for macOS

**An app that helps doctors write patient notes using AI - all running privately on your Mac**

---

## What is This?

Imagine you're a doctor. After every patient visit, you need to write detailed notes about:
- Why the patient came in
- What symptoms they described  
- What you found during the exam
- Your diagnosis and treatment plan

This takes **2+ hours per day** of typing. What if AI could do it for you?

**Clinical Scribe** listens to (or reads) a doctor-patient conversation and automatically writes a professional clinical note - all without sending any data to the cloud.

---

## Key Terms Explained

New to AI or healthcare? Here's what you need to know:

| Term | What It Means |
|------|---------------|
| **Clinical Note** | The official medical record a doctor writes after seeing a patient |
| **LLM** | Large Language Model - AI that can read and write text (like ChatGPT) |
| **Ollama** | Free software that runs AI models on your own computer |
| **Local/On-device** | Everything runs on YOUR computer - no data sent to the internet |
| **Privacy-first** | Patient data never leaves your machine |

---

## Why This Matters

| Problem | Our Solution |
|---------|--------------|
| Doctors waste hours on paperwork | AI writes the notes in seconds |
| Cloud AI services see your data | Everything stays on your Mac |
| Expensive enterprise software | 100% free and open source |
| Complex setup required | Just install and run |

---

## What It Looks Like

```
┌─────────────────────────────────────────────────────────────────────┐
│  Clinical Scribe                                                    │
├──────────────────────────────┬──────────────────────────────────────┤
│                              │                                      │
│  PASTE CONVERSATION HERE     │   AI-GENERATED NOTE APPEARS HERE    │
│                              │                                      │
│  Doctor: What brings you in? │   CHIEF COMPLAINT                   │
│  Patient: I've had a cough   │   Persistent cough x 2 weeks        │
│  for about two weeks...      │                                      │
│                              │   HISTORY OF PRESENT ILLNESS        │
│                              │   45-year-old presents with...      │
│                              │                                      │
│  [Load Sample]               │              [Generate] [Copy]      │
└──────────────────────────────┴──────────────────────────────────────┘
```

**Left side**: Paste the conversation  
**Right side**: Get a professional clinical note  

---

## Features

| Feature | What It Does |
|---------|--------------|
| **Split Panel View** | See conversation and note side-by-side |
| **Real-time Generation** | Watch the note write itself word-by-word |
| **Multiple AI Models** | Choose from different AI models based on your needs |
| **100% Private** | All processing happens on YOUR Mac - nothing sent online |
| **One-Click Copy** | Easily copy notes to paste into medical records |

---

## Requirements

Before you start, you'll need:

| Requirement | Details |
|-------------|---------|
| **Mac Computer** | macOS 13.0 (Ventura) or newer |
| **Ollama** | Free software to run AI models locally |
| **Storage Space** | ~15GB for the recommended AI model |
| **RAM** | 16GB recommended for smooth performance |

---

## Installation Guide

### Step 1: Install Ollama

Ollama is free software that runs AI models on your Mac.

**Option A: Using Homebrew (if you have it)**
```bash
brew install ollama
```

**Option B: Direct Download**
1. Go to [ollama.ai](https://ollama.ai)
2. Click "Download for macOS"
3. Open the downloaded file and drag to Applications

### Step 2: Start Ollama

Open Terminal (search "Terminal" in Spotlight) and run:
```bash
ollama serve
```

Keep this window open - Ollama needs to run in the background.

### Step 3: Download an AI Model

In a **new** Terminal window, download the AI model:

```bash
# Recommended: Best quality for medical notes
ollama pull gpt-oss-20b

# Alternative: Faster but slightly lower quality
ollama pull mistral:7b
```

**Note**: The first download takes 10-30 minutes depending on your internet speed.

### Step 4: Install Clinical Scribe

```bash
# Download the app
git clone https://github.com/justlab-ai/oss-20b-med-macos.git
cd oss-20b-med-macos

# Open in Xcode
open Package.swift
```

In Xcode:
1. Wait for packages to download (about 1 minute)
2. Press **Cmd + R** to build and run

**Don't have Xcode?** Download it free from the Mac App Store.

---

## How to Use

1. **Make sure Ollama is running** (Step 2 above)

2. **Open Clinical Scribe**

3. **Paste a conversation** in the left panel
   - Or click "Load Sample" to try an example

4. **Select your AI model** from the dropdown
   - `gpt-oss-20b` = Best quality (slower)
   - `mistral:7b` = Good quality (faster)

5. **Click "Generate"** and watch the magic happen!

6. **Click "Copy"** to copy the note to your clipboard

---

## Model Comparison

Which AI model should you use?

| Model | Quality | Speed | Best For |
|-------|---------|-------|----------|
| **gpt-oss-20b** | ⭐⭐⭐⭐⭐ Best | ~30 seconds | Final notes, accuracy matters |
| **mistral:7b** | ⭐⭐⭐⭐ Good | ~5 seconds | Quick drafts, testing |
| **llama3.2** | ⭐⭐⭐⭐ Good | ~6 seconds | General use |

**Our recommendation**: Start with `mistral:7b` to test, use `gpt-oss-20b` for real work.

---

## Troubleshooting

### "Connection refused" error
**Problem**: Ollama isn't running  
**Solution**: Open Terminal and run `ollama serve`

### "Model not found" error
**Problem**: You haven't downloaded the model yet  
**Solution**: Run `ollama pull gpt-oss-20b` (or your chosen model)

### App won't build in Xcode
**Problem**: Packages didn't download  
**Solution**: In Xcode, go to File → Packages → Reset Package Caches

### Generation is very slow
**Problem**: Your Mac may not have enough RAM  
**Solution**: Try a smaller model like `mistral:7b`

---

## Project Files

```
oss-20b-med-macos/
├── Package.swift              # App configuration
├── Sources/ClinicalScribe/
│   ├── ClinicalScribeApp.swift  # Where the app starts
│   ├── ContentView.swift        # The main screen you see
│   └── OllamaService.swift      # Code that talks to Ollama
└── README.md                    # You are here!
```

---

## FAQ

**Q: Is my patient data safe?**  
A: Yes! Everything runs locally on your Mac. No data is ever sent to the internet.

**Q: Is this free?**  
A: Yes, 100% free and open source.

**Q: Can I use this for real patients?**  
A: This is a research prototype. Always review AI-generated notes before using in clinical practice.

**Q: What if I don't have a Mac?**  
A: We're working on Windows and iOS versions. Stay tuned!

---

## Related Projects

- [oss-20b-aci-bench](https://github.com/justlab-ai/oss-20b-aci-bench) - See how we tested these AI models

## Contributors

Built by the [JustLab AI](https://github.com/justlab-ai) team.

## License

MIT License - Free to use and modify!
