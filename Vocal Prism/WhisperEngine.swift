//
//  WhisperEngine.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import Foundation
import Combine

class WhisperEngine: ObservableObject {
    @Published var transcriptionText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentStatus: String = "Ready"
    @Published var error: String?
    
    private var transcriptionProcess: Process?
    private var outputPipe: Pipe?
    private var cancellables = Set<AnyCancellable>()
    
    enum ModelVariant: String, CaseIterable {
        case base = "base.en"
        case small = "small.en"
        case medium = "medium.en"
        case large = "large"
        
        var displayName: String {
            switch self {
            case .base: return "Base (Fastest)"
            case .small: return "Small"
            case .medium: return "Medium"
            case .large: return "Large (Most Accurate)"
            }
        }
    }
    
    struct TranscriptionOptions {
        var threads: Int = 4
        var modelVariant: ModelVariant = .base
        var includeTimestamps: Bool = true
        var exportSRT: Bool = false
        var language: String? = nil  // nil for auto-detect
        var modelId: String? = nil   // Use custom model ID
    }
    
    // Optimized settings for live microphone transcription
    static func liveTranscriptionOptions() -> TranscriptionOptions {
        var options = TranscriptionOptions()
        options.threads = 6  // More threads for faster processing
        options.modelVariant = .base  // Fast model
        options.includeTimestamps = false  // Skip timestamps for speed
        options.exportSRT = false
        return options
    }
    
