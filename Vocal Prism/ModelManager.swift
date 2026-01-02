//
//  ModelManager.swift
//  Vocal Prism
//
//  Manages Whisper model downloads and language support
//

import Foundation
import Combine

class ModelManager: ObservableObject {
    @Published var availableModels: [WhisperModel] = []
    @Published var downloadProgress: [String: Double] = [:]
    @Published var isDownloading: [String: Bool] = [:]
    @Published var downloadError: String?
    
    static let shared = ModelManager()
    
    // Whisper model information
    struct WhisperModel: Identifiable, Equatable {
        let id: String
        let name: String
        let size: String
        let languages: [String]
        let downloadURL: String
        let fileName: String
        let description: String
        var isDownloaded: Bool
        
        var sizeInMB: Int {
            Int(size.replacingOccurrences(of: "MB", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
        }
    }
    
    init() {
        setupAvailableModels()
        checkDownloadedModels()
    }
    
    private func setupAvailableModels() {
        // CoreML-optimized models from custom repository
        // downloadURL now references the txt file name in Resources/ModelDownloadLinks
        
        availableModels = [
            // English-only models
            WhisperModel(
                id: "tiny.en",
                name: "Tiny (English)",
                size: "75 MB",
                languages: ["English"],
                downloadURL: "tiny.en",
                fileName: "ggml-tiny.en.bin",
                description: "Fastest, lowest accuracy. Good for quick transcription.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "base.en",
                name: "Base (English)",
                size: "142 MB",
                languages: ["English"],
                downloadURL: "base.en",
                fileName: "ggml-base.en.bin",
                description: "Fast with decent accuracy. Recommended for most use cases.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "small.en",
                name: "Small (English)",
                size: "466 MB",
                languages: ["English"],
                downloadURL: "small.en",
                fileName: "ggml-small.en.bin",
                description: "Good balance of speed and accuracy.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "medium.en",
                name: "Medium (English)",
                size: "1.5 GB",
                languages: ["English"],
                downloadURL: "medium.en",
                fileName: "ggml-medium.en.bin",
                description: "High accuracy, slower processing.",
                isDownloaded: false
            ),
            
            // Multilingual models (support 99 languages)
            WhisperModel(
                id: "tiny",
                name: "Tiny (Multilingual)",
                size: "75 MB",
                languages: ["99 languages"],
                downloadURL: "tiny",
                fileName: "ggml-tiny.bin",
                description: "Fastest multilingual. Supports Spanish, French, German, Chinese, Japanese, Korean, and 93 more.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "base",
                name: "Base (Multilingual)",
                size: "142 MB",
                languages: ["99 languages"],
                downloadURL: "base",
                fileName: "ggml-base.bin",
                description: "Fast multilingual with decent accuracy.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "small",
                name: "Small (Multilingual)",
                size: "466 MB",
                languages: ["99 languages"],
                downloadURL: "small",
                fileName: "ggml-small.bin",
                description: "Good multilingual accuracy.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "medium",
                name: "Medium (Multilingual)",
                size: "1.5 GB",
                languages: ["99 languages"],
                downloadURL: "medium",
                fileName: "ggml-medium.bin",
                description: "High accuracy for 99 languages.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "large-v1",
                name: "Large V1 (Multilingual)",
                size: "2.9 GB",
                languages: ["99 languages"],
                downloadURL: "large-v1",
                fileName: "ggml-large-v1.bin",
                description: "Highest accuracy, slowest. For professional use.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "large-v2",
                name: "Large V2 (Multilingual)",
                size: "2.9 GB",
                languages: ["99 languages"],
                downloadURL: "large-v2",
                fileName: "ggml-large-v2.bin",
                description: "Latest large model with improved accuracy.",
                isDownloaded: false
            ),
            WhisperModel(
                id: "large-v3",
                name: "Large V3 (Multilingual)",
                size: "2.9 GB",
                languages: ["99 languages"],
                downloadURL: "large-v3",
                fileName: "ggml-large-v3.bin",
                description: "Latest and most accurate model. Best for production.",
                isDownloaded: false
            )
        ]
    }
    
    func checkDownloadedModels() {
        let resourcePath = getModelsDirectory()
        
        for index in availableModels.indices {
            let modelId = availableModels[index].id
            let modelDir = resourcePath.appendingPathComponent(modelId)
            let modelPath = modelDir.appendingPathComponent(availableModels[index].fileName)
            
            // Check if the main .bin file exists
            availableModels[index].isDownloaded = FileManager.default.fileExists(atPath: modelPath.path)
            
            // Also check bundle resources (for bundled models)
            if !availableModels[index].isDownloaded {
                availableModels[index].isDownloaded = Bundle.main.path(forResource: availableModels[index].fileName, ofType: nil) != nil
            }
        }
    }
    
    func getModelsDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("VocalPrism/Models")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        
        return modelsDir
    }
    
