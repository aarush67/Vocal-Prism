//
//  ContentView.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct ContentView: View {
    @StateObject private var whisperEngine = WhisperEngine()
    @StateObject private var modelManager = ModelManager.shared
    
    @State private var selectedAudioFile: URL?
    @State private var isDropTargeted = false
    @State private var showingSettings = false
    @State private var showingLiveTranscription = false
    @State private var showingHistory = false
    @State private var showingKeyboardShortcuts = false
    @State private var showingHelp = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false
    @State private var showingQuickActions = false
    @State private var recentFiles: [URL] = []
    @State private var showingTextEditor = false
    @State private var editedTranscription = ""
    @State private var showingStats = false
    @AppStorage("recentFilePaths") private var recentFilePathsData = Data()
    
    // Transcription options - using AppStorage to sync with Settings
    @AppStorage("selectedThreads") private var selectedThreads = 4
    @AppStorage("selectedModelId") private var selectedModelId = "base.en"
    @AppStorage("selectedLanguage") private var selectedLanguage = "Auto"
    @State private var selectedModel: WhisperEngine.ModelVariant = .base
    @State private var includeTimestamps = true
    @State private var exportSRT = false
    
    // UI state
    @State private var showingTranscription = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                headerView
                    .padding(.top, 20)
                    .padding(.horizontal, 30)
                
                // Error banner (inline, dismissable)
                if let error = whisperEngine.error {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                        Text(error).lineLimit(2)
                        Spacer()
                        Button("Dismiss") { whisperEngine.error = nil }
                            .buttonStyle(.borderless)
                    }
                    .padding()
                    .glassBackground(opacity: 0.3)
                    .padding(.horizontal, 30)
                }
                
                ScrollView {
                    VStack {
                        if let audioFile = selectedAudioFile, showingTranscription {
                            transcriptionView(audioFile: audioFile)
                                .padding(30)
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            dropZoneWithLiveOption
                                .padding(30)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingLiveTranscription) {
            LiveTranscriptionView(whisperEngine: whisperEngine)
        }
        .sheet(isPresented: $showingHistory) {
            TranscriptionHistoryView()
        }
        .sheet(isPresented: $showingKeyboardShortcuts) {
            KeyboardShortcutsView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(isPresented: $showingOnboarding)
        }
        .sheet(isPresented: $showingStats) {
            TranscriptionStatsView()
        }
        .onAppear {
            print("🚀 ContentView appeared")
            print("🚀 showingOnboarding: \(showingOnboarding)")
            print("🚀 showingHistory: \(showingHistory)")
            print("🚀 showingHelp: \(showingHelp)")
            loadRecentFiles()
            if !hasSeenOnboarding {
                showingOnboarding = true
            }
        }
        .onChange(of: showingOnboarding) { _, newValue in
            if !newValue {
                hasSeenOnboarding = true
            }
        }
    }
    
    // MARK: - Header with Live Button
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: "waveform.badge.mic")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Vocal Prism")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Text(whisperEngine.currentStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: { showingLiveTranscription = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "mic.fill")
                            Text("Live")
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .glassBackground()
                    }
                    .buttonStyle(.plain)
                    
                    if showingTranscription {
                        GlassButton(title: "New", icon: "plus.circle.fill") {
                            resetView()
                        }
                    }
                    
                    GlassButton(title: "History", icon: "clock.arrow.circlepath") {
                        showingHistory = true
                    }
                    
                    GlassButton(title: "Help", icon: "questionmark.circle") {
                        showingHelp = true
                    }
                    
                    GlassButton(title: "Settings", icon: "gear") {
                        showingSettings = true
                    }
                    
                    GlassButton(title: "Stats", icon: "chart.bar.xaxis") {
                        showingStats = true
                    }
                    
                    Menu {
                        Button("Batch Transcribe Files", action: selectMultipleFiles)
                        Button("Export All History", action: exportAllHistory)
                        Button("Keyboard Shortcuts") { showingKeyboardShortcuts = true }
                        Divider()
                        Button(role: .destructive, action: clearAllCache) {
                            Text("Clear Cache")
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease")
                            Text("Quick Actions")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .glassBackground()
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .glassBackground()
    }
    
    // MARK: - Drop Zone with Live Option
    private var dropZoneWithLiveOption: some View {
        VStack(spacing: 30) {
            DropZoneView(isTargeted: $isDropTargeted) { url in
                handleFileSelection(url: url)
            }
            
            HStack(spacing: 20) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("or")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            .frame(maxWidth: 400)
            
            Button(action: { showingLiveTranscription = true }) {
                HStack(spacing: 15) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Record from Microphone")
                            .font(.headline)
                        Text("Speak and transcribe in real-time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .glassBackground()
            }
            .buttonStyle(.plain)
            
            if !recentFiles.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Files")
                            .font(.headline)
                        Spacer()
                        Button("Clear") { clearRecentFiles() }
                            .buttonStyle(.plain)
                            .font(.caption)
                    }
                    ForEach(recentFiles, id: \.self) { url in
                        Button {
                            handleFileSelection(url: url)
                        } label: {
                            HStack {
                                Image(systemName: "clock")
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                Spacer()
                                if let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 {
                                    Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .glassBackground()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Transcription View (same as before)
    private func transcriptionView(audioFile: URL) -> some View {
        VStack(spacing: 20) {
            audioFileInfoView(audioFile: audioFile)
            
            if whisperEngine.isTranscribing {
                WaveformView(isActive: whisperEngine.isTranscribing)
                    .frame(height: 80)
                    .glassBackground()
                    .transition(.opacity.combined(with: .scale))
            }
            
            if whisperEngine.isTranscribing || whisperEngine.progress > 0 {
                VStack(spacing: 8) {
                    GlassProgressBar(progress: whisperEngine.progress)
                    Text("\(Int(whisperEngine.progress * 100))% Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            if !whisperEngine.transcriptionText.isEmpty {
                transcriptionSummaryBar
            }
            
            transcriptionTextView
            actionButtonsView
        }
    }
    
    private var transcriptionSummaryBar: some View {
        HStack(spacing: 12) {
            summaryChip(title: "Words", value: "\(currentWordCount)", icon: "text.alignleft")
            summaryChip(title: "Characters", value: "\(currentCharacterCount)", icon: "character")
            summaryChip(title: "Model", value: selectedModelId, icon: "cpu.fill")
            summaryChip(title: "Language", value: selectedLanguage, icon: "globe")
        }
        .padding()
        .glassBackground()
    }
    
    private func summaryChip(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .fontWeight(.semibold)
            }
        }
        .padding(10)
        .glassBackground(opacity: 0.25)
    }
    
    private var currentWordCount: Int {
        whisperEngine.transcriptionText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
    
    private var currentCharacterCount: Int {
        whisperEngine.transcriptionText.count
    }
    
    private func audioFileInfoView(audioFile: URL) -> some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(audioFile.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let fileSize = try? FileManager.default.attributesOfItem(atPath: audioFile.path)[.size] as? Int64 {
                        Label(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file), systemImage: "doc")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label(audioFile.pathExtension.uppercased(), systemImage: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .glassBackground()
    }
    
    private var transcriptionTextView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if whisperEngine.transcriptionText.isEmpty && !whisperEngine.isTranscribing {
                        VStack(spacing: 10) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("Transcription will appear here")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                    } else {
                        Text(whisperEngine.transcriptionText)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("transcriptionEnd")
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .glassBackground()
            .onChange(of: whisperEngine.transcriptionText) { _, _ in
                withAnimation {
                    proxy.scrollTo("transcriptionEnd", anchor: .bottom)
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            if whisperEngine.isTranscribing {
                GlassButton(title: "Cancel", icon: "stop.circle.fill", action: {
                    whisperEngine.cancelTranscription()
                }, isDestructive: true)
            } else if !whisperEngine.transcriptionText.isEmpty {
                GlassButton(title: "Copy", icon: "doc.on.doc") {
                    copyTranscription()
                }
                GlassButton(title: "Save TXT", icon: "square.and.arrow.down") {
                    saveTranscriptionManually()
                }
                GlassButton(title: "Export PDF", icon: "doc.text") {
                    print("🔵 Export PDF button tapped")
                    exportAsPDF()
                }
                GlassButton(title: "Export DOCX", icon: "doc.richtext") {
                    print("🔵 Export DOCX button tapped")
                    exportAsDOCX()
                }
            } else {
                GlassButton(title: "Start Transcription", icon: "play.circle.fill") {
                    startTranscription()
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("Transcription Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Form {
                Section("Performance") {
                    HStack {
                        Text("CPU Threads:")
                        Spacer()
                        Picker("", selection: $selectedThreads) {
                            ForEach([1, 2, 4, 6, 8], id: \.self) { thread in
                                Text("\(thread)").tag(thread)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                    Text("💡 Use 6-8 threads for fastest live transcription")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Output Options") {
                    Toggle("Include Timestamps", isOn: $includeTimestamps)
                    Toggle("Export SRT Subtitles", isOn: $exportSRT)
                }
            }
            .formStyle(.grouped)
            
            Button("Close") {
                showingSettings = false
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(30)
        .frame(width: 500, height: 400)
    }
    
    // MARK: - Helper Methods
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            DispatchQueue.main.async {
                handleFileSelection(url: url)
            }
        }
        return true
    }
    
    private func handleFileSelection(url: URL) {
        let supportedExtensions = ["mp3", "wav", "m4a", "flac"]
        guard supportedExtensions.contains(url.pathExtension.lowercased()) else {
            whisperEngine.error = "Unsupported file format"
            return
        }
        selectedAudioFile = url
        
        // Add to recent files
        addRecentFile(url)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingTranscription = true
        }
    }
    
    private func startTranscription() {
        guard let audioFile = selectedAudioFile else { return }
        
        print("📋 Starting transcription with settings:")
        print("   Model ID: \(selectedModelId)")
        print("   Language: \(selectedLanguage)")
        print("   Threads: \(selectedThreads)")
        
        let options = WhisperEngine.TranscriptionOptions(
            threads: selectedThreads,
            modelVariant: selectedModel,
            includeTimestamps: includeTimestamps,
            exportSRT: exportSRT,
            language: selectedLanguage,
            modelId: selectedModelId
        )
        whisperEngine.transcribe(audioFile: audioFile, options: options) { result in
            switch result {
            case .success(let text):
                print("Transcription completed: \(text.prefix(100))...")
                // Add to history
                TranscriptionHistoryManager.shared.addRecord(
                    fileName: audioFile.lastPathComponent,
                    text: text,
                    modelId: selectedModelId,
                    language: selectedLanguage
                )
            case .failure(let error):
                print("Transcription failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func copyTranscription() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(whisperEngine.transcriptionText, forType: .string)
        whisperEngine.currentStatus = "Copied to clipboard"
    }
    
    private func saveTranscriptionManually() {
        guard let audioFile = selectedAudioFile else { return }
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = audioFile.deletingPathExtension().lastPathComponent + ".txt"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try whisperEngine.transcriptionText.write(to: url, atomically: true, encoding: .utf8)
                whisperEngine.currentStatus = "Saved successfully"
            } catch {
                whisperEngine.error = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
    
    private func exportAsPDF() {
        guard let audioFile = selectedAudioFile else { return }
        let fileName = audioFile.deletingPathExtension().lastPathComponent
        ExportManager.shared.exportToPDF(text: whisperEngine.transcriptionText, fileName: fileName) { result in
            switch result {
            case .success(let url):
                self.whisperEngine.currentStatus = "Exported to \(url.lastPathComponent)"
            case .failure(let error):
                self.whisperEngine.error = "Export failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func exportAsDOCX() {
        guard let audioFile = selectedAudioFile else { return }
        let fileName = audioFile.deletingPathExtension().lastPathComponent
        ExportManager.shared.exportToDOCX(text: whisperEngine.transcriptionText, fileName: fileName) { result in
            switch result {
            case .success(let url):
                self.whisperEngine.currentStatus = "Exported to \(url.lastPathComponent)"
            case .failure(let error):
                self.whisperEngine.error = "Export failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func resetView() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showingTranscription = false
            selectedAudioFile = nil
            whisperEngine.transcriptionText = ""
            whisperEngine.progress = 0.0
            whisperEngine.currentStatus = "Ready"
        }
    }
    
    private func selectMultipleFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mp3, .wav, .m4a, .flac, .audio]
        
        if panel.runModal() == .OK {
            let files = panel.urls
            processBatchFiles(files)
        }
    }
    
    private func processBatchFiles(_ files: [URL]) {
        whisperEngine.currentStatus = "Batch processing \(files.count) files..."
        
        Task {
            for (index, file) in files.enumerated() {
                whisperEngine.currentStatus = "Processing \(index + 1)/\(files.count): \(file.lastPathComponent)"
                
                let options = WhisperEngine.TranscriptionOptions(
                    threads: selectedThreads,
                    modelVariant: selectedModel,
                    includeTimestamps: includeTimestamps,
                    exportSRT: exportSRT,
                    language: selectedLanguage,
                    modelId: selectedModelId
                )
                
                await withCheckedContinuation { continuation in
                    whisperEngine.transcribe(audioFile: file, options: options) { result in
                        switch result {
                        case .success(let text):
                            TranscriptionHistoryManager.shared.addRecord(
                                fileName: file.lastPathComponent,
                                text: text,
                                modelId: self.selectedModelId,
                                language: self.selectedLanguage
                            )
                        case .failure(let error):
                            print("Batch error for \(file.lastPathComponent): \(error)")
                        }
                        continuation.resume()
                    }
                }
            }
            
            whisperEngine.currentStatus = "Batch processing complete! \(files.count) files processed."
        }
    }
    
    private func exportAllHistory() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "All_Transcriptions_\(Date().formatted(date: .numeric, time: .omitted)).txt"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            let allText = TranscriptionHistoryManager.shared.records
                .map { "=== \($0.fileName) ===\nDate: \($0.date.formatted())\nModel: \($0.modelId ?? "N/A")\nLanguage: \($0.language ?? "N/A")\n\n\($0.text)\n\n" }
                .joined(separator: "\n" + String(repeating: "-", count: 50) + "\n\n")
            
            do {
                try allText.write(to: url, atomically: true, encoding: .utf8)
                whisperEngine.currentStatus = "All history exported successfully"
            } catch {
                whisperEngine.error = "Failed to export: \(error.localizedDescription)"
            }
        }
    }
    
    private func clearAllCache() {
        let alert = NSAlert()
        alert.messageText = "Clear All Cache?"
        alert.informativeText = "This will clear all cached data and temporary files. This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Clear cache logic
            if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheDir)
            }
            whisperEngine.currentStatus = "Cache cleared successfully"
        }
    }

    // MARK: - Recent Files Persistence
    private func addRecentFile(_ url: URL) {
        recentFiles.removeAll { $0 == url }
        recentFiles.insert(url, at: 0)
        if recentFiles.count > 8 { recentFiles.removeLast(recentFiles.count - 8) }
        persistRecentFiles()
    }
    
    private func loadRecentFiles() {
        guard !recentFilePathsData.isEmpty,
              let paths = try? JSONDecoder().decode([String].self, from: recentFilePathsData) else { return }
        recentFiles = paths.compactMap { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
    
    private func persistRecentFiles() {
        let paths = recentFiles.map { $0.path }
        recentFilePathsData = (try? JSONEncoder().encode(paths)) ?? Data()
    }
    
    private func clearRecentFiles() {
        recentFiles.removeAll()
        recentFilePathsData = Data()
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
}
