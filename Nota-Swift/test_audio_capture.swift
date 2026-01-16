#!/usr/bin/env swift

import AVFoundation
import Foundation

print("🎤 Testing audio capture...")

// Check current default input device
let audioSession = AVAudioSession.sharedInstance()
do {
    try audioSession.setCategory(.record, mode: .default)
    try audioSession.setActive(true)
    print("✅ Audio session activated")
} catch {
    print("❌ Failed to activate audio session: \(error)")
}

// List available inputs
if let availableInputs = audioSession.availableInputs {
    print("\n📱 Available audio inputs:")
    for input in availableInputs {
        print("  - \(input.portName) (UID: \(input.uid))")
    }
}

// Get current input
if let currentRoute = audioSession.currentRoute.inputs.first {
    print("\n🎧 Current input: \(currentRoute.portName)")
}

// Test recording
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let audioFilename = documentsPath.appendingPathComponent("test_capture.wav")

let settings: [String: Any] = [
    AVFormatIDKey: Int(kAudioFormatLinearPCM),
    AVSampleRateKey: 16000,
    AVNumberOfChannelsKey: 1,
    AVLinearPCMBitDepthKey: 16,
    AVLinearPCMIsFloatKey: false,
    AVLinearPCMIsBigEndianKey: false
]

do {
    let recorder = try AVAudioRecorder(url: audioFilename, settings: settings)
    recorder.record()
    print("\n🔴 Recording for 3 seconds...")
    Thread.sleep(forTimeInterval: 3.0)
    recorder.stop()
    
    // Check file size
    let attributes = try FileManager.default.attributesOfItem(atPath: audioFilename.path)
    let fileSize = attributes[.size] as! UInt64
    print("✅ Recording saved: \(audioFilename.path)")
    print("📊 File size: \(fileSize) bytes")
    
    if fileSize < 1000 {
        print("⚠️ File is very small - might be silence or no audio captured")
    } else {
        print("✅ File size looks good - audio was captured")
    }
} catch {
    print("❌ Recording failed: \(error)")
}
