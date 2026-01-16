import AppKit
import SwiftUI

class MiniWindowController: NSObject {
    var window: NSWindow?
    var audioRecorder: AudioRecorder?
    
    func setAudioRecorder(_ recorder: AudioRecorder) {
        self.audioRecorder = recorder
    }
    
    func showWindow() {
        if window == nil {
            createMiniWindow()
        }
        
        window?.makeKeyAndOrderFront(nil)
        positionWindow()
    }
    
    private func createMiniWindow() {
        let contentView = MiniWindowView(audioRecorder: audioRecorder!)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 280),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = NSColor.clear
        window?.isOpaque = false
        window?.hasShadow = false
        window?.level = .floating  // Always on top!
        window?.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        window?.isMovableByWindowBackground = true
        window?.hidesOnDeactivate = false
        window?.title = "Nota Mini"
        window?.minSize = NSSize(width: 340, height: 240)
        window?.maxSize = NSSize(width: 480, height: 600)
    }
    
    func positionWindow() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        
        // Position at top center of screen
        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.maxY - windowSize.height - 20
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct MiniWindowView: View {
    @ObservedObject var audioRecorder: AudioRecorder
    @State private var selectedTab: Tab = .transcript
    @State private var questionText = ""
    @State private var isHovered = false
    @State private var transcriptSegments: [TranscriptSegment] = []
    
    enum Tab {
        case insights, transcript
    }
    
    struct TranscriptSegment: Identifiable {
        let id = UUID()
        let text: String
        let timestamp: Date
    }
    
    var body: some View {
        // Main glass container with liquid effect
        VStack(spacing: 0) {
            // Header with glass morphism
            headerSection
            
            // Content area with smooth transitions
            if audioRecorder.isRecording || !audioRecorder.transcript.isEmpty {
                contentSection
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
            
            // Chat input with glass effect
            chatInputSection
        }
        .background(
            // Enhanced liquid glass background - 2026 style
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    // Multi-layer gradient for depth
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.06),
                                    Color.clear,
                                    Color.black.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    // Subtle border with gradient
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.3)) {
                isHovered = hovering
            }
        }
        .onChange(of: audioRecorder.transcript) { newValue in
            updateTranscriptSegments(newValue)
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            // Status with glass pill
            HStack(spacing: 8) {
                // Static recording indicator (no animation)
                Circle()
                    .fill(audioRecorder.isRecording ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                    .opacity(audioRecorder.isRecording ? 1.0 : 0.7)
                
                Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                // Show connection status if not ready
                if audioRecorder.isRecording && !audioRecorder.connectionStatus.contains("Recording") {
                    Text("• \(audioRecorder.connectionStatus)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.thinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            
            Spacer()
            
            // Control buttons with glass effect
            HStack(spacing: 8) {
                // Record/Stop button
                Button(action: {
                    print("🔴 DEBUG: Record button clicked! Current state: \(audioRecorder.isRecording)")
                    print("🔴 DEBUG: About to call audioRecorder.startRecording()")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if audioRecorder.isRecording {
                            print("⏹️ DEBUG: Stopping recording...")
                            audioRecorder.stopRecording()
                        } else {
                            print("🎤 DEBUG: Starting recording...")
                            audioRecorder.startRecording()
                        }
                    }
                    print("🔴 DEBUG: Button action completed")
                }) {
                    Image(systemName: audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: audioRecorder.isRecording ? 
                                            [Color.red.opacity(0.9), Color.red.opacity(0.7)] :
                                            [Color.blue.opacity(0.9), Color.blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(
                                    color: audioRecorder.isRecording ? .red.opacity(0.3) : .blue.opacity(0.3),
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Dashboard button
                Button(action: {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.showDashboard()
                    }
                }) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.thinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Dashboard")
                
                // Close button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.miniWindow?.window?.orderOut(nil)
                        }
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.thinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Content Section
    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 0) {
            // Tab selector with liquid glass effect
            HStack(spacing: 0) {
                tabButton("Insights", icon: "lightbulb.fill", tab: .insights)
                tabButton("Transcript", icon: "doc.text.fill", tab: .transcript)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Content area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if selectedTab == .insights {
                        insightsContent
                    } else {
                        transcriptContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(minHeight: 120, maxHeight: 300)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Chat Input Section
    @ViewBuilder
    private var chatInputSection: some View {
        HStack(spacing: 10) {
            TextField("Ask a question...", text: $questionText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.25),
                                            Color.white.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                )
                .onSubmit {
                    if !questionText.isEmpty {
                        print("Question: \(questionText)")
                        questionText = ""
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Helper Methods
    private func tabButton(_ title: String, icon: String, tab: Tab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                selectedTab == tab ? Color.white.opacity(0.3) : Color.clear,
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var insightsContent: some View {
        if audioRecorder.transcript.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary.opacity(0.6))
                
                Text("AI insights will appear here during recording...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if audioRecorder.liveInsights.isEmpty {
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.bottom, 4)
                
                Text("Generating AI insights...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Requires OpenAI API key in Settings")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Live insights header
                    HStack {
                        Text("AI INSIGHTS")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.purple.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(.purple.opacity(0.3), lineWidth: 0.5)
                                    )
                            )
                        
                        Spacer()
                        
                        // Copy insights button
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(audioRecorder.liveInsights, forType: .string)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundStyle(.primary)
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(.thinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Copy insights")
                    }
                    
                    // Display the actual insights
                    Text(audioRecorder.liveInsights)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.purple.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.purple.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private var transcriptContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with copy button
            HStack {
                Text("LIVE TRANSCRIPT")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(.blue.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                
                Spacer()
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(audioRecorder.transcript, forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                        Text("Copy")
                            .font(.caption2)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if transcriptSegments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.6))
                    
                    Text("No transcript yet. Start recording to see live transcription.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Message bubbles like messenger
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(transcriptSegments) { segment in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(segment.text)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(.blue.opacity(0.15))
                                            )
                                        
                                        Text(segment.timestamp, style: .time)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary.opacity(0.7))
                                            .padding(.leading, 4)
                                    }
                                    Spacer()
                                }
                                .id(segment.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: transcriptSegments.count) { _ in
                        if let lastSegment = transcriptSegments.last {
                            withAnimation {
                                proxy.scrollTo(lastSegment.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper to split transcript into segments (incremental, not from scratch)
    private func updateTranscriptSegments(_ fullTranscript: String) {
        // Get the last processed position
        let lastProcessedText = transcriptSegments.last?.text ?? ""
        
        // If transcript is shorter than before, we're starting fresh
        if fullTranscript.count < lastProcessedText.count {
            transcriptSegments.removeAll()
        }
        
        // Find new content only
        let trimmed = fullTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Build the full text from existing segments
        let existingText = transcriptSegments.map { $0.text }.joined(separator: " ")
        
        // If transcript starts differently, reset
        if !trimmed.hasPrefix(existingText.prefix(min(50, existingText.count))) && !existingText.isEmpty {
            transcriptSegments.removeAll()
        }
        
        // Extract only NEW content
        let newContent: String
        if existingText.isEmpty {
            newContent = trimmed
        } else {
            // Find where new content starts
            if trimmed.count > existingText.count {
                let startIndex = trimmed.index(trimmed.startIndex, offsetBy: existingText.count)
                newContent = String(trimmed[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                return // No new content
            }
        }
        
        // Split new content into sentences
        if !newContent.isEmpty {
            // Split by sentence endings
            let sentences = newContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            
            for sentence in sentences {
                let cleaned = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count > 3 { // Minimum 3 characters
                    transcriptSegments.append(TranscriptSegment(
                        text: cleaned,
                        timestamp: Date()
                    ))
                }
            }
            
            // Keep only last 30 segments
            if transcriptSegments.count > 30 {
                transcriptSegments = Array(transcriptSegments.suffix(30))
            }
        }
    }
    
    private func actionButton(_ title: String, icon: String, color: Color) -> some View {
        Button(action: {
            print("\(title) action")
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}