    func downloadModel(_ model: WhisperModel) {
        guard !isDownloading[model.id, default: false] else {
            print("⚠️ Model \(model.name) is already downloading")
            return
        }
        
        print("📥 Starting download of \(model.name)...")
        
        isDownloading[model.id] = true
        downloadProgress[model.id] = 0.0
        downloadError = nil
        
        // Parse the download links from the txt file
        guard let downloadInfo = parseModelDownloadFile(model.downloadURL) else {
            downloadError = "Failed to read download links file"
            isDownloading[model.id] = false
            return
        }
        
        // Download all files asynchronously
        Task {
            do {
                try await downloadModelFiles(model: model, downloadInfo: downloadInfo)
                
                DispatchQueue.main.async {
                    self.downloadProgress[model.id] = 1.0
                    self.isDownloading[model.id] = false
                    self.checkDownloadedModels()
                    print("✅ Model \(model.name) downloaded successfully!")
                }
            } catch {
                DispatchQueue.main.async {
                    self.downloadError = "Download failed: \(error.localizedDescription)"
                    self.isDownloading[model.id] = false
                    print("❌ Download failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private struct FileDownloadInfo {
        let url: String
        let relativePath: String
    }
    
    private func parseModelDownloadFile(_ fileName: String) -> [FileDownloadInfo]? {
        // Read the txt file from Resources (Xcode copies them to root during build)
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            print("❌ Could not find file: \(fileName).txt in bundle Resources")
            return nil
        }
        
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            print("❌ Could not read file: \(fileName).txt")
            return nil
        }
        
        // Parse the file structure
        let lines = content.components(separatedBy: .newlines)
        var fileInfos: [FileDownloadInfo] = []
        var currentPath: [String] = []
        var lastIndentLevel = -1
        var isFirstLine = true
        
        print("📖 Parsing \(fileName).txt...")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            // Skip the first non-empty line (it's the model name, already in the path)
            if isFirstLine {
                isFirstLine = false
                print("  🏷️ Model name: \(trimmed) (skipping, already in path)")
                continue
            }
            
            // Check if it's a URL
            if trimmed.hasPrefix("http") {
                // Extract filename from URL
                guard let url = URL(string: trimmed) else { continue }
                let filename = url.lastPathComponent.components(separatedBy: "?").first ?? url.lastPathComponent
                
                // Build the full relative path: currentPath + filename
                let fullPath = (currentPath + [filename]).joined(separator: "/")
                fileInfos.append(FileDownloadInfo(url: trimmed, relativePath: fullPath))
                
                print("  📄 File: \(filename) → \(fullPath)")
            } else {
                // It's a directory/file name - update currentPath based on indentation
                let indentLevel = getIndentLevel(line)
                
                // When indent decreases or stays same, we need to pop directories
                if indentLevel <= lastIndentLevel {
                    // Pop directories until we match the indent level
                    let levelsToRemove = lastIndentLevel - indentLevel + 1
                    if levelsToRemove > 0 && currentPath.count >= levelsToRemove {
                        currentPath.removeLast(levelsToRemove)
                    }
                }
                
                // Add this directory to the path
                currentPath.append(trimmed)
                lastIndentLevel = indentLevel
                
                print("  📁 Dir [\(indentLevel)]: \(trimmed) → \(currentPath.joined(separator: "/"))")
            }
        }
        
        print("📋 Found \(fileInfos.count) files to download")
        return fileInfos
    }
    
    private func getIndentLevel(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " {
                count += 1
            } else {
                break
            }
        }
        // Each indent level is roughly 4-5 spaces in the txt files
        return count / 4
    }
    
