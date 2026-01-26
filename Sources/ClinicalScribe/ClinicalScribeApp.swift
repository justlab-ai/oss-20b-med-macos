import SwiftUI

@main
struct ClinicalScribeApp: App {
    @StateObject private var ollamaManager = EmbeddedOllamaManager.shared
    @State private var isSetupComplete = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isSetupComplete && ollamaManager.modelStatus == .ready {
                    ContentView()
                } else {
                    SetupView(ollamaManager: ollamaManager) {
                        isSetupComplete = true
                    }
                }
            }
            .task {
                await ollamaManager.startOllama()
                // Skip setup if model is already ready
                if ollamaManager.modelStatus == .ready {
                    isSetupComplete = true
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
