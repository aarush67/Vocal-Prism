//
//  LiveTranscriptionView.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import SwiftUI
import AVFoundation

struct LiveTranscriptionView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @ObservedObject var whisperEngine: WhisperEngine
    @Environment(\.dismiss) var dismiss
    
    @State private var recordedFileURL: URL?
    @State private var showingTranscription = false
    @State private var showingPermissionAlert = false
    @State private var permissionError: String = ""
    
    // User preferences from settings
    @AppStorage("selectedThreads") private var threadCount = 4
    @AppStorage("selectedModelId") private var selectedModelId = "base.en"
    @AppStorage("selectedLanguage") private var selectedLanguage = "Auto"
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 30) {
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
                    .padding(.horizontal, 20)
                }
                
                if !permissionError.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.slash.fill").foregroundColor(.orange)
                        Text(permissionError).lineLimit(2)
                        Spacer()
                        Button("Open Settings") { openSystemSettings() }
                            .buttonStyle(.borderless)
                    }
                    .padding()
                    .glassBackground(opacity: 0.3)
                    .padding(.horizontal, 20)
                }
                
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text("Live Transcription")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Text("").frame(width: 80)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                if showingTranscription {
                    transcriptionResultView
                } else {
                    recordingView
                }
            }
            .padding(30)
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open System Settings") {
                openSystemSettings()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(permissionError)
        }
    }
    
    // MARK: - Recording View
    private var recordingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Recording status
            VStack(spacing: 20) {
                if audioRecorder.isRecording {
                    recordingIndicator
                    
                    Text(formatDuration(audioRecorder.recordingDuration))
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                    
                    Text("Recording...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Tap to Start Recording")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Speak clearly into your microphone")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("(Permission dialog will appear on first use)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            // Audio level indicator
            if audioRecorder.isRecording {
                audioLevelIndicator
            }
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 30) {
                if audioRecorder.isRecording {
                    // Cancel button
                    Button(action: {
                        audioRecorder.cancelRecording()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                            Text("Cancel")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Stop and transcribe button
                    Button(action: {
                        stopAndTranscribe()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("Transcribe")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    // Start recording button
                    Button(action: {
                        startRecording()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                            }
                            Text("Record")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Transcription Result View
    private var transcriptionResultView: some View {
        VStack(spacing: 20) {
            if whisperEngine.isTranscribing {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Transcribing your recording...")
                        .font(.title3)
                    
                    Text(whisperEngine.currentStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if whisperEngine.progress > 0 {
                        GlassProgressBar(progress: whisperEngine.progress)
                            .frame(height: 8)
                            .padding(.horizontal, 40)
                    }
                }
            } else if !whisperEngine.transcriptionText.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Your Transcription")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                copyToClipboard()
                            }) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text(whisperEngine.transcriptionText)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .glassBackground()
                    }
                }
                
                HStack(spacing: 12) {
                    GlassButton(title: "New Recording", icon: "mic.fill") {
                        resetForNewRecording()
                    }
                    
                    GlassButton(title: "Done", icon: "checkmark") {
                        dismiss()
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Recording Indicator
    private var recordingIndicator: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color.red)
                .frame(width: 20, height: 20)
                .opacity(0.8)
                .overlay(
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                        .scaleEffect(1.5)
                        .opacity(0.5)
                )
            
            Text("REC")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassBackground()
    }
    
    // MARK: - Audio Level Indicator
    private var audioLevelIndicator: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 40)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(audioRecorder.audioLevel), height: 40)
                    .animation(.linear(duration: 0.05), value: audioRecorder.audioLevel)
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Methods
    private func startRecording() {
        print("🎙️ [LiveTranscription] Starting recording...")
        print("ℹ️ [LiveTranscription] Permission dialog will appear automatically if not yet granted")
        
        // Just start recording - the system will show permission dialog automatically
        if let url = audioRecorder.startRecording() {
            recordedFileURL = url
            print("✅ [LiveTranscription] Recording started")
        } else {
            // Recording failed - might be permission denied
            print("❌ [LiveTranscription] Recording failed to start")
            permissionError = "Could not start recording. If you previously denied microphone access, please enable it in:\n\nSystem Settings → Privacy & Security → Microphone\n\nEnable 'Vocal Prism' and try again."
            showingPermissionAlert = true
        }
    }
    
    private func stopAndTranscribe() {
        guard let url = audioRecorder.stopRecording() else {
            print("❌ No recording to transcribe")
            return
        }
        
        print("✅ Recording saved, starting transcription...")
        
        // Diagnostic: Check the audio file before transcription
        diagnoseAudioFile(url)
        
        showingTranscription = true
        
        // Use user preferences from settings
        var options = WhisperEngine.TranscriptionOptions()
        options.threads = threadCount  // More threads for faster processing
        options.modelId = selectedModelId
        options.language = selectedLanguage == "Auto" ? nil : selectedLanguage
        options.includeTimestamps = false  // Faster for live transcription
        options.exportSRT = false
        
        whisperEngine.transcribe(audioFile: url, options: options) { result in
            // Clean up temporary recording file after transcription completes
            defer {
                self.cleanupTemporaryFile(url)
            }
            
            switch result {
            case .success(let text):
                print("✅ Live transcription complete: \(text.prefix(100))...")
            case .failure(let error):
                print("❌ Live transcription failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func openSystemSettings() {
        print("⚙️ [LiveTranscription] Opening System Settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(whisperEngine.transcriptionText, forType: .string)
    }
    
    private func resetForNewRecording() {
        // Clean up any leftover files from previous recording
        if let url = recordedFileURL {
            cleanupTemporaryFile(url)
        }
        
        showingTranscription = false
        whisperEngine.transcriptionText = ""
        whisperEngine.progress = 0
        whisperEngine.currentStatus = "Ready"
        recordedFileURL = nil
    }
    
    private func diagnoseAudioFile(_ url: URL) {
        print("🔍 [Diagnostic] Checking audio file...")
        
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ [Diagnostic] File does not exist!")
            return
        }
        
        // Check file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            let sizeKB = Double(size) / 1024.0
            print("📊 [Diagnostic] File size: \(String(format: "%.2f", sizeKB)) KB")
            
            if size < 1000 {
                print("⚠️ [Diagnostic] File is suspiciously small - likely no audio captured!")
            }
        }
        
        // Try to read audio file properties
        let asset = AVURLAsset(url: url)
        Task {
            do {
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                if let audioTrack = audioTracks.first {
                    print("✅ [Diagnostic] Audio track found")
                    let timeScale = try await audioTrack.load(.naturalTimeScale)
                    let duration = try await asset.load(.duration)
                    print("📊 [Diagnostic] Sample rate: \(timeScale)")
                    print("📊 [Diagnostic] Duration: \(duration.seconds)s")
                } else {
                    print("❌ [Diagnostic] No audio track found in file!")
                }
            } catch {
                print("❌ [Diagnostic] Error reading audio properties: \(error.localizedDescription)")
            }
        }
    }
    
    private func cleanupTemporaryFile(_ url: URL) {
        do {
            // Delete the temporary audio recording file
            try FileManager.default.removeItem(at: url)
            print("🗑️ [LiveTranscription] Cleaned up temporary recording: \(url.lastPathComponent)")
            
            // Also clean up any .txt files created by whisper-cli
            let txtFile = url.deletingPathExtension().appendingPathExtension("txt")
            if FileManager.default.fileExists(atPath: txtFile.path) {
                try FileManager.default.removeItem(at: txtFile)
                print("🗑️ [LiveTranscription] Cleaned up transcription file: \(txtFile.lastPathComponent)")
            }
            
            // Clean up any .srt files if they exist
            let srtFile = url.deletingPathExtension().appendingPathExtension("srt")
            if FileManager.default.fileExists(atPath: srtFile.path) {
                try FileManager.default.removeItem(at: srtFile)
                print("🗑️ [LiveTranscription] Cleaned up subtitle file: \(srtFile.lastPathComponent)")
            }
        } catch {
            print("⚠️ [LiveTranscription] Failed to clean up temporary file: \(error.localizedDescription)")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
