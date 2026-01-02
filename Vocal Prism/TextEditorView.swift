//
//  TextEditorView.swift
//  Vocal Prism
//
//  Advanced text editor for transcriptions
//

import SwiftUI

struct TextEditorView: View {
    @Binding var text: String
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var wordCount = 0
    @State private var characterCount = 0
    @State private var findText = ""
    @State private var replaceText = ""
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Transcription")
                            .font(.title2)
                            .fontWeight(.bold)
                        HStack(spacing: 12) {
                            Text("\(wordCount) words")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(characterCount) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
                .glassBackground()
                
                // Find and Replace Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Find", text: $findText)
                        .textFieldStyle(.plain)
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(.secondary)
                    TextField("Replace", text: $replaceText)
                        .textFieldStyle(.plain)
                    
                    Button(action: performReplace) {
                        Text("Replace All")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .glassBackground()
                .padding(.top, 10)
                
                // Text Editor
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .glassBackground()
                    .padding()
                    .onChange(of: text) { _, newValue in
                        updateStats(newValue)
                    }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .frame(width: 120)
                            .padding()
                            .glassBackground()
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        onSave()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .frame(width: 900, height: 700)
        .onAppear {
            updateStats(text)
        }
    }
    
    private func updateStats(_ text: String) {
        wordCount = text.split(separator: " ").count
        characterCount = text.count
    }
    
    private func performReplace() {
        if !findText.isEmpty {
            text = text.replacingOccurrences(of: findText, with: replaceText)
            findText = ""
            replaceText = ""
        }
    }
}

#Preview {
    TextEditorView(text: .constant("Sample transcription text here"), onSave: {})
}
