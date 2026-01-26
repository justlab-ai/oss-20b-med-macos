import Foundation

/// Manages the embedded Ollama binary bundled with the app
/// Uses port 11435 to avoid conflicts with system Ollama on 11434
@MainActor
class EmbeddedOllamaManager: ObservableObject {
    static let shared = EmbeddedOllamaManager()

    @Published var status: OllamaStatus = .notStarted
    @Published var modelStatus: ModelStatus = .unknown
    @Published var downloadProgress: Double = 0
    @Published var statusMessage: String = ""

    private var ollamaProcess: Process?
    private let requiredModel = "gpt-oss:20b"

    /// Port used by embedded Ollama (different from default 11434)
    let ollamaPort = 11435

    enum OllamaStatus: Equatable {
        case notStarted
        case starting
        case running
        case failed(String)
    }

    enum ModelStatus: Equatable {
        case unknown
        case checking
        case notInstalled
        case downloading
        case ready
        case failed(String)
    }

    private var ollamaBinaryPath: String? {
        Bundle.main.path(forResource: "ollama", ofType: nil)
    }

    /// Application Support directory for ClinicalScribe
    private var appSupportDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ClinicalScribe")
    }

    /// Path for Ollama models
    private var modelsPath: URL {
        appSupportDir.appendingPathComponent("models")
    }

    /// Base URL for Ollama API
    var ollamaBaseURL: URL {
        URL(string: "http://127.0.0.1:\(ollamaPort)")!
    }

    /// Start the embedded Ollama server
    func startOllama() async {
        guard let binaryPath = ollamaBinaryPath else {
            status = .failed("Ollama binary not found in app bundle")
            return
        }

        // Check if our Ollama is already running on our port
        if await isOllamaRunning() {
            status = .running
            await checkModelStatus()
            return
        }

        status = .starting
        statusMessage = "Starting Ollama..."

        // Create directories
        try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: modelsPath, withIntermediateDirectories: true)

        // Start Ollama server on our dedicated port
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["serve"]
        process.environment = [
            "OLLAMA_HOST": "127.0.0.1:\(ollamaPort)",
            "OLLAMA_MODELS": modelsPath.path,
            "HOME": NSHomeDirectory(),
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"
        ]

        // Capture output for debugging
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            ollamaProcess = process

            // Wait for server to be ready
            var attempts = 0
            while attempts < 30 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                if await isOllamaRunning() {
                    status = .running
                    statusMessage = "Ollama running"
                    await checkModelStatus()
                    return
                }
                attempts += 1
            }

            // Read error output for debugging
            let errorData = errorPipe.fileHandleForReading.availableData
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            status = .failed("Ollama server failed to start: \(errorOutput.prefix(200))")
        } catch {
            status = .failed("Failed to start Ollama: \(error.localizedDescription)")
        }
    }

    /// Stop the embedded Ollama server
    func stopOllama() {
        ollamaProcess?.terminate()
        ollamaProcess = nil
        status = .notStarted
    }

    /// Check if Ollama server is responding
    func isOllamaRunning() async -> Bool {
        guard let url = URL(string: "\(ollamaBaseURL)/api/tags") else { return false }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    /// Check if the required model is installed
    func checkModelStatus() async {
        modelStatus = .checking
        statusMessage = "Checking model..."

        guard let url = URL(string: "\(ollamaBaseURL)/api/tags") else {
            modelStatus = .failed("Invalid URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let models = json["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { $0["name"] as? String }

                if modelNames.contains(where: { $0.hasPrefix("gpt-oss") }) {
                    modelStatus = .ready
                    statusMessage = "Ready"
                } else {
                    modelStatus = .notInstalled
                    statusMessage = "Model not installed"
                }
            } else {
                modelStatus = .notInstalled
            }
        } catch {
            modelStatus = .failed("Failed to check models: \(error.localizedDescription)")
        }
    }

    /// Download the required model using HTTP API with streaming
    func downloadModel() async {
        modelStatus = .downloading
        statusMessage = "Starting download..."
        downloadProgress = 0

        guard let url = URL(string: "\(ollamaBaseURL)/api/pull") else {
            modelStatus = .failed("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "name": requiredModel,
            "stream": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                modelStatus = .failed("Download request failed")
                return
            }

            var totalSize: Int64 = 0
            var completedSize: Int64 = 0

            for try await line in bytes.lines {
                guard !line.isEmpty else { continue }

                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {

                    // Update status message
                    if let statusStr = json["status"] as? String {
                        statusMessage = statusStr
                    }

                    // Track progress
                    if let total = json["total"] as? Int64 {
                        totalSize = total
                    }
                    if let completed = json["completed"] as? Int64 {
                        completedSize = completed
                    }

                    if totalSize > 0 {
                        downloadProgress = Double(completedSize) / Double(totalSize)
                        let percent = Int(downloadProgress * 100)
                        statusMessage = "Downloading... \(percent)%"
                    }

                    // Check for errors
                    if let error = json["error"] as? String {
                        modelStatus = .failed(error)
                        return
                    }
                }
            }

            // Download complete
            modelStatus = .ready
            statusMessage = "Ready"
            downloadProgress = 1.0

        } catch {
            modelStatus = .failed("Failed to download: \(error.localizedDescription)")
        }
    }

    /// Check if this is the first launch (no models directory)
    var isFirstLaunch: Bool {
        !FileManager.default.fileExists(atPath: modelsPath.path)
    }
}
