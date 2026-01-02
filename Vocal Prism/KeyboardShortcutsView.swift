//
//  KeyboardShortcutsManager.swift
//  Vocal Prism
//
//  Comprehensive keyboard shortcuts for power users
//

import SwiftUI

struct KeyboardShortcutsView: View {
    @Environment(\.dismiss) var dismiss
    
    let shortcuts = [
        ShortcutGroup(
            title: "General",
            shortcuts: [
                Shortcut(keys: "⌘ O", action: "Open Audio File"),
                Shortcut(keys: "⌘ R", action: "Start Live Recording"),
                Shortcut(keys: "⌘ T", action: "Start Transcription"),
                Shortcut(keys: "⌘ ,", action: "Open Settings"),
                Shortcut(keys: "⌘ N", action: "New/Reset"),
                Shortcut(keys: "⌘ W", action: "Close Window"),
                Shortcut(keys: "⌘ Q", action: "Quit App")
            ]
        ),
        ShortcutGroup(
            title: "Transcription",
            shortcuts: [
                Shortcut(keys: "⌘ C", action: "Copy Transcription"),
                Shortcut(keys: "⌘ S", action: "Save Transcription"),
                Shortcut(keys: "⌘ E", action: "Export as PDF"),
                Shortcut(keys: "⌘ ⇧ E", action: "Export as DOCX"),
                Shortcut(keys: "⌘ P", action: "Print Transcription"),
                Shortcut(keys: "Esc", action: "Cancel Transcription")
            ]
        ),
        ShortcutGroup(
            title: "Recording",
            shortcuts: [
                Shortcut(keys: "Space", action: "Start/Stop Recording"),
                Shortcut(keys: "⌘ ⇧ R", action: "Re-record"),
                Shortcut(keys: "⌘ D", action: "Delete Recording")
            ]
        ),
        ShortcutGroup(
            title: "Navigation",
            shortcuts: [
                Shortcut(keys: "⌘ 1", action: "Go to Upload View"),
                Shortcut(keys: "⌘ 2", action: "Go to Live Recording"),
                Shortcut(keys: "⌘ 3", action: "Go to Settings"),
                Shortcut(keys: "⌘ /", action: "Show Keyboard Shortcuts")
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keyboard Shortcuts")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Master Vocal Prism with these powerful shortcuts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(30)
                .glassBackground()
                
                // Shortcuts list
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(shortcuts, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(group.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 8) {
                                    ForEach(group.shortcuts, id: \.keys) { shortcut in
                                        HStack {
                                            Text(shortcut.action)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(shortcut.keys)
                                                .font(.system(.body, design: .monospaced))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 4)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .glassBackground()
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 700, height: 600)
    }
}

struct ShortcutGroup {
    let title: String
    let shortcuts: [Shortcut]
}

struct Shortcut {
    let keys: String
    let action: String
}

#Preview {
    KeyboardShortcutsView()
}