    private func downloadModelFiles(model: WhisperModel, downloadInfo: [FileDownloadInfo]) async throws {
        let modelsDir = getModelsDirectory()
        let totalFiles = downloadInfo.count
        var downloadedFiles = 0
        
        for info in downloadInfo {
            guard let url = URL(string: info.url) else {
                print("⚠️ Invalid URL: \(info.url)")
                continue
            }
            
            // Build the destination path: Models/{modelId}/{relativePath}
            let destinationURL = modelsDir.appendingPathComponent(model.id).appendingPathComponent(info.relativePath)
            
            // Create parent directory if needed
            let parentDir = destinationURL.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
            
            print("⬇️ [\(downloadedFiles+1)/\(totalFiles)] Downloading: \(info.relativePath)")
            
            // Download the file
            let (tempURL, _) = try await URLSession.shared.download(from: url)
            
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try? FileManager.default.removeItem(at: destinationURL)
            }
            
            // Move to final location
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            
            downloadedFiles += 1
            let progress = Double(downloadedFiles) / Double(totalFiles)
            
            DispatchQueue.main.async {
                self.downloadProgress[model.id] = progress
            }
            
            print("✅ [\(downloadedFiles)/\(totalFiles)] Downloaded: \(info.relativePath)")
        }
    }
    
    func deleteModel(_ model: WhisperModel) {
        let modelDir = getModelsDirectory().appendingPathComponent(model.id)
        
        do {
            if FileManager.default.fileExists(atPath: modelDir.path) {
                try FileManager.default.removeItem(at: modelDir)
                print("🗑️ Deleted model directory: \(model.name)")
                checkDownloadedModels()
            }
        } catch {
            print("❌ Failed to delete model: \(error.localizedDescription)")
            downloadError = "Failed to delete model: \(error.localizedDescription)"
        }
    }
    
    func getModelPath(for model: WhisperModel) -> String? {
        // Check application support directory first (in model's own folder)
        let modelDir = getModelsDirectory().appendingPathComponent(model.id)
        let modelPath = modelDir.appendingPathComponent(model.fileName)
        if FileManager.default.fileExists(atPath: modelPath.path) {
            return modelPath.path
        }
        
        // Check bundle resources
        return Bundle.main.path(forResource: model.fileName, ofType: nil)
    }
    
    // Supported languages by Whisper multilingual models
    static let supportedLanguages = [
        "Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Assamese", "Azerbaijani",
        "Bashkir", "Basque", "Belarusian", "Bengali", "Bosnian", "Breton", "Bulgarian",
        "Burmese", "Cantonese", "Catalan", "Chinese", "Croatian", "Czech", "Danish",
        "Dutch", "English", "Estonian", "Faroese", "Finnish", "French", "Galician",
        "Georgian", "German", "Greek", "Gujarati", "Haitian Creole", "Hausa", "Hawaiian",
        "Hebrew", "Hindi", "Hungarian", "Icelandic", "Indonesian", "Italian", "Japanese",
        "Javanese", "Kannada", "Kazakh", "Khmer", "Korean", "Lao", "Latin", "Latvian",
        "Lingala", "Lithuanian", "Luxembourgish", "Macedonian", "Malagasy", "Malay",
        "Malayalam", "Maltese", "Maori", "Marathi", "Mongolian", "Nepali", "Norwegian",
        "Nynorsk", "Occitan", "Pashto", "Persian", "Polish", "Portuguese", "Punjabi",
        "Romanian", "Russian", "Sanskrit", "Serbian", "Shona", "Sindhi", "Sinhala",
        "Slovak", "Slovenian", "Somali", "Spanish", "Sundanese", "Swahili", "Swedish",
        "Tagalog", "Tajik", "Tamil", "Tatar", "Telugu", "Thai", "Tibetan", "Turkish",
        "Turkmen", "Ukrainian", "Urdu", "Uzbek", "Vietnamese", "Welsh", "Yiddish", "Yoruba"
    ]
    
    // Map language names to ISO language codes for whisper-cli
    static let languageCodeMap: [String: String] = [
        "Afrikaans": "af", "Albanian": "sq", "Amharic": "am", "Arabic": "ar", "Armenian": "hy",
        "Assamese": "as", "Azerbaijani": "az", "Bashkir": "ba", "Basque": "eu", "Belarusian": "be",
        "Bengali": "bn", "Bosnian": "bs", "Breton": "br", "Bulgarian": "bg", "Burmese": "my",
        "Cantonese": "yue", "Catalan": "ca", "Chinese": "zh", "Croatian": "hr", "Czech": "cs",
        "Danish": "da", "Dutch": "nl", "English": "en", "Estonian": "et", "Faroese": "fo",
        "Finnish": "fi", "French": "fr", "Galician": "gl", "Georgian": "ka", "German": "de",
        "Greek": "el", "Gujarati": "gu", "Haitian Creole": "ht", "Hausa": "ha", "Hawaiian": "haw",
        "Hebrew": "he", "Hindi": "hi", "Hungarian": "hu", "Icelandic": "is", "Indonesian": "id",
        "Italian": "it", "Japanese": "ja", "Javanese": "jw", "Kannada": "kn", "Kazakh": "kk",
        "Khmer": "km", "Korean": "ko", "Lao": "lo", "Latin": "la", "Latvian": "lv",
        "Lingala": "ln", "Lithuanian": "lt", "Luxembourgish": "lb", "Macedonian": "mk", "Malagasy": "mg",
        "Malay": "ms", "Malayalam": "ml", "Maltese": "mt", "Maori": "mi", "Marathi": "mr",
        "Mongolian": "mn", "Nepali": "ne", "Norwegian": "no", "Nynorsk": "nn", "Occitan": "oc",
        "Pashto": "ps", "Persian": "fa", "Polish": "pl", "Portuguese": "pt", "Punjabi": "pa",
        "Romanian": "ro", "Russian": "ru", "Sanskrit": "sa", "Serbian": "sr", "Shona": "sn",
        "Sindhi": "sd", "Sinhala": "si", "Slovak": "sk", "Slovenian": "sl", "Somali": "so",
        "Spanish": "es", "Sundanese": "su", "Swahili": "sw", "Swedish": "sv", "Tagalog": "tl",
        "Tajik": "tg", "Tamil": "ta", "Tatar": "tt", "Telugu": "te", "Thai": "th",
        "Tibetan": "bo", "Turkish": "tr", "Turkmen": "tk", "Ukrainian": "uk", "Urdu": "ur",
        "Uzbek": "uz", "Vietnamese": "vi", "Welsh": "cy", "Yiddish": "yi", "Yoruba": "yo"
    ]
    
    // Convert language name to language code
    static func getLanguageCode(for languageName: String) -> String? {
        if languageName == "Auto" {
            return nil  // Auto-detect
        }
        return languageCodeMap[languageName]
    }
}
