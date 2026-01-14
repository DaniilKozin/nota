#!/usr/bin/env swift

import Foundation
import Speech
import AVFoundation

print("🧪 Testing Speech Recognition...")

// Check Speech Recognition authorization
let authStatus = SFSpeechRecognizer.authorizationStatus()
print("📋 Speech Recognition status: \(authStatus.rawValue)")

switch authStatus {
case .notDetermined:
    print("⚠️  Not determined - requesting...")
    SFSpeechRecognizer.requestAuthorization { status in
        print("✅ Authorization result: \(status.rawValue)")
        exit(0)
    }
    RunLoop.main.run()
case .denied:
    print("❌ DENIED - Enable in System Settings > Privacy & Security > Speech Recognition")
    exit(1)
case .restricted:
    print("❌ RESTRICTED")
    exit(1)
case .authorized:
    print("✅ AUTHORIZED")
@unknown default:
    print("❓ Unknown status")
}

// Check Microphone authorization
let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
print("🎤 Microphone status: \(micStatus.rawValue)")

switch micStatus {
case .notDetermined:
    print("⚠️  Not determined - requesting...")
    AVCaptureDevice.requestAccess(for: .audio) { granted in
        print("✅ Microphone result: \(granted)")
        exit(0)
    }
    RunLoop.main.run()
case .denied:
    print("❌ DENIED - Enable in System Settings > Privacy & Security > Microphone")
    exit(1)
case .restricted:
    print("❌ RESTRICTED")
    exit(1)
case .authorized:
    print("✅ AUTHORIZED")
@unknown default:
    print("❓ Unknown status")
}

// Check available recognizers
print("\n🌍 Available Speech Recognizers:")
let locales = ["en-US", "ru-RU", "es-ES", "fr-FR", "de-DE"]
for locale in locales {
    if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) {
        print("  ✅ \(locale): available=\(recognizer.isAvailable)")
    } else {
        print("  ❌ \(locale): not supported")
    }
}

print("\n✅ All checks passed!")
print("💡 If Nota still doesn't work, the issue is in the app code, not permissions")