    // Verify and set up whisper-cli on first launch
    func setupWhisperCLI() throws {
        guard let executablePath = Bundle.main.path(forResource: "whisper-cli", ofType: nil) else {
            throw NSError(domain: "WhisperEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "whisper-cli not found in bundle"])
        }
        
        // Make executable
        let fileManager = FileManager.default
        var attributes = try fileManager.attributesOfItem(atPath: executablePath)
        
        // Check if already executable
        if let permissions = attributes[.posixPermissions] as? NSNumber {
            let currentPerms = permissions.uint16Value
            if (currentPerms & 0o111) == 0 {
                // Not executable, make it executable
                try fileManager.setAttributes([.posixPermissions: NSNumber(value: 0o755)], ofItemAtPath: executablePath)
            }
        }
    }
    
    // Verify model presence
    func verifyModel(variant: ModelVariant) -> Bool {
        let modelName = "ggml-\(variant.rawValue).bin"
        return Bundle.main.path(forResource: modelName, ofType: nil) != nil
    }
    
    // Main transcription method with real-time streaming
    func transcribe(audioFile: URL, options: TranscriptionOptions, completion: @escaping (Result<String, Error>) -> Void) {
        guard !isTranscribing else {
            completion(.failure(NSError(domain: "WhisperEngine", code: 2, userInfo: [NSLocalizedDescriptionKey: "Already transcribing"])))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.setupWhisperCLI()
                
                guard let executablePath = Bundle.main.path(forResource: "whisper-cli", ofType: nil) else {
                    throw NSError(domain: "WhisperEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "whisper-cli not found"])
                }
                
                // Get model path from ModelManager if custom model ID specified
                let modelPath: String
                if let modelId = options.modelId {
                    // Find the model in ModelManager
                    if let model = ModelManager.shared.availableModels.first(where: { $0.id == modelId }) {
                        if let path = ModelManager.shared.getModelPath(for: model) {
                            modelPath = path
                            print("🎯 Using model: \(model.name) at \(modelPath)")
                        } else {
                            throw NSError(domain: "WhisperEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Model \(model.name) not downloaded. Please download it in Settings."])
                        }
                    } else {
                        throw NSError(domain: "WhisperEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Model ID \(modelId) not found"])
                    }
                } else {
                    // Use default model from bundle
                    let modelName = "ggml-\(options.modelVariant.rawValue).bin"
                    guard let bundlePath = Bundle.main.path(forResource: modelName, ofType: nil) else {
                        throw NSError(domain: "WhisperEngine", code: 3, userInfo: [NSLocalizedDescriptionKey: "Model \(modelName) not found"])
                    }
                    modelPath = bundlePath
                }
                
                // Prepare output file path (without extension, whisper-cli adds .txt)
                let outputBasePath = audioFile.deletingPathExtension().path
                let outputTxtPath = outputBasePath + ".txt"
                
                DispatchQueue.main.async {
                    self.isTranscribing = true
                    self.transcriptionText = ""
                    self.progress = 0.0
                    self.currentStatus = "Starting transcription..."
                    self.error = nil
                }
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                
                // Build arguments using actual whisper-cli flags
                var arguments = [
                    "-m", modelPath,              // Model path
                    "-f", audioFile.path,         // Input audio file
                    "-t", String(options.threads), // Thread count
                    "-otxt",                      // Output text file
                    "-of", outputBasePath,        // Output file base path (no extension)
                    "-pp"                         // Print progress
                ]
                
                // Add language parameter if specified (convert to ISO code)
                if let language = options.language {
                    // Convert language name to ISO code (e.g., "Spanish" -> "es")
                    if let languageCode = ModelManager.getLanguageCode(for: language) {
                        arguments.append(contentsOf: ["-l", languageCode])
                        print("🌍 Using language: \(language) (code: \(languageCode))")
                    } else {
                        print("🌍 Using auto-detect mode (language: \(language))")
                    }
                } else {
                    print("🌍 Using auto-detect mode (no language specified)")
                }
                
                if !options.includeTimestamps {
                    arguments.append("-nt")       // No timestamps
                }
                
                if options.exportSRT {
                    arguments.append("-osrt")     // Also export SRT subtitles
                }
                
                print("🎯 Whisper command: whisper-cli \(arguments.joined(separator: " "))")
                
                process.arguments = arguments
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe
                
                self.transcriptionProcess = process
                self.outputPipe = outputPipe
                
                // Monitor output for progress updates
                let outputHandle = outputPipe.fileHandleForReading
                let errorHandle = errorPipe.fileHandleForReading
                
                // Poll the output file for real-time transcription updates
                var fileMonitorTimer: Timer?
                var lastFileSize: Int64 = 0
                
                DispatchQueue.main.async {
                    fileMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
                        guard let self = self, self.isTranscribing else {
                            timer.invalidate()
                            return
                        }
                        
                        // Check if output file exists and read incremental content
                        if FileManager.default.fileExists(atPath: outputTxtPath) {
                            let currentSize = (try? FileManager.default.attributesOfItem(atPath: outputTxtPath)[.size] as? Int64) ?? 0
                            
                            if currentSize > lastFileSize {
                                if let text = try? String(contentsOfFile: outputTxtPath, encoding: .utf8) {
                                    DispatchQueue.main.async {
                                        self.transcriptionText = text
                                        self.currentStatus = "Transcribing..."
                                    }
                                }
                                lastFileSize = currentSize
                            }
                        }
                    }
                }
                
                // Capture stdout/stderr for progress
                outputHandle.readabilityHandler = { [weak self] handle in
                    let data = handle.availableData
                    if data.count > 0, let output = String(data: data, encoding: .utf8) {
                        self?.parseProgress(from: output)
                        print("[whisper-cli] \(output)")
                    }
                }
                
                errorHandle.readabilityHandler = { [weak self] handle in
                    let data = handle.availableData
                    if data.count > 0, let output = String(data: data, encoding: .utf8) {
                        self?.parseProgress(from: output)
                        print("[whisper-cli stderr] \(output)")
                    }
                }
                
                try process.run()
                
                DispatchQueue.main.async {
                    self.currentStatus = "Processing audio..."
                }
                
                process.waitUntilExit()
                
                // Stop file monitoring
                DispatchQueue.main.async {
                    fileMonitorTimer?.invalidate()
                }
                
                outputHandle.readabilityHandler = nil
                errorHandle.readabilityHandler = nil
                
                let exitCode = process.terminationStatus
                
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    self.progress = 1.0
                    
                    if exitCode == 0 {
                        // Read final transcription from output file
                        if let finalText = try? String(contentsOfFile: outputTxtPath, encoding: .utf8) {
                            self.transcriptionText = finalText
                            self.currentStatus = "Transcription complete - saved to \(outputTxtPath)"
                            completion(.success(finalText))
                        } else {
                            let errorMessage = "Failed to read transcription output file"
                            self.error = errorMessage
                            self.currentStatus = "Failed"
                            completion(.failure(NSError(domain: "WhisperEngine", code: 4, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        }
                    } else {
                        let errorMessage = "Transcription failed with exit code \(exitCode)"
                        self.error = errorMessage
                        self.currentStatus = "Failed"
                        completion(.failure(NSError(domain: "WhisperEngine", code: Int(exitCode), userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    self.error = error.localizedDescription
                    self.currentStatus = "Error"
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func parseProgress(from output: String) {
        // Whisper typically outputs progress as percentage or time indicators
        // This is a simplified parser - adjust based on actual output
        if let progressMatch = output.range(of: "(\\d+)%", options: .regularExpression) {
            let percentStr = String(output[progressMatch]).replacingOccurrences(of: "%", with: "")
            if let percent = Double(percentStr) {
                DispatchQueue.main.async {
                    self.progress = percent / 100.0
                }
            }
        }
    }
    
    func cancelTranscription() {
        transcriptionProcess?.terminate()
        
        DispatchQueue.main.async {
            self.isTranscribing = false
            self.currentStatus = "Cancelled"
            self.progress = 0.0
        }
    }
}
