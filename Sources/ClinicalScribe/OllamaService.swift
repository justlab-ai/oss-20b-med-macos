import Foundation
import Ollama

/// Service for interacting with Ollama API for clinical note generation
@MainActor
class OllamaService: ObservableObject {
    private let client = Client.default  // localhost:11434

    @Published var response = ""
    @Published var isGenerating = false
    @Published var availableModels: [String] = []
    @Published var errorMessage: String?
    @Published var isConnected = false

    private let systemPrompt = """
    You are a medical scribe assistant. Your task is to convert a doctor-patient conversation into a structured clinical note.

    The clinical note should include the following sections:

    **CHIEF COMPLAINT**
    The main reason for the visit in 1-2 sentences.

    **HISTORY OF PRESENT ILLNESS**
    Detailed description of the current problem including onset, duration, severity, and associated symptoms.

    **REVIEW OF SYSTEMS**
    Relevant symptoms mentioned, organized by body system.

    **PHYSICAL EXAMINATION**
    Any examination findings discussed during the conversation.

    **ASSESSMENT AND PLAN**
    Diagnosis or differential diagnoses, and the treatment plan discussed.

    Generate a professional, concise clinical note based on the conversation. Use medical terminology appropriately.
    """

    /// Generate a clinical note from a doctor-patient conversation
    func generateNote(conversation: String, model: String = "gpt-oss:20b") async {
        isGenerating = true
        response = ""
        errorMessage = nil

        do {
            // Use chat API with system prompt
            let messages: [Chat.Message] = [
                .system(systemPrompt),
                .user("Doctor-Patient Conversation:\n\n\(conversation)\n\nGenerate the clinical note:")
            ]

            // Stream the response for real-time display
            guard let modelId = Model.ID(rawValue: model) else {
                errorMessage = "Invalid model name: \(model)"
                isGenerating = false
                return
            }

            let stream = try client.chatStream(
                model: modelId,
                messages: messages,
                options: ["temperature": 0.3, "num_predict": 1024],
                keepAlive: .minutes(10)
            )

            for try await chunk in stream {
                response += chunk.message.content
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    /// Load available models from Ollama
    func loadModels() async {
        do {
            let modelList = try await client.listModels()
            availableModels = modelList.models.map { $0.name }
            isConnected = true

            // If no models available, provide defaults
            if availableModels.isEmpty {
                availableModels = ["gpt-oss:20b"]
            }
        } catch {
            availableModels = ["gpt-oss:20b"]
            isConnected = false
            errorMessage = "Cannot connect to Ollama. Make sure 'ollama serve' is running."
        }
    }

    /// Check if Ollama server is reachable
    func checkConnection() async -> Bool {
        do {
            _ = try await client.listModels()
            isConnected = true
            errorMessage = nil
            return true
        } catch {
            isConnected = false
            return false
        }
    }

    /// Stop the current generation (if supported)
    func stopGeneration() {
        // Note: Cancellation support depends on task management
        isGenerating = false
    }
}
