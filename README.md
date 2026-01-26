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

**Clinical Scribe** reads a doctor-patient conversation and automatically writes a professional clinical note - all without sending any data to the cloud.

---

## How It Works

### Data Flow

Here's exactly what happens when you click "Generate":

```
                    ╔═══════════════════════════════════════════════════════════╗
                    ║              YOUR MAC (Everything stays here)             ║
                    ╠═══════════════════════════════════════════════════════════╣
                    ║                                                           ║
                    ║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   ║
                    ║   │  You paste  │    │  Clinical   │    │   Ollama    │   ║
                    ║   │ conversation│───>│ Scribe App  │───>│   Server    │   ║
                    ║   └─────────────┘    └─────────────┘    └──────┬──────┘   ║
                    ║                                                │          ║
                    ║                                                ▼          ║
                    ║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   ║
                    ║   │  You copy   │    │Note streams │    │  AI Model   │   ║
                    ║   │  the note   │<───│ word-by-word│<───│(gpt-oss-20b)│   ║
                    ║   └─────────────┘    └─────────────┘    └─────────────┘   ║
                    ║                                                           ║
                    ╚═══════════════════════════════════════════════════════════╝
                    
                                          ┌─────────────┐
                                          │  Internet   │
                                          │ (NOT USED)  │
                                          │      ❌      │
                                          └─────────────┘
```

**Key point**: Your patient data NEVER leaves your computer.

---

## Architecture

```
╔═══════════════════════════════════════════════════════════════════════╗
║                         Clinical Scribe App                           ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║   ┌───────────────────────┐       ┌───────────────────────────┐       ║
║   │   ContentView.swift   │       │   OllamaService.swift     │       ║
║   │   (User Interface)    │<─────>│   (API Communication)     │       ║
║   │                       │       │                           │       ║
║   │  • Left: conversation │       │  • Connects to Ollama     │       ║
║   │  • Right: clinical    │       │  • Sends prompts          │       ║
║   │    note output        │       │  • Streams responses      │       ║
║   └───────────────────────┘       └─────────────┬─────────────┘       ║
║                                                 │                     ║
╚═════════════════════════════════════════════════╪═════════════════════╝
                                                  │
                                         HTTP API │ localhost:11434
                                                  │
                    ╔═════════════════════════════╧═════════════════════════════╗
                    ║                      Ollama Server                        ║
                    ╠═══════════════════════════════════════════════════════════╣
                    ║                                                           ║
                    ║              ┌───────────────────────────┐                ║
                    ║              │   AI Model (gpt-oss-20b)  │                ║
                    ║              │                           │                ║
                    ║              │  • 20 billion parameters  │                ║
                    ║              │  • Runs on Apple Silicon  │                ║
                    ║              │  • Medical knowledge      │                ║
                    ║              └───────────────────────────┘                ║
                    ║                                                           ║
                    ╚═══════════════════════════════════════════════════════════╝
```

---

## What the App Generates

The AI creates structured clinical notes with these sections:

| Section | What It Contains | Example |
|---------|------------------|---------|
| **Chief Complaint** | Why the patient came in | "Persistent cough x 2 weeks" |
| **History of Present Illness** | Details about the problem | "45-year-old male presents with dry cough..." |
| **Review of Systems** | Other symptoms mentioned | "Denies fever, chills. Reports mild fatigue." |
| **Physical Examination** | Exam findings discussed | "Lungs: mild wheezing on right side" |
| **Assessment & Plan** | Diagnosis + treatment | "Post-viral bronchitis. Start albuterol inhaler." |

---

