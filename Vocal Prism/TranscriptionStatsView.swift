//
//  TranscriptionStatsView.swift
//  Vocal Prism
//
//  Statistics and analytics for transcriptions
//

import SwiftUI
import Charts

struct TranscriptionStatsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var historyManager = TranscriptionHistoryManager.shared
    
    var totalWords: Int {
        historyManager.records.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    var totalCharacters: Int {
        historyManager.records.reduce(0) { $0 + $1.text.count }
    }
    
    var mostUsedModel: String {
        let models = historyManager.records.compactMap { $0.modelId }
        let counts = Dictionary(grouping: models, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    var mostUsedLanguage: String {
        let languages = historyManager.records.compactMap { $0.language }
        let counts = Dictionary(grouping: languages, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transcription Statistics")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Your transcription insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Button { historyManager.loadHistory() } label: {
                            Label("Refresh", systemImage: "arrow.clockwise").labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        .help("Reload stats from history")
                        Button { exportSummaryCSV() } label: {
                            Label("Export", systemImage: "square.and.arrow.up").labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        .help("Export summary CSV")
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(30)
                .glassBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            StatPill(title: "Today", value: formatNumber(todayWords) + " words")
                            StatPill(title: "7 days", value: formatNumber(weekWords) + " words")
                            StatPill(title: "Files", value: "\(historyManager.records.count)")
                        }
                        
                        HStack(spacing: 20) {
                            StatCard(title: "Total Transcriptions", value: "\(historyManager.records.count)", icon: "doc.text.fill", color: .blue)
                            StatCard(title: "Total Words", value: formatNumber(totalWords), icon: "textformat", color: .purple)
                            StatCard(title: "Total Characters", value: formatNumber(totalCharacters), icon: "character", color: .green)
                        }
                        
                        if !dailyCounts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Activity (14 days)").font(.headline)
                                Chart(dailyCounts) { item in
                                    LineMark(x: .value("Day", item.date, unit: .day), y: .value("Words", item.words)).foregroundStyle(.blue)
                                    AreaMark(x: .value("Day", item.date, unit: .day), y: .value("Words", item.words)).foregroundStyle(.blue.opacity(0.15))
                                }
                                .frame(height: 220)
                                .chartXAxis { AxisMarks(values: .stride(by: .day, count: 2)) }
                            }
                            .padding()
                            .glassBackground()
                        }
                        
                        HStack(spacing: 12) {
                            Label("Model: \(mostUsedModel)", systemImage: "cpu.fill").padding(10).glassBackground(opacity: 0.25)
                            Label("Language: \(mostUsedLanguage)", systemImage: "globe").padding(10).glassBackground(opacity: 0.25)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Model Usage").font(.headline)
                            HStack { Image(systemName: "cpu.fill").foregroundColor(.blue); Text("Most Used Model:"); Spacer(); Text(mostUsedModel).fontWeight(.semibold) }
                            HStack { Image(systemName: "globe").foregroundColor(.purple); Text("Most Used Language:"); Spacer(); Text(mostUsedLanguage).fontWeight(.semibold) }
                        }
                        .padding()
                        .glassBackground()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity").font(.headline)
                            ForEach(historyManager.records.prefix(5)) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.fileName).font(.subheadline).fontWeight(.medium)
                                        Text(record.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(record.text.split(separator: " ").count) words").font(.caption).foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                if record.id != historyManager.records.prefix(5).last?.id { Divider() }
                            }
                        }
                        .padding()
                        .glassBackground()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Image(systemName: "lightbulb.fill").foregroundColor(.yellow); Text("Performance Tips").font(.headline) }
                            TipRow(icon: "bolt.fill", text: "Use 6-8 CPU threads for fastest transcription", color: .orange)
                            TipRow(icon: "cpu.fill", text: "Choose Tiny model for quick drafts, Large V3 for accuracy", color: .blue)
                            TipRow(icon: "waveform", text: "Better audio quality = more accurate transcriptions", color: .green)
                        }
                        .padding()
                        .glassBackground()
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 800, height: 700)
        .onAppear { historyManager.loadHistory() }
        .onReceive(historyManager.$records) { _ in }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

// MARK: - Small helpers
private struct StatPill: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassBackground(opacity: 0.25)
    }
}

private extension TranscriptionStatsView {
    var todayWords: Int {
        let cal = Calendar.current
        return historyManager.records.filter { cal.isDateInToday($0.date) }.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    var weekWords: Int {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        return historyManager.records.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }
    
    struct DailyWordCount: Identifiable { let id = UUID(); let date: Date; let words: Int }
    
    var dailyCounts: [DailyWordCount] {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: -13, to: Date()) else { return [] }
        var buckets: [Date: Int] = [:]
        for record in historyManager.records where record.date >= start {
            let day = cal.startOfDay(for: record.date)
            buckets[day, default: 0] += record.text.split(separator: " ").count
        }
        return buckets.keys.sorted().map { DailyWordCount(date: $0, words: buckets[$0] ?? 0) }
    }
    
    func exportSummaryCSV() {
        let save = NSSavePanel()
        save.nameFieldStringValue = "VocalPrism_Stats.csv"
        save.allowedFileTypes = ["csv"]
        if save.runModal() == .OK, let url = save.url {
            var rows: [String] = ["Date,File,Words,Model,Language"]
            let formatter = ISO8601DateFormatter()
            for r in historyManager.records {
                let words = r.text.split(separator: " ").count
                rows.append("\(formatter.string(from: r.date)),\(r.fileName),\(words),\(r.modelId ?? "N/A"),\(r.language ?? "N/A")")
            }
            try? rows.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassBackground()
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TranscriptionStatsView()
}
