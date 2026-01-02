//
//  Vocal_PrismApp.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import SwiftUI

@main
struct Vocal_PrismApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(after: .help) {
                Button("Keyboard Shortcuts") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowKeyboardShortcuts"), object: nil)
                }
                .keyboardShortcut("/", modifiers: .command)
                
                Button("Help & Support") {
                    NotificationCenter.default.post(name: NSNotification.Name("ShowHelp"), object: nil)
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
    }
}
