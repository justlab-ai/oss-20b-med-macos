import SwiftUI

struct ContentView: View {
    @StateObject private var ollama = OllamaService()
    @State private var conversation = ""
    @State private var selectedModel = "gpt-oss:20b"
    @State private var generationTask: Task<Void, Never>?

    var body: some View {
        HSplitView {
            // Left Panel: Conversation Input
            conversationInputPanel
                .frame(minWidth: 350)

            // Right Panel: Clinical Note Output
            clinicalNoteOutputPanel
                .frame(minWidth: 450)
        }
        .frame(minWidth: 900, minHeight: 600)
        .task {
            await ollama.loadModels()
        }
    }

    // MARK: - Left Panel: Conversation Input

    private var conversationInputPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with connection status
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.blue)
                Text("Doctor-Patient Conversation")
                    .font(.headline)
                Spacer()
                connectionStatusBadge
            }

            // Conversation input
            TextEditor(text: $conversation)
                .font(.system(.body, design: .default))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            // Sample conversation button
            HStack {
                Button(action: { conversation = SampleConversations.respiratory }) {
                    Label("Load Sample", systemImage: "doc.text")
                }
                .buttonStyle(.link)

                Spacer()

                Text("\(conversation.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Right Panel: Clinical Note Output

    private var clinicalNoteOutputPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.green)
                Text("Clinical Note")
                    .font(.headline)

                Spacer()

                // Model selector
                Picker("Model", selection: $selectedModel) {
                    ForEach(ollama.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 180)

                // Generate button
                generateButton

                // Copy button
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(ollama.response.isEmpty)
                .help("Copy to clipboard")
            }

            // Error display
            if let error = ollama.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            // Clinical note output with streaming
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        if ollama.response.isEmpty && !ollama.isGenerating {
                            Text("Clinical note will appear here...")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            Text(ollama.response)
                                .textSelection(.enabled)
                                .font(.system(.body, design: .default))
                        }
                        Spacer()
                            .id("bottom")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: ollama.response) { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // Footer with generation status and metrics
            HStack {
                generationStatusView
                Spacer()
                Text("\(wordCount(ollama.response)) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Components

    private var connectionStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ollama.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(ollama.isConnected ? "Connected" : "Offline")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var generationStatusView: some View {
        switch ollama.generationPhase {
        case .idle:
            EmptyView()

        case .connecting:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("⏳ Starting... \(formattedElapsedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("(loading model into memory)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }

        case .loadingModel:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("⏳ Loading model... \(formattedElapsedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("(first load may take 20-60s)")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }

        case .processingPrompt:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("⏳ Processing prompt...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .generating:
            HStack(spacing: 6) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("✨ Generating")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if ollama.tokensPerSecond > 0 {
                    Text("(\(Int(ollama.tokensPerSecond)) tok/s)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Text("• \(formattedElapsedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .complete:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("✓ Done")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("• \(formattedElapsedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if ollama.tokensGenerated > 0 {
                    Text("• \(ollama.tokensGenerated) tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

        case .failed(let error):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("✗ Failed: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }
        }
    }

    private var formattedElapsedTime: String {
        let seconds = ollama.elapsedTime
        if seconds < 60 {
            return String(format: "%.1fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = Int(seconds) % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }

    private var generateButton: some View {
        Button(action: handleGenerateButtonTap) {
            HStack(spacing: 6) {
                if ollama.isGenerating {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                } else {
                    Image(systemName: "wand.and.stars")
                    Text("Generate")
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(ollama.isGenerating ? .red : .blue)
        .disabled(conversation.isEmpty && !ollama.isGenerating)
    }

    // MARK: - Actions

    private func handleGenerateButtonTap() {
        if ollama.isGenerating {
            // Stop generation
            generationTask?.cancel()
            ollama.stopGeneration()
        } else {
            // Start generation
            generationTask = Task {
                await ollama.generateNote(conversation: conversation, model: selectedModel)
            }
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ollama.response, forType: .string)
    }

    private func wordCount(_ text: String) -> Int {
        text.split(separator: " ").count
    }
}

// MARK: - Sample Conversations

struct SampleConversations {
    static let respiratory = """
Doctor: Good morning! What brings you in today?

Patient: Hi doctor. I've been having this persistent cough for about two weeks now.

Doctor: I see. Is it a dry cough or are you bringing up any phlegm?

Patient: It's mostly dry, but sometimes there's a little bit of clear mucus.

Doctor: Any fever, chills, or body aches?

Patient: No fever that I've noticed, but I have been feeling a bit tired lately.

Doctor: Have you had any shortness of breath or chest pain?

Patient: No chest pain, but I do feel a little winded when I climb stairs.

Doctor: Are you a smoker or have any history of lung problems?

Patient: I quit smoking about 5 years ago. Smoked for about 10 years before that.

Doctor: Any allergies or recent exposure to sick contacts?

Patient: My coworker had a cold last month. I don't have known allergies.

Doctor: Let me listen to your lungs... I hear some mild wheezing on the right side. Your oxygen saturation is 97%, which is good.

Patient: Is that concerning?

Doctor: It could be a post-viral bronchitis. I'd like to start you on an albuterol inhaler to help with the wheezing. Use it twice daily. If the cough persists beyond another week, we'll do a chest X-ray to rule out anything else.

Patient: Sounds good. Should I be worried about anything?

Doctor: If you develop fever, worsening shortness of breath, or start coughing up blood, come back immediately. Otherwise, the inhaler should help. Follow up in two weeks if not improving.
"""
}

// MARK: - Preview

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
