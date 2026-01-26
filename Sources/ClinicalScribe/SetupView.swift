import SwiftUI

/// First-launch setup view for downloading the model
struct SetupView: View {
    @ObservedObject var ollamaManager: EmbeddedOllamaManager
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // App icon placeholder
            Image(systemName: "stethoscope")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("Clinical Scribe")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("AI-Powered Medical Documentation")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()
                .frame(height: 20)

            // Status area
            statusSection

            Spacer()
        }
        .frame(width: 500, height: 450)
        .padding(40)
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(spacing: 20) {
            switch ollamaManager.status {
            case .notStarted, .starting:
                startingView

            case .running:
                modelStatusView

            case .failed(let error):
                errorView(error)
            }
        }
        .frame(maxWidth: 400)
    }

    private var startingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Starting AI engine...")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var modelStatusView: some View {
        switch ollamaManager.modelStatus {
        case .unknown, .checking:
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Checking model...")
                    .foregroundColor(.secondary)
            }

        case .notInstalled:
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("Download AI Model")
                    .font(.headline)

                Text("Clinical Scribe requires a language model to generate clinical notes. This is a one-time download (~12 GB).")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button(action: {
                    Task {
                        await ollamaManager.downloadModel()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download Model")
                    }
                    .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

        case .downloading:
            VStack(spacing: 16) {
                ProgressView(value: ollamaManager.downloadProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                Text(ollamaManager.statusMessage)
                    .foregroundColor(.secondary)

                Text("Please keep the app open")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .ready:
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)

                Text("Ready!")
                    .font(.headline)

                Button("Get Started") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

        case .failed(let error):
            errorView(error)
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Setup Error")
                .font(.headline)

            Text(error)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await ollamaManager.startOllama()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
