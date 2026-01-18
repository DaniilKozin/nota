import Foundation
import AVFoundation
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

class AudioRecorder: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var liveInsights = ""
    @Published var connectionStatus = "Ready"
    @Published var availableDevices: [AudioDevice] = []
    
    private var selectedDeviceId: String = "default"
    private var selectedLanguage: String = "auto"
    private var transcriptionProvider: String = "auto"
    
    // Audio recording with AVAudioEngine (supports device selection)
    private var audioEngine: AVAudioEngine?
    private var audioRecorder: AVAudioRecorder? // Fallback
    private var recordingURL: URL?
    private var audioFile: AVAudioFile?
    
    // Smart transcription and insights management
    private var lastTranscriptUpdate = Date()
    private var lastInsightsUpdate = Date()
    private var transcriptBuffer = ""
    private var lastProcessedTranscript = ""
    private var insightsCache: [String: Any] = [:]
    private var transcriptionTimer: Timer?
    private var insightsTimer: Timer?
    
    // Configuration for smart processing - optimized for GPT-5 nano
    private let transcriptionInterval: TimeInterval = 6.0 // 6 seconds
    private let insightsInterval: TimeInterval = 30.0 // 30 seconds (faster updates)
    private let minTranscriptLengthForInsights = 50 // characters (lower threshold for faster insights)
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
        loadSettings()
        // Discover audio devices on init
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.discoverAudioDevices()
        }
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
        // Add safety check to prevent crashes during recording
        guard !isRecording else {
            print("⚠️ Skipping settings update during recording")
            return
        }
        
        selectedDeviceId = UserDefaults.standard.string(forKey: "inputDeviceId") ?? "default"
        selectedLanguage = UserDefaults.standard.string(forKey: "outputLanguage") ?? "auto"
        transcriptionProvider = UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "auto"
        
        print("🔧 Settings updated: device=\(selectedDeviceId), language=\(selectedLanguage), provider=\(transcriptionProvider)")
    }
    
    // MARK: - Audio Device Discovery
    func discoverAudioDevices() {
        // Add safety check to prevent crashes during recording
        guard !isRecording else {
            print("⚠️ Skipping device discovery during recording")
            return
        }
        
        var devices: [AudioDevice] = []
        
        // Add default device
        devices.append(AudioDevice(id: "default", name: "Default Input", isInput: true))
        
        // Wrap CoreAudio operations in do-catch for safety
        do {
            try discoverCoreAudioDevices(&devices)
        } catch {
            print("⚠️ Error discovering audio devices: \(error)")
            // Continue with just default device
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.availableDevices = devices
            print("🎧 Total input devices found: \(devices.count)")
        }
    }
    
    private func discoverCoreAudioDevices(_ devices: inout [AudioDevice]) throws {
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
            return
        }
        
        guard dataSize > 0 else {
            print("⚠️ No audio devices found")
            return
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        guard deviceCount > 0 else {
            print("⚠️ Invalid device count: \(deviceCount)")
            return
        }
        
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
            return
        }
        
        for deviceID in audioDevices {
            // Add safety checks for each device
            do {
                if try safeHasInputChannels(deviceID: deviceID),
                   let deviceName = getDeviceName(deviceID: deviceID),
                   let deviceUID = getDeviceUID(deviceID: deviceID) {
                    devices.append(AudioDevice(
                        id: deviceUID,
                        name: deviceName,
                        isInput: true
                    ))
                    print("🎧 Found input device: \(deviceName) (UID: \(deviceUID))")
                }
            } catch {
                print("⚠️ Error checking device \(deviceID): \(error)")
                continue
            }
        }
    }
    
    private func safeHasInputChannels(deviceID: AudioDeviceID) throws -> Bool {
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
        
        // Safer memory allocation with proper error handling
        guard dataSize >= MemoryLayout<AudioBufferList>.size else {
            print("⚠️ Invalid data size for device \(deviceID): \(dataSize)")
            return false
        }
        
        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { 
            bufferListPointer.deallocate() 
        }
        
        // Initialize the allocated memory to prevent crashes
        bufferListPointer.initialize(to: AudioBufferList(
            mNumberBuffers: 0,
            mBuffers: AudioBuffer(
                mNumberChannels: 0,
                mDataByteSize: 0,
                mData: nil
            )
        ))
        defer {
            bufferListPointer.deinitialize(count: 1)
        }
        
        let getStatus = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            bufferListPointer
        )
        
        guard getStatus == noErr else {
            print("⚠️ Failed to get stream configuration for device \(deviceID): \(getStatus)")
            return false
        }
        
        let bufferList = bufferListPointer.pointee
        let hasChannels = bufferList.mNumberBuffers > 0 && bufferList.mBuffers.mNumberChannels > 0
        
        return hasChannels
    }
    

    
    // MARK: - Language Support
    private func getLanguageCode() -> String {
        let outputLanguage = UserDefaults.standard.string(forKey: "outputLanguage") ?? "auto"
        
        print("🌍 Output language setting: \(outputLanguage)")
        
        switch outputLanguage {
        case "auto":
            // Auto-detect based on system language
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            print("🌍 System language detected: \(systemLanguage)")
            
            switch systemLanguage {
            case "ru": 
                print("🇷🇺 Using Russian (ru-RU)")
                return "ru-RU"
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
            default: 
                print("🇺🇸 Using English (en-US) as default")
                return "en-US"
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
        print("🔴 DEBUG: startRecording() вызвана")
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
        
        // Only request microphone permission (no Speech Recognition needed!)
        requestMicrophonePermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Microphone permission granted, starting audio recording")
                    self?.startStreamingTranscription()
                    self?.startSmartProcessing()
                } else {
                    print("❌ Microphone permission denied")
                    self?.connectionStatus = "Microphone access denied - enable in System Settings"
                }
            }
        }
    }
    
    // MARK: - Streaming Transcription (AssemblyAI + Whisper)
    private var assemblyaiWebSocket: URLSessionWebSocketTask?
    private var assemblyaiSession: URLSession?
    private var assemblyaiAudioPosition: Int = 0
    
    private func startStreamingTranscription() {
        let provider = UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "auto"
        let language = getLanguageCode()
        
        print("🎙️ Transcription provider: \(provider), language: \(language)")
        
        // AssemblyAI Streaming only supports: English, Spanish, French, German, Italian, Portuguese
        let assemblyAISupportedLanguages = ["en", "es", "fr", "de", "it", "pt"]
        let languagePrefix = String(language.prefix(2))
        let isAssemblyAISupported = assemblyAISupportedLanguages.contains(languagePrefix)
        
        // Smart provider selection
        let selectedProvider: String
        if provider == "auto" {
            // Auto mode: Use AssemblyAI for supported languages, Whisper for others
            if isAssemblyAISupported {
                selectedProvider = "assemblyai"
                print("✅ Language \(language) supported by AssemblyAI streaming")
            } else {
                selectedProvider = "whisper"
                print("⚠️ Language \(language) NOT supported by AssemblyAI streaming, using Whisper")
            }
        } else {
            selectedProvider = provider
        }
        
        print("🎯 Selected provider: \(selectedProvider)")
        
        // Start with selected provider
        switch selectedProvider {
        case "assemblyai":
            if let key = UserDefaults.standard.string(forKey: "assemblyaiKey"), !key.isEmpty {
                if isAssemblyAISupported {
                    startAssemblyAIStreaming()
                } else {
                    print("⚠️ AssemblyAI doesn't support \(language), using Whisper")
                    startWhisperChunkedTranscription()
                }
            } else {
                print("⚠️ No AssemblyAI key, using Whisper")
                startWhisperChunkedTranscription()
            }
            
        case "whisper":
            startWhisperChunkedTranscription()
            
        default:
            // Fallback chain: AssemblyAI (if supported) -> Whisper
            if let key = UserDefaults.standard.string(forKey: "assemblyaiKey"), !key.isEmpty, isAssemblyAISupported {
                startAssemblyAIStreaming()
            } else {
                startWhisperChunkedTranscription()
            }
        }
    }
    
    // MARK: - AssemblyAI Streaming
    private func startAssemblyAIStreaming() {
        guard let assemblyaiKey = UserDefaults.standard.string(forKey: "assemblyaiKey"),
              !assemblyaiKey.isEmpty else {
            print("⚠️ No AssemblyAI key, falling back to Whisper")
            startWhisperChunkedTranscription()
            return
        }
        
        print("🎙️ Starting AssemblyAI v3 WebSocket streaming...")
        
        // AssemblyAI v3 WebSocket URL with connection parameters
        // According to docs: wss://streaming.assemblyai.com/v3/ws?sample_rate=16000&...
        var urlComponents = URLComponents(string: "wss://streaming.assemblyai.com/v3/ws")!
        urlComponents.queryItems = [
            URLQueryItem(name: "sample_rate", value: "16000")
        ]
        
        guard let url = urlComponents.url else {
            print("❌ Invalid AssemblyAI URL")
            startWhisperChunkedTranscription()
            return
        }
        
        print("🌍 Using universal-streaming-multilingual model (default)")
        print("📡 WebSocket URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue(assemblyaiKey, forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        assemblyaiSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        assemblyaiWebSocket = assemblyaiSession?.webSocketTask(with: request)
        
        // Start receiving messages
        receiveAssemblyAIMessage()
        
        // Connect
        assemblyaiWebSocket?.resume()
        print("✅ AssemblyAI WebSocket connecting...")
        
        // Start audio recording and streaming
        startAudioStreamingToAssemblyAI()
    }
    
    private func startAudioStreamingToAssemblyAI() {
        print("🎤 Starting audio streaming to AssemblyAI...")
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        recordingURL = audioFilename
        
        // AssemblyAI requires PCM16 audio at 16kHz
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            connectionStatus = "Recording (AssemblyAI)..."
            assemblyaiAudioPosition = 0
            print("✅ Audio recording started to file: \(audioFilename.lastPathComponent)")
            
            // Monitor audio levels
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                
                self.audioRecorder?.updateMeters()
                let avgPower = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                print("🎙️ Audio level: \(String(format: "%.1f", avgPower))dB")
                
                // Check file size
                if let url = self.recordingURL,
                   let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let fileSize = attributes[.size] as? UInt64 {
                    print("📁 File size: \(fileSize) bytes")
                }
            }
            
            // Stream audio chunks every 100ms
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                self.sendAudioChunkToAssemblyAI()
            }
        } catch {
            connectionStatus = "Failed to start recording: \(error.localizedDescription)"
            print("❌ Recording error: \(error)")
            startWhisperChunkedTranscription()
        }
    }
    
    private func sendAudioChunkToAssemblyAI() {
        guard let audioURL = recordingURL else {
            return
        }
        
        do {
            // Read entire audio file
            let audioData = try Data(contentsOf: audioURL)
            
            // Only send new data since last position
            guard audioData.count > assemblyaiAudioPosition else {
                return
            }
            
            let newData = audioData.subdata(in: assemblyaiAudioPosition..<audioData.count)
            assemblyaiAudioPosition = audioData.count
            
            // Send RAW PCM audio data (not base64, not JSON!)
            // AssemblyAI v3 expects binary PCM16 data directly
            let message = URLSessionWebSocketTask.Message.data(newData)
            assemblyaiWebSocket?.send(message) { error in
                if let error = error {
                    print("❌ Failed to send audio to AssemblyAI: \(error)")
                } else {
                    // Success - audio chunk sent
                    if newData.count > 0 {
                        print("📤 Sent \(newData.count) bytes to AssemblyAI")
                    }
                }
            }
        } catch {
            print("❌ Error reading audio file: \(error)")
        }
    }
    
    private func receiveAssemblyAIMessage() {
        assemblyaiWebSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleAssemblyAIResponse(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleAssemblyAIResponse(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveAssemblyAIMessage()
                
            case .failure(let error):
                print("❌ AssemblyAI WebSocket error: \(error)")
                DispatchQueue.main.async {
                    self?.startWhisperChunkedTranscription()
                }
            }
        }
    }
    
    private func handleAssemblyAIResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Check message type (as per official docs)
        guard let messageType = json["type"] as? String else {
            return
        }
        
        switch messageType {
        case "Begin":
            // Session started
            if let sessionId = json["id"] as? String {
                print("✅ AssemblyAI session started: \(sessionId)")
                DispatchQueue.main.async {
                    self.connectionStatus = "Recording (AssemblyAI - Multilingual)..."
                }
            }
            
        case "Turn":
            // Turn object with transcript
            if let transcript = json["transcript"] as? String, !transcript.isEmpty {
                let endOfTurn = json["end_of_turn"] as? Bool ?? false
                let turnIsFormatted = json["turn_is_formatted"] as? Bool ?? false
                
                // Language detection info
                let languageCode = json["language_code"] as? String
                let languageConfidence = json["language_confidence"] as? Double
                
                if let lang = languageCode, let conf = languageConfidence {
                    print("🌍 Detected language: \(lang) (confidence: \(String(format: "%.0f%%", conf * 100)))")
                }
                
                DispatchQueue.main.async {
                    if endOfTurn && turnIsFormatted {
                        // Final formatted transcript
                        self.transcriptBuffer += (self.transcriptBuffer.isEmpty ? "" : " ") + transcript
                        self.transcript = self.transcriptBuffer
                        print("✅ AssemblyAI final (formatted): \(transcript)")
                    } else if endOfTurn {
                        // Final unformatted transcript
                        self.transcriptBuffer += (self.transcriptBuffer.isEmpty ? "" : " ") + transcript
                        self.transcript = self.transcriptBuffer
                        print("✅ AssemblyAI final: \(transcript)")
                    } else {
                        // Interim result - show but don't add to buffer yet
                        let currentBuffer = self.transcriptBuffer
                        let preview = currentBuffer + (currentBuffer.isEmpty ? "" : " ") + transcript
                        self.transcript = preview
                        print("📝 AssemblyAI interim: \(transcript.prefix(50))...")
                    }
                }
            }
            
        case "Termination":
            // Session ended
            if let audioDuration = json["audio_duration_seconds"] as? Double {
                print("✅ AssemblyAI session terminated: \(audioDuration)s processed")
            }
            
        case "Error":
            // Error occurred
            if let errorMessage = json["error"] as? String {
                print("❌ AssemblyAI error: \(errorMessage)")
                DispatchQueue.main.async {
                    self.startWhisperChunkedTranscription()
                }
            }
            
        default:
            print("⚠️ Unknown AssemblyAI message type: \(messageType)")
        }
    }
    
    // MARK: - Whisper Fallback
    private func startWhisperChunkedTranscription() {
        print("🎤 Starting Whisper chunked transcription...")
        
        // Setup audio recording to file
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            connectionStatus = "Recording..."
            print("✅ Audio recording started")
            
            // Start periodic Whisper transcription (every 5 seconds)
            startPeriodicWhisperTranscription()
        } catch {
            connectionStatus = "Failed to start recording: \(error.localizedDescription)"
            print("❌ Recording error: \(error)")
        }
    }
    
    private func startPeriodicWhisperTranscription() {
        // Invalidate existing timer if any
        transcriptionTimer?.invalidate()
        
        // Send audio to Whisper API every 5 seconds for transcription
        transcriptionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            
            print("⏰ Timer fired - sending audio to Whisper...")
            
            // Pause recording temporarily
            self.audioRecorder?.pause()
            
            // Send current audio to Whisper
            if let audioURL = self.recordingURL {
                self.transcribeWithWhisper(audioURL: audioURL)
            } else {
                print("⚠️ No recording URL available")
            }
            
            // Resume recording
            self.audioRecorder?.record()
        }
        
        print("✅ Whisper timer started (5 second interval)")
    }
    
    private func transcribeWithWhisper(audioURL: URL) {
        guard let openaiKey = UserDefaults.standard.string(forKey: "openaiKey"),
              !openaiKey.isEmpty else {
            print("⚠️ No OpenAI key configured")
            return
        }
        
        print("📤 Sending audio to Whisper API...")
        
        let url = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openaiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add prompt parameter to maintain context between chunks
        // This helps Whisper understand the conversation flow and maintain consistency
        if !transcriptBuffer.isEmpty {
            // Use last 200 characters as context for next chunk
            let contextPrompt = String(transcriptBuffer.suffix(200))
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(contextPrompt)\r\n".data(using: .utf8)!)
            print("🔗 Using context prompt: \(contextPrompt.prefix(50))...")
        }
        
        // DON'T add language parameter for mixed-language support
        // Whisper will auto-detect the language per chunk
        // This allows mixed English + Russian in same meeting
        
        // Add audio file
        if let audioData = try? Data(contentsOf: audioURL) {
            print("📊 Audio file size: \(audioData.count) bytes")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        } else {
            print("❌ Failed to read audio file at \(audioURL)")
            return
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Whisper API error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Whisper API response status: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ No data received from Whisper")
                return
            }
            
            // Log raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Whisper raw response: \(responseString.prefix(200))")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Check for errors
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("❌ Whisper API error: \(message)")
                        return
                    }
                    
                    if let text = json["text"] as? String {
                        // Detect language from response if available
                        if let detectedLanguage = json["language"] as? String {
                            print("🌍 Whisper detected language: \(detectedLanguage)")
                        }
                        
                        DispatchQueue.main.async {
                            // Append to buffer instead of replacing (for chunked transcription)
                            if !self!.transcriptBuffer.isEmpty {
                                self?.transcriptBuffer += " " + text
                            } else {
                                self?.transcriptBuffer = text
                            }
                            self?.transcript = self!.transcriptBuffer
                            print("✅ Whisper transcription (\(text.count) chars): \(text.prefix(100))...")
                            print("📝 Total buffer size: \(self!.transcriptBuffer.count) chars")
                        }
                    } else {
                        print("⚠️ No 'text' field in Whisper response")
                    }
                }
            } catch {
                print("❌ Failed to parse Whisper response: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Raw response: \(responseString)")
                }
            }
        }.resume()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        print("⏹️ Stopping recording...")
        
        // Stop timers
        transcriptionTimer?.invalidate()
        insightsTimer?.invalidate()
        
        // Send termination message to AssemblyAI before closing
        if let webSocket = assemblyaiWebSocket {
            let terminateMessage = "{\"type\": \"Terminate\"}"
            webSocket.send(.string(terminateMessage)) { error in
                if let error = error {
                    print("⚠️ Failed to send termination to AssemblyAI: \(error)")
                }
            }
            // Give it a moment to send, then close
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                webSocket.cancel(with: .goingAway, reason: nil)
            }
            assemblyaiWebSocket = nil
        }
        
        // Stop audio engine
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
            audioEngine = nil
            print("✅ Audio engine stopped")
        }
        
        // Stop audio recorder (fallback)
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Close audio file
        audioFile = nil
        
        isRecording = false
        
        print("⏹️ Recording stopped")
        
        // Save current session to history
        saveCurrentSession()
        
        // Save recording to DataManager
        saveRecordingToDataManager()
        
        // Process final transcript and insights
        processFinalTranscript()
        
        // Clean up audio file
        if let audioURL = recordingURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
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
    
    private func findAudioDeviceID(byUID uid: String) -> AudioDeviceID? {
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
        
        for deviceID in audioDevices {
            if let deviceUID = getDeviceUID(deviceID: deviceID), deviceUID == uid {
                return deviceID
            }
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
        
        // Get system language for translation
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        let systemLanguageName = Locale.current.localizedString(forLanguageCode: systemLanguage) ?? "English"
        
        // Truncate transcript to control token usage - even more aggressive for nano
        let truncatedTranscript = String(transcript.suffix(maxTokensPerInsightRequest * 2)) // More aggressive truncation
        
        let prompt = """
        Meeting analysis (JSON only, respond in \(systemLanguageName)):
        {
          "topic": "main topic (3 words in \(systemLanguageName))",
          "points": ["key1", "key2"],
          "actions": ["action1", "action2"],
          "mood": "positive/neutral/negative",
          "keywords": ["keyword1", "keyword2", "keyword3"]
        }
        
        Note: Text may contain multiple languages. Analyze and respond in \(systemLanguageName).
        
        Text: \(truncatedTranscript)
        """
        
        sendOpenAIRequest(prompt: prompt, model: model, maxTokens: 150) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let insights):
                    self?.liveInsights = insights
                    self?.insightsCache["lastProcessedLength"] = transcript.count
                    self?.insightsCache["lastInsights"] = insights
                    print("✅ Generated multilingual live insights: \(insights.prefix(100))...")
                    
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
        
        // Generate comprehensive final insights with smart speaker identification
        generateFinalInsightsWithSpeakers(for: transcript)
    }
    
    private func generateFinalInsights(for transcript: String) {
        guard hasOpenAIKey() && !transcript.isEmpty else {
            connectionStatus = "Ready"
            return
        }
        
        // Choose model from user settings (default: gpt-5-nano)
        let selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5-nano"
        let model = selectedModel
        
        // Get system language for translation
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        let systemLanguageName = Locale.current.localizedString(forLanguageCode: systemLanguage) ?? "English"
        
        // Adjust tokens based on model
        let maxTokens: Int
        switch model {
        case "gpt-5-mini":
            maxTokens = transcript.count < 1000 ? 500 : 800
        default: // gpt-5-nano (default)
            maxTokens = transcript.count < 1000 ? 300 : 500
        }
        
        let prompt = """
        Analyze this meeting/conversation and provide structured insights in JSON format.
        
        IMPORTANT: The transcript may contain multiple languages (e.g., English + Russian + Korean).
        - Analyze the content in whatever languages are present
        - Provide ALL responses in \(systemLanguageName) (\(systemLanguage))
        - Translate any non-\(systemLanguageName) content to \(systemLanguageName) in your analysis
        - Preserve the original meaning and context when translating

        {
          "summary": "1-2 paragraph comprehensive summary of the main discussion (in \(systemLanguageName))",
          "action_items": [
            {
              "task": "Specific action to take (in \(systemLanguageName))",
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
            "Important insight or observation from the conversation (in \(systemLanguageName))"
          ],
          "topics_discussed": ["topic1", "topic2", "topic3"],
          "decisions_made": ["decision1", "decision2"],
          "questions_raised": ["question1", "question2"],
          "sentiment": "overall mood: positive/neutral/negative/mixed",
          "keywords": ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"],
          "languages_detected": ["list of languages spoken in the meeting"],
          "company_mentioned": "Company name if mentioned, otherwise null",
          "meeting_type": "Type of meeting: standup/planning/review/sales/support/interview/other"
        }

        Transcript (may contain multiple languages):
        \(transcript)
        """
        
        sendOpenAIRequest(prompt: prompt, model: model, maxTokens: maxTokens) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let analysis):
                    self?.liveInsights = analysis
                    self?.connectionStatus = "Ready"
                    print("✅ Generated multilingual analysis with \(model)")
                    
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
    
    // MARK: - Smart Speaker Identification (Context-based, FREE!)
    private func generateFinalInsightsWithSpeakers(for transcript: String) {
        guard hasOpenAIKey() && !transcript.isEmpty else {
            connectionStatus = "Ready"
            return
        }
        
        // Choose model from user settings (default: gpt-5-nano)
        let selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "gpt-5-nano"
        let model = selectedModel
        
        // Get system language for translation
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        let systemLanguageName = Locale.current.localizedString(forLanguageCode: systemLanguage) ?? "English"
        
        // Adjust tokens based on model
        let maxTokens: Int
        switch model {
        case "gpt-5-mini":
            maxTokens = 1200
        default: // gpt-5-nano (default)
            maxTokens = 800
        }
        
        let prompt = """
        Analyze this meeting/conversation and provide structured insights in JSON format.
        
        IMPORTANT INSTRUCTIONS:
        1. The transcript may contain multiple languages (e.g., English + Russian + Korean)
        2. Analyze the content in whatever languages are present
        3. Provide ALL responses in \(systemLanguageName) (\(systemLanguage))
        4. Translate any non-\(systemLanguageName) content to \(systemLanguageName) in your analysis
        
        SMART SPEAKER IDENTIFICATION:
        - Try to identify speakers from context (names mentioned, roles, topics)
        - If someone says "I'm John" or "This is Maria speaking" - use their name
        - If you can infer roles (Manager, Developer, Client) - use those
        - If no context available, use Speaker A, Speaker B, etc.
        - Format: "**Name/Role**: text" or "**Speaker A**: text"
        
        EXAMPLE:
        If transcript contains "Hi, I'm Alex from engineering" → use "**Alex (Engineering)**:"
        If transcript contains "As the project manager, I think..." → use "**Project Manager**:"
        If no context → use "**Speaker A**:", "**Speaker B**:"
        
        {
          "summary": "1-2 paragraph comprehensive summary (in \(systemLanguageName))",
          "speakers": [
            {
              "id": "speaker_1",
              "name": "Alex (Engineering)" or "Speaker A" if unknown,
              "role": "Engineer" or "Unknown",
              "key_points": ["point1", "point2"]
            }
          ],
          "conversation": [
            {
              "speaker": "Alex (Engineering)" or "Speaker A",
              "text": "What they said (in \(systemLanguageName))"
            }
          ],
          "action_items": [
            {
              "task": "Specific action (in \(systemLanguageName))",
              "assignee": "Person responsible (if mentioned)",
              "deadline": "Timeframe (if mentioned)",
              "priority": "high/medium/low"
            }
          ],
          "key_insights": ["Important insight (in \(systemLanguageName))"],
          "topics_discussed": ["topic1", "topic2"],
          "decisions_made": ["decision1", "decision2"],
          "questions_raised": ["question1", "question2"],
          "sentiment": "overall mood: positive/neutral/negative/mixed",
          "keywords": ["keyword1", "keyword2", "keyword3"]
        }
        
        Transcript:
        \(transcript)
        """
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(UserDefaults.standard.string(forKey: "openaiKey") ?? "")", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are an expert meeting analyst. Analyze conversations and identify speakers from context."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Final insights error: \(error)")
                DispatchQueue.main.async {
                    self?.connectionStatus = "Ready"
                }
                return
            }
            
            guard let data = data else {
                print("❌ No data from final insights")
                DispatchQueue.main.async {
                    self?.connectionStatus = "Ready"
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String,
                   let insightsData = content.data(using: .utf8),
                   let insights = try? JSONSerialization.jsonObject(with: insightsData) as? [String: Any] {
                    
                    // Format insights with speaker-aware conversation
                    var formattedInsights = ""
                    
                    // Add summary
                    if let summary = insights["summary"] as? String {
                        formattedInsights += "📋 Summary:\n\(summary)\n\n"
                    }
                    
                    // Add speaker-aware conversation
                    if let conversation = insights["conversation"] as? [[String: Any]], !conversation.isEmpty {
                        formattedInsights += "💬 Conversation:\n"
                        for turn in conversation {
                            if let speaker = turn["speaker"] as? String,
                               let text = turn["text"] as? String {
                                formattedInsights += "**\(speaker)**: \(text)\n"
                            }
                        }
                        formattedInsights += "\n"
                    }
                    
                    // Add action items
                    if let actionItems = insights["action_items"] as? [[String: Any]], !actionItems.isEmpty {
                        formattedInsights += "✅ Action Items:\n"
                        for (index, item) in actionItems.enumerated() {
                            if let task = item["task"] as? String {
                                let assignee = item["assignee"] as? String ?? "Unassigned"
                                let priority = item["priority"] as? String ?? "medium"
                                formattedInsights += "\(index + 1). [\(priority.uppercased())] \(task) - \(assignee)\n"
                            }
                        }
                        formattedInsights += "\n"
                    }
                    
                    // Add key insights
                    if let keyInsights = insights["key_insights"] as? [String], !keyInsights.isEmpty {
                        formattedInsights += "💡 Key Insights:\n"
                        for insight in keyInsights {
                            formattedInsights += "• \(insight)\n"
                        }
                        formattedInsights += "\n"
                    }
                    
                    // Add topics
                    if let topics = insights["topics_discussed"] as? [String], !topics.isEmpty {
                        formattedInsights += "📌 Topics: \(topics.joined(separator: ", "))\n"
                    }
                    
                    // Add decisions
                    if let decisions = insights["decisions_made"] as? [String], !decisions.isEmpty {
                        formattedInsights += "🎯 Decisions: \(decisions.joined(separator: ", "))\n"
                    }
                    
                    // Update UI
                    DispatchQueue.main.async {
                        self?.liveInsights = formattedInsights
                        self?.connectionStatus = "Ready"
                        print("✅ Final insights with smart speaker identification generated")
                    }
                }
            } catch {
                print("❌ Failed to parse final insights: \(error)")
                DispatchQueue.main.async {
                    self?.connectionStatus = "Ready"
                }
            }
        }.resume()
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
