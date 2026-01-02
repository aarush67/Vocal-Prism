//
//  AudioRecorder.swift
//  Vocal Prism
//
//  Created by Aarush Prakash on 12/7/25.
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var error: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var recordingURL: URL?
    
    // Check if we have permission by checking if we can record
    // Note: On macOS, the permission dialog appears automatically when you
    // first try to record with AVAudioRecorder. There's no separate API to
    // request permission in advance.
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        print("🎤 [AudioRecorder] Checking microphone permission...")
        
        // Try to create a test recorder to see if we have permission
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.wav")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1
        ]
        
        do {
            let testRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            
            // Try to prepare to record - this will trigger permission if needed
            if testRecorder.prepareToRecord() {
                print("✅ [AudioRecorder] Microphone access available")
                completion(true)
            } else {
                print("❌ [AudioRecorder] Cannot prepare to record")
                completion(false)
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            print("❌ [AudioRecorder] Error checking permission: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    func startRecording() -> URL? {
        print("🎤 [AudioRecorder] Starting recording...")
        
        // Create temporary file for recording
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "recording_\(Date().timeIntervalSince1970).wav"
        let url = tempDir.appendingPathComponent(filename)
        
        print("📁 [AudioRecorder] Recording to: \(url.path)")
        
        // Use 16kHz sample rate - Whisper's native format
        // This ensures best compatibility and avoids resampling issues
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,  // Whisper native sample rate
            AVNumberOfChannelsKey: 1,   // Mono
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        print("🎙️ [AudioRecorder] Using 16kHz sample rate (Whisper native format)")
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            print("🎙️ [AudioRecorder] AVAudioRecorder created successfully")
            print("🎙️ [AudioRecorder] Attempting to start recording...")
            
            if audioRecorder?.record() == true {
                isRecording = true
                recordingURL = url
                recordingDuration = 0
                
                print("✅ [AudioRecorder] Recording started successfully!")
                print("ℹ️ [AudioRecorder] If you see this but no audio is captured:")
                print("   1. Check System Settings → Sound → Input")
                print("   2. Make sure correct microphone is selected")
                print("   3. Check input volume is not muted")
                print("   4. Speak louder or closer to the microphone")
                
                // Start duration timer
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self, let recorder = self.audioRecorder else { return }
                    self.recordingDuration = recorder.currentTime
                }
                
                // Start level monitoring with detailed logging
                var logCounter = 0
                levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                    guard let self = self, let recorder = self.audioRecorder else { return }
                    recorder.updateMeters()
                    let level = recorder.averagePower(forChannel: 0)
                    let peakLevel = recorder.peakPower(forChannel: 0)
                    
                    // Convert dB (-160 to 0) to 0-1 range
                    let normalizedLevel = pow(10, level / 20)
                    self.audioLevel = max(0, min(1, normalizedLevel))
                    
                    // Log audio levels every 2 seconds
                    logCounter += 1
                    if logCounter >= 40 {
                        print("🎚️ [AudioRecorder] Audio - Avg: \(String(format: "%.1f", level))dB, Peak: \(String(format: "%.1f", peakLevel))dB")
                        if level < -40 {
                            print("⚠️ [AudioRecorder] Audio is VERY LOW! Increase mic volume or speak louder!")
                        }
                        logCounter = 0
                    }
                }
                
                print("✅ [AudioRecorder] Recording started successfully")
                return url
            } else {
                print("❌ [AudioRecorder] Failed to start recording")
                error = "Failed to start recording"
                return nil
            }
        } catch {
            print("❌ [AudioRecorder] Recording error: \(error.localizedDescription)")
            self.error = error.localizedDescription
            return nil
        }
    }
    
    func stopRecording() -> URL? {
        print("⏹️ [AudioRecorder] Stopping recording...")
        
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        audioRecorder?.stop()
        
        isRecording = false
        audioLevel = 0.0
        
        let url = recordingURL
        recordingURL = nil
        
        if let url = url, FileManager.default.fileExists(atPath: url.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                let sizeKB = Double(size) / 1024.0
                let sizeStr = sizeKB > 1024 ? String(format: "%.2f MB", sizeKB/1024) : String(format: "%.1f KB", sizeKB)
                
                print("✅ [AudioRecorder] Recording saved: \(url.lastPathComponent)")
                print("📊 [AudioRecorder] Duration: \(String(format: "%.1f", recordingDuration))s, Size: \(sizeStr)")
                
                // Verify file size (44.1kHz mono 16-bit = ~88KB/sec)
                let expectedSize = recordingDuration * 88200.0
                if Double(size) < expectedSize * 0.1 {
                    print("⚠️ [AudioRecorder] WARNING: File size is MUCH smaller than expected!")
                    print("⚠️ Expected ~\(Int(expectedSize/1024))KB, got \(Int(sizeKB))KB")
                    print("⚠️ This means NO AUDIO was captured - check mic permissions & settings!")
                }
            }
            return url
        } else {
            print("❌ [AudioRecorder] Recording file not found")
            return nil
        }
    }
    
    func cancelRecording() {
        print("🗑️ [AudioRecorder] Cancelling recording...")
        
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        audioRecorder?.stop()
        
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ [AudioRecorder] Deleted recording file")
        }
        
        isRecording = false
        recordingURL = nil
        audioLevel = 0.0
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎤 [AudioRecorder] Recording finished. Success: \(flag)")
        if !flag {
            error = "Recording failed"
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ [AudioRecorder] Encoding error: \(error?.localizedDescription ?? "unknown")")
        self.error = error?.localizedDescription
    }
}
