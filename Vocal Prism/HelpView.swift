//
//  HelpView.swift
//  Vocal Prism
//
//  Help and support documentation
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedSection = 0
    
    let helpSections = [
        HelpSection(
            icon: "play.circle.fill",
            title: "Getting Started",
            content: """
            Welcome to Vocal Prism! Here's how to get started:
            
            1. DROP OR SELECT AUDIO FILE
               • Drag and drop any audio file (MP3, WAV, M4A, FLAC)
               • Or click "Open Audio File" to browse
            
            2. CONFIGURE SETTINGS
               • Choose your Whisper model (Tiny to Large V3)
               • Select language or use Auto-detect
               • Adjust CPU threads for performance
            
            3. START TRANSCRIPTION
               • Click "Start Transcription" and wait
               • Watch progress bar for real-time updates
               • Cancel anytime with the Cancel button
            
            4. EXPORT OR SAVE
               • Copy to clipboard with ⌘C
               • Save as TXT, SRT, PDF, or DOCX
               • View in transcription history
            """
        ),
        HelpSection(
            icon: "mic.circle.fill",
            title: "Live Recording",
            content: """
            Record and transcribe in real-time:
            
            1. GRANT MICROPHONE PERMISSION
               • Click "Live" button in the header
               • Allow microphone access when prompted
               • Check System Settings > Privacy if needed
            
            2. START RECORDING
               • Press Space or click "Start Recording"
               • Speak clearly into your microphone
               • See live waveform animation
            
            3. REAL-TIME TRANSCRIPTION
               • Transcription updates every few seconds
               • Adjust sensitivity in Settings
               • Works with all supported languages
            
            4. SAVE YOUR RECORDING
               • Click "Stop Recording" when done
               • Export audio + transcription
               • Add to history automatically
            """
        ),
        HelpSection(
            icon: "cpu.fill",
            title: "Whisper Models",
            content: """
            Choose the right model for your needs:
            
            TINY (39 MB) - Fastest, good for quick tests
            • Speed: ~10x real-time
            • Accuracy: Basic
            • Best for: Short clips, drafts
            
            BASE (74 MB) - Balanced performance
            • Speed: ~7x real-time
            • Accuracy: Good
            • Best for: Most use cases
            
            SMALL (244 MB) - Higher accuracy
            • Speed: ~4x real-time
            • Accuracy: Very good
            • Best for: Important transcriptions
            
            MEDIUM (769 MB) - Professional quality
            • Speed: ~2x real-time
            • Accuracy: Excellent
            • Best for: Critical work
            
            LARGE V3 (1.5 GB) - Maximum accuracy
            • Speed: ~1x real-time
            • Accuracy: Best available
            • Best for: Mission-critical transcriptions
            
            All models support 99 languages with CoreML acceleration!
            """
        ),
        HelpSection(
            icon: "gearshape.2.fill",
            title: "Settings Guide",
            content: """
            Customize Vocal Prism to your needs:
            
            MODEL SETTINGS
            • Download additional Whisper models
            • Switch between Tiny, Base, Small, Medium, Large V3
            • Check download progress and storage used
            
            LANGUAGE SETTINGS
            • Auto-detect (recommended for mixed content)
            • 99 languages supported
            • Manual selection for better accuracy
            
            PERFORMANCE SETTINGS
            • CPU Threads: 1-8 (use 6-8 for live recording)
            • CoreML acceleration enabled automatically
            • Monitor transcription speed
            
            OUTPUT SETTINGS
            • Include timestamps in transcription
            • Export as SRT subtitles
            • Choose default export format
            
            KEYBOARD SHORTCUTS
            • Press ⌘/ to see all shortcuts
            • Customize in System Settings
            • Master power-user features
            """
        ),
        HelpSection(
            icon: "globe",
            title: "Supported Languages",
            content: """
            Vocal Prism supports 99 languages:
            
            MAJOR LANGUAGES:
            English, Spanish, French, German, Italian, Portuguese,
            Chinese (Mandarin), Japanese, Korean, Russian, Arabic,
            Hindi, Bengali, Urdu, Turkish, Polish, Dutch, Greek,
            Hebrew, Vietnamese, Thai, Indonesian, Malay, Filipino
            
            EUROPEAN LANGUAGES:
            Swedish, Norwegian, Danish, Finnish, Czech, Slovak,
            Hungarian, Romanian, Bulgarian, Serbian, Croatian,
            Ukrainian, Lithuanian, Latvian, Estonian, Slovenian,
            Catalan, Galician, Basque, Welsh, Irish
            
            ASIAN LANGUAGES:
            Tamil, Telugu, Gujarati, Marathi, Kannada, Malayalam,
            Punjabi, Nepali, Sinhala, Burmese, Lao, Khmer,
            Mongolian, Azerbaijani, Kazakh, Uzbek
            
            AFRICAN & OTHERS:
            Swahili, Amharic, Yoruba, Hausa, Zulu, Afrikaans,
            Persian, Pashto, Kurdish, Armenian, Georgian, Yiddish
            
            AND MORE! Use Auto-detect for best results.
            """
        ),
        HelpSection(
            icon: "questionmark.circle.fill",
            title: "Troubleshooting",
            content: """
            Common issues and solutions:
            
            TRANSCRIPTION NOT STARTING
            • Ensure audio file is valid format
            • Check if model is fully downloaded
            • Try restarting the app
            
            POOR ACCURACY
            • Use larger model (Medium or Large V3)
            • Select correct language manually
            • Ensure audio quality is good
            • Increase CPU threads in Settings
            
            MICROPHONE NOT WORKING
            • Check System Settings > Privacy & Security
            • Grant microphone permission to Vocal Prism
            • Test microphone in other apps
            • Restart app after granting permission
            
            SLOW PERFORMANCE
            • Use smaller model (Tiny or Base)
            • Reduce CPU threads (try 4)
            • Close other demanding apps
            • Check Activity Monitor for CPU usage
            
            EXPORT FAILED
            • Ensure you have write permissions
            • Check available disk space
            • Try different export format
            • Save to different location
            
            Still need help? Check our documentation online!
            """
        )
    ]
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            HStack(spacing: 0) {
                // Sidebar
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Help & Support")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(20)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(0..<helpSections.count, id: \.self) { index in
                                Button(action: { selectedSection = index }) {
                                    HStack {
                                        Image(systemName: helpSections[index].icon)
                                            .frame(width: 24)
                                        Text(helpSections[index].title)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(selectedSection == index ? Color.blue.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(selectedSection == index ? .primary : .secondary)
                            }
                        }
                        .padding(12)
                    }
                }
                .frame(width: 250)
                .background(Color.white.opacity(0.05))
                
                Divider()
                
                // Content
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 10) {
                                Image(systemName: helpSections[selectedSection].icon)
                                    .font(.title2)
                                Text(helpSections[selectedSection].title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.05))
                    
                    ScrollView {
                        Text(helpSections[selectedSection].content)
                            .font(.system(.body, design: .default))
                            .lineSpacing(8)
                            .padding(30)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(width: 900, height: 650)
    }
}

struct HelpSection {
    let icon: String
    let title: String
    let content: String
}

#Preview {
    HelpView()
}
