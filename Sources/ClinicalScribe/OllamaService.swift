import Foundation

/// Represents the current phase of generation
enum GenerationPhase: Equatable {
    case idle
    case connecting
    case loadingModel
    case processingPrompt
    case generating
    case complete
    case failed(String)

    var description: String {
        switch self {
        case .idle: return "Ready"
        case .connecting: return "Connecting..."
        case .loadingModel: return "Loading model..."
        case .processingPrompt: return "Processing prompt..."
        case .generating: return "Generating"
        case .complete: return "Done"
        case .failed(let error): return "Failed: \(error)"
        }
    }

    var icon: String {
        switch self {
        case .idle: return ""
        case .connecting, .loadingModel, .processingPrompt, .generating: return "⏳"
        case .complete: return "✓"
        case .failed: return "✗"
        }
    }
}

/// Service for interacting with Ollama API for clinical note generation
/// Connects to the embedded Ollama instance on port 11435
@MainActor
class OllamaService: ObservableObject {
    @Published var response = ""
    @Published var isGenerating = false
    @Published var availableModels: [String] = []
    @Published var errorMessage: String?
    @Published var isConnected = false

    // Generation metrics
    @Published var generationPhase: GenerationPhase = .idle
    @Published var tokensGenerated: Int = 0
    @Published var tokensPerSecond: Double = 0
    @Published var elapsedTime: TimeInterval = 0

    private var currentTask: Task<Void, Never>?
    private var startTime: Date?
    private var elapsedTimer: Timer?

    /// URLSession with extended timeout for model loading
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300  // 5 minutes for first model load
        config.timeoutIntervalForResource = 600 // 10 minutes total
        return URLSession(configuration: config)
    }()

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

    /// Base URL from the embedded Ollama manager
    private var baseURL: URL {
        EmbeddedOllamaManager.shared.ollamaBaseURL
    }

    /// Generate a clinical note from a doctor-patient conversation
    func generateNote(conversation: String, model: String = "gpt-oss:20b") async {
        // Reset state
        isGenerating = true
        response = ""
        errorMessage = nil
        generationPhase = .connecting
        tokensGenerated = 0
        tokensPerSecond = 0
        elapsedTime = 0
        startTime = Date()

        // Start elapsed time timer
        startElapsedTimer()

        currentTask = Task {
            do {
                let messages: [[String: String]] = [
                    ["role": "system", "content": systemPrompt],
                    ["role": "user", "content": "Doctor-Patient Conversation:\n\n\(conversation)\n\nGenerate the clinical note:"]
                ]

                let requestBody: [String: Any] = [
                    "model": model,
                    "messages": messages,
                    "stream": true,
                    "options": [
                        "temperature": 0.3,
                        "num_predict": 1024
                    ]
                ]

                guard let url = URL(string: "\(baseURL)/api/chat") else {
                    await MainActor.run {
                        self.errorMessage = "Invalid URL"
                        self.generationPhase = .failed("Invalid URL")
                        self.isGenerating = false
                        self.stopElapsedTimer()
                    }
                    return
                }

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                // Track if we've seen content yet to determine phase
                var hasSeenContent = false
                var hasSeenLoadDuration = false

                let (bytes, httpResponse) = try await session.bytes(for: request)

                guard let response = httpResponse as? HTTPURLResponse,
                      response.statusCode == 200 else {
                    await MainActor.run {
                        self.errorMessage = "Request failed"
                        self.generationPhase = .failed("Request failed")
                        self.isGenerating = false
                        self.stopElapsedTimer()
                    }
                    return
                }

                // Connected, now waiting for model to load
                await MainActor.run {
                    self.generationPhase = .loadingModel
                }

                for try await line in bytes.lines {
                    if Task.isCancelled { break }
                    guard !line.isEmpty else { continue }

                    if let data = line.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                        await MainActor.run {
                            // Check for load_duration - indicates model loading completed
                            if let loadDuration = json["load_duration"] as? Int64, !hasSeenLoadDuration {
                                hasSeenLoadDuration = true
                                // If load took significant time, it was actually loading
                                let loadSeconds = Double(loadDuration) / 1_000_000_000
                                if loadSeconds > 0.1 {
                                    // Model was loaded from disk
                                }
                            }

                            // Check for prompt_eval_count - indicates prompt processing
                            if let promptEvalCount = json["prompt_eval_count"] as? Int,
                               promptEvalCount > 0,
                               !hasSeenContent {
                                self.generationPhase = .processingPrompt
                            }

                            // Extract message content
                            if let message = json["message"] as? [String: Any],
                               let content = message["content"] as? String,
                               !content.isEmpty {
                                if !hasSeenContent {
                                    hasSeenContent = true
                                    self.generationPhase = .generating
                                }
                                self.response += content
                            }

                            // Extract token metrics from streaming response
                            if let evalCount = json["eval_count"] as? Int {
                                self.tokensGenerated = evalCount
                            }

                            // Calculate tokens per second
                            if let evalCount = json["eval_count"] as? Int,
                               let evalDuration = json["eval_duration"] as? Int64,
                               evalDuration > 0 {
                                let evalSeconds = Double(evalDuration) / 1_000_000_000
                                self.tokensPerSecond = Double(evalCount) / evalSeconds
                            }

                            // Check for errors
                            if let error = json["error"] as? String {
                                self.errorMessage = error
                                self.generationPhase = .failed(error)
                            }
                        }

                        // Check for done
                        if let done = json["done"] as? Bool, done {
                            await MainActor.run {
                                self.generationPhase = .complete
                            }
                            break
                        }
                    }
                }

            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                        self.generationPhase = .failed(error.localizedDescription)
                    }
                }
            }

            await MainActor.run {
                self.isGenerating = false
                self.stopElapsedTimer()
            }
        }

        await currentTask?.value
    }

    /// Start the elapsed time timer
    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    /// Stop the elapsed time timer
    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    /// Load available models from Ollama
    func loadModels() async {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            availableModels = ["gpt-oss:20b"]
            isConnected = false
            return
        }

        do {
            let (data, response) = try await session.data(from: url)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { $0["name"] as? String }
                availableModels = modelNames.isEmpty ? ["gpt-oss:20b"] : modelNames
                isConnected = true
            } else {
                availableModels = ["gpt-oss:20b"]
                isConnected = false
            }
        } catch {
            availableModels = ["gpt-oss:20b"]
            isConnected = false
            errorMessage = "Cannot connect to Ollama. Make sure it's running."
        }
    }

    /// Check if Ollama server is reachable
    func checkConnection() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            isConnected = false
            return false
        }

        do {
            let (_, response) = try await session.data(from: url)
            isConnected = (response as? HTTPURLResponse)?.statusCode == 200
            errorMessage = nil
            return isConnected
        } catch {
            isConnected = false
            return false
        }
    }

    /// Stop the current generation
    func stopGeneration() {
        currentTask?.cancel()
        isGenerating = false
        generationPhase = .idle
        stopElapsedTimer()
    }
}
