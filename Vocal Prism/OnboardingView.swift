//
//  OnboardingView.swift
//  Vocal Prism
//
//  Comprehensive onboarding experience for first launch
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var hasCompletedOnboarding = false
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.badge.mic",
            title: "Welcome to Vocal Prism",
            description: "Transform your audio into text with powerful AI transcription. Support for 99 languages and real-time processing.",
            gradient: [.blue, .purple]
        ),
        OnboardingPage(
            icon: "cpu.fill",
            title: "AI-Powered Transcription",
            description: "Choose from multiple Whisper models - from lightning-fast Tiny to ultra-accurate Large V3. All with CoreML hardware acceleration.",
            gradient: [.purple, .pink]
        ),
        OnboardingPage(
            icon: "globe",
            title: "99 Languages Supported",
            description: "Transcribe in English, Spanish, French, Chinese, Japanese, Arabic, and 93 more languages with auto-detection or manual selection.",
            gradient: [.pink, .orange]
        ),
        OnboardingPage(
            icon: "mic.circle.fill",
            title: "Live Recording",
            description: "Record directly from your microphone and get real-time transcriptions. Perfect for meetings, lectures, and interviews.",
            gradient: [.orange, .red]
        ),
        OnboardingPage(
            icon: "doc.text.fill",
            title: "Multiple Export Formats",
            description: "Export your transcriptions as Text, SRT subtitles, PDF documents, or DOCX files. Copy to clipboard or save anywhere.",
            gradient: [.red, .blue]
        ),
        OnboardingPage(
            icon: "gearshape.2.fill",
            title: "Powerful Settings",
            description: "Download additional models, adjust CPU threads, select languages, and customize your transcription experience.",
            gradient: [.blue, .cyan]
        ),
        OnboardingPage(
            icon: "checkmark.circle.fill",
            title: "Ready to Start!",
            description: "Drop an audio file or click Live to record. Your transcriptions are processed locally with full privacy.",
            gradient: [.cyan, .green]
        )
    ]
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: { completeOnboarding() }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                // Content
                ZStack {
                    ForEach(0..<pages.count, id: \.self) { index in
                        if currentPage == index {
                            OnboardingPageView(page: pages[index])
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .animation(.spring(), value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation {
                                    currentPage = index
                                }
                            }
                    }
                }
                .padding(.vertical, 20)
                
                // Navigation buttons
                HStack(spacing: 20) {
                    if currentPage > 0 {
                        Button(action: { withAnimation { currentPage -= 1 } }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .frame(width: 120)
                            .padding()
                            .glassBackground()
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer()
                            .frame(width: 120)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .frame(width: 120)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: pages[currentPage].gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: { completeOnboarding() }) {
                            HStack {
                                Text("Get Started")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .frame(width: 160)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 900, height: 700)
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.spring()) {
            isPresented = false
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: page.gradient.first?.opacity(0.5) ?? .clear, radius: 30)
            
            // Title
            Text(page.title)
                .font(.system(size: 36, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(.horizontal, 80)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
