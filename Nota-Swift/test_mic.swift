import Foundation
import AVFoundation
import Speech

print("🧪 Testing Microphone and Speech Recognition...")

// Test 1: Check microphone permission
print("\n1️⃣ Checking Microphone Permission...")
let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
print("   Status: \(micStatus.rawValue) (\(micStatus == .authorized ? "✅ Authorized" : "❌ Not Authorized"))")

if micStatus == .notDetermined {
    print("   Requesting permission...")
    let semaphore = DispatchSemaphore(value: 0)
    AVCaptureDevice.requestAccess(for: .audio) { granted in
        print("   Result: \(granted ? "✅ Granted" : "❌ Denied")")
        semaphore.signal()
    }
    semaphore.wait()
}

// Test 2: Check speech recognition permission
print("\n2️⃣ Checking Speech Recognition Permission...")
let speechStatus = SFSpeechRecognizer.authorizationStatus()
print("   Status: \(speechStatus.rawValue) (\(speechStatus == .authorized ? "✅ Authorized" : "❌ Not Authorized"))")

if speechStatus == .notDetermined {
    print("   Requesting permission...")
    let semaphore = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        print("   Result: \(status == .authorized ? "✅ Granted" : "❌ Denied")")
        semaphore.signal()
    }
    semaphore.wait()
}

// Test 3: Check if speech recognizer is available
print("\n3️⃣ Checking Speech Recognizer Availability...")
let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
if let recognizer = recognizer {
    print("   ✅ Speech recognizer created")
    print("   Available: \(recognizer.isAvailable)")
    print("   Locale: \(recognizer.locale.identifier)")
} else {
    print("   ❌ Failed to create speech recognizer")
}

// Test 4: Try to start audio engine
print("\n4️⃣ Testing Audio Engine...")
let audioEngine = AVAudioEngine()
let inputNode = audioEngine.inputNode
let format = inputNode.outputFormat(forBus: 0)
print("   Sample Rate: \(format.sampleRate) Hz")
print("   Channels: \(format.channelCount)")

do {
    try audioEngine.start()
    print("   ✅ Audio engine started successfully")
    audioEngine.stop()
} catch {
    print("   ❌ Audio engine failed: \(error)")
}

print("\n✅ All tests completed!")
print("\nIf all tests passed, the issue is in the app code.")
print("If any test failed, that's the problem to fix.")
