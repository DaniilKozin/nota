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
    
    // Audio recording for Whisper
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
        loadSettings()
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
    
    // MARK: - Streaming Transcription (Smart provider selection)
    private var deepgramWebSocket: URLSessionWebSocketTask?
    private var assemblyaiWebSocket: URLSessionWebSocketTask?
    private var deepgramSession: URLSession?
    private var assemblyaiSession: URLSession?
    private var assemblyaiAudioPosition: Int = 0
    private var deepgramAudioPosition: Int = 0
    private var deepgramKeepAliveTimer: Timer?
    
    private func startStreamingTranscription() {
        let provider = UserDefaults.standard.string(forKey: "transcriptionProvider") ?? "auto"
        let language = getLanguageCode()
        
        print("🎙️ Transcription provider: \(provider), language: \(language)")
        
        // Smart provider selection
        let selectedProvider: String
        if provider == "auto" {
            // Auto mode: Use Deepgram for better multilingual support
            // AssemblyAI multilingual has issues with real-time language switching
            selectedProvider = "deepgram"
        } else {
            selectedProvider = provider
        }
        
        print("🎯 Selected provider: \(selectedProvider)")
        
        // Start with selected provider
        switch selectedProvider {
        case "assemblyai":
            if let key = UserDefaults.standard.string(forKey: "assemblyaiKey"), !key.isEmpty {
                startAssemblyAIStreaming()
            } else {
                print("⚠️ No AssemblyAI key, trying Deepgram")
                startDeepgramStreaming()
            }
            
        case "deepgram":
            if let key = UserDefaults.standard.string(forKey: "deepgramKey"), !key.isEmpty {
                startDeepgramStreaming()
            } else {
                print("⚠️ No Deepgram key, trying AssemblyAI")
                startAssemblyAIStreaming()
            }
            
        case "whisper":
            startWhisperChunkedTranscription()
            
        default:
            // Fallback chain: Deepgram -> AssemblyAI -> Whisper
            if let key = UserDefaults.standard.string(forKey: "deepgramKey"), !key.isEmpty {
                startDeepgramStreaming()
            } else if let key = UserDefaults.standard.string(forKey: "assemblyaiKey"), !key.isEmpty {
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
            print("⚠️ No AssemblyAI key, falling back to Deepgram")
            startDeepgramStreaming()
            return
        }
        
        print("🎙️ Starting AssemblyAI WebSocket streaming...")
        
        // AssemblyAI v3 WebSocket URL with parameters
        // Always use multilingual model with language detection for mixed-language meetings
        var urlComponents = URLComponents(string: "wss://streaming.assemblyai.com/v3/ws")!
        urlComponents.queryItems = [
            URLQueryItem(name: "sample_rate", value: "16000"),
            URLQueryItem(name: "speech_model", value: "universal-streaming-multilingual"),
            URLQueryItem(name: "language_detection", value: "true"),
            URLQueryItem(name: "format_turns", value: "true")
        ]
        
        guard let url = urlComponents.url else {
            print("❌ Invalid AssemblyAI URL")
            startDeepgramStreaming()
            return
        }
        
        print("🌍 Using multilingual model with auto language detection")
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
            audioRecorder?.record()
            isRecording = true
            connectionStatus = "Recording (AssemblyAI)..."
            assemblyaiAudioPosition = 0
            print("✅ Audio recording started, streaming to AssemblyAI")
            
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
            startDeepgramStreaming()
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
            
            // Send as base64 in JSON format as per AssemblyAI docs
            let base64Audio = newData.base64EncodedString()
            let json: [String: Any] = ["audio_data": base64Audio]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: json),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                assemblyaiWebSocket?.send(message) { error in
                    if let error = error {
                        print("❌ Failed to send audio to AssemblyAI: \(error)")
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
                    self?.startDeepgramStreaming()
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
                    self.startDeepgramStreaming()
                }
            }
            
        default:
            print("⚠️ Unknown AssemblyAI message type: \(messageType)")
        }
    }
    
    private func startDeepgramStreaming() {
        guard let deepgramKey = UserDefaults.standard.string(forKey: "deepgramKey"),
              !deepgramKey.isEmpty else {
            print("⚠️ No Deepgram key, falling back to AssemblyAI")
            startAssemblyAIStreaming()
            return
        }
        
        print("🎙️ Starting Deepgram WebSocket streaming...")
        
        // Deepgram WebSocket URL with parameters
        // Use "multi" for automatic language detection
        var urlComponents = URLComponents(string: "wss://api.deepgram.com/v1/listen")!
        urlComponents.queryItems = [
            URLQueryItem(name: "encoding", value: "linear16"),
            URLQueryItem(name: "sample_rate", value: "16000"),
            URLQueryItem(name: "channels", value: "1"),
            URLQueryItem(name: "model", value: "nova-2"),
            URLQueryItem(name: "language", value: "multi"), // Automatic language detection
            URLQueryItem(name: "detect_language", value: "true"),
            URLQueryItem(name: "punctuate", value: "true"),
            URLQueryItem(name: "interim_results", value: "true"),
            URLQueryItem(name: "endpointing", value: "300") // 300ms silence detection
        ]
        
        guard let url = urlComponents.url else {
            print("❌ Invalid Deepgram URL")
            startAssemblyAIStreaming()
            return
        }
        
        print("🌍 Using Deepgram with automatic language detection")
        print("📡 WebSocket URL: \(url.absoluteString)")
        
        // Create WebSocket session
        var request = URLRequest(url: url)
        request.setValue("Token \(deepgramKey)", forHTTPHeaderField: "Authorization")
        
        let config = URLSessionConfiguration.default
        deepgramSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
        deepgramWebSocket = deepgramSession?.webSocketTask(with: request)
        
        // Start receiving messages
        receiveDeepgramMessage()
        
        // Connect
        deepgramWebSocket?.resume()
        
        // Start audio recording and streaming
        startAudioStreamingToDeepgram()
    }
    
    private func startAudioStreamingToDeepgram() {
        print("🎤 Starting audio streaming to Deepgram...")
        
        // Setup audio recording
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).wav")
        recordingURL = audioFilename
        
        // Deepgram requires PCM16 audio
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
            audioRecorder?.record()
            isRecording = true
            connectionStatus = "Recording (Deepgram)..."
            deepgramAudioPosition = 0
            print("✅ Audio recording started, streaming to Deepgram")
            
            // Stream audio chunks to Deepgram every 100ms
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                
                self.sendAudioChunkToDeepgram()
            }
            
            // Send KeepAlive messages every 5 seconds to maintain connection during silence
            deepgramKeepAliveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                
                // Send KeepAlive message (empty JSON object)
                let keepAlive = "{\"type\": \"KeepAlive\"}"
                self.deepgramWebSocket?.send(.string(keepAlive)) { error in
                    if let error = error {
                        print("⚠️ Failed to send KeepAlive to Deepgram: \(error)")
                    }
                }
            }
        } catch {
            connectionStatus = "Failed to start recording: \(error.localizedDescription)"
            print("❌ Recording error: \(error)")
            // Fallback to Whisper
            startWhisperChunkedTranscription()
        }
    }
    
    private func sendAudioChunkToDeepgram() {
        guard let audioURL = recordingURL else {
            return
        }
        
        do {
            // Read entire audio file
            let audioData = try Data(contentsOf: audioURL)
            
            // Only send new data since last position
            guard audioData.count > deepgramAudioPosition else {
                return
            }
            
            let newData = audioData.subdata(in: deepgramAudioPosition..<audioData.count)
            deepgramAudioPosition = audioData.count
            
            // Send raw PCM audio data (not base64, not JSON)
            let message = URLSessionWebSocketTask.Message.data(newData)
            deepgramWebSocket?.send(message) { error in
                if let error = error {
                    print("❌ Failed to send audio to Deepgram: \(error)")
                }
            }
        } catch {
            print("❌ Error reading audio file: \(error)")
        }
    }
    
    private func receiveDeepgramMessage() {
        deepgramWebSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleDeepgramResponse(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleDeepgramResponse(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving
                self?.receiveDeepgramMessage()
                
            case .failure(let error):
                print("❌ Deepgram WebSocket error: \(error)")
                // Fallback to Whisper
                DispatchQueue.main.async {
                    self?.startWhisperChunkedTranscription()
                }
            }
        }
    }
    
    private func handleDeepgramResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Check message type
        guard let messageType = json["type"] as? String else {
            return
        }
        
        // Handle different message types
        switch messageType {
        case "Results":
            // Parse Deepgram transcription response
            if let channel = json["channel"] as? [String: Any],
               let alternatives = channel["alternatives"] as? [[String: Any]],
               let firstAlternative = alternatives.first,
               let transcript = firstAlternative["transcript"] as? String,
               !transcript.isEmpty {
                
                let isFinal = json["is_final"] as? Bool ?? false
                let speechFinal = json["speech_final"] as? Bool ?? false
                
                // Language detection
                if let detectedLanguage = firstAlternative["detected_language"] as? String {
                    print("🌍 Deepgram detected language: \(detectedLanguage)")
                }
                
                DispatchQueue.main.async {
                    if speechFinal {
                        // Speech turn ended - add to buffer
                        self.transcriptBuffer += (self.transcriptBuffer.isEmpty ? "" : " ") + transcript
                        self.transcript = self.transcriptBuffer
                        print("✅ Deepgram speech final: \(transcript)")
                    } else if isFinal {
                        // Final transcript but speech continues
                        self.transcriptBuffer += (self.transcriptBuffer.isEmpty ? "" : " ") + transcript
                        self.transcript = self.transcriptBuffer
                        print("✅ Deepgram final: \(transcript)")
                    } else {
                        // Interim result - show preview
                        let currentBuffer = self.transcriptBuffer
                        let preview = currentBuffer + (currentBuffer.isEmpty ? "" : " ") + transcript
                        self.transcript = preview
                        print("📝 Deepgram interim: \(transcript.prefix(50))...")
                    }
                }
            }
            
        case "Metadata":
            // Connection metadata
            if let requestId = json["request_id"] as? String {
                print("✅ Deepgram connection established: \(requestId)")
            }
            
        case "UtteranceEnd":
            // Utterance ended
            print("🔚 Deepgram utterance ended")
            
        default:
            print("⚠️ Unknown Deepgram message type: \(messageType)")
        }
    }
    
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
        // Send audio to Whisper API every 5 seconds for transcription
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            
            // Pause recording temporarily
            self.audioRecorder?.pause()
            
            // Send current audio to Whisper
            if let audioURL = self.recordingURL {
                self.transcribeWithWhisper(audioURL: audioURL)
            }
            
            // Resume recording
            self.audioRecorder?.record()
        }
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
        
        // Add language parameter
        let language = getLanguageCode().prefix(2) // "en-US" -> "en"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)
        
        // Add audio file
        if let audioData = try? Data(contentsOf: audioURL) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Whisper API error: \(error)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received from Whisper")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    DispatchQueue.main.async {
                        self?.transcriptBuffer = text
                        self?.transcript = text
                        print("✅ Whisper transcription: \(text.prefix(100))...")
                    }
                }
            } catch {
                print("❌ Failed to parse Whisper response: \(error)")
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
        deepgramKeepAliveTimer?.invalidate()
        
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
        
        // Send close message to Deepgram before closing
        if let webSocket = deepgramWebSocket {
            let closeMessage = "{\"type\": \"CloseStream\"}"
            webSocket.send(.string(closeMessage)) { error in
                if let error = error {
                    print("⚠️ Failed to send close to Deepgram: \(error)")
                }
            }
            // Give it a moment to send, then close
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                webSocket.cancel(with: .goingAway, reason: nil)
            }
            deepgramWebSocket = nil
        }
        
        // Stop audio recorder
        audioRecorder?.stop()
        
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
