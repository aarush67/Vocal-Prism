//
//  TranscriptionHistoryView.swift
//  Vocal Prism
//
//  View and manage transcription history
//

import SwiftUI
import Combine

struct TranscriptionHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var historyManager = TranscriptionHistoryManager.shared
    @State private var searchText = ""
    
    var filteredHistory: [TranscriptionRecord] {
        if searchText.isEmpty {
            return historyManager.records
        }
        return historyManager.records.filter {
            $0.fileName.localizedCaseInsensitiveContains(searchText) ||
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transcription History")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\(historyManager.records.count) transcriptions")
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
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search transcriptions...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .glassBackground()
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // History list
                if filteredHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(searchText.isEmpty ? "No transcriptions yet" : "No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "Your transcriptions will appear here" : "Try a different search term")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredHistory) { record in
                                TranscriptionRecordRow(record: record) {
                                    historyManager.deleteRecord(record)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            historyManager.loadHistory()
        }
    }
}

struct TranscriptionRecordRow: View {
    let record: TranscriptionRecord
    let onDelete: () -> Void
    @State private var showingFullText = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.fileName)
                        .font(.headline)
                    Text(record.date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let modelId = record.modelId {
                        Text(modelId)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let language = record.language {
                        Text(language)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Text(record.text)
                .font(.body)
                .lineLimit(showingFullText ? nil : 3)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Button(action: { showingFullText.toggle() }) {
                    Text(showingFullText ? "Show less" : "Show more")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Button(action: { copyToClipboard(record.text) }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                Button(action: { exportRecord(record) }) {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .glassBackground()
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func exportRecord(_ record: TranscriptionRecord) {
        ExportManager.shared.exportToPDF(text: record.text, fileName: record.fileName) { _ in }
    }
}

// MARK: - History Manager

class TranscriptionHistoryManager: ObservableObject {
    static let shared = TranscriptionHistoryManager()
    
    @Published var records: [TranscriptionRecord] = []
    
    private let historyFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let historyDir = appSupport.appendingPathComponent("VocalPrism/History")
        try? FileManager.default.createDirectory(at: historyDir, withIntermediateDirectories: true)
        return historyDir.appendingPathComponent("history.json")
    }()
    
    func addRecord(fileName: String, text: String, modelId: String?, language: String?) {
        let record = TranscriptionRecord(
            fileName: fileName,
            text: text,
            date: Date(),
            modelId: modelId,
            language: language
        )
        records.insert(record, at: 0)
        saveHistory()
    }
    
    func deleteRecord(_ record: TranscriptionRecord) {
        records.removeAll { $0.id == record.id }
        saveHistory()
    }
    
    func loadHistory() {
        guard let data = try? Data(contentsOf: historyFileURL),
              let decoded = try? JSONDecoder().decode([TranscriptionRecord].self, from: data) else {
            return
        }
        records = decoded
    }
    
    private func saveHistory() {
        guard let encoded = try? JSONEncoder().encode(records) else { return }
        try? encoded.write(to: historyFileURL)
    }
}

struct TranscriptionRecord: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let text: String
    let date: Date
    let modelId: String?
    let language: String?
    
    init(fileName: String, text: String, date: Date, modelId: String?, language: String?) {
        self.id = UUID()
        self.fileName = fileName
        self.text = text
        self.date = date
        self.modelId = modelId
        self.language = language
    }
}

#Preview {
    TranscriptionHistoryView()
}
