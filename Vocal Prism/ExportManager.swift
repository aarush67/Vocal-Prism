//
//  ExportManager.swift
//  Vocal Prism
//
//  Advanced export features: PDF, DOCX, SRT, timestamps
//

import Foundation
import AppKit
import UniformTypeIdentifiers

@MainActor
class ExportManager {
    static let shared = ExportManager()
    
    enum ExportFormat {
        case txt
        case pdf
        case docx
        case srt
        case vtt
    }
    
    // MARK: - Export to PDF
    func exportToPDF(text: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = fileName + ".pdf"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            Task {
                do {
                    let pdfData = createPDF(from: text, title: fileName)
                    try pdfData.write(to: url)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createPDF(from text: String, title: String) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let pageRect = NSRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let pdfData = NSMutableData()
        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return Data()
        }
        
        var mediaBox = pageRect
        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        
        pdfContext.beginPDFPage(nil)
        
        // Create NSGraphicsContext for text drawing
        let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        NSGraphicsContext.current = graphicsContext
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        titleString.draw(at: CGPoint(x: 50, y: pageHeight - 60))
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = "Transcribed: \(dateFormatter.string(from: Date()))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.gray
        ]
        let dateAttributedString = NSAttributedString(string: dateString, attributes: dateAttributes)
        dateAttributedString.draw(at: CGPoint(x: 50, y: pageHeight - 85))
        
        // Content
        let textRect = NSRect(x: 50, y: 50, width: pageWidth - 100, height: pageHeight - 160)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.black
        ]
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        attributedText.draw(in: textRect)
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
    
    // MARK: - Export to DOCX (as RTF)
    func exportToDOCX(text: String, fileName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let savePanel = NSSavePanel()
        if let docxType = UTType(filenameExtension: "docx") {
            savePanel.allowedContentTypes = [docxType]
        }
        savePanel.nameFieldStringValue = fileName + ".docx"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            Task {
                do {
                    let rtfData = createRTF(from: text, title: fileName)
                    try rtfData.write(to: url)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func createRTF(from text: String, title: String) -> Data {
        let rtfString = """
        {\\rtf1\\ansi\\deff0
        {\\fonttbl{\\f0 Helvetica;}}
        {\\colortbl;\\red0\\green0\\blue0;}
        \\f0\\fs48\\b \(title)\\b0\\par
        \\fs24 Transcribed: \\i\(Date())\\i0\\par
        \\line
        \\fs24 \(text.replacingOccurrences(of: "\n", with: "\\par\n"))
        }
        """
        return rtfString.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Export to SRT/VTT
    func exportToSubtitles(text: String, fileName: String, format: ExportFormat, timestamps: [(start: TimeInterval, end: TimeInterval, text: String)], completion: @escaping (Result<URL, Error>) -> Void) {
        let savePanel = NSSavePanel()
        
        switch format {
        case .srt:
            if let srtType = UTType(filenameExtension: "srt") {
                savePanel.allowedContentTypes = [srtType]
            }
            savePanel.nameFieldStringValue = fileName + ".srt"
        case .vtt:
            if let vttType = UTType(filenameExtension: "vtt") {
                savePanel.allowedContentTypes = [vttType]
            }
            savePanel.nameFieldStringValue = fileName + ".vtt"
        default:
            return
        }
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            Task {
                do {
                    var content = ""
                    
                    if format == .vtt {
                        content = "WEBVTT\n\n"
                    }
                    
                    for (index, timestamp) in timestamps.enumerated() {
                        content += "\(index + 1)\n"
                        content += "\(formatTimestamp(timestamp.start, format: format)) --> \(formatTimestamp(timestamp.end, format: format))\n"
                        content += "\(timestamp.text)\n\n"
                    }
                    
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    completion(.success(url))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func formatTimestamp(_ time: TimeInterval, format: ExportFormat) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        
        if format == .vtt {
            return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
        } else {
            return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
        }
    }
    
    // MARK: - Quick Share
    func shareTranscription(text: String, from view: NSView) {
        let sharingPicker = NSSharingServicePicker(items: [text])
        sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
    }
}
