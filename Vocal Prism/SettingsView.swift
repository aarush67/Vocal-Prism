//
//  SettingsView.swift
//  Vocal Prism
//
//  Settings UI with model management and language options
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var modelManager = ModelManager.shared
    @AppStorage("selectedModelId") private var selectedModelId = "base.en"
    @AppStorage("selectedLanguage") private var selectedLanguage = "Auto"
    @AppStorage("selectedThreads") private var threadCount = 4
    
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Custom header bar with Done button
                HStack {
                    Text("Settings")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Text("Done")
                            Image(systemName: "xmark.circle.fill")
                        }
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header Icon
                        VStack(spacing: 10) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Performance Settings
                        settingsSection(title: "Performance") {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Text("CPU Threads")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(threadCount)")
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: Binding(
                                    get: { Double(threadCount) },
                                    set: { threadCount = Int($0) }
                                ), in: 1...12, step: 1)
                                
                                Text("More threads = faster transcription (uses more CPU)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Language Selection
                        settingsSection(title: "Language") {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Transcription Language")
                                    .font(.headline)
                                
                                Picker("Language", selection: $selectedLanguage) {
                                    Text("Auto Detect").tag("Auto")
                                    Divider()
                                    ForEach(ModelManager.supportedLanguages, id: \.self) { language in
                                        Text(language).tag(language)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                Text("Select 'Auto Detect' for automatic language detection or choose a specific language for better accuracy")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Model Management
                        settingsSection(title: "Models") {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Download and manage Whisper AI models")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Current Model
                                if let currentModel = modelManager.availableModels.first(where: { $0.id == selectedModelId }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Current Model")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(currentModel.name)
                                                .font(.headline)
                                        }
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                                
                                // Available Models
                                ForEach(modelManager.availableModels) { model in
                                    modelCard(model)
                                }
                            }
                        }
                        
                        // About Section
                        settingsSection(title: "About") {
                            VStack(alignment: .leading, spacing: 15) {
                                infoRow(label: "Version", value: "1.0")
                                infoRow(label: "Whisper Model", value: "OpenAI Whisper.cpp")
                                infoRow(label: "Supported Languages", value: "99+")
                                
                                Link(destination: URL(string: "https://github.com/ggerganov/whisper.cpp")!) {
                                    HStack {
                                        Image(systemName: "link.circle.fill")
                                        Text("View Whisper.cpp on GitHub")
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .padding()
                                    .glassBackground()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(30)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(minWidth: 850, idealWidth: 950, maxWidth: 1200, minHeight: 750, idealHeight: 850, maxHeight: 1000)
        .onAppear {
            modelManager.checkDownloadedModels()
        }
    }
    
    // MARK: - Model Card
    @ViewBuilder
    private func modelCard(_ model: ModelManager.WhisperModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        Label(model.size, systemImage: "internaldrive")
                        Text("•")
                        Text(model.languages.joined(separator: ", "))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if model.isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            Text(model.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Download/Delete/Select Buttons
            HStack(spacing: 10) {
                if model.isDownloaded {
                    Button(action: {
                        selectedModelId = model.id
                    }) {
                        HStack {
                            Image(systemName: selectedModelId == model.id ? "checkmark.circle.fill" : "circle")
                            Text(selectedModelId == model.id ? "Selected" : "Select")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedModelId == model.id ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        modelManager.deleteModel(model)
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    if modelManager.isDownloading[model.id] == true {
                        VStack(spacing: 8) {
                            ProgressView(value: modelManager.downloadProgress[model.id] ?? 0.0)
                            Text("\(Int((modelManager.downloadProgress[model.id] ?? 0.0) * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button(action: {
                            modelManager.downloadModel(model)
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Download")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .glassBackground()
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            content()
        }
    }
    
    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    SettingsView()
}
