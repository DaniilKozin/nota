#!/usr/bin/env swift

import Foundation
import AVFoundation
import Speech

print("🧪 Testing Nota Transcription System")
print("===================================")

// Test 1: Check microphone permissions
print("\n1️⃣ Testing microphone permissions...")
let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
switch micStatus {
case .authorized:
    print("✅ Microphone access: Authorized")
case .notDetermined:
    print("⚠️ Microphone access: Not determined - need to request")
case .denied:
    print("❌ Microphone access: Denied")
case .restricted:
    print("❌ Microphone access: Restricted")
@unknown default:
    print("❓ Microphone access: Unknown status")
}

// Test 2: Check Speech Recognition permissions
print("\n2️⃣ Testing Speech Recognition permissions...")
let speechStatus = SFSpeechRecognizer.authorizationStatus()
switch speechStatus {
case .authorized:
    print("✅ Speech Recognition: Authorized")
case .notDetermined:
    print("⚠️ Speech Recognition: Not determined - need to request")
case .denied:
    print("❌ Speech Recognition: Denied")
case .restricted:
    print("❌ Speech Recognition: Restricted")
@unknown default:
    print("❓ Speech Recognition: Unknown status")
}

// Test 3: Check available languages
print("\n3️⃣ Testing available languages...")
let availableLocales = SFSpeechRecognizer.supportedLocales()
print("✅ Supported locales count: \(availableLocales.count)")
for locale in availableLocales.prefix(10) {
    let recognizer = SFSpeechRecognizer(locale: locale)
    let available = recognizer?.isAvailable ?? false
    print("   \(locale.identifier): \(available ? "✅" : "❌")")
}

// Test 4: Check audio devices
print("\n4️⃣ Testing audio devices...")
let audioDevices = AVCaptureDevice.DiscoverySession(
    deviceTypes: [.builtInMicrophone, .externalUnknown],
    mediaType: .audio,
    position: .unspecified
).devices

print("✅ Found \(audioDevices.count) audio devices:")
for device in audioDevices {
    print("   📱 \(device.localizedName) (ID: \(device.uniqueID))")
}

// Test 5: Check UserDefaults settings
print("\n5️⃣ Testing UserDefaults settings...")
let openaiKey = UserDefaults.standard.string(forKey: "openaiKey") ?? ""
let deepgramKey = UserDefaults.standard.string(forKey: "deepgramKey") ?? ""
let transcriptionProvider = UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "auto"

print("OpenAI Key: \(openaiKey.isEmpty ? "❌ Not set" : "✅ Set (sk-...)")")
print("Deepgram Key: \(deepgramKey.isEmpty ? "❌ Not set" : "✅ Set")")
print("Transcription Provider: \(transcriptionProvider)")

// Test 6: Test audio engine setup
print("\n6️⃣ Testing audio engine setup...")
let audioEngine = AVAudioEngine()
let inputNode = audioEngine.inputNode
let recordingFormat = inputNode.outputFormat(forBus: 0)

print("Audio Engine:")
print("   Sample Rate: \(recordingFormat.sampleRate)Hz")
print("   Channels: \(recordingFormat.channelCount)")
print("   Format: \(recordingFormat.commonFormat.rawValue)")

// Test 7: Test OpenAI API connectivity (if key is available)
if !openaiKey.isEmpty && openaiKey.hasPrefix("sk-") {
    print("\n7️⃣ Testing OpenAI API connectivity...")
    
    var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
    request.setValue("Bearer \(openaiKey)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ OpenAI API Error: \(error.localizedDescription)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ OpenAI API Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                print("✅ OpenAI API: Connected successfully")
            } else {
                print("❌ OpenAI API: HTTP \(httpResponse.statusCode)")
            }
        }
    }.resume()
    
    semaphore.wait()
} else {
    print("\n7️⃣ Skipping OpenAI API test (no valid key)")
}

print("\n🎯 Test Summary:")
print("================")
print("Microphone: \(micStatus == .authorized ? "✅" : "❌")")
print("Speech Recognition: \(speechStatus == .authorized ? "✅" : "❌")")
print("Audio Devices: \(audioDevices.count > 0 ? "✅" : "❌")")
print("OpenAI Key: \(!openaiKey.isEmpty ? "✅" : "❌")")

if micStatus != .authorized || speechStatus != .authorized {
    print("\n⚠️ PERMISSIONS NEEDED:")
    print("Run the app and grant microphone and speech recognition permissions")
}

if openaiKey.isEmpty {
    print("\n💡 RECOMMENDATION:")
    print("Add OpenAI API key in settings for better transcription quality")
}

print("\n🚀 Ready to test recording!")