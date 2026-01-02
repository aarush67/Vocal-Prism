//
//  GlassmorphicViews.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Glass Background Effect
struct GlassBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var opacity: Double = 0.3
    var blur: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if colorScheme == .dark {
                        Color.white.opacity(opacity * 0.15)
                    } else {
                        Color.white.opacity(opacity * 0.7)
                    }
                }
                .blur(radius: blur)
            )
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassBackground(opacity: Double = 0.3, blur: CGFloat = 20) -> some View {
        modifier(GlassBackgroundModifier(opacity: opacity, blur: blur))
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.15, green: 0.05, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.25)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.9, green: 0.95, blue: 1.0),
                        Color(red: 0.95, green: 0.9, blue: 1.0),
                        Color(red: 0.85, green: 0.9, blue: 0.95)
                    ],
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDestructive: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .foregroundColor(isDestructive ? .red : .primary)
            .glassBackground(opacity: isHovered ? 0.5 : 0.3)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Progress Bar with Glass Effect
struct GlassProgressBar: View {
    var progress: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                // Progress
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(min(max(progress, 0), 1)), height: 8)
                    .shadow(color: Color.blue.opacity(0.5), radius: 5, x: 0, y: 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Waveform Visualization
struct WaveformView: View {
    @State private var phases: [Double] = Array(repeating: 0, count: 50)
    var isActive: Bool = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<50, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3)
                    .frame(height: isActive ? CGFloat.random(in: 10...60) * sin(phases[index]) : 5)
                    .animation(
                        isActive ? .easeInOut(duration: Double.random(in: 0.3...0.8)).repeatForever() : .default,
                        value: phases[index]
                    )
            }
        }
        .padding(.vertical, 10)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimating()
            }
        }
        .onAppear {
            if isActive {
                startAnimating()
            }
        }
    }
    
    private func startAnimating() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isActive {
                timer.invalidate()
            } else {
                phases = phases.map { _ in Double.random(in: 0...(.pi * 2)) }
            }
        }
    }
}

// MARK: - Drop Zone View
struct DropZoneView: View {
    @Binding var isTargeted: Bool
    var onDrop: (URL) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Drop audio file here")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("or")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            GlassButton(title: "Select File", icon: "folder") {
                selectFile(onSelect: onDrop)
            }
            
            Text("Supports: MP3, WAV, M4A, FLAC")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .glassBackground(opacity: isTargeted ? 0.5 : 0.3)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [10])
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: isTargeted ? [.blue, .purple] : [.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .scaleEffect(isTargeted ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTargeted)
    }
    
    private func selectFile(onSelect: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mp3, .wav, .m4a, .flac, .audio]
        
        if panel.runModal() == .OK, let url = panel.url {
            onSelect(url)
        }
    }
}