## What It Looks Like

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Clinical Scribe                                          [●] Online   │
├────────────────────────────────────┬────────────────────────────────────┤
│                                    │                                    │
│  Doctor-Patient Conversation       │  Clinical Note        [Model ▼]   │
│                                    │                                    │
│  ┌──────────────────────────────┐  │  ┌──────────────────────────────┐ │
│  │                              │  │  │                              │ │
│  │ Doctor: What brings you in? │  │  │ CHIEF COMPLAINT              │ │
│  │                              │  │  │ Persistent cough x 2 weeks   │ │
│  │ Patient: I've had a cough   │  │  │                              │ │
│  │ for two weeks...            │  │  │ HISTORY OF PRESENT ILLNESS   │ │
│  │                              │  │  │ 45-year-old presents with    │ │
│  │ Doctor: Any fever?          │  │  │ dry cough for 2 weeks...     │ │
│  │                              │  │  │                              │ │
│  │ Patient: No fever...        │  │  │ ASSESSMENT AND PLAN          │ │
│  │                              │  │  │ 1. Post-viral bronchitis     │ │
│  │                              │  │  │    - Albuterol inhaler BID   │ │
│  └──────────────────────────────┘  │  └──────────────────────────────┘ │
│                                    │                                    │
│  [Load Sample]          500 chars  │            [Generate] [Copy] 89w  │
└────────────────────────────────────┴────────────────────────────────────┘
```

---

## Key Terms Explained

| Term | What It Means |
|------|---------------|
| **Clinical Note** | The official medical record a doctor writes after seeing a patient |
| **LLM** | Large Language Model - AI that can read and write text (like ChatGPT) |
| **Ollama** | Free software that runs AI models on your own computer |
| **localhost:11434** | The address where Ollama runs on your Mac (only accessible locally) |
| **Streaming** | The note appears word-by-word instead of all at once |
| **Parameters** | The "brain size" of an AI model (20 billion = very capable) |

---

## Requirements

| Requirement | Details |
|-------------|---------|
| **Mac Computer** | macOS 13.0 (Ventura) or newer |
| **Ollama** | Free software to run AI models locally |
| **Storage Space** | ~15GB for the recommended AI model |
| **RAM** | 16GB recommended for smooth performance |

---

## Installation

### Step 1: Install Ollama

**Option A: Using Homebrew**
```bash
brew install ollama
```

**Option B: Direct Download**
1. Go to [ollama.ai](https://ollama.ai)
2. Click "Download for macOS"
3. Drag to Applications

### Step 2: Start Ollama Server

```bash
ollama serve
```
Keep this terminal window open.

### Step 3: Download an AI Model

In a **new** terminal window:
```bash
# Recommended (best quality)
ollama pull gpt-oss-20b

# Or faster alternative
ollama pull mistral:7b
```

### Step 4: Run Clinical Scribe

```bash
git clone https://github.com/justlab-ai/oss-20b-med-macos.git
cd oss-20b-med-macos
open Package.swift
```

In Xcode, press **Cmd + R** to build and run.

---

## Model Comparison

| Model | Quality | Speed | Best For |
|-------|---------|-------|----------|
| **gpt-oss-20b** | ⭐⭐⭐⭐⭐ | ~30 sec | Final notes |
| **mistral:7b** | ⭐⭐⭐⭐ | ~5 sec | Quick drafts |
| **llama3.2** | ⭐⭐⭐⭐ | ~6 sec | General use |

---

## Project Structure

```
oss-20b-med-macos/
├── Package.swift                    # Project configuration
├── Sources/ClinicalScribe/
│   ├── ClinicalScribeApp.swift      # App entry point
│   ├── ContentView.swift            # User interface (split panel)
│   └── OllamaService.swift          # Ollama API communication
└── README.md
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection refused" | Run `ollama serve` in terminal |
| "Model not found" | Run `ollama pull gpt-oss-20b` |
| App won't build | Xcode → File → Packages → Reset Package Caches |
| Generation is slow | Try smaller model: `mistral:7b` |

---

## Privacy & Security

| Question | Answer |
|----------|--------|
| Is my data sent to the cloud? | **No** - everything runs locally |
| Can anyone see my patient data? | **No** - data never leaves your Mac |
| Do I need internet? | **No** - works completely offline |
| Is it HIPAA compliant? | Local processing helps, but consult your compliance officer |

---

## Related Projects

- [oss-20b-aci-bench](https://github.com/justlab-ai/oss-20b-aci-bench) - How we tested these AI models

## License

MIT License - Free to use and modify!

---

Built by [JustLab AI](https://github.com/justlab-ai)
