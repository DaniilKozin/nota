import Foundation
import AVFoundation
import Speech
import Combine
import AppKit
import CoreAudio

// Recording session for history
struct RecordingSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let transcript: String
    let insights: String
    let language: String
    var duration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
}

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var liveInsights = ""
    @Published var connectionStatus = "Ready"
    @Published var availableDevices: [AudioDevice] = []
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var selectedDeviceId: String = "default"
    private var selectedLanguage: String = "auto"
    private var transcriptionProvider: String = "auto"
    
    // Audio recording for OpenAI Whisper
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    // Smart transcription and insights management
    private var lastTranscriptUpdate = Date()
    private var lastInsightsUpdate = Date()
    private var transcriptBuffer = ""
    private var lastProcessedTranscript = ""
    private var insightsCache: [String: Any] = [:]
    private var transcriptionTimer: Timer?
    private var insightsTimer: Timer?
    
    // Configuration for smart processing - optimized for GPT-5 nano
    private let transcriptionInterval: TimeInterval = 6.0 // 6 seconds (slightly longer)
    private let insightsInterval: TimeInterval = 45.0 // 45 seconds (more economical)
    private let minTranscriptLengthForInsights = 120 // characters (slightly higher threshold)
    private let maxTokensPerInsightRequest = 800 // reduced for nano model
    
    // Recording session tracking with DataManager
    private var currentSessionStartTime: Date?
    private var currentSessionId: UUID?
    private weak var dataManager: DataManager?
    
    struct AudioDevice {
        let id: String
        let name: String
        let isInput: Bool
    }
    
    override init() {
        super.init()
        setupSpeechRecognizer()
        loadSettings()
        // Don't discover devices immediately - wait until needed
        // This prevents crashes on first launch before permissions are granted
    }
    
    // Set data manager for saving recordings
    func setDataManager(_ manager: DataManager) {
        self.dataManager = manager
    }
    
    deinit {
        transcriptionTimer?.invalidate()
        insightsTimer?.invalidate()
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        selectedDeviceId = UserDefaults.standard.string(forKey: "inputDeviceId") ?? "default"
        selectedLanguage = UserDefaults.standard.string(forKey: "outputLanguage") ?? "auto"
        transcriptionProvider = UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "auto"
    }
    
    func updateSettings() {
        selectedDeviceId = UserDefaults.standard.string(forKey: "inputDeviceId") ?? "default"
        selectedLanguage = UserDefaults.standard.string(forKey: "outputLanguage") ?? "auto"
        transcriptionProvider = UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "auto"
        
        // Update speech recognizer if language changed
        let newLanguageCode = getLanguageCode()
        if speechRecognizer?.locale.identifier != newLanguageCode {
            setupSpeechRecognizer()
        }
    }
    
    // MARK: - Audio Device Discovery
    func discoverAudioDevices() {
        var devices: [AudioDevice] = []
        
        // Add default device
        devices.append(AudioDevice(id: "default", name: "Default Input", isInput: true))
        
        // Get all audio devices using CoreAudio
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else {
            print("⚠️ Could not get audio devices (permissions may not be granted yet)")
            DispatchQueue.main.async {
                self.availableDevices = devices
            }
            return
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &audioDevices
        )
        
        guard status == noErr else {
            print("⚠️ Could not get audio device data")
            DispatchQueue.main.async {
                self.availableDevices = devices
            }
            return
        }
        
        for deviceID in audioDevices {
            // Check if device has input channels
            if hasInputChannels(deviceID: deviceID),
               let deviceName = getDeviceName(deviceID: deviceID),
               let deviceUID = getDeviceUID(deviceID: deviceID) {
                devices.append(AudioDevice(
                    id: deviceUID,
                    name: deviceName,
                    isInput: true
                ))
                print("🎧 Found input device: \(deviceName) (UID: \(deviceUID))")
            }
        }
        
        DispatchQueue.main.async {
            self.availableDevices = devices
            print("🎧 Total input devices found: \(devices.count)")
        }
    }
    
    private func hasInputChannels(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr, dataSize > 0 else {
            return false
        }
        
        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferListPointer.deallocate() }
        
        let getStatus = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            bufferListPointer
        )
        
        guard getStatus == noErr else {
            return false
        }
        
        let bufferList = bufferListPointer.pointee
        return bufferList.mNumberBuffers > 0 && bufferList.mBuffers.mNumberChannels > 0
    }
    
    // MARK: - Speech Recognition Setup
    private func setupSpeechRecognizer() {
        // Determine language for speech recognition
        let languageCode = getLanguageCode()
        print("🌍 Setting up speech recognizer for: \(languageCode)")
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        
        // Check if the language is supported
        if let recognizer = speechRecognizer {
            print("✅ Speech recognizer created for \(languageCode)")
            print("📱 Is available: \(recognizer.isAvailable)")
            print("📱 Locale: \(recognizer.locale.identifier)")
        } else {
            print("❌ Failed to create speech recognizer for \(languageCode)")
        }
        
        // Request Speech Recognition authorization immediately
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.connectionStatus = "Ready"
                    print("✅ Speech Recognition authorized")
                case .denied:
                    self?.connectionStatus = "Speech recognition denied - enable in System Settings"
                    print("❌ Speech Recognition denied")
                case .restricted:
                    self?.connectionStatus = "Speech recognition restricted"
                    print("❌ Speech Recognition restricted")
                case .notDetermined:
                    self?.connectionStatus = "Speech recognition not determined"
                    print("⚠️ Speech Recognition not determined")
                @unknown default:
                    self?.connectionStatus = "Unknown authorization status"
                    print("❓ Speech Recognition unknown status")
                }
            }
        }
    }
    
    // MARK: - Language Support
    private func getLanguageCode() -> String {
        let outputLanguage = UserDefaults.standard.string(forKey: "outputLanguage") ?? "auto"
        
        switch outputLanguage {
        case "auto":
            // Auto-detect based on system language
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            switch systemLanguage {
            case "ru": return "ru-RU"
            case "es": return "es-ES" 
            case "fr": return "fr-FR"
            case "de": return "de-DE"
            case "zh": return "zh-CN"
            case "ja": return "ja-JP"
            case "ko": return "ko-KR"
            case "pt": return "pt-BR"
            case "it": return "it-IT"
            case "nl": return "nl-NL"
            case "sv": return "sv-SE"
            case "da": return "da-DK"
            case "no": return "nb-NO"
            case "fi": return "fi-FI"
            case "pl": return "pl-PL"
            case "tr": return "tr-TR"
            case "ar": return "ar-SA"
            case "he": return "he-IL"
            case "hi": return "hi-IN"
            case "th": return "th-TH"
            case "vi": return "vi-VN"
            default: return "en-US"
            }
        case "en": return "en-US"
        case "ru": return "ru-RU"
        case "es": return "es-ES"
        case "fr": return "fr-FR"
        case "de": return "de-DE"
        case "zh": return "zh-CN"
        case "ja": return "ja-JP"
        case "ko": return "ko-KR"
        case "pt": return "pt-BR"
        case "it": return "it-IT"
        case "nl": return "nl-NL"
        case "sv": return "sv-SE"
        case "da": return "da-DK"
        case "no": return "nb-NO"
        case "fi": return "fi-FI"
        case "pl": return "pl-PL"
        case "tr": return "tr-TR"
        case "ar": return "ar-SA"
        case "he": return "he-IL"
        case "hi": return "hi-IN"
        case "th": return "th-TH"
        case "vi": return "vi-VN"
        default: return "en-US"
        }
    }
    
    func getSupportedLanguages() -> [(code: String, name: String)] {
        return [
            ("auto", "Auto-detect"),
            ("en", "English"),
            ("ru", "Русский"),
            ("es", "Español"),
            ("fr", "Français"),
            ("de", "Deutsch"),
            ("zh", "中文"),
            ("ja", "日本語"),
            ("ko", "한국어"),
            ("pt", "Português"),
            ("it", "Italiano"),
            ("nl", "Nederlands"),
            ("sv", "Svenska"),
            ("da", "Dansk"),
            ("no", "Norsk"),
            ("fi", "Suomi"),
            ("pl", "Polski"),
            ("tr", "Türkçe"),
            ("ar", "العربية"),
            ("he", "עברית"),
            ("hi", "हिन्दी"),
            ("th", "ไทย"),
            ("vi", "Tiếng Việt")
        ]
    }
    
    // MARK: - Recording Control
    func startRecording() {
        guard !isRecording else { 
            print("⚠️ Already recording, ignoring start request")
            return 
        }
        
        print("🎤 Starting recording process...")
        connectionStatus = "Requesting permissions..."
        
        // Mark session start time
        currentSessionStartTime = Date()
        currentSessionId = UUID()
        
        // Reset buffers for new recording
        transcriptBuffer = ""
        lastProcessedTranscript = ""
        transcript = "" // Clear for new recording
        liveInsights = ""
        insightsCache.removeAll()
        
        // First, request Speech Recognition permission
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus != .authorized {
            print("🗣️ Requesting Speech Recognition permission...")
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        print("✅ Speech Recognition authorized")
                        // Now request microphone
                        self?.requestMicrophoneAndStart()
                    } else {
                        print("❌ Speech Recognition denied: \(status.rawValue)")
                        self?.connectionStatus = "Speech Recognition denied - enable in System Settings"
                    }
                }
            }
        } else {
            // Speech Recognition already authorized, request microphone
            requestMicrophoneAndStart()
        }
    }
    
    private func requestMicrophoneAndStart() {
        // Request microphone permission for macOS
        requestMicrophonePermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Microphone permission granted, starting audio recording")
                    self?.startAudioRecording()
                    self?.startSmartProcessing()
                } else {
                    print("❌ Microphone permission denied")
                    self?.connectionStatus = "Microphone access denied - enable in System Settings"
                }
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("⏹️ Stopping recording...")
        
        // Stop timers
        transcriptionTimer?.invalidate()
        insightsTimer?.invalidate()
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Clean up
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
        
        print("⏹️ Recording stopped")
        
        // Save current session to history
        saveCurrentSession()
        
        // Save recording to DataManager
        saveRecordingToDataManager()
        
        // Process final transcript and insights
        processFinalTranscript()
    }
    
    // MARK: - Permission Management
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        print("🎤 Current microphone status: \(currentStatus)")
        
        switch currentStatus {
        case .authorized:
            print("✅ Microphone already authorized")
            completion(true)
        case .notDetermined:
            print("⚠️ Requesting microphone permission...")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                print("🎤 Microphone permission result: \(granted)")
                completion(granted)
            }
        case .denied:
            print("❌ Microphone access denied - user needs to enable in System Settings")
            completion(false)
        case .restricted:
            print("❌ Microphone access restricted")
            completion(false)
        @unknown default:
            print("❓ Unknown microphone status")
            completion(false)
        }
    }
    
    // MARK: - Audio Recording
    private func startAudioRecording() {
        print("🎤 startAudioRecording() called")
        
        // For now, use Speech Framework (OpenAI Whisper can be added later)
        startSpeechFrameworkRecording()
    }
    
    private func startSpeechFrameworkRecording() {
        print("🎤 Starting Speech Framework recording...")
        
        // Log current language settings
        let currentLanguage = getLanguageCode()
        print("🌍 Current language code: \(currentLanguage)")
        print("🌍 Speech recognizer locale: \(speechRecognizer?.locale.identifier ?? "nil")")
        
        // Log selected audio device
        let selectedDevice = UserDefaults.standard.string(forKey: "inputDeviceId") ?? "default"
        print("🎧 Selected audio device: \(selectedDevice)")
        
        // Check if Speech Recognition is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            connectionStatus = "Speech recognition not available for selected language"
            print("❌ Speech recognizer not available for language: \(currentLanguage)")
            print("💡 Try changing language in settings or check if \(currentLanguage) is supported")
            return
        }
        
        print("✅ Speech recognizer available for: \(speechRecognizer.locale.identifier)")
        
        // Check authorization
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        guard authStatus == .authorized else {
            connectionStatus = "Speech recognition not authorized - enable in System Settings"
            print("❌ Speech recognition not authorized: \(authStatus)")
            return
        }
        
        // Reset previous session
        if audioEngine.isRunning {
            print("🎤 Stopping previous audio engine...")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        
        // ВАЖНО: НЕ меняем системный default device!
        // Вместо этого используем выбранный device только для AVAudioEngine
        if selectedDevice != "default" {
            // Просто логируем, но НЕ устанавливаем как системный default
            if let deviceName = findDeviceName(deviceId: selectedDevice) {
                print("🎧 Will try to use device: \(deviceName)")
            }
        } else {
            print("🎧 Using system default audio input device")
            logCurrentAudioDevice()
        }
        
        // Setup recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            connectionStatus = "Unable to create recognition request"
            print("❌ Failed to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Add context for better recognition
        if #available(macOS 13.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        // Setup audio input with larger buffer for better quality
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Ensure we have a valid format
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            connectionStatus = "Invalid audio format"
            print("❌ Invalid audio format: \(recordingFormat)")
            return
        }
        
        print("🎤 Audio format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")
        print("🎤 Buffer size: 4096 samples")
        
        // Increased buffer size for better audio capture (4096 instead of 1024)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    let newTranscript = result.bestTranscription.formattedString
                    
                    // Filter out phantom/hallucination text
                    if let strongSelf = self, !strongSelf.isPhantomTranscript(newTranscript) {
                        // Update buffer for smart processing
                        strongSelf.transcriptBuffer = newTranscript
                        
                        // ALSO update the published transcript immediately for live feedback
                        strongSelf.transcript = newTranscript
                        
                        print("🎤 Transcript updated: \(newTranscript.count) chars - \(newTranscript.prefix(50))...")
                    }
                }
                
                if let error = error {
                    print("❌ Speech recognition error: \(error)")
                    if !error.localizedDescription.contains("cancelled") {
                        self?.connectionStatus = "Recognition error: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            connectionStatus = "Recording (Speech Framework)..."
            print("✅ Speech Framework recording started successfully")
            print("🎧 Recording from: \(getActiveAudioDeviceName())")
        } catch {
            let errorMsg = "Audio engine start failed: \(error.localizedDescription)"
            connectionStatus = errorMsg
            print("❌ Audio engine error: \(error)")
            print("❌ Error details: \(error)")
            
            // Try to provide more helpful error message
            if error.localizedDescription.contains("561015905") {
                connectionStatus = "Audio device error - check Settings"
                print("💡 This usually means the selected audio device is not available")
            }
            
            // Show alert to user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Recording Failed"
                alert.informativeText = errorMsg
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    // MARK: - Audio Device Management (Helper functions only, no system changes)
    private func findDeviceName(deviceId: String) -> String? {
        // Get all audio devices
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else { return nil }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var audioDevices = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &audioDevices
        )
        
        guard status == noErr else { return nil }
        
        // Find the device by UID
        for deviceID in audioDevices {
            if let deviceUID = getDeviceUID(deviceID: deviceID),
               deviceUID == deviceId,
               let deviceName = getDeviceName(deviceID: deviceID) {
                return deviceName
            }
        }
        
        return nil
    }
    
    private func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        var deviceName: Unmanaged<CFString>?
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceName
        )
        
        if status == noErr, let name = deviceName?.takeUnretainedValue() as String? {
            return name
        }
        
        return nil
    }
    
    private func getDeviceUID(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        var deviceUID: Unmanaged<CFString>?
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceUID
        )
        
        if status == noErr, let uid = deviceUID?.takeUnretainedValue() as String? {
            return uid
        }
        
        return nil
    }
    
    private func logCurrentAudioDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        
        if status == noErr, let deviceName = getDeviceName(deviceID: deviceID) {
            print("🎧 Current input device: \(deviceName) (ID: \(deviceID))")
        } else {
            print("⚠️ Could not get current input device")
        }
    }
    
    private func getActiveAudioDeviceName() -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        
        if status == noErr, let deviceName = getDeviceName(deviceID: deviceID) {
            return deviceName
        }
        
        return "Unknown"
    }
    
    // MARK: - Smart Processing System
    private func startSmartProcessing() {
        print("🧠 Starting smart processing timers...")
        
        // Transcription processing timer (every 5 seconds)
        transcriptionTimer = Timer.scheduledTimer(withTimeInterval: transcriptionInterval, repeats: true) { [weak self] _ in
            self?.processTranscriptionUpdate()
        }
        
        // Insights processing timer (every 30 seconds)
        insightsTimer = Timer.scheduledTimer(withTimeInterval: insightsInterval, repeats: true) { [weak self] _ in
            self?.processInsightsUpdate()
        }
    }
    
    private func processTranscriptionUpdate() {
        guard isRecording else { return }
        
        let currentTranscript = transcriptBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only process if we have new content
        guard !currentTranscript.isEmpty && currentTranscript != lastProcessedTranscript else {
            return
        }
        
        print("📝 Processing transcription update: \(currentTranscript.count) chars")
        
        // Update the published transcript
        DispatchQueue.main.async {
            self.transcript = currentTranscript
        }
        
        lastProcessedTranscript = currentTranscript
        lastTranscriptUpdate = Date()
    }
    
    private func processInsightsUpdate() {
        guard isRecording else { return }
        
        let currentTranscript = transcriptBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only generate insights if we have enough content
        guard currentTranscript.count >= minTranscriptLengthForInsights else {
            print("🧠 Skipping insights: transcript too short (\(currentTranscript.count) chars)")
            return
        }
        
        // Check if we have significant new content since last insights
        let newContentLength = currentTranscript.count - (insightsCache["lastProcessedLength"] as? Int ?? 0)
        guard newContentLength >= 50 else { // At least 50 new characters
            print("🧠 Skipping insights: not enough new content (\(newContentLength) chars)")
            return
        }
        
        print("🧠 Generating insights for \(currentTranscript.count) chars (\(newContentLength) new)")
        
        generateLiveInsights(for: currentTranscript)
    }
    
    private func generateLiveInsights(for transcript: String) {
        guard hasOpenAIKey() else {
            print("🧠 Skipping insights: no OpenAI key")
            return
        }
        
        // Always use gpt-5-nano for live insights (most cost-effective)
        let model = "gpt-5-nano"
        
        // Truncate transcript to control token usage - even more aggressive for nano
        let truncatedTranscript = String(transcript.suffix(maxTokensPerInsightRequest * 2)) // More aggressive truncation
        
        let prompt = """
        Meeting analysis (JSON only):
        {
          "topic": "main topic (3 words)",
          "points": ["key1", "key2"],
          "actions": ["action1", "action2"],
          "mood": "positive/neutral/negative",
          "keywords": ["keyword1", "keyword2", "keyword3"]
        }
        
        Text: \(truncatedTranscript)
        """
        
        sendOpenAIRequest(prompt: prompt, model: model, maxTokens: 150) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let insights):
                    self?.liveInsights = insights
                    self?.insightsCache["lastProcessedLength"] = transcript.count
                    self?.insightsCache["lastInsights"] = insights
                    print("✅ Generated live insights: \(insights.prefix(100))...")
                    
                case .failure(let error):
                    print("❌ Insights generation failed: \(error)")
                }
            }
        }
    }
    
    private func processFinalTranscript() {
        guard !transcript.isEmpty else {
            connectionStatus = "Ready"
            return
        }
        
        connectionStatus = "Generating final analysis..."
        
        // Generate comprehensive final insights
        generateFinalInsights(for: transcript)
    }
    
    private func generateFinalInsights(for transcript: String) {
        guard hasOpenAIKey() && !transcript.isEmpty else {
            connectionStatus = "Ready"
            return
        }
        
        // Choose model from user settings (default: gpt-5-nano)
        let selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5-nano"
        let model = selectedModel
        
        // Adjust tokens based on model
        let maxTokens: Int
        switch model {
        case "gpt-5-mini":
            maxTokens = transcript.count < 1000 ? 500 : 800
        default: // gpt-5-nano (default)
            maxTokens = transcript.count < 1000 ? 300 : 500
        }
        
        let prompt = """
        Analyze this meeting/conversation and provide structured insights in JSON format:

        {
          "summary": "1-2 paragraph comprehensive summary of the main discussion",
          "action_items": [
            {
              "task": "Specific action to take",
              "assignee": "Person responsible (if mentioned)",
              "deadline": "Timeframe (if mentioned)",
              "priority": "high/medium/low",
              "specific": "Is it specific? true/false",
              "measurable": "Is it measurable? true/false",
              "achievable": "Is it achievable? true/false",
              "relevant": "Is it relevant? true/false",
              "timebound": "Is it time-bound? true/false"
            }
          ],
          "key_insights": [
            "Important insight or observation from the conversation"
          ],
          "topics_discussed": ["topic1", "topic2", "topic3"],
          "decisions_made": ["decision1", "decision2"],
          "questions_raised": ["question1", "question2"],
          "sentiment": "overall mood: positive/neutral/negative/mixed",
          "keywords": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"],
          "company_mentioned": "Company name if mentioned, otherwise null",
          "meeting_type": "Type of meeting: standup/planning/review/sales/support/interview/other"
        }

        Transcript:
        \(transcript)
        """
        
        sendOpenAIRequest(prompt: prompt, model: model, maxTokens: maxTokens) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let analysis):
                    self?.liveInsights = analysis
                    self?.connectionStatus = "Ready"
                    print("✅ Generated final analysis with \(model)")
                    
                case .failure(let error):
                    self?.connectionStatus = "Ready"
                    print("❌ Final analysis failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - OpenAI API Helper
    private func sendOpenAIRequest(prompt: String, model: String = "gpt-4o-mini", maxTokens: Int, completion: @escaping (Result<String, Error>) -> Void) {
        guard let openaiKey = UserDefaults.standard.string(forKey: "openaiKey"),
              !openaiKey.isEmpty else {
            completion(.failure(NSError(domain: "AudioRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])))
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openaiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.3
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AudioRecorder", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let error = json["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    completion(.failure(NSError(domain: "OpenAI", code: 3, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(NSError(domain: "AudioRecorder", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    private func hasOpenAIKey() -> Bool {
        let key = UserDefaults.standard.string(forKey: "openaiKey") ?? ""
        return !key.isEmpty && key.hasPrefix("sk-")
    }
    
    private func isPhantomTranscript(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Empty or very short text
        if trimmed.isEmpty || trimmed.count < 3 {
            return true
        }
        
        // Common phantom phrases from Speech Framework
        let phantomPhrases = [
            "thank you",
            "thanks for watching",
            "subscribe",
            "subtitles",
            "спасибо за просмотр",
            "подписывайтесь",
            "субтитры"
        ]
        
        for phrase in phantomPhrases {
            if trimmed.contains(phrase) {
                return true
            }
        }
        
        // Repetitive single words
        let words = trimmed.components(separatedBy: .whitespaces)
        if words.count >= 3 && Set(words).count == 1 {
            return true
        }
        
        // Very repetitive content
        if words.count > 1 {
            let uniqueWords = Set(words)
            let repetitionRatio = Double(words.count) / Double(uniqueWords.count)
            if repetitionRatio > 3.0 {
                return true
            }
        }
        
        return false
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let commonWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should"])
        
        let keywords = words.filter { word in
            word.count > 3 && !commonWords.contains(word)
        }
        
        return Array(Set(keywords)).prefix(5).map { $0 }
    }
    
    private func generateTitle(from text: String) -> String {
        let sentences = text.components(separatedBy: ". ")
        if let firstSentence = sentences.first, firstSentence.count > 10 {
            let title = String(firstSentence.prefix(50))
            return title.hasSuffix("...") ? title : title + "..."
        }
        return "Meeting \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
    }
    
    // MARK: - Recording Management with DataManager
    private func saveRecordingToDataManager() {
        guard let dataManager = dataManager,
              let startTime = currentSessionStartTime,
              !transcript.isEmpty else {
            print("⚠️ No recording to save or DataManager not set")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let keywords = extractKeywords(from: transcript)
        let title = generateTitle(from: transcript)
        
        // Create recording
        var recording = Recording(
            title: title,
            transcript: transcript,
            summary: liveInsights,
            tasks: [],
            keywords: keywords,
            projectId: nil,
            language: getLanguageCode(),
            duration: duration
        )
        
        // Try to auto-assign to project based on keywords and transcript
        if let matchingProjectId = dataManager.findMatchingProject(for: keywords, transcript: transcript) {
            recording.projectId = matchingProjectId
            print("🎯 Auto-assigned to project: \(matchingProjectId)")
        }
        
        // Save to DataManager
        dataManager.addRecording(recording)
        print("✅ Recording saved: \(duration)s, \(transcript.count) chars, \(keywords.count) keywords")
    }
    
    func continueFromRecording(_ recording: Recording) {
        // Load previous recording to continue
        transcript = recording.transcript
        transcriptBuffer = recording.transcript
        liveInsights = recording.summary
        print("📝 Continuing from previous recording: \(recording.transcript.count) chars")
    }
    
    // MARK: - Recording Session History Management
    func getSavedRecordings() -> [RecordingSession] {
        guard let data = UserDefaults.standard.data(forKey: "recordingSessions"),
              let sessions = try? JSONDecoder().decode([RecordingSession].self, from: data) else {
            return []
        }
        return sessions.sorted { $0.startTime > $1.startTime }
    }
    
    func saveCurrentSession() {
        guard let sessionId = currentSessionId,
              let startTime = currentSessionStartTime,
              !transcript.isEmpty else {
            print("⚠️ No session to save")
            return
        }
        
        let session = RecordingSession(
            id: sessionId,
            startTime: startTime,
            endTime: Date(),
            transcript: transcript,
            insights: liveInsights,
            language: getLanguageCode()
        )
        
        var sessions = getSavedRecordings()
        sessions.insert(session, at: 0)
        
        // Keep only last 50 recordings
        if sessions.count > 50 {
            sessions = Array(sessions.prefix(50))
        }
        
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "recordingSessions")
            print("✅ Session saved: \(session.duration)s, \(transcript.count) chars")
        }
    }
    
    func continueFromSession(_ session: RecordingSession) {
        // Load previous transcript to continue
        transcript = session.transcript
        transcriptBuffer = session.transcript
        liveInsights = session.insights
        print("📝 Continuing from previous session: \(session.transcript.count) chars")
    }
    
    func deleteSession(_ sessionId: UUID) {
        var sessions = getSavedRecordings()
        sessions.removeAll { $0.id == sessionId }
        
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "recordingSessions")
            print("🗑️ Session deleted: \(sessionId)")
        }
    }
    
    func clearAllSessions() {
        UserDefaults.standard.removeObject(forKey: "recordingSessions")
        print("🗑️ All sessions cleared")
    }
}
